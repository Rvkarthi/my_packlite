import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database_helper.dart';
import '../../data/datasources/local/bag_local_datasource.dart';
import '../../data/datasources/local/item_local_datasource.dart';
import '../../data/datasources/local/todo_local_datasource.dart';
import '../../data/datasources/local/trip_local_datasource.dart';
import '../../data/repositories/bag_repository_impl.dart';
import '../../data/repositories/item_repository_impl.dart';
import '../../data/repositories/todo_repository_impl.dart';
import '../../data/repositories/trip_repository_impl.dart';
import '../../domain/repositories/bag_repository.dart';
import '../../domain/repositories/item_repository.dart';
import '../../domain/repositories/todo_repository.dart';
import '../../domain/repositories/trip_repository.dart';
import '../../services/ai/offline_ai_service.dart';
import '../../services/ai/weather_service.dart';
import '../../services/sync/sync_service.dart';

// Infrastructure
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    ref.read(databaseHelperProvider),
    ref.read(connectivityProvider),
  );
});

// Datasources
final tripLocalDatasourceProvider = Provider<TripLocalDatasource>((ref) {
  return TripLocalDatasource(ref.read(databaseHelperProvider));
});

final itemLocalDatasourceProvider = Provider<ItemLocalDatasource>((ref) {
  return ItemLocalDatasource(ref.read(databaseHelperProvider));
});

final todoLocalDatasourceProvider = Provider<TodoLocalDatasource>((ref) {
  return TodoLocalDatasource(ref.read(databaseHelperProvider));
});

final bagLocalDatasourceProvider = Provider<BagLocalDatasource>((ref) {
  return BagLocalDatasource(ref.read(databaseHelperProvider));
});

// Repositories
final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepositoryImpl(
    ref.read(tripLocalDatasourceProvider),
    ref.read(syncServiceProvider),
  );
});

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepositoryImpl(
    ref.read(itemLocalDatasourceProvider),
    ref.read(syncServiceProvider),
  );
});

final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  return TodoRepositoryImpl(
    ref.read(todoLocalDatasourceProvider),
    ref.read(syncServiceProvider),
  );
});

final bagRepositoryProvider = Provider<BagRepository>((ref) {
  return BagRepositoryImpl(
    ref.read(bagLocalDatasourceProvider),
    ref.read(syncServiceProvider),
  );
});

// Services
final offlineAiServiceProvider = Provider<OfflineAiService>((ref) {
  return OfflineAiService();
});

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});
