import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'local/app_database.dart';
import 'repositories/interests_repository.dart';
import 'repositories/local_data_repository.dart';
import 'repositories/read_history_repository.dart';
import 'repositories/saved_items_repository.dart';

final databaseProvider = FutureProvider<Database>((ref) => AppDatabase.open());

final interestsRepositoryProvider = FutureProvider<InterestsRepository>((
  ref,
) async {
  final database = await ref.watch(databaseProvider.future);
  return SqfliteInterestsRepository(database);
});

final savedItemsRepositoryProvider = FutureProvider<SavedItemsRepository>((
  ref,
) async {
  final database = await ref.watch(databaseProvider.future);
  return SqfliteSavedItemsRepository(database);
});

final readHistoryRepositoryProvider = FutureProvider<ReadHistoryRepository>((
  ref,
) async {
  final database = await ref.watch(databaseProvider.future);
  return SqfliteReadHistoryRepository(database);
});

final localDataRepositoryProvider = FutureProvider<LocalDataRepository>((
  ref,
) async {
  final database = await ref.watch(databaseProvider.future);
  return SqfliteLocalDataRepository(database);
});
