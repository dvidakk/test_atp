import 'package:bluesky/bluesky.dart' as bsky;
import 'package:flutter/material.dart';
import 'package:test_atp/core/widgets/post_action.dart';
import 'package:test_atp/core/constants/colors.dart';

class PostActions extends StatelessWidget {
  final bsky.FeedView post;
  final bool isCompact;
  final VoidCallback onLike;
  final VoidCallback onRepost;
  final VoidCallback onReply;

  const PostActions({
    required this.post,
    required this.isCompact,
    required this.onLike,
    required this.onRepost,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        PostAction(
          icon: Icons.chat_bubble_outline,
          count: post.post.replyCount,
          size: isCompact ? 18 : 20,
          onPressed: onReply,
        ),
        PostAction(
          icon: Icons.repeat,
          activeIcon: Icons.repeat,
          count: post.post.repostCount,
          size: isCompact ? 18 : 20,
          isActive: post.post.viewer.repost != null,
          onPressed: onRepost,
        ),
        PostAction(
          icon: Icons.favorite_border,
          activeIcon: Icons.favorite,
          count: post.post.likeCount,
          size: isCompact ? 18 : 20,
          isActive: post.post.viewer.like != null,
          onPressed: onLike,
        ),
        IconButton(
          icon: Icon(
            Icons.share_outlined,
            size: isCompact ? 18 : 20,
          ),
          onPressed: () {},
          color: AppColors.darkGray,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(
            minWidth: isCompact ? 32 : 40,
            minHeight: isCompact ? 32 : 40,
          ),
        ),
      ],
    );
  }
}
