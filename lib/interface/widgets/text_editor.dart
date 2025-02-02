import 'dart:async';

import 'package:e1547/interface/interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sub/flutter_sub.dart';

typedef TextEditorSubmit = FutureOr<String?> Function(
    BuildContext context, String value);
typedef TextEditorBuilder = Widget Function(
    BuildContext context, TextEditingController controller);

class TextEditor extends StatefulWidget {
  const TextEditor({
    required this.onSubmit,
    this.title,
    this.content,
    this.actionBuilder,
    this.previewBuilder,
    this.bottomSheetBuilder,
  });

  final Widget? title;
  final String? content;

  final TextEditorSubmit onSubmit;

  final List<Widget>? Function(
    BuildContext context,
    TextEditingController controller,
  )? actionBuilder;
  final TextEditorBuilder? previewBuilder;
  final TextEditorBuilder? bottomSheetBuilder;

  @override
  State<StatefulWidget> createState() {
    return _TextEditorState();
  }
}

class _TextEditorState extends State<TextEditor> {
  late bool showBar = widget.bottomSheetBuilder != null;
  bool isLoading = false;
  late TextEditingController textController =
      TextEditingController(text: widget.content);

  @override
  Widget build(BuildContext context) {
    Widget scrollView(Widget child) {
      return SingleChildScrollView(
        padding: defaultActionListPadding.add(const EdgeInsets.all(8)),
        child: Row(
          children: [Expanded(child: child)],
        ),
      );
    }

    Widget editor() {
      return scrollView(
        TextField(
          controller: textController,
          keyboardType: TextInputType.multiline,
          autofocus: true,
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'type here...',
          ),
          maxLines: null,
          enabled: !isLoading,
        ),
      );
    }

    Widget fab() {
      return Builder(
        builder: (context) => FloatingActionButton(
          heroTag: 'float',
          backgroundColor: Theme.of(context).cardColor,
          onPressed: isLoading
              ? null
              : () async {
                  ScaffoldMessengerState messenger =
                      ScaffoldMessenger.of(context);
                  String text = textController.text.trim();
                  setState(() {
                    isLoading = true;
                  });
                  String? error = await widget.onSubmit(context, text);
                  setState(() {
                    isLoading = false;
                  });
                  if (error != null) {
                    messenger.showSnackBar(SnackBar(
                      duration: const Duration(seconds: 1),
                      content: Text(error),
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                },
          child: Icon(Icons.check, color: Theme.of(context).iconTheme.color),
        ),
      );
    }

    Widget loadingBar() {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedCircularProgressIndicator(size: 24),
          ],
        ),
      );
    }

    bool hasPreview = widget.previewBuilder != null;

    Map<Widget, Widget>? tabs = {
      const Tab(text: 'Write'): editor(),
      if (hasPreview)
        const Tab(text: 'Preview'): scrollView(
          widget.previewBuilder!(context, textController),
        ),
    };

    return DefaultTabController(
      length: tabs.length,
      child: Builder(
        builder: (context) => SubListener(
          initialize: true,
          listenable: DefaultTabController.of(context),
          listener: () {
            if (hasPreview && DefaultTabController.of(context).index == 0) {
              if (!showBar) {
                setState(() {
                  showBar = true;
                });
              }
            } else {
              if (showBar) {
                FocusScope.of(context).unfocus();
                setState(() {
                  showBar = false;
                });
              }
            }
          },
          child: Scaffold(
            floatingActionButton: fab(),
            bottomSheet: isLoading
                ? loadingBar()
                : showBar
                    ? widget.bottomSheetBuilder?.call(context, textController)
                    : null,
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverOverlapAbsorber(
                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                    context,
                  ),
                  sliver: DefaultSliverAppBar(
                    pinned: true,
                    leading: ModalRoute.of(context)!.canPop
                        ? const CloseButton()
                        : null,
                    title: widget.title,
                    actions:
                        widget.actionBuilder?.call(context, textController),
                    bottom: tabs.length > 1
                        ? TabBar(
                            tabs: tabs.keys.toList(),
                            labelColor: Theme.of(context).iconTheme.color,
                            indicatorColor: Theme.of(context).iconTheme.color,
                          )
                        : null,
                  ),
                ),
              ],
              body: TabBarView(
                children: tabs.values.toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
