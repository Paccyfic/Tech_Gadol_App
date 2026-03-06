import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../data/repositories/product_repository.dart';

enum CategoryStatus { initial, loading, loaded, error }

class CategoryState extends Equatable {
  final CategoryStatus status;
  final List<String> categories;
  final String? errorMessage;

  const CategoryState({
    this.status = CategoryStatus.initial,
    this.categories = const [],
    this.errorMessage,
  });

  CategoryState copyWith({
    CategoryStatus? status,
    List<String>? categories,
    String? errorMessage,
  }) => CategoryState(
    status: status ?? this.status,
    categories: categories ?? this.categories,
    errorMessage: errorMessage ?? this.errorMessage,
  );

  @override
  List<Object?> get props => [status, categories, errorMessage];
}

class CategoryCubit extends Cubit<CategoryState> {
  final ProductRepository _repository;

  CategoryCubit({required ProductRepository repository})
      : _repository = repository,
        super(const CategoryState());

  Future<void> loadCategories() async {
    if (state.status == CategoryStatus.loading) return;
    emit(state.copyWith(status: CategoryStatus.loading));

    final result = await _repository.getCategories();
    result.fold(
      (failure) => emit(state.copyWith(
        status: CategoryStatus.error,
        errorMessage: failure.message,
      )),
      (categories) => emit(state.copyWith(
        status: CategoryStatus.loaded,
        categories: categories,
      )),
    );
  }
}
