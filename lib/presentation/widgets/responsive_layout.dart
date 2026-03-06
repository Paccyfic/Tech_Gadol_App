import 'package:flutter/material.dart';

const double kTabletBreakpoint = 768.0;

bool isTablet(BuildContext context) =>
    MediaQuery.of(context).size.width >= kTabletBreakpoint;

/// Shell that wraps the app's navigation
class ResponsiveShell extends StatelessWidget {
  final Widget child;

  const ResponsiveShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

/// Master-detail layout for tablet
class MasterDetailLayout extends StatelessWidget {
  final Widget master;
  final Widget? detail;
  final Widget emptyDetail;
  final double masterWidth;

  const MasterDetailLayout({
    super.key,
    required this.master,
    required this.detail,
    required this.emptyDetail,
    this.masterWidth = 380,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Master panel
        SizedBox(
          width: masterWidth,
          child: master,
        ),
        // Divider
        const VerticalDivider(width: 1),
        // Detail panel
        Expanded(
          child: detail ?? emptyDetail,
        ),
      ],
    );
  }
}

/// Placeholder shown on tablet right panel when no product selected
class DetailEmptyPrompt extends StatelessWidget {
  const DetailEmptyPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.touch_app_rounded,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Select a product',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a product from the list to view details',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
}
