import 'package:flutter/material.dart';

class PostBody extends StatelessWidget {
  final String text;
  final bool isCompact;

  const PostBody({
    required this.text,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: isCompact ? 14 : 16,
        height: 1.4,
      ),
    );
  }
}
