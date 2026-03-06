import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:tech_gadol_catalog/core/errors/failures.dart';
import 'package:tech_gadol_catalog/data/models/product_model.dart';
import 'package:tech_gadol_catalog/data/repositories/product_repository.dart';
import 'package:tech_gadol_catalog/presentation/bloc/product_list/product_list_bloc.dart';

class MockProductRepository extends Mock implements ProductRepository {}

const _mockProduct = ProductModel(
  id: 1,
  title: 'Test Product',
  description: 'Desc',
  price: 99.99,
  discountPercentage: 10.0,
  rating: 4.5,
  stock: 20,
  brand: 'Brand',
  category: 'electronics',
  thumbnail: 'https://example.com/thumb.jpg',
  images: ['https://example.com/img.jpg'],
);

final _mockResponse = ProductListResponse(
  products: [_mockProduct],
  total: 1,
  skip: 0,
  limit: 20,
);

const _emptyResponse = ProductListResponse(
  products: [],
  total: 0,
  skip: 0,
  limit: 20,
);

void main() {
  late MockProductRepository mockRepository;

  setUp(() {
    mockRepository = MockProductRepository();
  });

  ProductListBloc buildBloc() =>
      ProductListBloc(repository: mockRepository);

  group('ProductListBloc', () {
    test('initial state is correct', () {
      final bloc = buildBloc();
      expect(bloc.state.status, ProductListStatus.initial);
      expect(bloc.state.products, isEmpty);
      expect(bloc.state.searchQuery, '');
      expect(bloc.state.selectedCategory, isNull);
    });

    blocTest<ProductListBloc, ProductListState>(
      'emits [loading, loaded] when products fetch succeeds',
      build: () {
        when(() => mockRepository.getProducts(limit: any(named: 'limit'), skip: any(named: 'skip')))
            .thenAnswer((_) async => Right(_mockResponse));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ProductListLoadRequested()),
      expect: () => [
        isA<ProductListState>().having(
          (s) => s.status,
          'status',
          ProductListStatus.loading,
        ),
        isA<ProductListState>()
            .having((s) => s.status, 'status', ProductListStatus.loaded)
            .having((s) => s.products.length, 'products count', 1)
            .having((s) => s.hasMore, 'hasMore', false),
      ],
    );

    blocTest<ProductListBloc, ProductListState>(
      'emits [loading, error] when products fetch fails with NetworkFailure',
      build: () {
        when(() => mockRepository.getProducts(limit: any(named: 'limit'), skip: any(named: 'skip')))
            .thenAnswer((_) async => const Left(NetworkFailure('No internet')));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ProductListLoadRequested()),
      expect: () => [
        isA<ProductListState>().having((s) => s.status, 'status', ProductListStatus.loading),
        isA<ProductListState>()
            .having((s) => s.status, 'status', ProductListStatus.error)
            .having((s) => s.errorMessage, 'errorMessage', 'No internet'),
      ],
    );

    blocTest<ProductListBloc, ProductListState>(
      'emits [loading, empty] when no products returned',
      build: () {
        when(() => mockRepository.getProducts(limit: any(named: 'limit'), skip: any(named: 'skip')))
            .thenAnswer((_) async => Right(_emptyResponse));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ProductListLoadRequested()),
      expect: () => [
        isA<ProductListState>().having((s) => s.status, 'status', ProductListStatus.loading),
        isA<ProductListState>()
            .having((s) => s.status, 'status', ProductListStatus.empty)
            .having((s) => s.products, 'products', isEmpty),
      ],
    );

    blocTest<ProductListBloc, ProductListState>(
      'uses searchProducts when query is non-empty',
      build: () {
        when(() => mockRepository.searchProducts(
              any(),
              limit: any(named: 'limit'),
              skip: any(named: 'skip'),
            )).thenAnswer((_) async => Right(_mockResponse));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ProductListSearchChanged('phone')),
      wait: const Duration(milliseconds: 500), // wait for debounce
      verify: (_) {
        verify(() => mockRepository.searchProducts(
              'phone',
              limit: any(named: 'limit'),
              skip: any(named: 'skip'),
            )).called(1);
      },
    );

    blocTest<ProductListBloc, ProductListState>(
      'uses getProductsByCategory when category selected',
      build: () {
        when(() => mockRepository.getProductsByCategory(
              any(),
              limit: any(named: 'limit'),
              skip: any(named: 'skip'),
            )).thenAnswer((_) async => Right(_mockResponse));
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const ProductListCategorySelected('smartphones')),
      expect: () => [
        isA<ProductListState>()
            .having((s) => s.selectedCategory, 'selectedCategory', 'smartphones')
            .having((s) => s.status, 'status', ProductListStatus.loading),
        isA<ProductListState>()
            .having((s) => s.status, 'status', ProductListStatus.loaded)
            .having((s) => s.selectedCategory, 'selectedCategory', 'smartphones'),
      ],
      verify: (_) {
        verify(() => mockRepository.getProductsByCategory(
              'smartphones',
              limit: any(named: 'limit'),
              skip: any(named: 'skip'),
            )).called(1);
      },
    );

    blocTest<ProductListBloc, ProductListState>(
      'does not trigger load more when hasMore is false',
      build: () {
        when(() => mockRepository.getProducts(limit: any(named: 'limit'), skip: any(named: 'skip')))
            .thenAnswer((_) async => Right(_mockResponse));
        return buildBloc();
      },
      seed: () => const ProductListState(
        status: ProductListStatus.loaded,
      ),
      act: (bloc) => bloc.add(const ProductListLoadMoreRequested()),
      expect: () => [],
    );

    blocTest<ProductListBloc, ProductListState>(
      'does not trigger load more when already loading more',
      build: () => buildBloc(),
      seed: () => const ProductListState(
        status: ProductListStatus.loaded,
        hasMore: true,
        isLoadingMore: true,
      ),
      act: (bloc) => bloc.add(const ProductListLoadMoreRequested()),
      expect: () => [],
    );

    blocTest<ProductListBloc, ProductListState>(
      'appends products on load more',
      build: () {
        when(() => mockRepository.getProducts(
              limit: any(named: 'limit'),
              skip: any(named: 'skip'),
            )).thenAnswer((_) async => Right(ProductListResponse(
              products: [_mockProduct],
              total: 40,
              skip: 20,
              limit: 20,
            )));
        return buildBloc();
      },
      seed: () => ProductListState(
        status: ProductListStatus.loaded,
        products: [_mockProduct],
        hasMore: true,
      ),
      act: (bloc) => bloc.add(const ProductListLoadMoreRequested()),
      expect: () => [
        isA<ProductListState>().having((s) => s.isLoadingMore, 'isLoadingMore', true),
        isA<ProductListState>()
            .having((s) => s.isLoadingMore, 'isLoadingMore', false)
            .having((s) => s.products.length, 'products length', 2),
      ],
    );

    blocTest<ProductListBloc, ProductListState>(
      'refresh resets products list',
      build: () {
        when(() => mockRepository.getProducts(limit: any(named: 'limit'), skip: any(named: 'skip')))
            .thenAnswer((_) async => Right(_mockResponse));
        return buildBloc();
      },
      seed: () => ProductListState(
        status: ProductListStatus.loaded,
        products: List.generate(
          5,
          (i) => ProductModel(
            id: i,
            title: 'Product $i',
            description: '',
            price: 10.0,
            discountPercentage: 0,
            rating: 4.0,
            stock: 10,
            brand: 'Brand',
            category: 'cat',
            thumbnail: '',
            images: [],
          ),
        ),
      ),
      act: (bloc) => bloc.add(const ProductListRefreshRequested()),
      expect: () => [
        isA<ProductListState>().having((s) => s.status, 'status', ProductListStatus.loading),
        isA<ProductListState>()
            .having((s) => s.status, 'status', ProductListStatus.loaded)
            .having((s) => s.products.length, 'products length', 1),
      ],
    );
  });
}
