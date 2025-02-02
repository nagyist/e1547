import 'package:e1547/follow/follow.dart';
import 'package:e1547/interface/interface.dart';
import 'package:e1547/post/post.dart';
import 'package:flutter/material.dart';

class FollowsTimelinePage extends StatefulWidget {
  const FollowsTimelinePage({super.key});

  @override
  State<FollowsTimelinePage> createState() => _FollowsTimelinePageState();
}

class _FollowsTimelinePageState extends State<FollowsTimelinePage> {
  @override
  Widget build(BuildContext context) {
    return RouterDrawerEntry<FollowsTimelinePage>(
      child: PostsProvider(
        fetch: (controller, search, page, force) async {
          FollowsService service = context.read<FollowsService>();
          return controller.client.postsByTags(
            (await service.getAll(
              host: controller.client.host,
              types: [FollowType.update, FollowType.notify],
            ))
                .map((e) => e.tags)
                .toList(),
            page,
            force: force,
            cancelToken: controller.cancelToken,
          );
        },
        canSearch: false,
        child: Consumer<PostsController>(
          builder: (context, controller, child) => PostsPage(
            appBar: const DefaultAppBar(
              title: Text('Timeline'),
              actions: [ContextDrawerButton()],
            ),
            controller: controller,
            drawerActions: const [FollowEditingTile()],
            displayType: PostDisplayType.timeline,
            canSelect: false,
          ),
        ),
      ),
    );
  }
}
