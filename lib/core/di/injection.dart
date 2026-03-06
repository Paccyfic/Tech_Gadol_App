import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import 'package:tech_gadol_catalog/domain/repositories/product_repository_impl.dart';

import '../network/network_client.dart';
import '../../data/datasources/local/hive_constants.dart';
import '../../data/datasources/local/product_hive_model.dart';
import '../../data/datasources/local/product_local_datasource.dart';
import '../../data/datasources/product_remote_datasource.dart';
//import '../../data/repositories/product_repository_impl.dart';
import '../../data/repositories/product_repository.dart';
import '../../presentation/bloc/product_list/product_list_bloc.dart';
import '../../presentation/bloc/product_detail/product_detail_bloc.dart';
import '../../presentation/bloc/category/category_cubit.dart';
import '../../presentation/bloc/theme/theme_cubit.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Core
  getIt.registerLazySingleton<Logger>(() => Logger(
        printer: PrettyPrinter(methodCount: 0, printTime: false),
        level: Level.debug,
      ));

  getIt.registerLazySingleton<NetworkClient>(
    () => NetworkClient(logger: getIt<Logger>()),
  );

  // Data sources — remote
  getIt.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(
      dio: getIt<NetworkClient>().dio,
      logger: getIt<Logger>(),
    ),
  );

  // Data sources — local (Hive boxes already opened in main)
  getIt.registerLazySingleton<ProductLocalDataSource>(
    () => ProductLocalDataSourceImpl(
      productsBox: Hive.box<ProductHiveModel>(HiveConstants.productsBox),
      metaBox: Hive.box<dynamic>(HiveConstants.metaBox),
      logger: getIt<Logger>(),
    ),
  );

  // Repositories
  getIt.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(
      remote: getIt<ProductRemoteDataSource>(),
      local: getIt<ProductLocalDataSource>(),
      logger: getIt<Logger>(),
    ),
  );

  // Blocs / Cubits
  getIt.registerFactory<ProductListBloc>(
    () => ProductListBloc(repository: getIt<ProductRepository>()),
  );

  getIt.registerFactory<ProductDetailBloc>(
    () => ProductDetailBloc(repository: getIt<ProductRepository>()),
  );

  getIt.registerFactory<CategoryCubit>(
    () => CategoryCubit(repository: getIt<ProductRepository>()),
  );

  getIt.registerLazySingleton<ThemeCubit>(() => ThemeCubit());
}