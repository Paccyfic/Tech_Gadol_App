import 'package:hive/hive.dart';
import 'package:logger/logger.dart';

import '../../models/product_model.dart';
import 'hive_constants.dart';
import 'product_hive_model.dart';

enum CacheStatus { fresh, stale, empty }

class CachedProductPage {
  final List<ProductModel> products;
  final int total;
  final CacheStatus status;

  const CachedProductPage({
    required this.products,
    required this.total,
    required this.status,
  });
}

abstract class ProductLocalDataSource {
  Future<CachedProductPage> getCachedProducts({int skip = 0, int limit = 20});
  Future<void> cacheProducts(List<ProductModel> products,
      {required int total, bool replace = false});
  Future<void> clearCache();
  bool get hasCachedData;
  DateTime? get lastFetchedAt;
  bool get isCacheExpired;
}

class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  final Box<ProductHiveModel> _productsBox;
  final Box<dynamic> _metaBox;
  final Logger _logger;

  ProductLocalDataSourceImpl({
    required Box<ProductHiveModel> productsBox,
    required Box<dynamic> metaBox,
    Logger? logger,
  })  : _productsBox = productsBox,
        _metaBox = metaBox,
        _logger = logger ?? Logger();

  @override
  bool get hasCachedData => _productsBox.isNotEmpty;

  @override
  DateTime? get lastFetchedAt {
    final ms = _metaBox.get(HiveConstants.lastFetchedKey) as int?;
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  @override
  bool get isCacheExpired {
    final fetched = lastFetchedAt;
    if (fetched == null) return true;
    return DateTime.now().difference(fetched) > HiveConstants.cacheTtl;
  }

  @override
  Future<CachedProductPage> getCachedProducts(
      {int skip = 0, int limit = 20}) async {
    if (!hasCachedData) {
      return const CachedProductPage(
          products: [], total: 0, status: CacheStatus.empty);
    }

    final allKeys = _productsBox.keys.toList()..sort();
    final total =
        _metaBox.get(HiveConstants.totalCountKey) as int? ?? allKeys.length;
    final end = (skip + limit).clamp(0, allKeys.length);
    final pageKeys =
        allKeys.sublist(skip.clamp(0, allKeys.length), end);

    final products = pageKeys
        .map((k) => _productsBox.get(k))
        .whereType<ProductHiveModel>()
        .map((h) => h.toDomain())
        .toList();

    final status =
        isCacheExpired ? CacheStatus.stale : CacheStatus.fresh;
    _logger.d(
        'Cache hit: ${products.length} products (${status.name}), skip=$skip');
    return CachedProductPage(products: products, total: total, status: status);
  }

  @override
  Future<void> cacheProducts(
    List<ProductModel> products, {
    required int total,
    bool replace = false,
  }) async {
    if (replace) await _productsBox.clear();

    final entries = {
      for (final p in products) p.id: ProductHiveModel.fromDomain(p),
    };
    await _productsBox.putAll(entries);
    await _metaBox.put(
      HiveConstants.lastFetchedKey,
      DateTime.now().millisecondsSinceEpoch,
    );
    await _metaBox.put(HiveConstants.totalCountKey, total);
    _logger.d(
        'Cached ${products.length} products (replace=$replace), total=$total');
  }

  @override
  Future<void> clearCache() async {
    await _productsBox.clear();
    await _metaBox.clear();
    _logger.i('Product cache cleared');
  }
}