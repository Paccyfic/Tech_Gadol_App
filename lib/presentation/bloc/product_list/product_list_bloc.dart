import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../data/datasources/local/product_local_datasource.dart';
import '../../../data/models/product_model.dart';
import '../../../domain/repositories/product_repository_impl.dart';
import '../../../data/repositories/product_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class ProductListEvent extends Equatable {
  const ProductListEvent();
  @override
  List<Object?> get props => [];
}

class ProductListLoadRequested extends ProductListEvent {
  const ProductListLoadRequested();
}

class ProductListLoadMoreRequested extends ProductListEvent {
  const ProductListLoadMoreRequested();
}

class ProductListSearchChanged extends ProductListEvent {
  final String query;
  const ProductListSearchChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class ProductListCategorySelected extends ProductListEvent {
  final String? category;
  const ProductListCategorySelected(this.category);
  @override
  List<Object?> get props => [category];
}

class ProductListRefreshRequested extends ProductListEvent {
  const ProductListRefreshRequested();
}

class _ProductListSilentRefreshRequested extends ProductListEvent {
  const _ProductListSilentRefreshRequested();
}

// ── State ─────────────────────────────────────────────────────────────────────

enum ProductListStatus { initial, loading, loaded, error, empty }

class ProductListState extends Equatable {
  final ProductListStatus status;
  final List<ProductModel> products;
  final String? selectedCategory;
  final String searchQuery;
  final bool hasMore;
  final bool isLoadingMore;
  final String? errorMessage;
  final int currentSkip;
  final bool isFromCache;
  final bool isCacheStale;

  const ProductListState({
    this.status = ProductListStatus.initial,
    this.products = const [],
    this.selectedCategory,
    this.searchQuery = '',
    this.hasMore = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.currentSkip = 0,
    this.isFromCache = false,
    this.isCacheStale = false,
  });

  ProductListState copyWith({
    ProductListStatus? status,
    List<ProductModel>? products,
    String? Function()? selectedCategory,
    String? searchQuery,
    bool? hasMore,
    bool? isLoadingMore,
    String? errorMessage,
    int? currentSkip,
    bool? isFromCache,
    bool? isCacheStale,
  }) {
    return ProductListState(
      status: status ?? this.status,
      products: products ?? this.products,
      selectedCategory: selectedCategory != null
          ? selectedCategory()
          : this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage ?? this.errorMessage,
      currentSkip: currentSkip ?? this.currentSkip,
      isFromCache: isFromCache ?? this.isFromCache,
      isCacheStale: isCacheStale ?? this.isCacheStale,
    );
  }

  @override
  List<Object?> get props => [
        status,
        products,
        selectedCategory,
        searchQuery,
        hasMore,
        isLoadingMore,
        errorMessage,
        currentSkip,
        isFromCache,
        isCacheStale,
      ];
}

// ── Bloc ──────────────────────────────────────────────────────────────────────

class ProductListBloc extends Bloc<ProductListEvent, ProductListState> {
  final ProductRepository _repository;
  Timer? _debounceTimer;

  ProductRepositoryImpl? get _repoImpl =>
      _repository is ProductRepositoryImpl
          ? _repository as ProductRepositoryImpl
          : null;

  ProductListBloc({required ProductRepository repository})
      : _repository = repository,
        super(const ProductListState()) {
    on<ProductListLoadRequested>(_onLoadRequested);
    on<ProductListLoadMoreRequested>(_onLoadMore);
    on<ProductListSearchChanged>(_onSearchChanged);
    on<ProductListCategorySelected>(_onCategorySelected);
    on<ProductListRefreshRequested>(_onRefresh);
    on<_ProductListSilentRefreshRequested>(_onSilentRefresh);
  }

  Future<void> _onLoadRequested(
    ProductListLoadRequested event,
    Emitter<ProductListState> emit,
  ) async {
    if (state.status == ProductListStatus.loading) return;
    emit(state.copyWith(status: ProductListStatus.loading, currentSkip: 0));
    await _fetchProducts(emit, skip: 0, reset: true);
  }

