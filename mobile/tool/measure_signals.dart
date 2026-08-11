/// Gerekçe etiketlerinin **dağılımını** ölçer.
///
/// `feed_signal.dart` sıralamayı "nadir olan daha bilgilendiricidir" ilkesine
/// dayandırıyor. İlke ancak ölçülürse geçerli: bir etiket kayıtların çoğuna
/// yapışıyorsa hiçbir kaydı diğerinden ayırmaz ve satıra yalnız gürültü ekler.
///
/// Kullanım: `dart run tool/measure_signals.dart [feed.json]`
library;

import 'dart:convert';
import 'dart:io';

import 'package:tecos/data/feed/feed_schema.dart';
import 'package:tecos/data/interests/interest_taxonomy.dart';
import 'package:tecos/ui/feed_signal.dart';

void _table(String title, Map<String, int> counts, int total) {
  stdout.writeln(title);
  final ranked = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final entry in ranked) {
    final share = 100 * entry.value / total;
    stdout.writeln(
      '  ${entry.key.padRight(24)} ${entry.value.toString().padLeft(3)}'
      ' / $total  ${share.toStringAsFixed(1)}%',
    );
  }
  stdout.writeln('');
}

Future<void> main(List<String> args) async {
  final path = args.isEmpty ? 'assets/feed/feed.json' : args.first;
  final feed = Feed.fromJson(
    jsonDecode(await File(path).readAsString()) as Map<String, Object?>,
  );
  final items = feed.visibleItems;
  // "Şimdi", üretimin kendi zamanı: tazelik etiketi ölçüm gününe göre değil
  // feed'in üretildiği ana göre hesaplanmalı, yoksa gün geçtikçe sıfıra iner.
  final now = feed.generatedAt;

  stdout.writeln('Feed: ${items.length} kayıt · üretim $now\n');

  /// Bir seçim kümesi için gerekçe dağılımı.
  void report(String title, Set<String> selection) {
    final counts = <String, int>{'(etiketsiz)': 0};
    for (final item in items) {
      final signal = feedSignalFor(item, interests: selection, now: now);
      final key = signal?.label ?? '(etiketsiz)';
      counts[key] = (counts[key] ?? 0) + 1;
    }
    _table(title, counts, items.length);
  }

  report('TÜMÜ sekmesi · hiç konu seçili değil', const {});
  report('TÜMÜ sekmesi · 3 konu (yapay-zeka, acik-kaynak, donanim)', const {
    'yapay-zeka',
    'acik-kaynak',
    'donanim',
  });
  report('TÜMÜ sekmesi · 8 konunun hepsi', {
    for (final interest in interestTaxonomy) interest.id,
  });

  /// "SANA" yerine eşleşen konunun adı yazılsaydı dağılım ne olurdu?
  ///
  /// Eşleşme kullanıcının **sırasına** göre ilk bulunan konu olurdu; burada
  /// sözlük sırası kullanılıyor (varsayılan sıra).
  void reportNamed(String title, List<String> selection) {
    final counts = <String, int>{'(konu eşleşmesi yok)': 0};
    for (final item in items) {
      String? matched;
      for (final id in selection) {
        final interest = interestById(id);
        if (interest == null) continue;
        if (itemMatchesInterest(item, interest)) {
          matched = interest.label;
          break;
        }
      }
      final key = matched ?? '(konu eşleşmesi yok)';
      counts[key] = (counts[key] ?? 0) + 1;
    }
    _table(title, counts, items.length);
  }

  reportNamed('Konu adı yazılsaydı · 3 konu', const [
    'yapay-zeka',
    'acik-kaynak',
    'donanim',
  ]);
  reportNamed('Konu adı yazılsaydı · 8 konu', [
    for (final interest in interestTaxonomy) interest.id,
  ]);
}
