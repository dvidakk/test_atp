import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class PostAvatar extends StatelessWidget {
  final String? avatarUrl;
  final bool isCompact;

  const PostAvatar({
    required this.avatarUrl,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: isCompact ? 20 : 24,
      backgroundImage: CachedNetworkImageProvider(
        avatarUrl ?? 'https://placeholder.com/150',
      ),
    );
  }
}