  Future<void> _onLoadMore(
    ProductListLoadMoreRequested event,
    Emitter<ProductListState> emit,
  ) async {
    if (!state.hasMore || state.isLoadingMore) return;
    emit(state.copyWith(isLoadingMore: true));
    await _fetchProducts(
        emit, skip: state.currentSkip + ApiConstants.defaultLimit);
  }

  Future<void> _onSearchChanged(
    ProductListSearchChanged event,
    Emitter<ProductListState> emit,
  ) async {
    _debounceTimer?.cancel();
    emit(state.copyWith(searchQuery: event.query, currentSkip: 0));

    final completer = Completer<void>();
    _debounceTimer = Timer(
      const Duration(milliseconds: ApiConstants.searchDebounceMs),
      () => completer.complete(),
    );
    await completer.future;

    if (!isClosed) {
      emit(state.copyWith(status: ProductListStatus.loading));
      await _fetchProducts(emit, skip: 0, reset: true);
    }
  }

  Future<void> _onCategorySelected(
    ProductListCategorySelected event,
    Emitter<ProductListState> emit,
  ) async {
    emit(state.copyWith(
      selectedCategory: () => event.category,
      status: ProductListStatus.loading,
      currentSkip: 0,
    ));
    await _fetchProducts(emit, skip: 0, reset: true);
  }

  Future<void> _onRefresh(
    ProductListRefreshRequested event,
    Emitter<ProductListState> emit,
  ) async {
    emit(state.copyWith(
      status: ProductListStatus.loading,
      currentSkip: 0,
      isFromCache: false,
      isCacheStale: false,
    ));
    await _fetchProducts(emit, skip: 0, reset: true, forceNetwork: true);
  }

  Future<void> _onSilentRefresh(
    _ProductListSilentRefreshRequested event,
    Emitter<ProductListState> emit,
  ) async {
    final repoImpl = _repoImpl;
    if (repoImpl == null) return;
    final result = await repoImpl.refreshProducts(
      limit: ApiConstants.defaultLimit,
      skip: 0,
    );
    result.fold(
      (_) => null, // silent fail — stale data remains shown
      (response) {
        if (!isClosed) {
          emit(state.copyWith(
            products: response.products,
            hasMore: response.hasMore,
            currentSkip: 0,
            isFromCache: false,
            isCacheStale: false,
          ));
        }
      },
    );
  }

  Future<void> _fetchProducts(
    Emitter<ProductListState> emit, {
    required int skip,
    bool reset = false,
    bool forceNetwork = false,
  }) async {
    final query = state.searchQuery.trim();
    final category = state.selectedCategory;

    final result = await _resolveRequest(
      query: query,
      category: category,
      skip: skip,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: ProductListStatus.error,
          isLoadingMore: false,
          errorMessage: _mapFailureMessage(failure),
        ));
      },
      (response) {
        final newProducts = reset
            ? response.products
            : [...state.products, ...response.products];

        final isStale = response.isFromCache &&
            response.cacheStatus == CacheStatus.stale;

        emit(state.copyWith(
          status: newProducts.isEmpty
              ? ProductListStatus.empty
              : ProductListStatus.loaded,
          products: newProducts,
          hasMore: response.hasMore,
          isLoadingMore: false,
          currentSkip: skip,
          errorMessage: null,
          isFromCache: response.isFromCache,
          isCacheStale: isStale,
        ));

        // Trigger silent background refresh when stale
        if (isStale && !isClosed) {
          add(const _ProductListSilentRefreshRequested());
        }
      },
    );
  }

  Future<dynamic> _resolveRequest({
    required String query,
    required String? category,
    required int skip,
  }) {
    if (query.isNotEmpty) {
      return _repository.searchProducts(
        query,
        limit: ApiConstants.defaultLimit,
        skip: skip,
      );
    } else if (category != null) {
      return _repository.getProductsByCategory(
        category,
        limit: ApiConstants.defaultLimit,
        skip: skip,
      );
    } else {
      return _repository.getProducts(
        limit: ApiConstants.defaultLimit,
        skip: skip,
      );
    }
  }

  String _mapFailureMessage(Failure failure) {
    if (failure is NetworkFailure) return failure.message;
    if (failure is ServerFailure) return 'Server error. Please try again.';
    return 'Something went wrong. Please try again.';
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}