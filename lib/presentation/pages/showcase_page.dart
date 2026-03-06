import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/injection.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/product_model.dart';
import '../bloc/theme/theme_cubit.dart';
import '../widgets/design_system/app_badges.dart';
import '../widgets/design_system/app_network_image.dart';
import '../widgets/design_system/app_search_bar.dart';
import '../widgets/design_system/app_states.dart';
import '../widgets/design_system/category_chip.dart';
import '../widgets/design_system/skeleton_loader.dart';
import '../widgets/product/product_card.dart';

class ShowcasePage extends StatefulWidget {
  const ShowcasePage({super.key});

  @override
  State<ShowcasePage> createState() => _ShowcasePageState();
}

class _ShowcasePageState extends State<ShowcasePage> {
  String? _selectedCategory;

  static final _mockProduct = ProductModel(
    id: 1,
    title: 'iPhone 14 Pro Max',
    description: 'An amazingly powerful smartphone',
    price: 1299.99,
    discountPercentage: 15.0,
    rating: 4.7,
    stock: 8,
    brand: 'Apple',
    category: 'smartphones',
    thumbnail: 'https://cdn.dummyjson.com/product-images/1/thumbnail.jpg',
    images: ['https://cdn.dummyjson.com/product-images/1/thumbnail.jpg'],
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Component Showcase'),
        actions: [
          BlocBuilder<ThemeCubit, ThemeMode>(
            bloc: getIt<ThemeCubit>(),
            builder: (_, mode) => IconButton(
              icon: Icon(mode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined),
              onPressed: () => getIt<ThemeCubit>().toggle(),
              tooltip: 'Toggle theme',
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _section(
            context,
            'SearchBar',
            'Input component with clear button and prefix icon',
            const AppSearchBar(),
          ),
          _section(
            context,
            'CategoryChips',
            'Horizontal scrollable filter chips',
            CategoryChipRow(
              categories: ['smartphones', 'laptops', 'fragrances', 'skincare', 'groceries'],
              selectedCategory: _selectedCategory,
              onCategorySelected: (cat) => setState(() => _selectedCategory = cat),
            ),
          ),
          _section(
            context,
            'ProductCard',
            'Default and selected state',
            Column(
              children: [
                ProductCard(
                  product: _mockProduct,
                  onTap: () {},
                ),
                const SizedBox(height: 8),
                ProductCard(
                  product: _mockProduct,
                  isSelected: true,
                  onTap: () {},
                ),
              ],
            ),
          ),
          _section(
            context,
            'AppNetworkImage',
            'Valid URL, invalid URL, and null URL',
            Row(
              children: [
                Expanded(
                  child: AppNetworkImage(
                    imageUrl: _mockProduct.thumbnail,
                    height: 100,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppNetworkImage(
                    imageUrl: 'invalid-url',
                    height: 100,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppNetworkImage(
                    imageUrl: null,
                    height: 100,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ],
            ),
          ),
          _section(
            context,
            'AppPriceBadge',
            'With discount, without discount, unavailable',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppPriceBadge(price: 99.99, discountPercentage: 20, fontSize: 16),
                const SizedBox(height: 8),
                AppPriceBadge(price: 49.99, discountPercentage: 0, fontSize: 16),
                const SizedBox(height: 8),
                AppPriceBadge(price: -1, discountPercentage: 0, fontSize: 16),
              ],
            ),
          ),
          _section(
            context,
            'AppRatingBadge',
            'High, medium, and low ratings',
            Row(
              children: [
                AppRatingBadge(rating: 4.8, size: 14),
                const SizedBox(width: 24),
                AppRatingBadge(rating: 3.5, size: 14),
                const SizedBox(width: 24),
                AppRatingBadge(rating: 2.1, size: 14),
              ],
            ),
          ),
          _section(
            context,
            'AppStockBadge',
            'In stock, low stock, out of stock',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppStockBadge(stock: 120),
                const SizedBox(height: 8),
                AppStockBadge(stock: 4),
                const SizedBox(height: 8),
                AppStockBadge(stock: 0),
              ],
            ),
          ),
          _section(
            context,
            'Skeleton Loader',
            'Loading placeholder',
            Column(
              children: [
                ProductCardSkeleton(),
                ProductCardSkeleton(),
              ],
            ),
          ),
          _section(
            context,
            'ErrorState',
            'Error UI with retry action',
            AppErrorState(
              message: 'No internet connection. Please check your network settings.',
              onAction: () {},
            ),
          ),
          _section(
            context,
            'EmptyState',
            'Empty search results',
            AppEmptyState(
              title: 'No products found',
              subtitle: 'Try searching for something else',
              onAction: () {},
              actionLabel: 'Clear Search',
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  Widget _section(
    BuildContext context,
    String title,
    String description,
    Widget child,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          child,
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
        ],
      ),
    );
  }
}
