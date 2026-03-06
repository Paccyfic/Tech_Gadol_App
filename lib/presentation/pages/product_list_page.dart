import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/product_model.dart';
import '../bloc/category/category_cubit.dart';
import '../bloc/product_detail/product_detail_bloc.dart';
import '../bloc/product_list/product_list_bloc.dart';
import '../bloc/theme/theme_cubit.dart';
import '../widgets/design_system/app_search_bar.dart';
import '../widgets/design_system/app_states.dart';
import '../widgets/design_system/cache_banner.dart';
import '../widgets/design_system/category_chip.dart';
import '../widgets/design_system/skeleton_loader.dart';
import '../widgets/product/product_card.dart';
import '../widgets/responsive_layout.dart';
import 'product_detail_page.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  int? _selectedProductId;

  late final ProductListBloc _listBloc;
  late final CategoryCubit _categoryCubit;

  @override
  void initState() {
    super.initState();
    _listBloc = getIt<ProductListBloc>()
      ..add(const ProductListLoadRequested());
    _categoryCubit = getIt<CategoryCubit>()..loadCategories();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_isNearBottom) _listBloc.add(const ProductListLoadMoreRequested());
  }

  bool get _isNearBottom {
    if (!_scrollController.hasClients) return false;
    final max = _scrollController.position.maxScrollExtent;
    return _scrollController.offset >= max - 300;
  }

  void _onProductTap(ProductModel product, BuildContext context) {
    if (isTablet(context)) {
      setState(() => _selectedProductId = product.id);
    } else {
      context.push(AppRoutes.productDetailPath(product.id));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _listBloc.close();
    _categoryCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _listBloc),
        BlocProvider.value(value: _categoryCubit),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tablet = constraints.maxWidth >= kTabletBreakpoint;
          return tablet
              ? _buildTabletLayout(context)
              : _buildPhoneLayout(context);
        },
      ),
    );
  }

  Widget _buildPhoneLayout(BuildContext context) => Scaffold(
        appBar: _buildAppBar(context),
        body: _buildListContent(context),
      );

  Widget _buildTabletLayout(BuildContext context) => Scaffold(
        appBar: _buildAppBar(context),
        body: MasterDetailLayout(
          master: _buildListContent(context),
          detail: _selectedProductId != null
              ? BlocProvider<ProductDetailBloc>(
                  create: (_) => getIt<ProductDetailBloc>()
                    ..add(ProductDetailLoadRequested(_selectedProductId!)),
                  child: ProductDetailBody(productId: _selectedProductId!),
                )
              : null,
          emptyDetail: const DetailEmptyPrompt(),
        ),
      );

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Catalog'),
      actions: [
        IconButton(
          icon: const Icon(Icons.auto_stories_outlined),
          tooltip: 'Component Showcase',
          onPressed: () => context.push(AppRoutes.showcase),
        ),
        BlocBuilder<ThemeCubit, ThemeMode>(
          bloc: getIt<ThemeCubit>(),
          builder: (context, themeMode) {
            final isDark = themeMode == ThemeMode.dark ||
                (themeMode == ThemeMode.system &&
                    MediaQuery.of(context).platformBrightness ==
                        Brightness.dark);
            return IconButton(
              // Enhancement C: smooth icon rotation on theme toggle
              icon: AnimatedSwitcher(
                duration: AppDuration.normal,
                transitionBuilder: (child, anim) => RotationTransition(
                  turns: Tween(begin: 0.75, end: 1.0).animate(anim),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Icon(
                  isDark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  key: ValueKey(isDark),
                ),
              ),
              tooltip: isDark ? 'Light Mode' : 'Dark Mode',
              onPressed: () => getIt<ThemeCubit>().toggle(),
            );
          },
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }

  Widget _buildListContent(BuildContext context) {
    return Column(
      children: [
        // Enhancement B: cache status indicator
        BlocBuilder<ProductListBloc, ProductListState>(
          builder: (context, state) {
            if (state.isFromCache) {
              return CacheBanner(
                isStale: state.isCacheStale,
                onRefresh: () =>
                    _listBloc.add(const ProductListRefreshRequested()),
              );
            }
            return const SizedBox.shrink();
          },
        ),

        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm,
          ),
          child: AppSearchBar(
            controller: _searchController,
            onChanged: (q) => _listBloc.add(ProductListSearchChanged(q)),
            onClear: () =>
                _listBloc.add(const ProductListSearchChanged('')),
          ),
        ),

        // Category chips
        BlocBuilder<CategoryCubit, CategoryState>(
          builder: (context, state) {
            if (state.status == CategoryStatus.loaded &&
                state.categories.isNotEmpty) {
              return BlocBuilder<ProductListBloc, ProductListState>(
                builder: (context, listState) => CategoryChipRow(
                  categories: state.categories,
                  selectedCategory: listState.selectedCategory,
                  onCategorySelected: (cat) =>
                      _listBloc.add(ProductListCategorySelected(cat)),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),

        const SizedBox(height: AppSpacing.sm),

        Expanded(
          child: BlocBuilder<ProductListBloc, ProductListState>(
            builder: (context, state) => _buildBody(context, state),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, ProductListState state) {
    switch (state.status) {
      case ProductListStatus.initial:
      case ProductListStatus.loading:
        return const SkeletonList();

      case ProductListStatus.error:
        return AppErrorState(
          message: state.errorMessage ?? 'Failed to load products.',
          onAction: () =>
              _listBloc.add(const ProductListRefreshRequested()),
        );

      case ProductListStatus.empty:
        return AppEmptyState(
          title: 'No products found',
          subtitle: state.searchQuery.isNotEmpty
              ? 'Try a different search term'
              : 'No products in this category',
          onAction: () {
            _searchController.clear();
            _listBloc
              ..add(const ProductListSearchChanged(''))
              ..add(const ProductListCategorySelected(null));
          },
          actionLabel: 'Clear Filters',
        );

      case ProductListStatus.loaded:
        return RefreshIndicator(
          color: Theme.of(context).colorScheme.primary,
          backgroundColor: Theme.of(context).colorScheme.surface,
          strokeWidth: 2.5,
          onRefresh: () async {
            _listBloc.add(const ProductListRefreshRequested());
            await _listBloc.stream.firstWhere(
              (s) => s.status != ProductListStatus.loading,
            );
          },
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
                top: AppSpacing.xs, bottom: AppSpacing.xl),
            itemCount:
                state.products.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= state.products.length) {
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                      strokeWidth: 2,
                    ),
                  ),
                );
              }
              final product = state.products[index];
              return ProductCard(
                key: ValueKey(product.id),
                product: product,
                index: index, // Enhancement C: stagger index
                isSelected: product.id == _selectedProductId,
                onTap: () => _onProductTap(product, context),
              );
            },
          ),
        );
    }
  }
}