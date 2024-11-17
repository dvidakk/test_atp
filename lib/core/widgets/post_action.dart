import 'package:flutter/material.dart';
import 'package:test_atp/core/constants/colors.dart';

class PostAction extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final int? count;
  final double size;
  final bool isActive;
  final VoidCallback? onPressed;

  const PostAction({
    super.key,
    required this.icon,
    this.activeIcon,
    this.count,
    this.size = 20,
    this.isActive = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            isActive ? (activeIcon ?? icon) : icon,
            size: size,
            color: isActive ? AppColors.blue : AppColors.darkGray,
          ),
          onPressed: onPressed,
          padding: EdgeInsets.all(size * 0.4),
          constraints: BoxConstraints(
            minWidth: size * 2,
            minHeight: size * 2,
          ),
        ),
        if (count != null && count! > 0)
          Text(
            count.toString(),
            style: TextStyle(
              color: isActive ? AppColors.blue : AppColors.darkGray,
              fontSize: size * 0.7,
            ),
          ),
      ],
    );
  }
}
