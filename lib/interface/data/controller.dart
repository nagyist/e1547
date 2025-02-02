import 'dart:async';

import 'package:collection/collection.dart';
import 'package:e1547/interface/interface.dart';
import 'package:flutter/foundation.dart';
import 'package:mutex/mutex.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

export 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

abstract class DataController<KeyType, ItemType>
    extends PagingController<KeyType, ItemType> {
  /// A controller for a paged widget.
  DataController({required super.firstPageKey}) {
    super.addPageRequestListener(loadPage);
    _refreshListeners.forEach((e) => e.addListener(refresh));
    super.addListener(_maybeReset);
  }

  /// Ensures we do not request duplicate pages.
  final PageLock<KeyType> _pageLock = PageLock<KeyType>();

  /// Used to prevent calling listeners after disposal.
  bool _disposed = false;

  /// List of [Listenable]s which will trigger a refresh on notification.
  late final List<Listenable> _refreshListeners = getRefreshListeners();

  @override
  void dispose() {
    super.removePageRequestListener(loadPage);
    _refreshListeners.forEach((e) => e.removeListener(refresh));
    super.removeListener(_maybeReset);
    _disposed = true;
    super.dispose();
  }

  /// Called to get the next page of items for [page].
  @protected
  Future<PageResponse<KeyType, ItemType>> requestPage(KeyType page, bool force);

  /// Loads a page of items and adds them to the list.
  ///
  /// - If reset is true, the list will be emptied before adding the new items.
  /// - If background is true, the new items are loaded before the list is reset.
  /// - If force is true, the item cache is ignored.
  @protected
  Future<void> loadPage(
    KeyType page, {
    bool reset = false,
    bool background = false,
    bool force = false,
  }) async {
    await _pageLock.protect(
      page,
      reset: reset,
      () async {
        if (reset) {
          if (background) {
            this.reset();
          } else {
            value = PagingState<KeyType, ItemType>(
              nextPageKey: page,
            );
          }
        }
        PageResponse<KeyType, ItemType> response =
            await requestPage(page, force);
        if (_disposed) return;
        if (response.error != null) {
          failure(response.error!);
          throw KeyWasNotUsedException(page);
        }
        if (reset) {
          this.reset(hasLoaded: true);
          value = response.toState();
        } else {
          appendPage(response.itemList!, response.nextPageKey);
        }
        success();
      },
    );
  }

  /// Called when a request of this controller fails.
  @protected
  @mustCallSuper
  void failure(Object error) {
    if (_disposed) return;
    this.error = error;
  }

  /// Called when a request of this controller succeeds.
  @protected
  @mustCallSuper
  void success() {}

  @override
  void refresh({bool force = false, bool background = false}) async {
    return loadPage(
      firstPageKey,
      reset: true,
      background: background,
      force: force,
    );
  }

  /// Allows adding listeners that trigger a refresh by overriding this function.
  ///
  /// Can be used in mixins which do not have a constructor.
  @protected
  @mustCallSuper
  List<Listenable> getRefreshListeners() => [];

  /// Called when the [itemList] is changed entirely.
  @protected
  @mustCallSuper
  void reset({bool hasLoaded = false}) {}

  /// Calls [reset] if the [itemList] has been set to null.
  void _maybeReset() {
    if (value.itemList == null) {
      reset();
    }
  }

  /// Ensures that the controller contains the [item] in its [itemList]
  @protected
  void assertOwnsItem(ItemType item) {
    if (itemList == null || !itemList!.contains(item)) {
      throw StateError('$runtimeType doesn\'t own this ${item.runtimeType}');
    }
  }

  /// Replaces the [item] at [index] in the [itemList].
  void updateItem(int index, ItemType item) {
    if ((itemList?.length ?? -1) < index) {
      throw StateError('$runtimeType doesn\'t have an item at $index');
    }
    List<ItemType> updated = List.from(itemList!);
    updated[index] = item;
    value = PagingState(
      nextPageKey: nextPageKey,
      itemList: updated,
      error: error,
    );
  }
}

class PageResponse<KeyType, ItemType> {
  /// The response for a page request.
  const PageResponse({
    required List<ItemType> this.itemList,
    required this.nextPageKey,
  }) : error = null;

  /// The response for a page request.
  ///
  /// Is treated as the last page to be added.
  const PageResponse.last({
    required List<ItemType> this.itemList,
  })  : nextPageKey = null,
        error = null;

