import 'dart:async';

import 'package:e1547/interface/interface.dart';
import 'package:e1547/post/post.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sub/flutter_sub.dart';
import 'package:video_player/video_player.dart';

class VideoButton extends StatefulWidget {
  const VideoButton({super.key, required this.videoController, this.size = 54});

  final VideoPlayerController videoController;
  final double size;

  @override
  State<VideoButton> createState() => _VideoButtonState();
}

class _VideoButtonState extends State<VideoButton> {
  @override
  Widget build(BuildContext context) {
    ScaffoldFrameController? frameController = ScaffoldFrame.maybeOf(context);
    return SubAnimationController(
      duration: defaultAnimationDuration,
      keys: [widget.videoController],
      builder: (context, animationController) => AnimatedBuilder(
        animation: Listenable.merge([widget.videoController, frameController]),
        builder: (context, child) {
          bool loading = !widget.videoController.value.isInitialized ||
              widget.videoController.value.isBuffering;
          bool shown = !widget.videoController.value.isPlaying || loading;
          if (frameController != null) {
            shown = frameController.visible || shown;
          }

          return ScaffoldFrameChild(
            shown: shown,
            child: Material(
              clipBehavior: Clip.antiAlias,
              shape: const CircleBorder(),
              color: Colors.black26,
              child: IconButton(
                iconSize: widget.size,
                onPressed: () {
                  if (widget.videoController.value.isPlaying) {
                    frameController?.cancel();
                    widget.videoController.pause();
                  } else {
                    widget.videoController.play();
                    frameController?.hideFrame(
                        duration: const Duration(milliseconds: 500));
                  }
                },
                icon: Center(
                  child: CrossFade(
                    secondChild: const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    showChild:
                        !widget.videoController.value.isPlaying || !loading,
                    duration: const Duration(milliseconds: 100),
                    child: SubListener(
                      initialize: true,
                      listenable: widget.videoController,
                      listener: () {
                        if (widget.videoController.value.isPlaying) {
                          animationController.forward();
                        } else {
                          animationController.reverse();
                        }
                      },
                      child: AnimatedBuilder(
                        animation: animationController,
                        builder: (context, child) => AnimatedIcon(
                          icon: AnimatedIcons.play_pause,
                          progress: animationController,
                          size: widget.size,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class VideoBar extends StatelessWidget {
  const VideoBar({required this.videoController});

  final VideoPlayerController videoController;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ScaffoldFrameChild(
        child: AnimatedBuilder(
          animation: videoController,
          builder: (context, child) => CrossFade.builder(
            showChild: videoController.value.isInitialized,
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const VideoHandlerVolumeControl(),
                      const SizedBox(
                        width: 4,
                      ),
                      Text(
                        videoController.value.position
                            .toString()
                            .substring(2, 7),
                      ),
                      Flexible(
                          child: Slider(
                        max: videoController.value.duration.inMilliseconds
                            .toDouble(),
                        value: videoController.value.position.inMilliseconds
                            .toDouble()
                            .clamp(
                              0,
                              videoController.value.duration.inMilliseconds
                                  .toDouble(),
                            ),
                        onChangeStart: (value) =>
                            ScaffoldFrame.maybeOf(context)?.cancel(),
                        onChanged: (value) => videoController
                            .seekTo(Duration(milliseconds: value.toInt())),
                        onChangeEnd: (value) {
                          if (videoController.value.isPlaying) {
                            ScaffoldFrame.maybeOf(context)?.hideFrame(
                                duration: const Duration(seconds: 2));
                          }
                        },
                      )),
                      Text(
                        videoController.value.duration
                            .toString()
                            .substring(2, 7),
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      InkWell(
                        onTap: Navigator.of(context).maybePop,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.fullscreen_exit,
                            size: 24,
                            color: Theme.of(context).iconTheme.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class VideoGesture extends StatefulWidget {
  const VideoGesture({required this.forward, required this.videoController});

  final bool forward;
  final VideoPlayerController videoController;

  @override
  State<VideoGesture> createState() => _VideoGestureState();
}

class _VideoGestureState extends State<VideoGesture>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400));
  late final Animation<double> fadeAnimation = CurvedAnimation(
    parent: animationController,
    curve: Curves.easeInOut,
  );
  int combo = 0;
  Timer? comboReset;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onDoubleTap: () async {
        if (widget.videoController.value.isInitialized) {
          Duration current = (await widget.videoController.position)!;
          bool boundOnZero = current == Duration.zero;
          // final position is never reported, so we subtract 1 ms.
          // see: https://github.com/flutter/flutter/issues/90114
          bool boundOnEnd = current ==
              widget.videoController.value.duration -
                  const Duration(milliseconds: 1);
          if ((!widget.forward && boundOnZero) ||
              (widget.forward && boundOnEnd)) {
            return;
          }

          Duration target = current;
          if (widget.forward) {
            target += const Duration(seconds: 10);
          } else {
            target -= const Duration(seconds: 10);
          }
          setState(() {
            combo++;
          });

          widget.videoController.seekTo(target);
          comboReset?.cancel();
          comboReset = Timer(const Duration(milliseconds: 900),
              () => setState(() => combo = 0));
          await animationController.forward();
          await animationController.reverse();
        }
      },
      child: FadeTransition(
        opacity: fadeAnimation,
        child: Stack(children: [
          IconMessage(
            icon: Icon(
              widget.forward ? Icons.fast_forward : Icons.fast_rewind,
              color: Colors.white,
            ),
            title: Text(
              '${10 * combo} seconds',
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
          LayoutBuilder(builder: (context, constraints) {
            double size = constraints.maxHeight * 2;
            return AnimatedBuilder(
              animation: fadeAnimation,
              builder: (context, child) => Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    right: widget.forward ? null : constraints.maxWidth * 0.2,
                    left: widget.forward ? constraints.maxWidth * 0.2 : null,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: Theme.of(context).splashColor,
                        borderRadius: widget.forward
                            ? BorderRadius.only(
                                topLeft: Radius.circular(size),
                                bottomLeft: Radius.circular(size),
                              )
                            : BorderRadius.only(
                                topRight: Radius.circular(size),
                                bottomRight: Radius.circular(size),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          })
        ]),
      ),
    );
  }
}

class VideoGestures extends StatefulWidget {
  const VideoGestures({required this.videoController, required this.child});

  final Widget child;
  final VideoPlayerController videoController;

  @override
  State<VideoGestures> createState() => _VideoGesturesState();
}

class _VideoGesturesState extends State<VideoGestures> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        alignment: Alignment.center,
        children: [
          widget.child,
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: VideoGesture(
                    forward: false,
                    videoController: widget.videoController,
                  ),
                ),
                SizedBox(
                  width: constraints.maxWidth * 0.1,
                ),
                Expanded(
                  child: VideoGesture(
                    forward: true,
                    videoController: widget.videoController,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PostVideoRoute extends StatefulWidget {
  const PostVideoRoute({
    super.key,
    required this.child,
    required this.post,
    this.stopOnDispose = true,
  });

  final Widget child;
  final Post post;
  final bool stopOnDispose;

  static PostVideoRouteState of(BuildContext context) =>
      context.findAncestorStateOfType<PostVideoRouteState>()!;

  static PostVideoRouteState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<PostVideoRouteState>();

  @override
  State<PostVideoRoute> createState() => PostVideoRouteState();
}

class PostVideoRouteState extends State<PostVideoRoute> with RouteAware {
  late VideoPlayerController? _videoController;
  late RouterDrawerController _navigation;
  late final bool _wasPlaying;
  bool _keepPlaying = false;

  void keepPlaying() => _keepPlaying = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _wasPlaying = widget.post.getVideo(context)?.value.isPlaying ?? false;
      }
    });
  }

  @override
  void didPushNext() {
    super.didPushNext();
    if (_keepPlaying) {
      _keepPlaying = false;
    } else {
      _videoController?.pause();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navigation = context.watch<RouterDrawerController>();
    _navigation.routeObserver.subscribe(this, ModalRoute.of(context)!);
    _videoController = widget.post.getVideo(context);
  }

  @override
  void reassemble() {
    super.reassemble();
    _navigation.routeObserver.unsubscribe(this);
    _navigation.routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    _navigation.routeObserver.unsubscribe(this);
    if (widget.stopOnDispose && !_wasPlaying) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _videoController?.pause(),
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class PostVideoLoader extends StatefulWidget {
  const PostVideoLoader({required this.post, required this.child});

  final Post post;
  final Widget child;

  @override
  State<PostVideoLoader> createState() => _PostVideoLoaderState();
}

class _PostVideoLoaderState extends State<PostVideoLoader> {
  Future<void> ensureVideo() async {
    await widget.post.loadVideo(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => ensureVideo());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class PostVideoWidget extends StatelessWidget {
  const PostVideoWidget({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    Widget placeholder() {
      return PostImageWidget(
        post: post,
        size: PostImageSize.sample,
        fit: BoxFit.cover,
        showProgress: false,
        lowResCacheSize: context.watch<ImageCacheSize?>()?.size,
      );
    }

    if (post.getVideo(context) != null) {
      return AnimatedBuilder(
        animation: post.getVideo(context)!,
        builder: (context, child) => post.getVideo(context)!.value.isInitialized
            ? AspectRatio(
                aspectRatio: post.getVideo(context)!.value.aspectRatio,
                child: VideoPlayer(post.getVideo(context)!),
              )
            : placeholder(),
      );
    }
    return placeholder();
  }
}
