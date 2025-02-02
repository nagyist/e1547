import 'package:e1547/client/client.dart';
import 'package:e1547/follow/follow.dart';
import 'package:e1547/interface/interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sub/flutter_sub.dart';

class FollowMarkReadTile extends StatelessWidget {
  const FollowMarkReadTile({
    this.onTap,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Consumer2<FollowsService, Client>(
      builder: (context, service, client, child) => SubStream<int>(
        create: () => service.watchUnseen(host: client.host).map(
              (e) => e.fold(0, (a, b) => a + b.unseen!),
            ),
        keys: [service, client.host],
        builder: (context, snapshot) => ListTile(
          enabled: (snapshot.data ?? 0) > 0,
          leading: Icon(
              (snapshot.data ?? 0) > 0 ? Icons.mark_email_read : Icons.drafts),
          title: const Text('unseen posts'),
          subtitle: (snapshot.data ?? 0) > 0
              ? TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: snapshot.data ?? 0),
                  duration: defaultAnimationDuration,
                  builder: (context, value, child) {
                    return Text('mark $value posts as seen');
                  },
                )
              : const Text('no unseen posts'),
          onTap: () {
            Scaffold.of(context).closeEndDrawer();
            service.markAsSeen();
            onTap?.call();
          },
        ),
      ),
    );
  }
}

class FollowFilterReadTile extends StatelessWidget {
  const FollowFilterReadTile({
    required this.filterUnseen,
    required this.onChanged,
  });

  final bool filterUnseen;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: filterUnseen,
      onChanged: (value) {
        Scaffold.of(context).closeEndDrawer();
        onChanged(value);
      },
      secondary: Icon(filterUnseen ? Icons.mark_email_unread : Icons.email),
      title: const Text('show unseen only'),
      subtitle: filterUnseen
          ? const Text('filtering for unseen')
          : const Text('all posts shown'),
    );
  }
}

class FollowEditingTile extends StatelessWidget {
  const FollowEditingTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Edit'),
      leading: const Icon(Icons.edit),
      onTap: () {
        Scaffold.of(context).closeEndDrawer();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const FollowEditor(),
          ),
        );
      },
    );
  }
}
