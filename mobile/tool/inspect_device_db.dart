/// Cihazdan çekilen veritabanını okur.
///
/// Kalıcılık iddialarının **cihaz tarafındaki** kanıtı: ekran görüntüsü bir
/// listenin göründüğünü gösterir, bu dosya satırın gerçekten yazıldığını.
///
/// Kullanım: `dart run tool/inspect_device_db.dart <yol>`
library;

import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Kullanım: dart run tool/inspect_device_db.dart <yol>');
    exitCode = 1;
    return;
  }

  sqfliteFfiInit();
  final database = await databaseFactoryFfi.openDatabase(
    args.first,
    options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
  );

  final version = await database.getVersion();
  stdout.writeln('şema sürümü: $version');

  final tables = await database.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table' "
    "AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%' ORDER BY name",
  );

  for (final row in tables) {
    final name = row['name']! as String;
    final count =
        (await database.rawQuery(
              'SELECT COUNT(*) AS n FROM "$name"',
            )).first['n']
            as int;
    stdout.writeln('\n--- $name ($count satır) ---');
    if (count == 0) continue;

    final sample = await database.rawQuery('SELECT * FROM "$name" LIMIT 12');
    for (final entry in sample) {
      final parts = <String>[];
      for (final field in entry.entries) {
        final value = field.value;
        // Önbellek gövdesi gzip'lenmiş ikili veri; ekrana basılmaz.
        if (value is List<int>) {
          parts.add('${field.key}=<${value.length} bayt>');
          continue;
        }
        final text = '$value';
        parts.add(
          '${field.key}=${text.length > 44 ? '${text.substring(0, 44)}…' : text}',
        );
      }
      stdout.writeln('  ${parts.join(' · ')}');
    }
  }

  final indexes = await database.rawQuery(
    "SELECT name, tbl_name FROM sqlite_master WHERE type='index' "
    "AND name NOT LIKE 'sqlite_%' ORDER BY name",
  );
  stdout.writeln('\n--- indeksler ---');
  for (final row in indexes) {
    stdout.writeln('  ${row['name']} (${row['tbl_name']})');
  }

  await database.close();
}
