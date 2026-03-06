class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://dummyjson.com';
  static const int defaultLimit = 20;
  static const int searchDebounceMs = 400;

  // Endpoints
  static const String products = '/products';
  static const String search = '/products/search';
  static const String categories = '/products/categories';

  static String categoryProducts(String category) => '/products/category/$category';
  static String productById(int id) => '/products/$id';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
