import 'package:bluesky/bluesky.dart' as bsky;
import 'package:flutter/material.dart';
import 'package:test_atp/core/constants/colors.dart';
import 'package:test_atp/core/services/post_service.dart';
import 'package:test_atp/feed/widgets/post_card/post_card.dart';
import 'package:test_atp/profile/screens/profile_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostHeader extends StatelessWidget {
  final bsky.FeedView post;
  final bool isCompact;
  final PostService postService; // Add this

  const PostHeader({
    super.key,
    required this.post,
    required this.isCompact,
    required this.postService, // Add this
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(
                    handle: post.post.author.handle,
                  ),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.post.author.displayName ?? post.post.author.handle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isCompact ? 14 : 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '@${post.post.author.handle}',
                  style: TextStyle(
                    color: AppColors.darkGray,
                    fontSize: isCompact ? 12 : 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        Text(
          timeago.format(post.post.indexedAt),
          style: TextStyle(
            color: AppColors.darkGray,
            fontSize: isCompact ? 12 : 14,
          ),
        ),
      ],
    );
  }
}
