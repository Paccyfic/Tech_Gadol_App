import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class AppRatingBadge extends StatelessWidget {
  final double rating;
  final bool showCount;
  final int? reviewCount;
  final double size;

  const AppRatingBadge({
    super.key,
    required this.rating,
    this.showCount = false,
    this.reviewCount,
    this.size = 12,
  });

  Color _ratingColor(double r) {
    if (r >= 4.5) return AppTheme.successColor;
    if (r >= 3.5) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  @override
  Widget build(BuildContext context) {
    final color = _ratingColor(rating);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: size + 2, color: color),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        if (showCount && reviewCount != null) ...[
          const SizedBox(width: 4),
          Text(
            '($reviewCount)',
            style: TextStyle(
              fontSize: size - 1,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ],
    );
  }
}

class AppPriceBadge extends StatelessWidget {
  final double? price;
  final double? discountPercentage;
  final double fontSize;

  const AppPriceBadge({
    super.key,
    required this.price,
    this.discountPercentage,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (price == null || price! <= 0) {
      return Text(
        'Price unavailable',
        style: TextStyle(
          fontSize: fontSize,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final hasDiscount = discountPercentage != null && discountPercentage! > 0;
    final discountedPrice = hasDiscount ? price! * (1 - discountPercentage! / 100) : price!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '\$${discountedPrice.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        if (hasDiscount) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(
            '\$${price!.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: fontSize - 2,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Text(
              '-${discountPercentage!.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: fontSize - 4,
                fontWeight: FontWeight.w700,
                color: AppTheme.errorColor,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class AppStockBadge extends StatelessWidget {
  final int stock;

  const AppStockBadge({super.key, required this.stock});

  @override
  Widget build(BuildContext context) {
    final inStock = stock > 0;
    final color = inStock ? AppTheme.successColor : AppTheme.errorColor;
    final label = inStock ? (stock < 10 ? 'Only $stock left' : 'In Stock') : 'Out of Stock';
    final icon = inStock ? Icons.check_circle_outline_rounded : Icons.remove_circle_outline_rounded;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
