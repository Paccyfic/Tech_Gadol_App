import 'package:logger/logger.dart';

final _log = Logger();

class ProductModel {
  final int id;
  final String title;
  final String description;
  final double price;
  final double discountPercentage;
  final double rating;
  final int stock;
  final String brand;
  final String category;
  final String thumbnail;
  final List<String> images;

  const ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.discountPercentage,
    required this.rating,
    required this.stock,
    required this.brand,
    required this.category,
    required this.thumbnail,
    required this.images,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Validate and sanitize price
    double price = 0.0;
    final rawPrice = json['price'];
    if (rawPrice == null) {
      _log.e('ProductModel: Missing price for product id=${json['id']}');
    } else {
      final parsed = (rawPrice as num?)?.toDouble() ?? -1.0;
      if (parsed < 0) {
        _log.e('ProductModel: Negative price ($parsed) for product id=${json['id']}');
      } else {
        price = parsed;
      }
    }

    // Validate thumbnail URL
    String thumbnail = '';
    final rawThumb = json['thumbnail'] as String?;
    if (rawThumb == null || rawThumb.isEmpty) {
      _log.w('ProductModel: Missing thumbnail for product id=${json['id']}');
    } else {
      thumbnail = rawThumb;
    }

    // Validate and sanitize images list
    List<String> images = [];
    final rawImages = json['images'];
    if (rawImages is List) {
      images = rawImages
          .whereType<String>()
          .where((url) => url.isNotEmpty)
          .toList();
      if (images.length != rawImages.length) {
        _log.w('ProductModel: Some image URLs were invalid for product id=${json['id']}');
      }
    }
    if (images.isEmpty && thumbnail.isNotEmpty) {
      images = [thumbnail];
    }

    return ProductModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? 'Unknown Product',
      description: json['description'] as String? ?? 'No description available',
      price: price,
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      brand: json['brand'] as String? ?? 'Unknown Brand',
      category: json['category'] as String? ?? 'Uncategorized',
      thumbnail: thumbnail,
      images: images,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'price': price,
        'discountPercentage': discountPercentage,
        'rating': rating,
        'stock': stock,
        'brand': brand,
        'category': category,
        'thumbnail': thumbnail,
        'images': images,
      };

  double get discountedPrice => price * (1 - discountPercentage / 100);

  bool get isInStock => stock > 0;

  bool get hasPriceData => price > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ProductModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class ProductListResponse {
  final List<ProductModel> products;
  final int total;
  final int skip;
  final int limit;

  const ProductListResponse({
    required this.products,
    required this.total,
    required this.skip,
    required this.limit,
  });

  factory ProductListResponse.fromJson(Map<String, dynamic> json) {
    final rawProducts = json['products'] as List<dynamic>? ?? [];
    return ProductListResponse(
      products: rawProducts
          .whereType<Map<String, dynamic>>()
          .map(ProductModel.fromJson)
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
    );
  }

  bool get hasMore => (skip + limit) < total;
}
