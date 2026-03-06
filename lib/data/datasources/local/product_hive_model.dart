import 'package:hive/hive.dart';
import '../../models/product_model.dart';
import 'hive_constants.dart';

part 'product_hive_model.g.dart';

@HiveType(typeId: HiveConstants.productHiveTypeId)
class ProductHiveModel extends HiveObject {
  @HiveField(0)
  final int id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final double price;
  @HiveField(4)
  final double discountPercentage;
  @HiveField(5)
  final double rating;
  @HiveField(6)
  final int stock;
  @HiveField(7)
  final String brand;
  @HiveField(8)
  final String category;
  @HiveField(9)
  final String thumbnail;
  @HiveField(10)
  final List<String> images;

  ProductHiveModel({
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

  factory ProductHiveModel.fromDomain(ProductModel p) => ProductHiveModel(
        id: p.id,
        title: p.title,
        description: p.description,
        price: p.price,
        discountPercentage: p.discountPercentage,
        rating: p.rating,
        stock: p.stock,
        brand: p.brand,
        category: p.category,
        thumbnail: p.thumbnail,
        images: List<String>.from(p.images),
      );

  ProductModel toDomain() => ProductModel(
        id: id,
        title: title,
        description: description,
        price: price,
        discountPercentage: discountPercentage,
        rating: rating,
        stock: stock,
        brand: brand,
        category: category,
        thumbnail: thumbnail,
        images: images,
      );
}