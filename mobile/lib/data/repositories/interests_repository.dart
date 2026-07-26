import 'package:sqflite/sqflite.dart';

import '../local/schema.dart';

abstract interface class InterestsRepository {
  Future<List<String>> readAll();

  Future<void> replaceAll(List<String> interests);

  Future<void> clear();
}

final class SqfliteInterestsRepository implements InterestsRepository {
  SqfliteInterestsRepository(this._database);

  final Database _database;

  @override
  Future<List<String>> readAll() async {
    final rows = await _database.query(
      InterestsTable.name,
      columns: [InterestsTable.label],
      orderBy: '${InterestsTable.createdAt} ASC, ${InterestsTable.id} ASC',
    );
    return rows
        .map((row) => row[InterestsTable.label]! as String)
        .toList(growable: false);
  }

  @override
  Future<void> replaceAll(List<String> interests) async {
    await _database.transaction((transaction) async {
      await transaction.delete(InterestsTable.name);
      final createdAt = DateTime.now().millisecondsSinceEpoch;
      for (var index = 0; index < interests.length; index++) {
        final label = interests[index];
        await transaction.insert(InterestsTable.name, {
          InterestsTable.id: label,
          InterestsTable.label: label,
          InterestsTable.createdAt: createdAt + index,
        });
      }
    });
  }

  @override
  Future<void> clear() async {
    await _database.delete(InterestsTable.name);
  }
}
