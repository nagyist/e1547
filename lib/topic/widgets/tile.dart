import 'package:e1547/interface/interface.dart';
import 'package:e1547/topic/topic.dart';
import 'package:flutter/material.dart';
import 'package:relative_time/relative_time.dart';

class TopicTile extends StatelessWidget {
  const TopicTile({
    required this.topic,
    this.onPressed,
    this.onCountPressed,
  });

  final Topic topic;
  final VoidCallback? onPressed;
  final VoidCallback? onCountPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onPressed,
          onLongPress: () => topicSheet(context, topic),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topic.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        DimSubtree(
                          child: Text(
                            topic.updatedAt.relativeTime(context),
                            style: const TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: onCountPressed,
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 8, right: 16, top: 6, bottom: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          topic.responseCount.toString(),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (topic.createdAt
                            .add(const Duration(minutes: 1))
                            .isBefore(topic.updatedAt))
                          DimSubtree(
                            child: Text(
                              topic.createdAt.relativeTime(context),
                              style: const TextStyle(
                                fontSize: 12,
                              ),
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
        const Divider(indent: 8, endIndent: 8),
      ],
    );
  }
}
