import 'dart:async';
import 'dart:io';

import 'package:e1547/interface/interface.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:talker/talker.dart';

export 'package:talker/talker.dart' show TalkerDataInterface;

class LoggerPage extends StatelessWidget {
  const LoggerPage({super.key, required this.talker});

  final Talker talker;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: talker.stream,
      builder: (context, child) => Scaffold(
        appBar: const DefaultAppBar(
          title: Text('Logs'),
        ),
        body: talker.history.isNotEmpty
            ? LimitedWidthLayout.builder(
          builder: (context) => ListView.builder(
            reverse: true,
            padding: LimitedWidthLayout.of(context)
                .padding
                .add(defaultActionListPadding),
            itemCount: talker.history.length,
            itemBuilder: (context, index) => LoggerCard(
              item: talker.history.reversed.toList()[index],
            ),
          ),
        )
            : const Center(
          child: IconMessage(
            title: Text('No log items!'),
            icon: Icon(
              Icons.close,
            ),
          ),
        ),
        floatingActionButton: talker.history.isNotEmpty
            ? FloatingActionButton(
          onPressed: () async {
            if (Platform.isAndroid || Platform.isIOS) {
              Directory temp = await getTemporaryDirectory();
              File log = File(join(
                  temp.path, '${DateTime.now().toIso8601String()}.log'));
              await log.writeAsString(talker.history.text, flush: true);
              await Share.shareFiles([log.path]);
              await log.delete();
            } else {
              Clipboard.setData(
                ClipboardData(text: talker.history.text),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  duration: Duration(seconds: 1),
                  content: Text('Copied to clipboard'),
                ),
              );
            }
          },
          child: const Icon(Icons.file_download),
        )
            : null,
      ),
    );
  }
}

class LoggerCard extends StatefulWidget {
  const LoggerCard({
    super.key,
    required this.item,
    this.expanded = false,
  });

  final TalkerDataInterface item;
  final bool expanded;

  @override
  State<LoggerCard> createState() => _LoggerCardState();
}

class _LoggerCardState extends State<LoggerCard> {
  TalkerDataInterface get item => widget.item;

  late ExpandableController controller =
  ExpandableController(initialExpanded: widget.expanded);

  @override
  void didUpdateWidget(covariant LoggerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded != widget.expanded) {
      controller.expanded = widget.expanded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExpandableNotifier(
      controller: controller,
      child: ScrollOnExpand(
        child: ExpandableTheme(
          data: ExpandableThemeData(
            headerAlignment: ExpandablePanelHeaderAlignment.center,
            iconColor: item.logLevel.color,
          ),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.bodyText2!.copyWith(
                  color: item.logLevel.color,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  fit: StackFit.passthrough,
                  children: [
                    Container(
                      margin: const EdgeInsets.all(4).copyWith(bottom: 0),
                      padding: const EdgeInsets.all(10).copyWith(top: 20),
                      decoration: BoxDecoration(
                        border: Border.all(color: item.logLevel.color),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ExpandablePanel(
                                  collapsed: Text(item.logShort),
                                  expanded: Text(item.logLong),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 16,
                      top: -8,
                      child: Container(
                        color: Theme.of(context).cardColor,
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 10),
                        child: Text(item.logTitle),
                      ),
                    ),
                    if (item.logShort != item.logLong)
                      Positioned(
                        right: 16,
                        top: -10,
                        child: Material(
                          color: Theme.of(context).cardColor,
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(text: item.logMessage),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      duration: Duration(seconds: 1),
                                      content: Text('Copied to clipboard'),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Icon(
                                    Icons.copy,
                                    size: 20,
                                    color: item.logLevel.color,
                                  ),
                                ),
                              ),
                              Builder(
                                builder: (context) => InkWell(
                                  onTap:
                                  ExpandableController.of(context)?.toggle,
                                  child: ExpandableIcon(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoggerErrorNotifier extends StatefulWidget {
  const LoggerErrorNotifier({
    super.key,
    required this.child,
    required this.talker,
    this.onOpenLogs,
  });

  final Widget child;
  final Talker talker;
  final VoidCallback? onOpenLogs;

  @override
  State<LoggerErrorNotifier> createState() => _LoggerErrorNotifierState();
}

class _LoggerErrorNotifierState extends State<LoggerErrorNotifier> {
  late StreamSubscription<TalkerDataInterface> subscription;

  @override
  void initState() {
    super.initState();
    subscription = widget.talker.stream.listen(onMessage);
  }

  @override
  void didUpdateWidget(covariant LoggerErrorNotifier oldWidget) {
    if (oldWidget.talker != widget.talker) {
      subscription.cancel();
      subscription = widget.talker.stream.listen(onMessage);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  void onMessage(TalkerDataInterface event) {
    if ([LogLevel.critical, LogLevel.error].contains(event.logLevel)) {
      Color background = event.logLevel.color;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          content: Builder(
            builder: (context) {
              TextStyle style = Theme.of(context).textTheme.bodyText2!;
              Color textColor = style.color!;
              double textLuminance = textColor.computeLuminance();
              double colorDifference =
                  background.computeLuminance() - textLuminance;
              if (colorDifference.abs() < 0.2) {
                if (textLuminance > 0.5) {
                  textColor = ThemeData(brightness: Brightness.light)
                      .textTheme
                      .subtitle1!
                      .color!;
                } else {
                  textColor = ThemeData(brightness: Brightness.dark)
                      .textTheme
                      .subtitle1!
                      .color!;
                }
              }
              return Text(
                'A fatal error has occured! ${event.logShort.trim()}',
                style: style.copyWith(
                  color: textColor,
                ),
              );
            },
          ),
          backgroundColor: background,
          behavior: SnackBarBehavior.floating,
          action: widget.onOpenLogs != null
              ? SnackBarAction(
                  label: 'LOGS',
                  onPressed: widget.onOpenLogs!,
                )
              : null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

extension Messages on TalkerDataInterface {
  String get logShort {
    switch (runtimeType) {
      case TalkerException:
        return displayException;
      case TalkerError:
        return displayError;
      case TalkerLog:
        if (message == null) {
          return '';
        }
        if (message!.length >= 30) {
          return '${message?.substring(0, 30)}...';
        }
        return message!;
      default:
        return '';
    }
  }

  String get logLong {
    switch (runtimeType) {
      case TalkerException:
        return '$displayException\n$displayStackTrace';
      case TalkerError:
        return '$displayError\n$displayStackTrace';
      case TalkerLog:
        return message ?? '';
      default:
        return '';
    }
  }

  String get logTitle {
    return '$displayTitle | ${DateFormat('HH:mm:ss.SSS').format(time)}';
  }

  String get logMessage {
    return '$logTitle\n\n$logLong';
  }
}

extension ToColor on LogLevel? {
  Color get color {
    switch (this) {
      case LogLevel.critical:
        return Colors.red[800]!;
      case LogLevel.error:
        return Colors.red[400]!;
      case LogLevel.fine:
        return Colors.teal[400]!;
      case LogLevel.warning:
        return Colors.orange[800]!;
      case LogLevel.verbose:
        return Colors.grey[400]!;
      case LogLevel.info:
        return Colors.blue[400]!;
      case LogLevel.good:
        return Colors.green[400]!;
      case LogLevel.debug:
      default:
        return Colors.grey;
    }
  }
}
