import 'package:e1547/interface/interface.dart';
import 'package:flutter/foundation.dart';

class Tagset extends Iterable<StringTag> {
  Tagset(Set<StringTag> tags) : _tags = {for (final t in tags) t.name: t};

  Tagset.parse(String tagString) : _tags = {} {
    for (final ts in tagString.split(' ').trim()) {
      if (ts.trim().isEmpty) {
        continue;
      }
      StringTag t = StringTag.parse(ts);
      _tags[t.name] = t;
    }
  }

  final Map<String, StringTag> _tags;

  String get link => '/posts?tags=${toString()}';

  @override
  bool contains(Object? element) => _tags.containsValue(element);

  bool containsTag(String tag) => _tags.containsKey(tag);

  String? operator [](String? name) {
    StringTag? t = _tags[name!];
    if (t == null) {
      return null;
    }

    return t.value;
  }

  void operator []=(String name, String? value) {
    _tags[name] = StringTag(name, value);
  }

  void remove(String? name) {
    _tags.remove(name);
  }

  @override
  Iterator<StringTag> get iterator => _tags.values.iterator;

  List<String> toStringList() {
    List<StringTag> sorted = List.of(_tags.values)..sort();
    return sorted.map((e) => e.toString()).toList();
  }

  @override
  String toString() => toStringList().join(' ');
}

@immutable
class StringTag implements Comparable<StringTag> {
  const StringTag(this.name, [this._value]);

  factory StringTag.parse(String tag) {
    tag = tag.trim();
    if (tag.isEmpty) throw ArgumentError('StringTag cannot be empty.');
    List<String> parts = tag.split(':');
    String name = parts.first;
    String? value = parts.skip(1).join(':');
    return StringTag(name, value);
  }

  final String name;
  final String? _value;
  String? get value => _value?.isNotEmpty ?? false ? _value : null;

  @override
  String toString() => '$name${value != null ? ':$value' : ''}';

  @override
  bool operator ==(Object other) =>
      other is StringTag && name == other.name && value == other.value;

  @override
  int get hashCode => toString().hashCode;

  @override
  int compareTo(StringTag other) {
    // meta tags come after normal tags
    if (value != null) {
      if (other.value == null) {
        return 1;
      }
    } else if (other.value != null) {
      return -1;
    }

    // regular tags, then optional, then subtracting
    int getPrefix(String prefix) {
      switch (prefix[0]) {
        case '-':
          return 1;
        case '~':
          return 0;
        default:
          return -1;
      }
    }

    int out = getPrefix(name).compareTo(getPrefix(other.name));
    if (out == 0) {
      out = name.compareTo(other.name);
    }
    return out;
  }
}
