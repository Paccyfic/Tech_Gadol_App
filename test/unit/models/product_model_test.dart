import 'package:flutter_test/flutter_test.dart';
import 'package:tech_gadol_catalog/data/models/product_model.dart';

void main() {
  group('ProductModel.fromJson', () {
    test('parses complete valid JSON correctly', () {
      final json = {
        'id': 1,
        'title': 'iPhone 14 Pro',
        'description': 'An Apple flagship',
        'price': 999.99,
        'discountPercentage': 10.0,
        'rating': 4.8,
        'stock': 50,
        'brand': 'Apple',
        'category': 'smartphones',
        'thumbnail': 'https://example.com/thumb.jpg',
        'images': [
          'https://example.com/img1.jpg',
          'https://example.com/img2.jpg',
        ],
      };

      final product = ProductModel.fromJson(json);

      expect(product.id, 1);
      expect(product.title, 'iPhone 14 Pro');
      expect(product.price, 999.99);
      expect(product.discountPercentage, 10.0);
      expect(product.rating, 4.8);
      expect(product.stock, 50);
      expect(product.brand, 'Apple');
      expect(product.category, 'smartphones');
      expect(product.images.length, 2);
    });

    test('uses defaults for missing optional fields', () {
      final json = {
        'id': 2,
        'price': 50.0,
        'thumbnail': 'https://example.com/thumb.jpg',
        'images': <dynamic>[],
      };

      final product = ProductModel.fromJson(json);

      expect(product.title, 'Unknown Product');
      expect(product.brand, 'Unknown Brand');
      expect(product.category, 'Uncategorized');
      expect(product.description, 'No description available');
    });

    test('handles missing price with 0.0 default and logs error', () {
      final json = {
        'id': 3,
        'title': 'Test Product',
        'thumbnail': 'https://example.com/thumb.jpg',
        'images': <dynamic>[],
      };

      final product = ProductModel.fromJson(json);

      expect(product.price, 0.0);
      expect(product.hasPriceData, isFalse);
    });

    test('handles negative price with 0.0 and logs error', () {
      final json = {
        'id': 4,
        'title': 'Test Product',
        'price': -10.0,
        'thumbnail': 'https://example.com/thumb.jpg',
        'images': <dynamic>[],
      };

      final product = ProductModel.fromJson(json);

      expect(product.price, 0.0);
      expect(product.hasPriceData, isFalse);
    });

    test('handles missing thumbnail with empty string and logs warning', () {
      final json = {
        'id': 5,
        'title': 'Test Product',
        'price': 10.0,
        'images': <dynamic>[],
      };

      final product = ProductModel.fromJson(json);

      expect(product.thumbnail, '');
    });

    test('falls back thumbnail into images if images list is empty', () {
      final json = {
        'id': 6,
        'title': 'Test',
        'price': 10.0,
        'thumbnail': 'https://example.com/thumb.jpg',
        'images': <dynamic>[],
      };

      final product = ProductModel.fromJson(json);

      expect(product.images, ['https://example.com/thumb.jpg']);
    });

    test('filters out invalid image URLs', () {
      final json = {
        'id': 7,
        'title': 'Test',
        'price': 10.0,
        'thumbnail': 'https://example.com/thumb.jpg',
        'images': ['https://example.com/valid.jpg', '', 'https://example.com/valid2.jpg'],
      };

      final product = ProductModel.fromJson(json);

      expect(product.images.length, 2);
      expect(product.images.every((u) => u.isNotEmpty), isTrue);
    });

    test('correctly computes discounted price', () {
      final json = {
        'id': 8,
        'price': 100.0,
        'discountPercentage': 20.0,
        'thumbnail': 'https://example.com/thumb.jpg',
        'images': <dynamic>[],
      };

      final product = ProductModel.fromJson(json);

      expect(product.discountedPrice, closeTo(80.0, 0.001));
    });

    test('isInStock returns false when stock is 0', () {
      final json = {
        'id': 9,
        'price': 10.0,
        'stock': 0,
        'thumbnail': 'https://example.com/thumb.jpg',
        'images': <dynamic>[],
      };

      final product = ProductModel.fromJson(json);

      expect(product.isInStock, isFalse);
    });

    test('isInStock returns true when stock is positive', () {
      final json = {
        'id': 10,
        'price': 10.0,
        'stock': 5,
        'thumbnail': 'https://example.com/thumb.jpg',
        'images': <dynamic>[],
      };

      final product = ProductModel.fromJson(json);

      expect(product.isInStock, isTrue);
    });

    test('handles numeric fields as both int and double', () {
      final json = {
        'id': 11,
        'price': 99, // int
        'discountPercentage': 10, // int
        'rating': 4, // int
        'stock': 20,
        'thumbnail': 'https://example.com/thumb.jpg',
        'images': <dynamic>[],
      };

      final product = ProductModel.fromJson(json);

      expect(product.price, 99.0);
      expect(product.discountPercentage, 10.0);
      expect(product.rating, 4.0);
    });

    test('equality is based on id', () {
      final json = {
        'id': 1,
        'price': 10.0,
        'thumbnail': 'https://example.com/thumb.jpg',
        'images': <dynamic>[],
      };

      final p1 = ProductModel.fromJson(json);
      final p2 = ProductModel.fromJson({...json, 'title': 'Different title'});

      expect(p1, equals(p2));
    });
  });

  group('ProductListResponse.fromJson', () {
    test('parses response with products', () {
      final json = {
        'products': [
          {
            'id': 1,
            'price': 10.0,
            'thumbnail': 'https://example.com/thumb.jpg',
            'images': <dynamic>[],
          }
        ],
        'total': 100,
        'skip': 0,
        'limit': 20,
      };

      final response = ProductListResponse.fromJson(json);

      expect(response.products.length, 1);
      expect(response.total, 100);
      expect(response.hasMore, isTrue);
    });

    test('hasMore is false when all products loaded', () {
      final json = {
        'products': <dynamic>[],
        'total': 20,
        'skip': 0,
        'limit': 20,
      };

      final response = ProductListResponse.fromJson(json);

      expect(response.hasMore, isFalse);
    });

    test('handles empty products array', () {
      final json = {
        'products': <dynamic>[],
        'total': 0,
        'skip': 0,
        'limit': 20,
      };

      final response = ProductListResponse.fromJson(json);

      expect(response.products, isEmpty);
      expect(response.total, 0);
    });
  });
}
