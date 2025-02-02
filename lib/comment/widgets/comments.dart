import 'package:e1547/client/client.dart';
import 'package:e1547/comment/comment.dart';
import 'package:e1547/interface/interface.dart';
import 'package:flutter/material.dart';

class PostCommentsPage extends StatelessWidget {
  const PostCommentsPage({required this.postId});

  final int postId;

  @override
  Widget build(BuildContext context) {
    return CommentsProvider(
      postId: postId,
      child: Consumer<CommentsController>(
        builder: (context, controller, child) => RefreshableControllerPage(
          appBar: DefaultAppBar(
            title: Text('#$postId comments'),
            actions: const [
              ContextDrawerButton(),
            ],
          ),
          floatingActionButton: context.read<Client>().hasLogin
              ? FloatingActionButton(
                  heroTag: 'float',
                  backgroundColor: Theme.of(context).cardColor,
                  child: Icon(Icons.comment,
                      color: Theme.of(context).iconTheme.color),
                  onPressed: () => writeComment(
                    context: context,
                    postId: postId,
                  ).then((value) {
                    if (value) {
                      controller.refresh();
                    }
                  }),
                )
              : null,
          controller: controller,
          endDrawer: ContextDrawer(
            title: const Text('Comments'),
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: controller.orderByOldest,
                builder: (context, value, child) => SwitchListTile(
                  secondary: const Icon(Icons.sort),
                  title: const Text('Comment order'),
                  subtitle: Text(value ? 'oldest first' : 'newest first'),
                  value: value,
                  onChanged: (value) {
                    controller.orderByOldest.value = value;
                    Scaffold.of(context).closeEndDrawer();
                  },
                ),
              ),
            ],
          ),
          child: PagedListView<String, Comment>(
            primary: true,
            padding: defaultActionListPadding,
            pagingController: controller,
            builderDelegate: defaultPagedChildBuilderDelegate(
              pagingController: controller,
              itemBuilder: (context, item, index) => CommentTile(comment: item),
              onEmpty: const Text('No comments'),
              onError: const Text('Failed to load comments'),
            ),
          ),
        ),
      ),
    );
  }
}