  /// The response for a page request.
  ///
  /// Is treated as a failed page request.
  const PageResponse.error({
    required Object this.error,
  })  : itemList = null,
        nextPageKey = null;

  /// The key for the next page.
  ///
  /// If null, this is treated as the last page.
  final KeyType? nextPageKey;

  /// The list of items for this page.
  final List<ItemType>? itemList;

  /// The error that was thrown during loading this page.
  final Object? error;

  PagingState<KeyType, ItemType> toState() => PagingState<KeyType, ItemType>(
        itemList: itemList,
        nextPageKey: nextPageKey,
      );
}

class PageLock<KeyType> {
  /// Keeps track of what keys have been used to paginate.
  ///
  /// Using keys requires requesting and releasing a Mutex lock to ensure key exclusivity.
  PageLock();

  /// Protects operations on the list of used keys.
  final Mutex _mutex = Mutex();

  /// Whether the lock is currently locked.
  bool get isLocked => _mutex.isLocked;

  /// List of all used up keys.
  final List<KeyType> _used = [];

  /// The key which is currently used.
  KeyType? _currentKey;

  /// The key which is currently used.
  KeyType? get currentKey => _currentKey;

  /// Acquires the lock for a [key].
  ///
  /// If the [key] has already been used, the lock will not be acquired
  /// and a [KeyAlreadyUsedException] will be thrown.
  ///
  /// If [reset] is true, all used keys will be cleared before usage.
  Future<void> acquire(KeyType key, {bool reset = false}) async {
    await _mutex.acquire();
    if (reset) {
      _used.clear();
    }
    if (_used.contains(key)) {
      throw KeyAlreadyUsedException<KeyType>(key);
    }
    _currentKey = key;
  }

  /// Releases the lock for a [key].
  ///
  /// If the [key] is null, it will count as unused.
  ///
  /// It is an error if the [key] to be released does not match the key that was acquired.
  void release(KeyType? key) {
    try {
      if (key == null) {
        return;
      }
      if (key != _currentKey) {
        throw StateError(
            'Attempted to release $key, but current key was $_currentKey!');
      }
      _used.add(key);
    } finally {
      _currentKey = null;
      _mutex.release();
    }
  }

  /// This method guarantees a lock is always acquired before invoking the
  /// [criticalSection] function. It also guarantees the lock is always
  /// released.
  ///
  /// If the key was already used,
  /// the [criticalSection] function will not be called.
  ///
  /// If an exception occurs in the [criticalSection] function, the key will not be used.
  Future<T?> protect<T>(
    KeyType key,
    Future<T> Function() criticalSection, {
    bool reset = false,
  }) async {
    KeyType? outKey;
    try {
      await acquire(key, reset: reset);
      T result = await criticalSection();
      outKey = key;
      return result;
    } on KeyAlreadyUsedException<KeyType> {
      return null;
    } on KeyWasNotUsedException<KeyType> {
      return null;
    } finally {
      release(outKey);
    }
  }

  /// Waits for the current key operation to complete, if there is any.
  Future<void> wait() async => _mutex.protect(() async {});

  /// Clears all used keys.
  ///
  /// Does not interrupt key operations.
  Future<void> reset() async => _mutex.protect(() async => _used.clear());
}

class KeyAlreadyUsedException<KeyType> implements Exception {
  /// Exception thrown when a key was attempted to be used again in a [PageLock].
  const KeyAlreadyUsedException(this.key);

  /// The key that was attempted to be used.
  final KeyType key;

  @override
  String toString() => '$runtimeType: $key was already used!';
}

class KeyWasNotUsedException<KeyType> implements Exception {
  /// Exception thrown when a key that was acquired in a [PageLock] wasn't used (e.g. because the operation didn't complete).
  const KeyWasNotUsedException(this.key);

  /// The key that was attempted to be used.
  final KeyType key;

  @override
  String toString() => '$runtimeType: $key was not used!';
}

