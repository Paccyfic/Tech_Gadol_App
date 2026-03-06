import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../data/datasources/local/product_local_datasource.dart';
import '../../data/datasources/product_remote_datasource.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _remote;
  final ProductLocalDataSource _local;
  final Logger _logger;

  ProductRepositoryImpl({
    required ProductRemoteDataSource remote,
    required ProductLocalDataSource local,
    Logger? logger,
  })  : _remote = remote,
        _local = local,
        _logger = logger ?? Logger();

  // ── Products (cache-first / stale-while-revalidate) ───────────────────────

  @override
  Future<Either<Failure, ProductListResponse>> getProducts({
    int limit = 20,
    int skip = 0,
  }) async {
    if (_local.hasCachedData) {
      final cached =
          await _local.getCachedProducts(skip: skip, limit: limit);

      if (!_local.isCacheExpired && cached.status == CacheStatus.fresh) {
        _logger.d('Serving fresh cache (skip=$skip)');
        return Right(ProductListResponse(
          products: cached.products,
          total: cached.total,
          skip: skip,
          limit: limit,
          isFromCache: true,
          cacheStatus: CacheStatus.fresh,
        ));
      }

      if (cached.products.isNotEmpty) {
        _logger.d('Serving stale cache (skip=$skip), background refresh pending');
        return Right(ProductListResponse(
          products: cached.products,
          total: cached.total,
          skip: skip,
          limit: limit,
          isFromCache: true,
          cacheStatus: CacheStatus.stale,
        ));
      }
    }

    return _fetchAndCache(limit: limit, skip: skip);
  }

  Future<Either<Failure, ProductListResponse>> _fetchAndCache({
    required int limit,
    required int skip,
  }) async {
    return _handleRequest(() async {
      final response = await _remote.getProducts(limit: limit, skip: skip);
      if (skip == 0) {
        await _local.cacheProducts(
          response.products,
          total: response.total,
          replace: true,
        );
      } else {
        await _local.cacheProducts(response.products, total: response.total);
      }
      return response;
    });
  }

  /// Called by the Bloc after serving stale data to refresh in the background.
  Future<Either<Failure, ProductListResponse>> refreshProducts({
    int limit = 20,
    int skip = 0,
  }) =>
      _fetchAndCache(limit: limit, skip: skip);

  // ── Other endpoints ───────────────────────────────────────────────────────

  @override
  Future<Either<Failure, ProductListResponse>> searchProducts(
    String query, {
    int limit = 20,
    int skip = 0,
  }) async {
    return _handleRequest(
        () => _remote.searchProducts(query, limit: limit, skip: skip));
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
      () => _remote.getProductsByCategory(category,
          limit: limit, skip: skip),
    );
  }

  @override
  Future<Either<Failure, ProductModel>> getProductById(int id) async {
    return _handleRequest(() => _remote.getProductById(id));
  }

  // ── Cache helpers (accessed by Bloc via down-cast) ────────────────────────

  Future<void> clearCache() => _local.clearCache();
  bool get hasCachedData => _local.hasCachedData;
  DateTime? get cacheLastFetchedAt => _local.lastFetchedAt;
  bool get isCacheExpired => _local.isCacheExpired;

  // ── Error handling ────────────────────────────────────────────────────────

  Future<Either<Failure, T>> _handleRequest<T>(
      Future<T> Function() call) async {
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