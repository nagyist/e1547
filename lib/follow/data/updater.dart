import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:e1547/client/client.dart';
import 'package:e1547/follow/follow.dart';
import 'package:e1547/logs/logs.dart';
import 'package:e1547/post/post.dart';
import 'package:e1547/tag/tag.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class FollowsUpdater extends ValueNotifier<FollowUpdate?> {
  FollowsUpdater({required this.service}) : super(null);

  final FollowsService service;

  final StreamController<int> _remaining = BehaviorSubject();
  Stream<int> get remaining => _remaining.stream;

  late StreamSubscription<int> _remainingCurrent;

  @override
  set value(FollowUpdate? value) {
    List<Object?> previous = [
      this.value?.client,
      this.value?.denylist,
      this.value?.force,
    ];
    List<Object?> current = [
      value?.client,
      value?.denylist,
      value?.force,
    ];
    bool noneRunning = this.value?.completed ?? true;
    bool dependenciesChanged =
        !const DeepCollectionEquality().equals(previous, current);
    if (noneRunning || dependenciesChanged) {
      if (this.value != null) {
        this.value!.cancel();
        _remainingCurrent.cancel();
      }
      super.value = value;
      if (value != null) {
        _remainingCurrent = value.remaining.listen(
          _remaining.add,
          onError: _remaining.addError,
        );
        value.run();
      }
    }
  }

  void update({
    required Client client,
    required List<String> denylist,
    bool? force,
  }) =>
      value = FollowUpdate(
        service: service,
        client: client,
        denylist: denylist,
        force: force,
      );

  void cancel() => value = null;

  @override
  void dispose() {
    value?.cancel();
    _remaining.close();
    super.dispose();
  }
}

class FollowUpdate with ObjectLoggy {
  FollowUpdate({
    required this.service,
    required this.client,
    required this.denylist,
    this.force,
    this.refreshAmount = 5,
    this.refreshRate = const Duration(hours: 1),
  });

  final int refreshAmount;
  final Duration refreshRate;

  final FollowsService service;
  final Client client;
  final List<String> denylist;
  final bool? force;

  bool _running = false;
  bool get running => _running;

  bool _cancelled = false;
  bool get cancelled => _cancelled;

  void cancel() {
    loggy.debug('Follow update cancelled!');
    _cancelled = true;
  }

  Object? _error;
  Object? get error => _error;

  late final StreamController<int> _remaining = BehaviorSubject()
    ..stream.listen(
      (value) => loggy.debug('Updating $value follows...'),
      onError: (exception, stacktrace) =>
          loggy.error('Follow update failed!', exception, stacktrace),
      onDone: () => loggy.info('Follow update finished!'),
    );

  Stream<int> get remaining => _remaining.stream;

  bool get completed => _remaining.isClosed;

  List<String> _previousTags = [];

  void _assertNoDuplicates(List<String> tags) {
    bool tagsAreDifferent =
        !const DeepCollectionEquality().equals(_previousTags, tags);
    assert(
      tagsAreDifferent,
      'Follow update tried refreshing same follows twice!',
    );
    _previousTags = tags;
  }

  Future<void> run() async {
    if (_running) return;
    _running = true;
    loggy.info('Follow update started!');
    try {
      if (force ?? false) {
        loggy.debug('Force refreshing follows...');
        await service.transaction(() async {
          List<Follow> follows = await service.getAll(
            host: client.host,
            types: [FollowType.notify, FollowType.update],
          );
          for (final follow in follows) {
            await service.replace(follow.copyWith(
              updated: null,
            ));
          }
        });
      }

      while (!cancelled) {
        List<Follow> follows = [];

        follows.addAll(await service.getOutdated(
          host: client.host,
          minAge: refreshRate,
          types: [FollowType.notify, FollowType.update],
        ));

        follows.addAll(await service.getFresh(
          host: client.host,
          types: [FollowType.bookmark],
        ));

        _remaining.add(follows.length);

        List<Follow> singles = follows.where((e) => e.isSingle).toList();
        if (singles.isNotEmpty) {
          List<Follow> updates = await _refreshSingles(singles);
          await service.transaction(() async {
            for (final update in updates) {
              await service.replace(update);
            }
          });
          continue;
        }

        List<Follow> multiples = follows.whereNot(singles.contains).toList();
        if (multiples.isNotEmpty) {
          Follow update = await _refreshMultiples(multiples);
          await service.replace(update);
          continue;
        }

        break;
      }
    } on ClientException catch (error, stacktrace) {
      _remaining.addError(error, stacktrace);
    } finally {
      _remaining.close();
    }
  }

