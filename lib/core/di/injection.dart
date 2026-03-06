import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

import '../network/network_client.dart';
import '../../data/datasources/product_remote_datasource.dart';
import '../../domain/repositories/product_repository_impl.dart';
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

  // Data sources
  getIt.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(
      dio: getIt<NetworkClient>().dio,
      logger: getIt<Logger>(),
    ),
  );

  // Repositories
  getIt.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(
      remote: getIt<ProductRemoteDataSource>(),
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