mixin FilterableController<PageKeyType, ItemType>
    on DataController<PageKeyType, ItemType> {
  /// List of actual items of this controller.
  List<ItemType>? _rawItemList;

  /// List of actual items of this controller.
  List<ItemType>? get rawItemList => _rawItemList.maybeUnmodifiable();

  /// List of actual items of this controller.
  set rawItemList(List<ItemType>? value) {
    _rawItemList = value;
    this.value = PagingState(
      nextPageKey: nextPageKey,
      itemList: _rawItemList != null ? filter(_rawItemList!) : null,
      error: error,
    );
  }

  /// Corresponding to ValueNotifier.value.
  ///
  /// Passing filtered items for [itemList] in [PagingState] is an error,
  /// because it will lead to those filtered items being excluded from the new [rawItemList]
  /// and effectively being lost.
  @override
  set value(PagingState<PageKeyType, ItemType> state) {
    const equality = DeepCollectionEquality();
    final bool rawItemsIsItems = equality.equals(_rawItemList, itemList);
    final bool itemsIsNotNewItems = !equality.equals(itemList, state.itemList);
    assert(
      rawItemsIsItems || itemsIsNotNewItems,
      'Filtering error in $runtimeType!\nDo not pass filtered items as [itemList] for [PagingState], '
      'because this will lead to the erasure of filtered items!\n',
    );
    _rawItemList = state.itemList;
    super.value = PagingState(
      nextPageKey: state.nextPageKey,
      itemList: _rawItemList != null ? filter(_rawItemList!) : null,
      error: state.error,
    );
  }

  @override
  void appendPage(List<ItemType> newItems, PageKeyType? nextPageKey) {
    value = PagingState(
      itemList: (_rawItemList ?? []) + newItems,
      nextPageKey: nextPageKey,
    );
  }

  @override
  void updateItem(int index, ItemType item, {bool force = false}) {
    if ((itemList?.length ?? -1) < index) {
      throw StateError('$runtimeType doesn\'t have an item at $index');
    }
    _rawItemList![_rawItemList!.indexOf(itemList![index])] = item;
    refilter();
  }

  /// Filters items and returns the filtered list.
  @protected
  List<ItemType> filter(List<ItemType> items);

  /// Reapplies filtering after the filter variables have changed.
  @protected
  void refilter() {
    if (_rawItemList == null) return;
    value = PagingState(
      nextPageKey: nextPageKey,
      itemList: _rawItemList,
      error: error,
    );
  }
}

mixin SearchableController<PageKeyType, ItemType>
    on DataController<PageKeyType, ItemType> {
  /// The current search of this controller.
  ValueNotifier<String> get search => ValueNotifier<String>('');

  @override
  @protected
  List<Listenable> getRefreshListeners() =>
      super.getRefreshListeners()..add(search);

  @override
  void dispose() {
    super.dispose();
    search.dispose();
  }
}

mixin RefreshableController<PageKeyType, ItemType>
    on DataController<PageKeyType, ItemType> {
  /// The [RefreshController] for this controller.
  ///
  /// Will automatically be set to the right states (success and failure).
  /// Note that it is not reusable.
  RefreshController refreshController = RefreshController();

  @override
  @protected
  void failure(Object error) {
    super.failure(error);
    refreshController.refreshFailed();
  }

  @override
  @protected
  void success() {
    super.success();
    refreshController.refreshCompleted();
  }

  @override
  void dispose() {
    super.dispose();
    refreshController.dispose();
  }
}

extension DataControllerLoading on DataController {
  /// Waits for the first Page of this controller to be loaded.
  ///
  /// If the controller has already loaded the page, will return immediately.
  /// Does not trigger a new page load on it's own.
  ///
  /// If the page load fails with an error, the error is thrown.
  Future<void> waitForFirstPage() async {
    await Future.delayed(Duration.zero);
    Completer<void> completer = Completer<void>();

    void onUpdate() {
      switch (value.status) {
        case PagingStatus.loadingFirstPage:
          // ignored
          break;
        case PagingStatus.ongoing:
        case PagingStatus.noItemsFound:
        case PagingStatus.completed:
          removeListener(onUpdate);
          completer.complete();
          break;
        case PagingStatus.firstPageError:
        case PagingStatus.subsequentPageError:
          removeListener(onUpdate);
          completer.completeError(error);
          break;
      }
    }

    if (_disposed) return;
    addListener(onUpdate);
    onUpdate();
    return completer.future;
  }

  /// Requests and waits for the first Page of this controller to be loaded.
  /// Triggers a page request for the first page key.
  Future<void> loadFirstPage() async {
    Future<void> loaded = waitForFirstPage();
    if (nextPageKey == firstPageKey) {
      notifyPageRequestListeners(nextPageKey);
      await loaded;
    }
  }
}
