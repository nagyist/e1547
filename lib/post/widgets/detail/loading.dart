import 'dart:async';

import 'package:e1547/client/client.dart';
import 'package:e1547/denylist/denylist.dart';
import 'package:e1547/interface/interface.dart';
import 'package:e1547/post/post.dart';
import 'package:flutter/material.dart';

class PostLoadingPage extends StatelessWidget {
  const PostLoadingPage(this.id);

  final int id;

  @override
  Widget build(BuildContext context) {
    return SingleFuturePostsProvider(
      id: id,
      child: Consumer<Future<PostsController>>(
        builder: (context, controller, child) =>
            FutureLoadingPage<PostsController>(
          future: controller,
          builder: (context, value) => PostsRouteConnector(
            controller: value,
            child: PostDetailGallery(controller: value),
          ),
          title: Text('Post #$id'),
          onError: const Text('Failed to load post'),
          onEmpty: const Text('Post not found'),
        ),
      ),
    );
  }
}

class SingleFuturePostsProvider
    extends SubProvider2<Client, DenylistService, Future<PostsController>> {
  SingleFuturePostsProvider({required int id, super.child, super.builder})
      : super(
          create: (context, client, denylist) =>
              Future<PostsController>(() async {
            PostsController controller = PostsController.single(
              id: id,
              client: client,
              denylist: denylist,
            );
            await controller.loadFirstPage();
            return controller;
          }),
          keys: (context) => [id],
          dispose: (context, value) async => (await value).dispose(),
        );
}
