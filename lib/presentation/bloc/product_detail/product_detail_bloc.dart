import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/errors/failures.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class ProductDetailEvent extends Equatable {
  const ProductDetailEvent();
  @override
  List<Object?> get props => [];
}

class ProductDetailLoadRequested extends ProductDetailEvent {
  final int productId;
  const ProductDetailLoadRequested(this.productId);
  @override
  List<Object?> get props => [productId];
}

class ProductDetailRefreshRequested extends ProductDetailEvent {
  final int productId;
  const ProductDetailRefreshRequested(this.productId);
  @override
  List<Object?> get props => [productId];
}

// ── State ─────────────────────────────────────────────────────────────────────

enum ProductDetailStatus { initial, loading, loaded, error }

class ProductDetailState extends Equatable {
  final ProductDetailStatus status;
  final ProductModel? product;
  final String? errorMessage;

  const ProductDetailState({
    this.status = ProductDetailStatus.initial,
    this.product,
    this.errorMessage,
  });

  ProductDetailState copyWith({
    ProductDetailStatus? status,
    ProductModel? product,
    String? errorMessage,
  }) {
    return ProductDetailState(
      status: status ?? this.status,
      product: product ?? this.product,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, product, errorMessage];
}

// ── Bloc ──────────────────────────────────────────────────────────────────────

class ProductDetailBloc extends Bloc<ProductDetailEvent, ProductDetailState> {
  final ProductRepository _repository;

  ProductDetailBloc({required ProductRepository repository})
      : _repository = repository,
        super(const ProductDetailState()) {
    on<ProductDetailLoadRequested>(_onLoad);
    on<ProductDetailRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoad(
    ProductDetailLoadRequested event,
    Emitter<ProductDetailState> emit,
  ) async {
    emit(state.copyWith(status: ProductDetailStatus.loading));
    await _fetch(event.productId, emit);
  }

  Future<void> _onRefresh(
    ProductDetailRefreshRequested event,
    Emitter<ProductDetailState> emit,
  ) async {
    emit(state.copyWith(status: ProductDetailStatus.loading));
    await _fetch(event.productId, emit);
  }

  Future<void> _fetch(int id, Emitter<ProductDetailState> emit) async {
    final result = await _repository.getProductById(id);
    result.fold(
      (failure) => emit(state.copyWith(
        status: ProductDetailStatus.error,
        errorMessage: _mapFailure(failure),
      )),
      (product) => emit(state.copyWith(
        status: ProductDetailStatus.loaded,
        product: product,
      )),
    );
  }

  String _mapFailure(Failure failure) {
    if (failure is NetworkFailure) return failure.message;
    if (failure is ServerFailure) {
      if (failure.statusCode == 404) return 'Product not found.';
      return 'Server error. Please try again.';
    }
    return 'Failed to load product.';
  }
}
