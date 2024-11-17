// First add shimmer package to pubspec.yaml
// shimmer: ^3.0.0

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:test_atp/core/constants/colors.dart';

class PostCardSkeleton extends StatelessWidget {
  final bool isCompact;

  const PostCardSkeleton({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar skeleton
              Container(
                width: isCompact ? 40 : 48,
                height: isCompact ? 40 : 48,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: isCompact ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Author info row
                    Row(
                      children: [
                        Container(
                          width: 120,
                          height: isCompact ? 14 : 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        SizedBox(width: isCompact ? 2 : 4),
                        Container(
                          width: 80,
                          height: isCompact ? 12 : 14,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 60,
                          height: isCompact ? 12 : 14,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isCompact ? 2 : 4),
                    // Post content lines
                    ...List.generate(
                      3,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Container(
                          width: double.infinity,
                          height: isCompact ? 14 : 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isCompact ? 8 : 12),
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        4,
                        (index) => Container(
                          width: isCompact ? 32 : 40,
                          height: isCompact ? 32 : 40,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
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
