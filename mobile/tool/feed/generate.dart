/// Feed üreticisi.
///
/// Kaynakları çeker, bağlayıcılarla ayrıştırır, kopyaları birleştirir ve tek
/// bir JSON dosyası yazar. Uygulama bu dosyayı **salt-okunur** okur; ağ ve
/// anahtar uygulamaya hiç girmez.
///
/// Kullanım:
/// ```
/// dart run tool/feed/generate.dart --out assets/feed/feed.json
/// dart run tool/feed/generate.dart --dry-run
/// ```
library;

import 'dart:convert';
import 'dart:io';

import 'package:teknoakis/data/feed/feed_schema.dart';

import 'connectors/connector_support.dart';
import 'fetch.dart';
import 'merge.dart';
import 'sources.dart';
import 'summarize.dart';

/// Bir kaynağın o koşudaki sonucu.
final class SourceOutcome {
  const SourceOutcome({
    required this.name,
    this.items = 0,
    this.available = 0,
    this.skipped = const [],
    this.error,
  });

  final String name;

  /// Feed'e giren kayıt sayısı (tavan uygulandıktan sonra).
  final int items;

  /// Kaynağın döndürdüğü toplam. [items]'tan büyükse tavan devreye girmiştir;
  /// rapor bunu göstermeli, yoksa 943 kaydın 30'a inmesi görünmez olur.
  final int available;

  final List<SkippedRecord> skipped;

  /// `null` değilse kaynak okunamadı. Boş dönmekle **okunamamak** farklıdır:
  /// ilki içerik yokluğu, ikincisi bizim hatamız olabilir.
  final String? error;

  bool get failed => error != null;

  @override
  String toString() => failed
      ? '$name: HATA — $error'
      : '$name: $items kayıt'
            '${available > items ? ' ($available içinden)' : ''}'
            '${skipped.isEmpty ? '' : ', ${skipped.length} elendi'}';
}

/// Yayımlanabilirlik kapısı.
///
/// **Resmi kaynaklar koşulsuz geçer**: duyuruyu yapan kurumun kendisidir,
/// yıldız sayısı sormaya gerek yok.
///
/// Üçüncü taraf içerik ise en az bir **dış** kalite sinyali göstermeli:
/// lisans ya da popülerlik. Bakım ve güncellik yeterli sayılmaz — dün açılmış
/// boş bir depo ikisini de sağlar. Ölçülen gerçek koşuda listenin başında
/// `RafaelBatistaDev/Claude_Code-free-9router` vardı; açıklaması adının
/// tekrarıydı, lisansı ve yıldızı yoktu ve tarih sıralamasında gerçek bir
/// duyuruyu geçiyordu.
///
/// Kapı, popülerliği güven ölçütü hâline **getirmez**: hâlâ 100 puanın
/// yalnız 10'unu veriyor. Buradaki soru "ne kadar iyi" değil, "dışarıdan
/// bakan biri bunu hiç değerlendirmiş mi".
bool meetsQualityBar(FeedItem item) =>
    item.trust.officialSource ||
    item.trust.hasLicense ||
    (item.trust.popularity ?? 0) > 0;

/// En yeni [count] kaydı verir.
///
/// Beslemenin sırasına güvenilmez: kaynak istediği sırada döndürebilir.
/// Eşitlikte kimliğe göre — aynı girdi her koşuda aynı çıktıyı vermeli.
List<FeedItem> _newest(List<FeedItem> items, int count) {
  if (items.length <= count) return items;
  final ordered = [...items]
    ..sort((a, b) {
      final byDate = b.publishedAt.compareTo(a.publishedAt);
      return byDate != 0 ? byDate : a.id.compareTo(b.id);
    });
  return ordered.sublist(0, count);
}

final class GenerationReport {
  const GenerationReport({
    required this.feed,
    required this.outcomes,
    this.summaries,
  });

  final Feed feed;
  final List<SourceOutcome> outcomes;

  /// Özet katmanının o koşudaki sonucu. Anahtar yoksa hepsi sıfırdır.
  final SummaryPass? summaries;

  Iterable<SourceOutcome> get failures => outcomes.where((o) => o.failed);
  Iterable<SkippedRecord> get skipped =>
      outcomes.expand((outcome) => outcome.skipped);
}

class GenerationException implements Exception {
  const GenerationException(this.message);
  final String message;
  @override
  String toString() => 'GenerationException: $message';
}

