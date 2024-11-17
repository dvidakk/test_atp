// lib/composer/widgets/base_composer.dart
import 'package:flutter/material.dart';
import 'package:test_atp/core/constants/colors.dart';
import 'package:test_atp/core/services/post_service.dart';
import 'package:bluesky/bluesky.dart' as bsky;

enum ComposerType {
  newPost,
  reply,
  quote,
  // Add other types as needed
}

class BaseComposer extends StatefulWidget {
  final PostService postService;
  final VoidCallback onCancel;
  final Future<void> Function(String text) onSubmit;
  final ComposerType type;
  final bsky.FeedView? parentPost; // For replies or quotes
  final String? hintText;
  final String? submitButtonText;

  const BaseComposer({
    Key? key,
    required this.postService,
    required this.onSubmit,
    required this.onCancel,
    required this.type,
    this.parentPost,
    this.hintText,
    this.submitButtonText,
  }) : super(key: key);

  @override
  State<BaseComposer> createState() => _BaseComposerState();
}

class _BaseComposerState extends State<BaseComposer> {
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;
  static const int _maxChars = 300;

  Future<void> _handleSubmit() async {
    if (_textController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onSubmit(_textController.text);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error: $e');
      // Optionally show error message to the user
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  PreferredSizeWidget _buildHeader() {
    return AppBar(
      leading: IconButton(
        onPressed: widget.onCancel,
        icon: const Icon(Icons.close),
      ),
      title: Text(widget.submitButtonText ?? 'Compose'),
      actions: [
        TextButton(
          onPressed:
              _isLoading || _textController.text.isEmpty ? null : _handleSubmit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  widget.submitButtonText ??
                      (widget.type == ComposerType.reply ? 'Reply' : 'Post'),
                  style: const TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }

  Widget _buildComposerContent() {
    switch (widget.type) {
      case ComposerType.reply:
        return _buildReplyComposer();
      case ComposerType.newPost:
        return _buildNewPostComposer();
      case ComposerType.quote:
        return _buildQuoteComposer();
      default:
        return _buildNewPostComposer();
    }
  }

  Widget _buildReplyComposer() {
    final parentPost = widget.parentPost!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Replying to text
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Replying to @${parentPost.post.author.handle}',
              style: TextStyle(
                color: AppColors.blue,
                fontSize: 14,
              ),
            ),
          ),
          // Parent post preview
          _buildParentPostPreview(parentPost),
          const Divider(),
          // Text input with avatar
          _buildTextInput(),
        ],
      ),
    );
  }

  Widget _buildNewPostComposer() {
    return SingleChildScrollView(
      child: _buildTextInput(),
    );
  }

  Widget _buildQuoteComposer() {
    final parentPost = widget.parentPost!;
    return SingleChildScrollView(
      child: Column(
        children: [
          // Text input
          _buildTextInput(),
          // Parent post preview
          _buildParentPostPreview(parentPost),
        ],
      ),
    );
  }

  Widget _buildParentPostPreview(bsky.FeedView parentPost) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: parentPost.post.author.avatar != null
            ? NetworkImage(parentPost.post.author.avatar!)
            : null,
        backgroundColor: Colors.grey[300],
      ),
      title: Text(
        parentPost.post.author.displayName ?? parentPost.post.author.handle,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(parentPost.post.record.text),
    );
  }

  Widget _buildTextInput() {
    final charCount = _textController.text.length;
    final isOverLimit = charCount > _maxChars;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User avatar (placeholder)
          CircleAvatar(
            backgroundColor: Colors.grey[300],
            // TODO: Replace with current user's avatar
          ),
          const SizedBox(width: 12),
          // Text input area
          Expanded(
            child: Column(
              children: [
                TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: widget.hintText ??
                        (widget.type == ComposerType.reply
                            ? 'Tweet your reply'
                            : "What's happening?"),
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  maxLength: _maxChars,
                  onChanged: (_) {
                    setState(() {});
                  },
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.image),
                      onPressed: () {},
                      color: AppColors.blue,
                    ),
                    IconButton(
                      icon: const Icon(Icons.gif_box),
                      onPressed: () {},
                      color: AppColors.blue,
                    ),
                    IconButton(
                      icon: const Icon(Icons.emoji_emotions),
                      onPressed: () {},
                      color: AppColors.blue,
                    ),
                    const Spacer(),
                    Text(
                      '$charCount/$_maxChars',
                      style: TextStyle(
                        color: isOverLimit ? Colors.red : Colors.grey,
                        fontWeight:
                            isOverLimit ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildHeader(),
      body: _buildComposerContent(),
    );
  }
}
