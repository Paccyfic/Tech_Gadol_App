import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_theme.dart';

class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF21262D) : const Color(0xFFE5E7EB);
    final highlightColor = isDark ? const Color(0xFF30363D) : const Color(0xFFF3F4F6);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail skeleton
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.md),
                  bottomLeft: Radius.circular(AppRadius.md),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Content skeleton
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: double.infinity, color: Colors.white),
                    const SizedBox(height: AppSpacing.sm),
                    Container(height: 12, width: 180, color: Colors.white),
                    const SizedBox(height: AppSpacing.md),
                    Container(height: 12, width: 100, color: Colors.white),
                    const SizedBox(height: AppSpacing.sm),
                    Container(height: 12, width: 60, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int count;

  const SkeletonList({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      itemBuilder: (_, __) => const ProductCardSkeleton(),
    );
  }
}
