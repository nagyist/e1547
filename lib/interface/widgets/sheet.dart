import 'package:e1547/interface/interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sub/flutter_sub.dart';
import 'package:sliding_sheet/sliding_sheet.dart';

class _SheetActions extends InheritedNotifier<SheetActionController> {
  const _SheetActions({required super.child, required this.controller})
      : super(notifier: controller);

  final SheetActionController controller;
}

class SheetActions extends StatelessWidget {
  const SheetActions({super.key, required this.child, this.controller});

  final Widget child;
  final SheetActionController? controller;

  static SheetActionController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SheetActions>()!.controller;

  static SheetActionController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SheetActions>()?.controller;

  @override
  Widget build(BuildContext context) {
    return SubValue<SheetActionController?>(
      create: () => controller == null ? SheetActionController() : null,
      dispose: (value) => value?.dispose(),
      keys: [controller],
      builder: (context, controller) => _SheetActions(
        controller: this.controller ?? controller!,
        child: child,
      ),
    );
  }
}

class SheetActionController extends ActionController {
  PersistentBottomSheetController? sheetController;
  bool get isShown => sheetController != null;

  void close() => sheetController?.close.call();

  @override
  void onSuccess() {
    sheetController?.close();
  }

  @override
  void reset() {
    sheetController = null;
    super.reset();
  }

  @override
  void setAction(ActionControllerCallback submit) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      super.setAction(submit);
    });
  }

  void show(BuildContext context, Widget child) {
    sheetController = Scaffold.of(context).showBottomSheet(
      (context) => ActionBottomSheet(controller: this, child: child),
    );
    sheetController!.closed.then((_) => reset());
  }

  void actionOrShow(BuildContext context, Widget child) {
    if (action != null) {
      action!();
    } else {
      show(context, child);
    }
  }
}

class ActionBottomSheet extends StatelessWidget {
  const ActionBottomSheet({required this.controller, required this.child});

  final Widget child;
  final SheetActionController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      child: child,
      builder: (context, child) => Padding(
        padding: const EdgeInsets.all(10).copyWith(top: 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CrossFade(
                  showChild: controller.isLoading,
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: SizedCircularProgressIndicator(size: 16),
                    ),
                  ),
                ),
                CrossFade(
                  showChild: controller.isError && !controller.isForgiven,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Icon(
                        Icons.clear,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
                Expanded(child: child!),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class SheetFloatingActionButton extends StatelessWidget {
  const SheetFloatingActionButton({
    required this.builder,
    required this.actionIcon,
    this.controller,
    this.confirmIcon,
  });

  final IconData actionIcon;
  final IconData? confirmIcon;
  final SheetActionController? controller;
  final Widget Function(BuildContext context, ActionController actionController)
      builder;

  @override
  Widget build(BuildContext context) {
    return SubDefault<SheetActionController>(
      value: controller ?? SheetActions.maybeOf(context),
      create: () => SheetActionController(),
      dispose: (value) => value.dispose(),
      builder: (context, controller) => AnimatedBuilder(
        animation: controller,
        builder: (context, child) => FloatingActionButton(
          onPressed: controller.isLoading
              ? null
              : () => controller.actionOrShow(
                    context,
                    builder(context, controller),
                  ),
          child: controller.isShown
              ? Icon(confirmIcon ?? Icons.check)
              : Icon(actionIcon),
        ),
      ),
    );
  }
}

Future<T?> showDefaultSlidingBottomSheet<T>(
  BuildContext context,
  SheetBuilder builder,
) async {
  return showSlidingBottomSheet<T>(
    context,
    builder: (context) => defaultSlidingSheetDialog(
      context,
      builder,
    ),
  );
}

SlidingSheetDialog defaultSlidingSheetDialog(
  BuildContext context,
  SheetBuilder builder,
) {
  return SlidingSheetDialog(
    scrollSpec: const ScrollSpec(physics: ClampingScrollPhysics()),
    duration: const Duration(milliseconds: 400),
    avoidStatusBar: true,
    isBackdropInteractable: true,
    cornerRadius: 16,
    cornerRadiusOnFullscreen: 0,
    maxWidth: 600,
    headerBuilder: (context, state) => const SheetHandle(),
    builder: builder,
    snapSpec: const SnapSpec(
      snappings: [
        0.6,
        SnapSpec.expanded,
      ],
    ),
  );
}

class DefaultSheetBody extends StatelessWidget {
  const DefaultSheetBody({
    this.title,
    required this.body,
  });

  final Widget? title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: DefaultTextStyle(
                      style: Theme.of(context).textTheme.titleLarge!,
                      child: title!,
                    ),
                  ),
                ],
              ),
            ),
          body,
        ],
      ),
    );
  }
}

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Theme.of(context).iconTheme.color!,
          ),
          height: 3,
          width: 32,
        ),
      ],
    );
  }
}
