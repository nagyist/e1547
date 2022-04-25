import 'dart:async';

import 'package:e1547/client/client.dart';
import 'package:e1547/denylist/denylist.dart';
import 'package:e1547/follow/follow.dart';
import 'package:e1547/history/history.dart';
import 'package:e1547/interface/interface.dart';
import 'package:e1547/pool/pool.dart';
import 'package:e1547/post/post.dart';
import 'package:e1547/settings/settings.dart';
import 'package:e1547/topic/topic.dart';
import 'package:e1547/user/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  await initialize();
  runApp(App());
}

Future<void> initialize() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await initializeSettings();
  await initializeAppInfo();
  initializeHttpCache();
}

class App extends StatelessWidget {
  @override
  Widget build(context) => NavigationData(
        controller: _topLevelNavigationController,
        child: ValueListenableBuilder<AppTheme>(
          valueListenable: settings.theme,
          builder: (context, value, child) => ExcludeSemantics(
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: appThemeMap[value]!.appBarTheme.systemOverlayStyle!,
              child: MaterialApp(
                title: appInfo.appName,
                theme: appThemeMap[value],
                routes: NavigationData.of(context).routes,
                navigatorObservers: [
                  NavigationData.of(context).routeObserver,
                ],
                scrollBehavior: DesktopScrollBehaviour(),
                builder: (context, child) => StartupActions(
                  child: child!,
                  actions: [
                    initializeUserAvatar,
                    (_) => denylistController.update(),
                    (_) => followController.update(),
                    (_) => initializeDateFormatting(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

final NavigationController _topLevelNavigationController =
    NavigationController(destinations: _topLevelDestinations);

final List<NavigationRouteDestination> _topLevelDestinations = [
  NavigationDrawerDestination(
    path: '/',
    name: 'Home',
    icon: Icon(Icons.home),
    builder: (context) => HomePage(),
    unique: true,
    group: DrawerGroup.search.name,
  ),
  NavigationDrawerDestination(
    path: '/hot',
    name: 'Hot',
    icon: Icon(Icons.whatshot),
    builder: (context) => HotPage(),
    unique: true,
    group: DrawerGroup.search.name,
  ),
  NavigationDrawerDestination(
    path: '/search',
    name: 'Search',
    icon: Icon(Icons.search),
    builder: (context) => SearchPage(),
    group: DrawerGroup.search.name,
  ),
  NavigationDrawerDestination(
    path: '/fav',
    name: 'Favorites',
    icon: Icon(Icons.favorite),
    builder: (context) => FavPage(),
    unique: true,
    group: DrawerGroup.collection.name,
  ),
  NavigationDrawerDestination(
    path: '/follows',
    name: 'Following',
    icon: Icon(Icons.turned_in),
    builder: (context) => FollowsPage(),
    unique: true,
    group: DrawerGroup.collection.name,
  ),
  NavigationDrawerDestination(
    path: '/pools',
    name: 'Pools',
    icon: Icon(Icons.collections),
    builder: (context) => PoolsPage(),
    unique: true,
    group: DrawerGroup.collection.name,
  ),
  NavigationDrawerDestination(
    path: '/topics',
    name: 'Forum',
    icon: Icon(Icons.forum),
    builder: (context) => TopicsPage(),
    visible: (context) => settings.showBeta.value,
    unique: true,
    group: DrawerGroup.collection.name,
  ),
  NavigationDrawerDestination(
    path: '/history',
    name: 'History',
    icon: Icon(Icons.history),
    builder: (context) => HistoryPage(),
    visible: (context) => settings.writeHistory.value,
    group: DrawerGroup.settings.name,
  ),
  NavigationDrawerDestination(
    path: '/settings',
    name: 'Settings',
    icon: Icon(Icons.settings),
    builder: (context) => SettingsPage(),
    group: DrawerGroup.settings.name,
  ),
  NavigationDrawerDestination(
    path: '/about',
    name: 'About',
    icon: DrawerUpdateIcon(),
    builder: (context) => AboutPage(),
    group: DrawerGroup.settings.name,
  ),
  NavigationRouteDestination(
    path: '/login',
    builder: (context) => LoginPage(),
  ),
  NavigationRouteDestination(
    path: '/blacklist',
    builder: (context) => DenyListPage(),
  ),
  NavigationRouteDestination(
    path: '/following',
    builder: (context) => FollowingPage(),
  ),
];