/// Feed'i üretir.
///
/// [now] dışarıdan verilir: çıktı belirlenimci olmalı ve testler saat
/// okumamalı. Aynı girdi + aynı [now] her zaman aynı JSON'u verir.
Future<GenerationReport> generateFeed({
  required FeedFetcher fetcher,
  required List<FeedSource> sources,
  required DateTime now,
  int limit = 200,
  Summarizer summarizer = const DisabledSummarizer(),
}) async {
  final outcomes = <SourceOutcome>[];
  final collected = <FeedItem>[];

  for (final source in sources) {
    try {
      final response = await fetcher.fetch(source.url);
      if (!response.isOk) {
        outcomes.add(
          SourceOutcome(
            name: source.name,
            error: 'HTTP ${response.statusCode}',
          ),
        );
        continue;
      }
      final result = source.parse(response.body, checkedAt: now);

      // Kapı **tavandan önce** işler: aksi hâlde tavan, zaten yayımlanmayacak
      // kayıtlarla dolar ve iyi olanlar dışarıda kalırdı.
      final publishable = <FeedItem>[];
      final rejected = <SkippedRecord>[];
      for (final item in result.items) {
        if (meetsQualityBar(item)) {
          publishable.add(item);
        } else {
          rejected.add(SkippedRecord(item.title, SkipReason.lowSignal));
        }
      }

      final taken = _newest(publishable, source.maxItems);
      collected.addAll(taken);
      outcomes.add(
        SourceOutcome(
          name: source.name,
          items: taken.length,
          available: result.items.length,
          skipped: [...result.skipped, ...rejected],
        ),
      );
    } catch (error) {
      // Tek kaynağın çökmesi koşuyu bitirmez: diğerleri hâlâ değerli.
      outcomes.add(SourceOutcome(name: source.name, error: '$error'));
    }
  }

  // Hiçbiri okunamadıysa **yazılmaz**. Boş bir dosyayla iyi bir feed'in
  // üzerine yazmak, güncellememekten kötüdür.
  if (outcomes.every((outcome) => outcome.failed)) {
    throw const GenerationException(
      'Hiçbir kaynak okunamadı; var olan feed korunuyor.',
    );
  }

  final merged = mergeDuplicates(collected);
  final trimmed = merged.length <= limit
      ? merged
      : merged.sublist(0, limit).toList(growable: false);

  // Özetleme **en sona** bırakılır: birleştirme ve limit sonrasında kalan
  // kayıtlar özetlenir. Önce özetlemek, birleştirmede kaybedilecek kopyalar
  // için de model çağrısı yapmak olurdu.
  final summaries = await applySummaries(trimmed, summarizer: summarizer);

  return GenerationReport(
    feed: Feed(
      schemaVersion: feedSchemaVersion,
      generatedAt: now,
      items: summaries.items,
    ),
    outcomes: outcomes,
    summaries: summaries,
  );
}

/// Feed'i dosyaya yazılacak biçimde kodlar.
///
/// Girintili ve sonu satırbaşlı: cron her koşuda aynı dosyayı yazmalı ve
/// değişiklik olduğunda diff **okunabilir** olmalı.
String encodeFeed(Feed feed) =>
    '${const JsonEncoder.withIndent('  ').convert(feed.toJson())}\n';

/// Çıkış kodları: 0 tam başarı, 2 kısmi (bazı kaynaklar okunamadı ama feed
/// yazıldı), 1 çalışma hatası. Barındırma iş akışı 2'yi nasıl yorumlayacağına
/// kendi karar verir — sessizce başarı saymasın diye ayrıldı.
Future<int> run(List<String> args, {FeedFetcher? fetcher}) async {
  String? output = 'assets/feed/feed.json';
  var limit = 200;
  var dryRun = false;

  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--out':
        output = i + 1 < args.length ? args[++i] : null;
      case '--limit':
        limit = int.tryParse(i + 1 < args.length ? args[++i] : '') ?? limit;
      case '--dry-run':
        dryRun = true;
      case '--help':
        stdout.writeln(
          'Kullanım: dart run tool/feed/generate.dart '
          '[--out <yol>] [--limit <n>] [--dry-run]',
        );
        return 0;
    }
  }

  // Anahtar yoksa katman tamamen kapalıdır ve feed yine eksiksiz üretilir.
  final apiKey = Platform.environment['ANTHROPIC_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    stdout.writeln(
      '  ANTHROPIC_API_KEY yok — özetler kaynağın kendi metniyle kalıyor.',
    );
  }

  final report = await generateFeed(
    fetcher:
        fetcher ??
        HttpFeedFetcher(githubToken: Platform.environment['GITHUB_TOKEN']),
    sources: defaultSources(),
    now: DateTime.now().toUtc(),
    limit: limit,
    summarizer: apiKey == null || apiKey.isEmpty
        ? const DisabledSummarizer()
        : AnthropicSummarizer(apiKey: apiKey),
  );

  for (final outcome in report.outcomes) {
    stdout.writeln('  $outcome');
  }

  // Elenenler sebebe göre özetlenir: tek tek yazmak konsolu boğuyor (bir
  // koşuda 108 satır) ve asıl bilgi olan dağılımı görünmez kılıyordu.
  final byReason = <SkipReason, List<String>>{};
  for (final record in report.skipped) {
    (byReason[record.reason] ??= []).add(record.identifier);
  }
  for (final entry in byReason.entries) {
    final examples = entry.value.take(3).join(', ');
    final rest = entry.value.length - 3;
    stdout.writeln(
      '  elenen · ${entry.key.name}: ${entry.value.length}'
      ' — $examples${rest > 0 ? ' … (+$rest)' : ''}',
    );
  }

  final summaries = report.summaries;
  if (summaries != null &&
      (summaries.summarized > 0 ||
          summaries.rejected.isNotEmpty ||
          summaries.failed > 0)) {
    stdout.writeln(
      '  özet · ${summaries.summarized} Türkçeleştirildi'
      '${summaries.failed > 0 ? ', ${summaries.failed} çağrı hatası' : ''}'
      '${summaries.budgetExhausted ? ', bütçe doldu' : ''}',
    );
    for (final entry in summaries.rejected.entries) {
      stdout.writeln('  özet · reddedildi (${entry.key.name}): ${entry.value}');
    }
  }

  stdout.writeln('Toplam: ${report.feed.items.length} kayıt.');

  if (!dryRun && output != null) {
    final file = File(output);
    await file.parent.create(recursive: true);
    await file.writeAsString(encodeFeed(report.feed));
    stdout.writeln('Yazıldı: $output');
  }

  return report.failures.isEmpty ? 0 : 2;
}

Future<void> main(List<String> args) async {
  try {
    exitCode = await run(args);
  } on GenerationException catch (error) {
    stderr.writeln(error.message);
    exitCode = 1;
  }
}
