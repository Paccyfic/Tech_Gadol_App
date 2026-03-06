import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<ProductListResponse> getProducts({int limit = 20, int skip = 0});
  Future<ProductListResponse> searchProducts(String query, {int limit = 20, int skip = 0});
  Future<List<String>> getCategories();
  Future<ProductListResponse> getProductsByCategory(String category, {int limit = 20, int skip = 0});
  Future<ProductModel> getProductById(int id);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final Dio _dio;
  final Logger _logger;

  ProductRemoteDataSourceImpl({required Dio dio, Logger? logger})
      : _dio = dio,
        _logger = logger ?? Logger();

  @override
  Future<ProductListResponse> getProducts({int limit = 20, int skip = 0}) async {
    try {
      final response = await _dio.get(
        ApiConstants.products,
        queryParameters: {'limit': limit, 'skip': skip},
      );
      return ProductListResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e);
    }
    throw const NetworkException('Unknown error fetching products');
  }

  @override
  Future<ProductListResponse> searchProducts(String query, {int limit = 20, int skip = 0}) async {
    try {
      final response = await _dio.get(
        ApiConstants.search,
        queryParameters: {'q': query, 'limit': limit, 'skip': skip},
      );
      return ProductListResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e);
    }
    throw const NetworkException('Unknown error searching products');
  }

  @override
  Future<List<String>> getCategories() async {
    try {
      final response = await _dio.get(ApiConstants.categories);
      final data = response.data;
      if (data is List) {
        // Handle both string array and object array (API may return objects)
        return data.map((e) {
          if (e is String) return e;
          if (e is Map<String, dynamic>) return e['slug'] as String? ?? e['name'] as String? ?? '';
          return '';
        }).where((s) => s.isNotEmpty).toList();
      }
      return [];
    } on DioException catch (e) {
      _handleDioError(e);
    }
    return [];
  }

  @override
  Future<ProductListResponse> getProductsByCategory(
    String category, {
    int limit = 20,
    int skip = 0,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.categoryProducts(category),
        queryParameters: {'limit': limit, 'skip': skip},
      );
      return ProductListResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e);
    }
    throw const NetworkException('Unknown error fetching category products');
  }

  @override
  Future<ProductModel> getProductById(int id) async {
    try {
      final response = await _dio.get(ApiConstants.productById(id));
      return ProductModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e);
    }
    throw const NetworkException('Unknown error fetching product detail');
  }

  Never _handleDioError(DioException e) {
    _logger.e('DioError: ${e.type} - ${e.message}');
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw const NetworkException('No internet connection. Please check your network.');
      case DioExceptionType.badResponse:
        throw ServerException(
          'Server error: ${e.response?.statusCode}',
          statusCode: e.response?.statusCode ?? 500,
        );
      default:
        throw NetworkException(e.message ?? 'Unknown network error');
    }
  }
}
