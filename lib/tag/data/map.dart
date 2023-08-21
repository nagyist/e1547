import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

/// A collection of parameters.
///
/// Entries are comprised of a name and an optional value.
/// They are sorted by
///
/// A key may be present multiple times with different values.
/// When accessing a key, the first value is returned.
/// To access all values of a key, use [toMapAll].
class QueryMap extends MapBase<String, String?> {
  /// Creates an empty query map.
  QueryMap() : _tags = SplayTreeSet<QueryValue>();

  /// Creates a query map from a map.
  factory QueryMap.from(Map<String, String?> other) =>
      QueryMap()..addAll(other);

  /// Creates a query map from a string.
  ///
  /// Input is expected to be in the format `name:value name2`.
  factory QueryMap.parse(String tags) {
    QueryMap result = QueryMap();
    result._tags.addAll(
      tags.trim().split(' ').where((e) => e.isNotEmpty).map(QueryValue.parse),
    );
    return result;
  }

  final Set<QueryValue> _tags;

  List<String> get tags => _tags.map((tag) => tag.toString()).toList();

  @override
  String? operator [](Object? key) =>
      _tags.firstWhereOrNull((tag) => tag.name == key)?.value;

  @override
  void operator []=(String key, String? value) {
    remove(key);
    _tags.add(QueryValue(key, value));
  }

  @override
  void clear() => _tags.clear();

  @override
  Iterable<String> get keys => _tags.map((tag) => tag.name);

  @override
  String? remove(Object? key) {
    for (final tag in _tags) {
      if (tag.name == key) {
        _tags.remove(tag);
        return tag.value;
      }
    }
    return null;
  }

  @override
  String toString() => _tags.map((tag) => tag.toString()).join(' ');

  /// Returns a new QueryMap with the same values.
  Map<String, String?> toMap() => QueryMap.from(this);

  Map<String, List<String?>> toMapAll() {
    Map<String, List<String?>> result = {};
    for (final tag in _tags) {
      if (result.containsKey(tag.name)) {
        result[tag.name]!.add(tag.value);
      } else {
        result[tag.name] = [tag.value];
      }
    }
    return result;
  }
}

/// Represents a tag with a name and an optional value.
///
/// Can be parsed from a string in the format `name:value`.
@immutable
class QueryValue implements Comparable<QueryValue> {
  const QueryValue(this.name, [this.value]);

  factory QueryValue.parse(String tag) {
    List<String> result = tag.split(':');
    String? value;
    if (result.length > 1) {
      value = result.sublist(1).join(':');
    }
    return QueryValue(result[0], value);
  }

  final String name;
  final String? value;

  @override
  String toString() => value == null ? name : '$name:$value';

  @override
  bool operator ==(Object other) =>
      other is QueryValue && name == other.name && value == other.value;

  @override
  int get hashCode => Object.hash(name, value);

  /// Whether this value starts with a special character instead of a letter.
  ///
  /// Usually, those values are meant to denote special syntax.
  bool get _isSpecial => RegExp(r'^[a-zA-Z]').hasMatch(name);

  /// Compares this vlaue to another value.
  @override
  int compareTo(QueryValue other) {
    if (value == null && other.value != null) return 1;
    if (value != null && other.value == null) return -1;
    if (_isSpecial != other._isSpecial) {
      if (_isSpecial) return 1;
      if (other._isSpecial) return -1;
      return name[0].compareTo(other.name[0]);
    }
    if (name != other.name) return name.compareTo(other.name);
    if (value == null && other.value == null) return 0;
    return value!.compareTo(other.value!);
  }
}
