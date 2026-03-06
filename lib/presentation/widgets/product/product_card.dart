import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/product_model.dart';
import '../design_system/app_badges.dart';
import '../design_system/app_network_image.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final bool isSelected;
  final int index;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.isSelected = false,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: AppDuration.fast,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primary.withOpacity(0.08)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: isSelected
            ? Border.all(color: colorScheme.primary, width: 1.5)
            : Border.all(color: Colors.transparent),
        boxShadow: isSelected
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: AppNetworkImage(
                    imageUrl: product.thumbnail,
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.brand,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.title,
                        style: theme.textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppPriceBadge(
                        price: product.price,
                        discountPercentage: product.discountPercentage,
                        fontSize: 14,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          AppRatingBadge(rating: product.rating, size: 11),
                          const Spacer(),
                          AppStockBadge(stock: product.stock),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 40 * (index % 20)),
          duration: AppDuration.slow,
          curve: Curves.easeOut,
        )
        .slideY(
          begin: 0.12,
          end: 0,
          delay: Duration(milliseconds: 40 * (index % 20)),
          duration: AppDuration.slow,
          curve: Curves.easeOutCubic,
        );
  }
}