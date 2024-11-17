import 'dart:typed_data';

import 'package:bluesky/bluesky.dart' as bsky;
import 'package:bluesky/app_bsky_actor_defs.dart';
import 'package:flutter/material.dart';
import 'package:test_atp/core/constants/colors.dart';
import 'package:test_atp/core/services/post_service.dart';
import 'package:test_atp/composer/widgets/reply_composer.dart';
import 'avatar.dart';
import 'post_header.dart';
import 'body.dart';
import 'actions.dart';

class PostContext extends InheritedWidget {
  final bsky.FeedView post;
  final PostService postService;
  final Function(bsky.FeedView) onUpdatePost;
  final bool isCompact;

  const PostContext({
    super.key,
    required this.post,
    required this.postService,
    required this.onUpdatePost,
    required this.isCompact,
    required super.child,
  });

  static PostContext of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PostContext>()!;
  }

  Future<void> handleLike() async {
    try {
      if (post.post.viewer.like == null) {
        await postService.likePost(post.post.uri, post.post.cid);
        onUpdatePost(post.copyWith(
          post: post.post.copyWith(
            likeCount: post.post.likeCount + 1,
            viewer: post.post.viewer.copyWith(like: post.post.uri),
          ),
        ));
      } else {
        await postService.unlikePost(post.post.viewer.like!);
        onUpdatePost(post.copyWith(
          post: post.post.copyWith(
            likeCount: post.post.likeCount - 1,
            viewer: post.post.viewer.copyWith(like: null),
          ),
        ));
      }
    } catch (e) {
      debugPrint('Error liking/unliking post: $e');
    }
  }

  Future<void> handleRepost() async {
    try {
      if (post.post.viewer.repost == null) {
        await postService.repost(post.post.uri, post.post.cid);
        onUpdatePost(post.copyWith(
          post: post.post.copyWith(
            repostCount: post.post.repostCount + 1,
            viewer: post.post.viewer.copyWith(repost: post.post.uri),
          ),
        ));
      } else {
        await postService.unrepost(post.post.viewer.repost!);
        onUpdatePost(post.copyWith(
          post: post.post.copyWith(
            repostCount: post.post.repostCount - 1,
            viewer: post.post.viewer.copyWith(repost: null),
          ),
        ));
      }
    } catch (e) {
      debugPrint('Error reposting/unreposting post: $e');
    }
  }

  void handleReply(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ReplyComposer(
        postService: postService,
        replyTo: post,
      ),
    );
  }

  @override
  bool updateShouldNotify(PostContext oldWidget) {
    return post != oldWidget.post;
  }
}

// Update PostCard class to handle different types
class PostCard extends StatefulWidget {
  final bsky.FeedView post;
  final bool isSelected;
  final bool isCompact;
  final PostService postService;
  final Function(bsky.FeedView) onUpdatePost;

