import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:tech_gadol_catalog/core/errors/failures.dart';
import 'package:tech_gadol_catalog/data/models/product_model.dart';
import 'package:tech_gadol_catalog/data/repositories/product_repository.dart';
import 'package:tech_gadol_catalog/presentation/bloc/product_detail/product_detail_bloc.dart';

class MockProductRepository extends Mock implements ProductRepository {}

const _mockProduct = ProductModel(
  id: 42,
  title: 'MacBook Pro',
  description: 'Powerful laptop',
  price: 1999.99,
  discountPercentage: 5.0,
  rating: 4.9,
  stock: 15,
  brand: 'Apple',
  category: 'laptops',
  thumbnail: 'https://example.com/thumb.jpg',
  images: ['https://example.com/img1.jpg'],
);

void main() {
  late MockProductRepository mockRepository;

  setUp(() {
    mockRepository = MockProductRepository();
  });

  ProductDetailBloc buildBloc() =>
      ProductDetailBloc(repository: mockRepository);

  group('ProductDetailBloc', () {
    test('initial state is correct', () {
      final bloc = buildBloc();
      expect(bloc.state.status, ProductDetailStatus.initial);
      expect(bloc.state.product, isNull);
      expect(bloc.state.errorMessage, isNull);
    });

    blocTest<ProductDetailBloc, ProductDetailState>(
      'emits [loading, loaded] when product fetch succeeds',
      build: () {
        when(() => mockRepository.getProductById(42))
            .thenAnswer((_) async => Right(_mockProduct));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ProductDetailLoadRequested(42)),
      expect: () => [
        isA<ProductDetailState>()
            .having((s) => s.status, 'status', ProductDetailStatus.loading),
        isA<ProductDetailState>()
            .having((s) => s.status, 'status', ProductDetailStatus.loaded)
            .having((s) => s.product, 'product', _mockProduct)
            .having((s) => s.errorMessage, 'errorMessage', isNull),
      ],
    );

    blocTest<ProductDetailBloc, ProductDetailState>(
      'emits [loading, error] when product fetch fails with NetworkFailure',
      build: () {
        when(() => mockRepository.getProductById(any()))
            .thenAnswer((_) async => const Left(NetworkFailure('No internet connection. Please check your network.')));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ProductDetailLoadRequested(99)),
      expect: () => [
        isA<ProductDetailState>()
            .having((s) => s.status, 'status', ProductDetailStatus.loading),
        isA<ProductDetailState>()
            .having((s) => s.status, 'status', ProductDetailStatus.error)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              contains('No internet'),
            ),
      ],
    );

    blocTest<ProductDetailBloc, ProductDetailState>(
      'emits specific message for 404 ServerFailure',
      build: () {
        when(() => mockRepository.getProductById(any()))
            .thenAnswer((_) async => const Left(
                  ServerFailure('Not found', statusCode: 404),
                ));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ProductDetailLoadRequested(9999)),
      expect: () => [
        isA<ProductDetailState>()
            .having((s) => s.status, 'status', ProductDetailStatus.loading),
        isA<ProductDetailState>()
            .having((s) => s.status, 'status', ProductDetailStatus.error)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              'Product not found.',
            ),
      ],
    );

    blocTest<ProductDetailBloc, ProductDetailState>(
      'refresh loads product again',
      build: () {
        when(() => mockRepository.getProductById(42))
            .thenAnswer((_) async => Right(_mockProduct));
        return buildBloc();
      },
      seed: () => const ProductDetailState(status: ProductDetailStatus.error),
      act: (bloc) => bloc.add(const ProductDetailRefreshRequested(42)),
      expect: () => [
        isA<ProductDetailState>()
            .having((s) => s.status, 'status', ProductDetailStatus.loading),
        isA<ProductDetailState>()
            .having((s) => s.status, 'status', ProductDetailStatus.loaded)
            .having((s) => s.product?.id, 'product.id', 42),
      ],
    );
  });
}
