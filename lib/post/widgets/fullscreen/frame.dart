import 'dart:async';

import 'package:e1547/interface/interface.dart';
import 'package:e1547/post/post.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'appbar.dart';

class FrameController extends ChangeNotifier {
  FrameController({this.onToggle, this.visible = false});

  final void Function(bool shown)? onToggle;
  Timer? frameToggler;
  bool visible;

  static FrameController? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FrameData>()?.notifier;

  void showFrame({Duration? duration}) =>
      toggleFrame(shown: true, duration: duration);

  void hideFrame({Duration? duration}) =>
      toggleFrame(shown: false, duration: duration);

  void toggleFrame({bool? shown, Duration? duration}) {
    bool result = shown ?? !visible;
    if (result == visible) {
      return;
    }
    frameToggler?.cancel();
    void toggle() {
      visible = result;
      notifyListeners();
      onToggle?.call(visible);
    }

    if (duration == null) {
      toggle();
    } else {
      frameToggler = Timer(duration, toggle);
    }
  }

  void cancel() => frameToggler?.cancel();

  @override
  void dispose() {
    cancel();
    super.dispose();
  }
}

class FrameData extends InheritedNotifier<FrameController> {
  const FrameData({required super.child, required FrameController controller})
      : super(notifier: controller);
}

class PostFullscreenFrame extends StatefulWidget {
  const PostFullscreenFrame({
    required this.child,
    required this.post,
    this.controller,
    this.visible,
  }) : assert(visible == null || controller == null);

  final Post post;
  final Widget child;
  final FrameController? controller;
  final bool? visible;

  @override
  State<PostFullscreenFrame> createState() => _PostFullscreenFrameState();
}

class _PostFullscreenFrameState extends State<PostFullscreenFrame>
    with RouteAware {
  late FrameController controller =
      widget.controller ?? FrameController(visible: widget.visible ?? false);
  late NavigationController navigation;

  Future<void> toggleFrame(bool shown) async {
    if (shown) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    }
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIChangeCallback(
        (hidden) async => controller.toggleFrame(shown: !hidden));
  }

  @override
  void didPop() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    navigation = context.watch<NavigationController>();
    navigation.routeObserver
        .subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    navigation.routeObserver.unsubscribe(this);
    SystemChrome.setSystemUIChangeCallback(null);
    if (widget.controller == null) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(PostFullscreenFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      controller.cancel();
    } else {
      if (oldWidget.controller == null) {
        controller.dispose();
      }
      controller = widget.controller ?? FrameController();
      SystemChrome.setSystemUIChangeCallback(
          (hidden) async => controller.toggleFrame(shown: !hidden));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableListener(
      listener: () => toggleFrame(controller.visible),
      listenable: controller,
      child: FrameData(
        controller: controller,
        child: Scaffold(
          body: AnimatedBuilder(
            animation: controller,
            child: widget.child,
            builder: (contex, child) => Scaffold(
              extendBodyBehindAppBar: true,
              appBar: FrameAppBar(
                child: PostFullscreenAppBar(post: widget.post),
              ),
              body: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  controller.toggleFrame();
                  if ((widget.post.getVideo(context)?.value.isPlaying ??
                          false) &&
                      controller.visible) {
                    controller.hideFrame(duration: const Duration(seconds: 2));
                  }
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    child!,
                    if (widget.post.getVideo(context) != null) ...[
                      Positioned(
                        bottom: 0,
                        right: 0,
                        left: 0,
                        child: VideoBar(
                          videoController: widget.post.getVideo(context)!,
                        ),
                      ),
                      VideoButton(
                        videoController: widget.post.getVideo(context)!,
                      ),
                    ]
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

class FrameChild extends StatelessWidget {
  final bool? shown;
  final Widget child;

  final Duration fadeOutDuration = const Duration(milliseconds: 50);

  const FrameChild({required this.child, this.shown});

  @override
  Widget build(BuildContext context) {
    FrameController? controller = FrameController.of(context);
    bool shown = this.shown ?? controller?.visible ?? true;

    Widget body() {
      return AnimatedOpacity(
        opacity: shown ? 1 : 0,
        duration: fadeOutDuration,
        child: IgnorePointer(
          ignoring: !shown,
          child: child,
        ),
      );
    }

    if (controller != null) {
      return AnimatedBuilder(
        animation: controller,
        builder: (context, child) => body(),
        child: child,
      );
    } else {
      return body();
    }
  }
}

class FrameAppBar extends StatelessWidget with AppBarBuilderWidget {
  @override
  final PreferredSizeWidget child;

  const FrameAppBar({required this.child});

  @override
  Widget build(BuildContext context) {
    return FrameChild(
      child: child,
    );
  }
}
