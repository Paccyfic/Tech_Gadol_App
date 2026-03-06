import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';

class CacheBanner extends StatelessWidget {
  final bool isStale;
  final VoidCallback? onRefresh;

  const CacheBanner({
    super.key,
    required this.isStale,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isStale ? AppTheme.warningColor : AppTheme.infoColor;
    final label = isStale
        ? 'Showing cached data · tap to refresh'
        : 'Loaded from cache';
    final icon = isStale
        ? Icons.sync_problem_rounded
        : Icons.offline_pin_rounded;

    return Material(
      color: color.withOpacity(0.12),
      child: InkWell(
        onTap: isStale ? onRefresh : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style:
                      theme.textTheme.labelSmall?.copyWith(color: color),
                ),
              ),
              if (isStale)
                Icon(Icons.chevron_right_rounded, size: 16, color: color),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: -0.5, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }
}