import 'package:e1547/interface/interface.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'comment.freezed.dart';
part 'comment.g.dart';

@freezed
class Comment with _$Comment {
  const factory Comment({
    required int id,
    required DateTime createdAt,
    required int postId,
    required int creatorId,
    required String body,
    required int score,
    required DateTime updatedAt,
    required int updaterId,
    required bool doNotBumpPost,
    required bool isHidden,
    required bool isSticky,
    required WarningType? warningType,
    required int? warningUserId,
    required String creatorName,
    required String updaterName,
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(VoteStatus.unknown)
        VoteStatus voteStatus,
  }) = _Comment;

  factory Comment.fromJson(dynamic json) => _$CommentFromJson(json);
}

@JsonEnum()
enum WarningType {
  warning,
  record,
  ban;

  String get message {
    switch (this) {
      case warning:
        return 'User received a warning for this message';
      case record:
        return 'User received a record for this message';
      case ban:
        return 'User was banned for this message';
    }
  }
}
