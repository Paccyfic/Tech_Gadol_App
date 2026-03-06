class HiveConstants {
  HiveConstants._();

  static const String productsBox = 'products_cache';
  static const String metaBox = 'cache_meta';

  static const String lastFetchedKey = 'last_fetched';
  static const String totalCountKey = 'total_count';

  // Cache TTL — 1 hour
  static const Duration cacheTtl = Duration(hours: 1);

  static const int productHiveTypeId = 0;
}