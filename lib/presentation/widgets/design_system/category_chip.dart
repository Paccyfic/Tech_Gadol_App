import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  String get _displayLabel => label.replaceAll('-', ' ').split(' ').map((w) {
        return w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}';
      }).join(' ');

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: AnimatedContainer(
        duration: AppDuration.fast,
        child: FilterChip(
          label: Text(_displayLabel),
          selected: isSelected,
          onSelected: (_) => onTap(),
          selectedColor: colorScheme.primary.withOpacity(0.15),
          checkmarkColor: colorScheme.primary,
          labelStyle: TextStyle(
            color: isSelected ? colorScheme.primary : Theme.of(context).textTheme.bodySmall?.color,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 12,
          ),
          showCheckmark: false,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        ),
      ),
    );
  }
}

class CategoryChipRow extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;

  const CategoryChipRow({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: categories.length + 1, // +1 for "All"
        itemBuilder: (context, index) {
          if (index == 0) {
            return CategoryChip(
              label: 'All',
              isSelected: selectedCategory == null,
              onTap: () => onCategorySelected(null),
            );
          }
          final category = categories[index - 1];
          return CategoryChip(
            label: category,
            isSelected: selectedCategory == category,
            onTap: () => onCategorySelected(
              selectedCategory == category ? null : category,
            ),
          );
        },
      ),
    );
  }
}
