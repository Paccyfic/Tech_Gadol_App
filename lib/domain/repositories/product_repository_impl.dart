import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../data/datasources/product_remote_datasource.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _remote;
  final Logger _logger;

  ProductRepositoryImpl({
    required ProductRemoteDataSource remote,
    Logger? logger,
  })  : _remote = remote,
        _logger = logger ?? Logger();

  @override
  Future<Either<Failure, ProductListResponse>> getProducts({
    int limit = 20,
    int skip = 0,
  }) async {
    return _handleRequest(() => _remote.getProducts(limit: limit, skip: skip));
  }

  @override
  Future<Either<Failure, ProductListResponse>> searchProducts(
    String query, {
    int limit = 20,
    int skip = 0,
  }) async {
    return _handleRequest(() => _remote.searchProducts(query, limit: limit, skip: skip));
  }

  @override
  Future<Either<Failure, List<String>>> getCategories() async {
    return _handleRequest(() => _remote.getCategories());
  }

  @override
  Future<Either<Failure, ProductListResponse>> getProductsByCategory(
    String category, {
    int limit = 20,
    int skip = 0,
  }) async {
    return _handleRequest(
      () => _remote.getProductsByCategory(category, limit: limit, skip: skip),
    );
  }

  @override
  Future<Either<Failure, ProductModel>> getProductById(int id) async {
    return _handleRequest(() => _remote.getProductById(id));
  }

  Future<Either<Failure, T>> _handleRequest<T>(Future<T> Function() call) async {
    try {
      final result = await call();
      return Right(result);
    } on NetworkException catch (e) {
      _logger.w('NetworkException: ${e.message}');
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      _logger.e('ServerException ${e.statusCode}: ${e.message}');
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e, st) {
      _logger.e('Unexpected error', error: e, stackTrace: st);
      return Left(UnknownFailure(e.toString(), stackTrace: st));
    }
  }
}
