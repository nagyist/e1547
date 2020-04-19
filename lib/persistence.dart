import 'dart:async' show Future;

import 'package:flutter/foundation.dart' show ValueNotifier;

import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

import 'package:e1547/appinfo.dart' as appInfo;
import 'tag.dart' show Tagset;

typedef T _SharedPreferencesReceiver<T>(SharedPreferences prefs);

final Persistence db = new Persistence();

class Persistence {
  ValueNotifier<Future<String>> host;
  ValueNotifier<Future<Tagset>> homeTags;
  ValueNotifier<Future<String>> username;
  ValueNotifier<Future<String>> apiKey;
  ValueNotifier<Future<bool>> showWebm;
  ValueNotifier<Future<List<String>>> blacklist;

  Persistence() {
    host = _makeNotifier((p) => p.getString('host') ?? appInfo.defaultEndpoint);
    host.addListener(_saveString('host', host));

    homeTags = _makeNotifier((p) => new Tagset.parse(p.getString('homeTags') ?? ''));
    homeTags.addListener(_saveString('homeTags', homeTags));

    username = _makeNotifier((p) => p.getString('username'));
    username.addListener(_saveString('username', username));

    apiKey = _makeNotifier((p) => p.getString('apiKey'));
    apiKey.addListener(_saveString('apiKey', apiKey));

    showWebm = _makeNotifier((p) => p.getBool('showWebm') ?? true);
    showWebm.addListener(_saveBool('showWebm', showWebm));

    blacklist = _makeNotifier((p) => p.getStringList('blacklist') ?? []);
    blacklist.addListener(_saveList('blacklist', blacklist));
  }

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  ValueNotifier<Future<T>> _makeNotifier<T>(
      _SharedPreferencesReceiver<T> receiver) {
    return new ValueNotifier(_prefs.then(receiver));
  }

  Function() _saveString(String key, ValueNotifier<Future<dynamic>> notifier) {
    return () async {
      var val = await notifier.value;
      (await _prefs).setString(key, val != null ? val.toString() : null);
    };
  }

  Function() _saveList(String key, ValueNotifier<Future<List<String>>> notifier) {
    return () async {
      (await _prefs).setStringList(key, await notifier.value);
    };
  }

  Function() _saveBool(String key, ValueNotifier<Future<bool>> notifier) {
    return () async {
      (await _prefs).setBool(key, await notifier.value);
    };
  }

  Function() _saveInt(String key, ValueNotifier<Future<int>> notifier) {
    return () async {
      (await _prefs).setInt(key, await notifier.value);
    };
  }


}
