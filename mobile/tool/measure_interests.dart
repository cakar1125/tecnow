/// İlgi alanı eşleşmesinin **gerçek** feed üzerindeki kapsamını ölçer.
///
/// Sözlüğü tahminle değil ölçümle ayarlamak için: bir ilgi alanı hiç kayıt
/// getirmiyorsa o çip kullanıcı için ölü demektir.
///
/// Kullanım: `dart run tool/measure_interests.dart [feed.json]`
library;

import 'dart:convert';
import 'dart:io';

import 'package:tecos/data/feed/feed_schema.dart';
import 'package:tecos/data/interests/interest_taxonomy.dart';

Future<void> main(List<String> args) async {
  final path = args.isEmpty ? 'assets/feed/feed.json' : args.first;
  final feed = Feed.fromJson(
    jsonDecode(await File(path).readAsString()) as Map<String, Object?>,
  );
  final items = feed.visibleItems;

  stdout.writeln('Feed: ${items.length} kayıt');
  stdout.writeln(
    'Konusu olmayan: ${items.where((i) => i.topics.isEmpty).length}',
  );
  stdout.writeln('');

  for (final interest in interestTaxonomy) {
    final matched = items.where((i) => itemMatchesInterest(i, interest));
    stdout.writeln(
      '${interest.label.padRight(16)} ${matched.length.toString().padLeft(3)}'
      ' / ${items.length}',
    );
  }

  stdout.writeln('');
  final anyMatch = items.where(
    (item) => interestTaxonomy.any((i) => itemMatchesInterest(item, i)),
  );
  stdout.writeln(
    'En az bir ilgi alanına giren: ${anyMatch.length} / ${items.length}',
  );

  // Hiçbir ilgi alanına girmeyen kayıtlar: sözlükteki boşlukları gösterir.
  final orphans = items.where(
    (item) =>
        item.topics.isNotEmpty &&
        !interestTaxonomy.any((i) => itemMatchesInterest(item, i)),
  );
  stdout.writeln('Konusu olup hiçbirine girmeyen: ${orphans.length}');
  final orphanTopics = <String, int>{};
  for (final item in orphans) {
    for (final topic in item.topics) {
      orphanTopics[topic] = (orphanTopics[topic] ?? 0) + 1;
    }
  }
  final ranked = orphanTopics.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  stdout.writeln('  en sık eşleşmeyen konular:');
  for (final entry in ranked.take(15)) {
    stdout.writeln('    ${entry.key}: ${entry.value}');
  }
}
