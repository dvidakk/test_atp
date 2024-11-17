// lib/composer/widgets/reply_composer.dart
import 'package:bluesky/bluesky.dart' as bsky;
import 'package:flutter/material.dart';
import 'package:test_atp/composer/widgets/base_composer.dart';
import 'package:test_atp/core/services/post_service.dart';

class ReplyComposer extends StatelessWidget {
  final PostService postService;
  final bsky.FeedView replyTo;

  const ReplyComposer({
    Key? key,
    required this.postService,
    required this.replyTo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseComposer(
      postService: postService,
      onCancel: () => Navigator.pop(context),
      onSubmit: (text) => postService.reply(
        text,
        replyTo.post.uri,
        replyTo.post.cid,
      ),
      type: ComposerType.reply, // Specify the composer type
      parentPost: replyTo, // Provide the parent post for reply
      // Remove hintText, submitButtonText, and header unless you want to override them
    );
  }
}