  const PostCard({
    super.key,
    required this.post,
    required this.postService,
    required this.onUpdatePost,
    this.isSelected = false,
    this.isCompact = false,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bsky.FeedView _post;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  Future<void> _handleLike() async {
    // Store the previous state in case we need to revert
    final previousState = _post;

    try {
      // Update UI immediately
      setState(() {
        if (_post.post.viewer.like == null) {
          _post = _post.copyWith(
            post: _post.post.copyWith(
              likeCount: _post.post.likeCount + 1,
              viewer: _post.post.viewer.copyWith(like: _post.post.uri),
            ),
          );
        } else {
          _post = _post.copyWith(
            post: _post.post.copyWith(
              likeCount: _post.post.likeCount - 1,
              viewer: _post.post.viewer.copyWith(like: null),
            ),
          );
        }
      });

      // Make API call after UI update
      if (previousState.post.viewer.like == null) {
        await widget.postService.likePost(_post.post.uri, _post.post.cid);
      } else {
        await widget.postService.unlikePost(previousState.post.viewer.like!);
      }

      widget.onUpdatePost(_post);
    } catch (e) {
      // If API call fails, revert to previous state
      setState(() {
        _post = previousState;
      });
      debugPrint('Error liking/unliking post: $e');
    }
  }

  Future<void> _handleRepost() async {
    // Store the previous state in case we need to revert
    final previousState = _post;

    try {
      // Update UI immediately
      setState(() {
        if (_post.post.viewer.repost == null) {
          _post = _post.copyWith(
            post: _post.post.copyWith(
              repostCount: _post.post.repostCount + 1,
              viewer: _post.post.viewer.copyWith(repost: _post.post.uri),
            ),
          );
        } else {
          _post = _post.copyWith(
            post: _post.post.copyWith(
              repostCount: _post.post.repostCount - 1,
              viewer: _post.post.viewer.copyWith(repost: null),
            ),
          );
        }
      });

      // Make API call after UI update
      if (previousState.post.viewer.repost == null) {
        await widget.postService.repost(_post.post.uri, _post.post.cid);
      } else {
        await widget.postService.unrepost(previousState.post.viewer.repost!);
      }

      widget.onUpdatePost(_post);
    } catch (e) {
      // If API call fails, revert to previous state
      setState(() {
        _post = previousState;
      });
      debugPrint('Error reposting/unreposting post: $e');
    }
  }

  void _handleReply(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ReplyComposer(
        postService: widget.postService,
        replyTo: _post,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PostContext(
      post: _post,
      postService: widget.postService,
      onUpdatePost: widget.onUpdatePost,
      isCompact: widget.isCompact,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: widget.isSelected ? Colors.grey.shade50 : null,
        child: Padding(
          padding: EdgeInsets.all(widget.isCompact ? 12.0 : 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PostAvatar(
                avatarUrl: _post.post.author.avatar,
                isCompact: widget.isCompact,
              ),
              SizedBox(width: widget.isCompact ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show reply info if this is a reply
                    if (_post.reply != null) ReplyInfo(replyTo: _post.reply!),

                    PostHeader(
                      post: _post,
                      isCompact: widget.isCompact,
                      postService: widget.postService,
                    ),
                    SizedBox(height: widget.isCompact ? 2 : 4),
                    PostBody(
                      text: _post.post.record.text,
                      isCompact: widget.isCompact,
                    ),

                    // Show embedded media if present
                    if (_post.post.embed != null)
                      PostEmbed(embed: _post.post.embed!),

                    SizedBox(height: widget.isCompact ? 8 : 12),
                    PostActions(
                      post: _post,
                      isCompact: widget.isCompact,
                      onLike: _handleLike,
                      onRepost: _handleRepost,
                      onReply: () => _handleReply(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Add a ReplyInfo widget
class ReplyInfo extends StatelessWidget {
  final bsky.Reply replyTo;

  const ReplyInfo({super.key, required this.replyTo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.reply, size: 12, color: AppColors.darkGray),
              const SizedBox(width: 4),
              Text(
                'Replying to @${(replyTo.parent.data as bsky.Post).author.handle}',
                style: TextStyle(
                  color: AppColors.blue,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          // const SizedBox(height: 4),
          // Text(
          //   postText,
          //   style: TextStyle(
          //     color: AppColors.darkGray,
          //     fontSize: 12,
          //   ),
          //),
        ],
      ),
    );
  }
}

// Add a PostEmbed widget to handle different embed types
class PostEmbed extends StatelessWidget {
  final bsky.EmbedView embed; // Changed from Embed to EmbedView

  const PostEmbed({super.key, required this.embed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: _buildEmbed(),
    );
  }

  Widget _buildEmbed() {
    if (embed is bsky.EmbedImages) {
      return ImageEmbed(images: (embed as bsky.EmbedImages).images);
    } else if (embed is bsky.EmbedRecord) {
      return RecordEmbed(record: embed as bsky.EmbedRecord);
    } else if (embed is bsky.EmbedExternal) {
      return ExternalEmbed(external: embed as bsky.EmbedExternal);
    }
    return const SizedBox.shrink();
  }
}

// Add widgets for different embed types
class ImageEmbed extends StatelessWidget {
  final List<bsky.Image> images;

  const ImageEmbed({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: images.length == 1 ? 1 : 2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final image = images[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            image.image.ref.link,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}

// Add RecordEmbed widget
class RecordEmbed extends StatelessWidget {
  final bsky.EmbedRecord record;

  const RecordEmbed({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child:
          Text(record.toString()), // Customize this to display record details
    );
  }
}

class ExternalEmbed extends StatelessWidget {
  final bsky.EmbedExternal external;

  const ExternalEmbed({super.key, required this.external});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (external.external.title != null)
            Text(
              external.external.title!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          if (external.external.description != null)
            Text(external.external.description!),
          if (external.external.uri != null)
            Text(
              external.external.uri!,
              style: const TextStyle(color: Colors.blue),
            ),
        ],
      ),
    );
  }
}

// Simplified PostActions widget that uses PostContext
class PostActionsWidget extends StatelessWidget {
  const PostActionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final postContext = PostContext.of(context);

    return PostActions(
      post: postContext.post,
      isCompact: postContext.isCompact,
      onLike: () => postContext.handleLike(),
      onRepost: () => postContext.handleRepost(),
      onReply: () => postContext.handleReply(context),
    );
  }
}
