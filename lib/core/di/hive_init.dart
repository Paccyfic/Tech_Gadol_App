import 'package:hive_flutter/hive_flutter.dart';
import '../../data/datasources/local/hive_constants.dart';
import '../../data/datasources/local/product_hive_model.dart';

Future<void> initHive() async {
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(HiveConstants.productHiveTypeId)) {
    Hive.registerAdapter(ProductHiveModelAdapter());
  }
}

Future<void> openHiveBoxes() async {
  await Hive.openBox<ProductHiveModel>(HiveConstants.productsBox);
  await Hive.openBox<dynamic>(HiveConstants.metaBox);
}