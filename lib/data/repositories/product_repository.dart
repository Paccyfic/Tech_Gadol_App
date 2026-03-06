// ── Abstract (domain layer) ──────────────────────────────────────────────────
import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../models/product_model.dart';

abstract class ProductRepository {
  Future<Either<Failure, ProductListResponse>> getProducts({int limit, int skip});
  Future<Either<Failure, ProductListResponse>> searchProducts(String query, {int limit, int skip});
  Future<Either<Failure, List<String>>> getCategories();
  Future<Either<Failure, ProductListResponse>> getProductsByCategory(String category, {int limit, int skip});
  Future<Either<Failure, ProductModel>> getProductById(int id);
}