  Future<List<Follow>> _refreshSingles(List<Follow> singles) async {
    List<Follow> follows = singles.take(40).toList();
    List<String> tags = follows.map((e) => e.tags).toList();
    _assertNoDuplicates(tags);

    int limit = follows.length * refreshAmount;
    List<Post> allPosts = await rateLimit(client.postsByTags(
      tags,
      1,
      limit: limit,
      force: force,
    ));

    Map<Follow, List<Post>> assign(List<Follow> follows, List<Post> posts) {
      Map<Follow, List<Post>> result = {};
      for (final follow in follows) {
        result.putIfAbsent(follow, () => []);
        for (final post in posts) {
          if (post.hasTag(follow.alias ?? follow.tags)) {
            result.update(
              follow,
              (value) => value..add(post),
            );
          }
        }
      }
      return result;
    }

    Map<Follow, List<Post>> updates = assign(follows, allPosts);

    bool hasLeftovers() {
      List<Post> picked = updates.values.flattened.toList();
      List<Post> leftovers = allPosts.whereNot(picked.contains).toList();
      return leftovers.isNotEmpty;
    }

    if (hasLeftovers()) {
      for (final update in Map.from(updates).entries) {
        Follow follow = update.key;
        List<Post> posts = update.value;
        if (posts.isNotEmpty) continue;
        String? alias = await rateLimit(client.tagAlias(follow.tags));
        if (alias != follow.alias) {
          Follow updated = follow.copyWith(alias: alias);
          updates[updated] = updates.remove(follow)!;
          loggy.info(
            'Follow update corrected alias for ${follow.tags} to $alias',
          );
          updates = assign(updates.keys.toList(), allPosts);
          if (!hasLeftovers()) break;
        }
      }
    }

    List<Follow> result = [];
    for (final update in updates.entries) {
      Follow follow = update.key;
      List<Post> posts = update.value;
      bool limitReached = posts.length >= 5;
      bool latestReached = posts.any((e) => e.id == follow.latest);
      bool depleted = allPosts.length < limit;
      if ([limitReached, latestReached, depleted].any((e) => e)) {
        posts.removeWhere((e) => e.isIgnored() || e.isDeniedBy(denylist));
        result.add(follow.withUnseen(posts));
      }
    }
    return result;
  }

  Future<Follow> _refreshMultiples(List<Follow> multiples) async {
    Follow follow = multiples.first;
    _assertNoDuplicates([follow.tags]);

    List<Post> posts = await rateLimit(client.posts(
      1,
      search: follow.tags,
      limit: refreshAmount,
      ordered: false,
      force: force,
    ));
    posts.removeWhere((e) => e.isIgnored() || e.isDeniedBy(denylist));
    follow = follow.withUnseen(posts);
    RegExpMatch? match = poolRegex().firstMatch(follow.tags);
    if (follow.title == null && match != null) {
      try {
        follow = follow.withPool(
          await client.pool(
            int.parse(match.namedGroup('id')!),
            force: force,
          ),
        );
      } on ClientException catch (e) {
        if (e.response?.statusCode == HttpStatus.notFound) {
          follow = follow.copyWith(
            type: FollowType.bookmark,
          );
          loggy.info(
            'Follow update found no pool for ${follow.tags}. Set to bookmarked!',
          );
        } else {
          rethrow;
        }
      }
    }
    return follow;
  }
}
