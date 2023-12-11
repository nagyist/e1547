import 'dart:io';

import 'package:dio_cache_interceptor_db_store/dio_cache_interceptor_db_store.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:e1547/app/app.dart';
import 'package:e1547/logs/logs.dart';
import 'package:flutter/widgets.dart';
import 'package:notified_preferences/notified_preferences.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

export 'package:e1547/logs/logs.dart' show Logs;
export 'package:e1547/settings/settings.dart' show AppInfo;
export 'package:window_manager/window_manager.dart' show WindowManager;

/// Initializes an AppInfo with default production values.
Future<void> initializeAppInfo() async => AppInfo.initializePlatform(
      developer: 'binaryfloof',
      github: 'clragon/e1547',
      discord: 'MRwKGqfmUz',
      website: 'e1547.clynamic.net',
      kofi: 'binaryfloof',
      email: 'support@clynamic.net',
    );

/// Initializes the storages used by the app with default production values.
Future<AppStorage> initializeAppStorage() async {
  final String temporaryFiles = await getTemporaryDirectory()
      .then((value) => join(value.path, AppInfo.instance.appName));
  return AppStorage(
    preferences: await SharedPreferences.getInstance(),
    temporaryFiles: temporaryFiles,
    httpCache: DbCacheStore(databasePath: temporaryFiles),
    sqlite: AppDatabase(connectDatabase('app.db')),
  );
}

DatabaseConnection connectDatabase(String name) =>
    DatabaseConnection.delayed(Future(
      () async => NativeDatabase.createBackgroundConnection(
        File(
          join((await getApplicationSupportDirectory()).path, name),
        ),
      ),
    ));

/// Initializes the logger used by the app with default production values.
Future<Logs> initializeLogger({
  required String path,
  String? postfix,
  List<LogPrinter>? printers,
}) async {
  Logger.root.level = Level.ALL;

  Logs logs = Logs();
  File logFile = createLogFile(path, postfix);

  printers ??= [];
  printers.add(logs);
  printers.add(FileLogPrinter(logFile));
  printers.add(const ConsoleLogPrinter());

  for (final printer in printers) {
    printer.connect(Logger.root.onRecord);
  }

  registerFlutterErrorHandler(
    (error, trace) => Logger('Flutter').log(
      Level.SHOUT,
      error,
      error,
      trace,
    ),
  );
  return logs;
}

File createLogFile(String directoryPath, String? postfix) {
  File logFile = File(join(directoryPath,
      '${logFileDateFormat.format(DateTime.now())}${postfix != null ? '.$postfix' : ''}.log'));

  Directory dir = Directory(directoryPath);
  List<File> logFiles = dir
      .listSync()
      .whereType<File>()
      .where((entity) => entity.path.endsWith('.log'))
      .toList();

  DateTime getFileDate(String fileName) {
    var name = basenameWithoutExtension(fileName);
    return logFileDateFormat.parse(name);
  }

  logFiles.sort((a, b) => getFileDate(b.path).compareTo(getFileDate(a.path)));

  if (logFiles.length > 50) {
    for (final oldFile in logFiles.sublist(10)) {
      oldFile.deleteSync();
    }
  }

  return logFile;
}

/// Registers an error callback for uncaught exceptions and flutter errors.
void registerFlutterErrorHandler(
  void Function(Object error, StackTrace? trace) handler,
) {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    handler(error, stack);
    return false;
  };
  FlutterError.onError = (details) => handler(details.exception, details.stack);
}

/// Returns an initialized WindowManager or null the current Platform is unsupported.
Future<WindowManager?> initializeWindowManager() async {
  if ([Platform.isWindows, Platform.isLinux, Platform.isMacOS].any((e) => e)) {
    WindowManager manager = WindowManager.instance;
    await manager.ensureInitialized();
    return manager;
  }
  return null;
}
