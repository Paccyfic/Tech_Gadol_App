import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:tech_gadol_catalog/core/errors/failures.dart';
import 'package:tech_gadol_catalog/data/repositories/product_repository.dart';
import 'package:tech_gadol_catalog/presentation/bloc/category/category_cubit.dart';

class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late MockProductRepository mockRepository;

  setUp(() => mockRepository = MockProductRepository());

  CategoryCubit buildCubit() =>
      CategoryCubit(repository: mockRepository);

  group('CategoryCubit', () {
    test('initial state is correct', () {
      expect(buildCubit().state, const CategoryState());
      expect(buildCubit().state.status, CategoryStatus.initial);
      expect(buildCubit().state.categories, isEmpty);
    });

    blocTest<CategoryCubit, CategoryState>(
      'emits [loading, loaded] with categories on success',
      build: () {
        when(() => mockRepository.getCategories()).thenAnswer(
          (_) async => const Right(['smartphones', 'laptops', 'fragrances']),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.loadCategories(),
      expect: () => [
        isA<CategoryState>().having(
          (s) => s.status,
          'status',
          CategoryStatus.loading,
        ),
        isA<CategoryState>()
            .having((s) => s.status, 'status', CategoryStatus.loaded)
            .having(
              (s) => s.categories,
              'categories',
              ['smartphones', 'laptops', 'fragrances'],
            ),
      ],
    );

    blocTest<CategoryCubit, CategoryState>(
      'emits [loading, error] on failure',
      build: () {
        when(() => mockRepository.getCategories()).thenAnswer(
          (_) async => const Left(NetworkFailure('Failed to fetch categories')),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.loadCategories(),
      expect: () => [
        isA<CategoryState>()
            .having((s) => s.status, 'status', CategoryStatus.loading),
        isA<CategoryState>()
            .having((s) => s.status, 'status', CategoryStatus.error)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              'Failed to fetch categories',
            ),
      ],
    );

    blocTest<CategoryCubit, CategoryState>(
      'does not re-fetch if already loading',
      build: () {
        when(() => mockRepository.getCategories()).thenAnswer(
          (_) async => const Right(['smartphones']),
        );
        return buildCubit();
      },
      seed: () => const CategoryState(status: CategoryStatus.loading),
      act: (cubit) => cubit.loadCategories(),
      expect: () => [],
    );
  });
}
