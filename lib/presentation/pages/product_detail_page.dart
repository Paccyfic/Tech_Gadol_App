import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../core/di/injection.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/product_model.dart';
import '../bloc/product_detail/product_detail_bloc.dart';
import '../widgets/design_system/app_badges.dart';
import '../widgets/design_system/app_states.dart';
import '../widgets/product/product_image_gallery.dart';

class ProductDetailPage extends StatelessWidget {
  final int productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProductDetailBloc>(
      create: (_) => getIt<ProductDetailBloc>()
        ..add(ProductDetailLoadRequested(productId)),
      child: ProductDetailBody(productId: productId),
    );
  }
}

class ProductDetailBody extends StatefulWidget {
  final int productId;

  const ProductDetailBody({super.key, required this.productId});

  @override
  State<ProductDetailBody> createState() => _ProductDetailBodyState();
}

class _ProductDetailBodyState extends State<ProductDetailBody> {
  @override
  void didUpdateWidget(ProductDetailBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId) {
      context.read<ProductDetailBloc>().add(
            ProductDetailLoadRequested(widget.productId),
          );
    }
  }

  @override

Widget build(BuildContext context) {
  return BlocBuilder<ProductDetailBloc, ProductDetailState>(
    builder: (context, state) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
             'Product Details',
            overflow: TextOverflow.ellipsis,
          ),
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                )
              : null,
        ),
        body: _buildBody(context, state),
      );
    },
  );
}

  Widget _buildBody(BuildContext context, ProductDetailState state) {
    switch (state.status) {
      case ProductDetailStatus.initial:
      case ProductDetailStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case ProductDetailStatus.error:
        return AppErrorState(
          message: state.errorMessage ?? 'Failed to load product.',
          onAction: () => context.read<ProductDetailBloc>().add(
                ProductDetailRefreshRequested(widget.productId),
              ),
        );

      case ProductDetailStatus.loaded:
        return _buildContent(context, state.product!);
    }
  }

  Widget _buildContent(BuildContext context, ProductModel product) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Enhancement C: helper for per-section staggered entrance
    Widget animSection(Widget child, int step) => child
        .animate()
        .fadeIn(
            delay: Duration(milliseconds: 60 * step), duration: 350.ms)
        .slideY(
            begin: 0.08,
            end: 0,
            delay: Duration(milliseconds: 60 * step),
            duration: 350.ms,
            curve: Curves.easeOutCubic);

    return CustomScrollView(
      slivers: [
        // Image gallery — Hero transition on first image
        SliverToBoxAdapter(
          child: ProductImageGallery(
            images: product.images,
            productId: product.id,
            height: 280,
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // [0] Category tag
                animSection(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      product.category
                          .replaceAll('-', ' ')
                          .toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  0,
                ),
                const SizedBox(height: AppSpacing.md),

                // [1] Title + Brand
                animSection(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.title,
                          style: theme.textTheme.headlineSmall),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'by ${product.brand}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  1,
                ),
                const SizedBox(height: AppSpacing.lg),

                // [2] Price
                animSection(
                  AppPriceBadge(
                    price: product.price,
                    discountPercentage: product.discountPercentage,
                    fontSize: 22,
                  ),
                  2,
                ),
                const SizedBox(height: AppSpacing.lg),

                // [3] Rating + Stock
                animSection(
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: product.rating,
                        itemBuilder: (context, _) => Icon(
                          Icons.star_rounded,
                          color: AppTheme.warningColor,
                        ),
                        itemCount: 5,
                        itemSize: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        product.rating.toStringAsFixed(1),
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '/ 5.0',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const Spacer(),
                      AppStockBadge(stock: product.stock),
                    ],
                  ),
                  3,
                ),
                const SizedBox(height: AppSpacing.lg),

                const Divider(),
                const SizedBox(height: AppSpacing.lg),

                // [4] Description
                animSection(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Description',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        product.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color:
                              colorScheme.onSurface.withOpacity(0.75),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                  4,
                ),
                const SizedBox(height: AppSpacing.xxl),

                // [5] Details table
                animSection(
                    _buildDetailsSection(context, product), 5),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection(
      BuildContext context, ProductModel product) {
    final theme = Theme.of(context);
    final items = [
      ('Brand', product.brand),
      ('Category', product.category.replaceAll('-', ' ')),
      ('Stock', '${product.stock} units'),
      ('Discount',
          '${product.discountPercentage.toStringAsFixed(1)}%'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Product Details', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            children: List.generate(items.length, (index) {
              final item = items[index];
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.$1,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.6),
                          ),
                        ),
                        Text(
                          item.$2,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  if (index < items.length - 1)
                    const Divider(height: 1),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}