import 'package:e1547/app/app.dart';
import 'package:e1547/interface/interface.dart';
import 'package:e1547/post/post.dart';
import 'package:flutter/material.dart';

class PostDetailImage extends StatelessWidget {
  const PostDetailImage({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return PostImageWidget(
      post: post,
      size: PostImageSize.sample,
      fit: BoxFit.cover,
      lowResCacheSize: context.watch<ImageCacheSize?>()?.size,
    );
  }
}

class PostDetailVideo extends StatelessWidget {
  const PostDetailVideo({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    Player? player = post.getVideo(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: player != null
          ? () => player.state.playing ? player.pause() : player.play()
          : null,
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.passthrough,
        children: [
          PostVideoWidget(post: post),
          Positioned.fill(
            child: Center(
              child: CrossFade.builder(
                showChild: post.getVideo(context) != null,
                builder: (context) => Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  child: VideoButton(player: post.getVideo(context)!),
                ),
                secondChild: const SizedCircularProgressIndicator(size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PostDetailImageToggle extends StatelessWidget {
  const PostDetailImageToggle({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return PostsConnector(
      post: post,
      builder: (context, post) {
        if (post.flags.deleted) return const SizedBox.shrink();
        if (post.file.url == null) return const SizedBox.shrink();
        PostsController controller = context.watch<PostsController>();
        return CrossFade.builder(
          showChild: (!post.isFavorited && controller.isDenied(post)) ||
              controller.isAllowed(post),
          duration: const Duration(milliseconds: 200),
          builder: (context) => Card(
            color: controller.isAllowed(post)
                ? Colors.black12
                : Colors.transparent,
            elevation: 0,
            child: InkWell(
              onTap: () => controller.isAllowed(post)
                  ? controller.unallow(post)
                  : controller.allow(post),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Icon(
                        controller.isAllowed(post)
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 16,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Text(controller.isAllowed(post) ? 'hide' : 'show'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class PostDetailImageActions extends StatelessWidget {
  const PostDetailImageActions({
    required this.post,
    required this.child,
    this.onOpen,
  });

  final Post post;
  final Widget child;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return PostsConnector(
      post: post,
      builder: (context, post) {
        VoidCallback? onTap;

        PostsController controller = context.watch<PostsController>();
        bool visible = post.file.url != null &&
            (!controller.isDenied(post) || post.isFavorited);

        if (visible) {
          onTap = post.type == PostType.unsupported
              ? () => launch(post.file.url!)
              : onOpen;
        }

        Widget fullscreenButton() {
          if (post.type == PostType.video && onTap != null) {
            return CrossFade.builder(
              showChild: visible,
              builder: (context) => Card(
                elevation: 0,
                color: Colors.black12,
                child: InkWell(
                  onTap: onTap,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.fullscreen,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
        }

        Widget muteButton() {
          return CrossFade.builder(
            showChild: post.type == PostType.video && post.file.url != null,
            builder: (context) => const Card(
              elevation: 0,
              color: Colors.black12,
              child: VideoHandlerVolumeControl(),
            ),
          );
        }

        Player? player = post.getVideo(context);

        return Stack(
          fit: StackFit.passthrough,
          children: [
            InkWell(
              hoverColor: Colors.transparent,
              onTap: player != null
                  ? () => player.state.playing ? player.pause() : player.play()
                  : onTap,
              child: child,
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    muteButton(),
                    const Spacer(),
                    fullscreenButton(),
                    PostDetailImageToggle(post: post),
                  ],
                ),
              ),
            )
          ],
        );
      },
    );
  }
}

class PostDetailImageDisplay extends StatelessWidget {
  const PostDetailImageDisplay({
    required this.post,
    this.onTap,
  });

  final Post post;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PostDetailImageActions(
      onOpen: onTap,
      post: post,
      child: ImageOverlay(
        post: post,
        builder: (context) => Center(
          child: Hero(
            tag: post.link,
            child: ImageCacheSizeProvider(
              size: context.watch<ImageCacheSize?>()?.size,
              child: post.type == PostType.video
                  ? PostDetailVideo(post: post)
                  : PostDetailImage(post: post),
            ),
          ),
        ),
      ),
    );
  }
}
