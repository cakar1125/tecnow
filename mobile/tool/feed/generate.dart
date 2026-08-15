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

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:tecos/data/feed/feed_schema.dart';

import 'connectors/connector_support.dart';
import 'fetch.dart';
import 'merge.dart';
import 'sources.dart';
import 'summarize.dart';

/// Yayına yazılan tazeleme aralığı — uygulamaların bu dosyaya ne sıklıkta
/// bakacağı.
///
/// Buradan yönetiliyor çünkü uygulamada derleme zamanı sabiti olarak
/// tutulduğunda mağaza yayınından sonra değiştirilemiyordu: güncellemeyen
/// kullanıcı eski temposunda kalıcı olarak kalırdı.
///
/// Üretim temposuyla (`publish-feed.yml`, saatte bir) eşleştirilmedi ve bu
/// kasıtlı: iş akışı gecikebiliyor (GitHub zamanlanmış işleri yoğunlukta 5–20
/// dakika erteliyor), o yüzden istemci daha sık bakıyor. Değişmemiş içerikte
/// isteğin bedeli **0 bayt gövde** (`If-None-Match` → `304`), yani sık bakmak
/// bedava; geç görmek değil.
///
/// Sınırlar okuma tarafında: [feedMinRefreshAfter] / [feedMaxRefreshAfter].
const feedPublishedRefreshAfter = Duration(minutes: 15);

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
  return _byNewest(items).sublist(0, count);
}

/// AÇIK SORUN — geleceğe tarihli kayıt sıralamanın tepesini işgal ediyor.
///
/// Ölçüldü 2026-08-06, yayındaki gerçek feed'de: VS Code 1.133 Insiders kaydı
/// `publishedAt: 2026-08-11` taşıyor, yani o günden **beş gün sonrası**.
/// Kaynak yayın tarihini ileri yazmış; biz olduğu gibi taşıyoruz ve kayıt,
/// gerçek zaman ona yetişene kadar listenin birinci sırasında kalıyor.
///
/// **Denenen ve reddedilen çözüm:** sıralama anahtarını `now`'a kırpmak.
/// İşe yaramadı ve ölçüm bunu gösterdi (2026-08-06, üretici gerçek veriyle
/// koşturuldu): `now` koşu anıdır, yani **her gerçek kaydın tarihinden
/// yenidir**. Kırpılmış kayıt yine hepsini geçiyor, üstelik `now` her koşuda
/// ilerlediği için süresiz. Kırpma bu vakada tam bir no-op.
///
/// **Doğru çözüm, durum gerektiriyor:** kaydı **ilk gördüğümüz** an
/// saklanmalı ve sıralama `min(publishedAt, firstSeenAt)` ile yapılmalı. O
/// zaman kayıt ilk koşuda tepede başlar, ertesi gün yayınlanan gerçek kayıtlar
/// onu geçer. Bunun için `FeedItem`'a taşınan ve `previous`'tan devralınan bir
/// alan gerekiyor — `applySummaries`'in özetleri devrettiği mekanizmanın
/// aynısı. Ayrı bir iş olarak duruyor.
List<FeedItem> _byNewest(Iterable<FeedItem> items) => [...items]
  ..sort((a, b) {
    final byDate = b.publishedAt.compareTo(a.publishedAt);
    return byDate != 0 ? byDate : a.id.compareTo(b.id);
  });

/// Her tür için ayrılan taban kontenjan.
///
/// Uygulamanın sekmeleri içerik **türüne** göre süzüyor; saf tarih sıralaması
/// bir sekmeyi tamamen boşaltabilir. Ölçüldü (2026-07-28): blog kaynakları
/// eklendikten sonra duyurular tarih sıralamasında modelleri ezdi ve
/// "AI Modelleri" sekmesinde 200 kayıttan yalnız **4** tanesi kaldı.
///
/// Taban, tarihi devre dışı bırakmaz: önce her tür kendi tabanını en yeni
/// kayıtlarıyla doldurur, kalan yerler yine küresel tarih sırasına gider.
const _floorPerKind = 20;

/// Feed'i [limit] kayda indirir — türler arası dengeyi koruyarak.
///
/// Rehberin işi "en son ne yazıldı" değil, "her alanda neler var" sorusuna
/// cevap vermek. Tek bir yüksek hacimli kategori feed'in tamamını
/// kaplayamamalı.
List<FeedItem> balancedTrim(
  List<FeedItem> items, {
  required int limit,
  int floorPerKind = _floorPerKind,
}) {
  if (items.length <= limit) return _byNewest(items);

  final byKind = <FeedItemKind, List<FeedItem>>{};
  for (final item in _byNewest(items)) {
    (byKind[item.kind] ??= []).add(item);
  }

  // Taban, türe düşen paydan büyük olamaz: tek bir türün tabanı bütün yeri
  // yiyip diğerlerine hiç bırakmamalı.
  final perKind = byKind.isEmpty
      ? 0
      : (limit ~/ byKind.length).clamp(0, floorPerKind);

  final selected = <String, FeedItem>{};
  for (final group in byKind.values) {
    for (final item in group.take(perKind)) {
      selected[item.id] = item;
    }
  }

  // Kalan yerler küresel tarih sırasına göre dolar.
  for (final item in _byNewest(items)) {
    if (selected.length >= limit) break;
    selected[item.id] = item;
  }

  return _byNewest(selected.values);
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
  String language = feedDefaultLanguage,
  List<FeedLanguage> availableLanguages = const [],
  int summaryBudget = defaultSummaryBudget,
  List<FeedItem> previous = const [],
  Duration refreshAfter = feedPublishedRefreshAfter,
}) async {
  // Üretici **katı**, uygulama hoşgörülü. `Feed.fromJson` kendi diliyle
  // çelişen bir listeyi sessizce boşa düşürüyor — doğru davranış, çünkü
  // kullanıcı okuduğu dile geri dönemeyen bir seçim listesiyle kalmamalı.
  // Ama o sessizlik burada olsaydı, hatalı bir yayın "dil seçimi çalışmıyor"
  // diye kullanıcıya ulaşırdı. Kusur üretim anında, yüksek sesle ölür.
  if (availableLanguages.isNotEmpty &&
      !availableLanguages.any((entry) => entry.code == language)) {
    throw GenerationException(
      'Dil listesi üretilen dili ($language) içermiyor: '
      '${availableLanguages.map((entry) => entry.code).join(", ")}',
    );
  }
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
  final trimmed = balancedTrim(merged, limit: limit);

  // Özetleme **en sona** bırakılır: birleştirme ve limit sonrasında kalan
  // kayıtlar özetlenir. Önce özetlemek, birleştirmede kaybedilecek kopyalar
  // için de model çağrısı yapmak olurdu.
  final summaries = await applySummaries(
    trimmed,
    summarizer: summarizer,
    language: language,
    budget: summaryBudget,
    previous: previous,
  );

  return GenerationReport(
    feed: Feed(
      schemaVersion: feedSchemaVersion,
      generatedAt: now,
      items: summaries.items,
      refreshAfter: refreshAfter,
      language: language,
      availableLanguages: availableLanguages,
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

/// `--languages tr=feed.json,en=feed.en.json` biçimini okur.
///
/// Ayrıştırma **katı**: bozuk bir giriş sessizce atlanmaz, hata fırlatır.
/// Uygulama tarafındaki hoşgörünün ([Feed.fromJson]) burada karşılığı yok ve
/// olmaması bilinçli — orada amaç kullanıcının içeriği görmeye devam etmesi,
/// burada amaç yanlış yayının hiç çıkmaması. Aynı kural iki tarafta zıt
/// davranış gerektiriyor.
List<FeedLanguage> parseLanguageList(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return const [];

  final entries = <FeedLanguage>[];
  for (final part in trimmed.split(',')) {
    final piece = part.trim();
    if (piece.isEmpty) continue;

    final separator = piece.indexOf('=');
    if (separator <= 0 || separator == piece.length - 1) {
      throw FormatException('"$piece" <kod>=<yol> biçiminde değil');
    }

    final code = piece.substring(0, separator).trim();
    final url = piece.substring(separator + 1).trim();
    if (code.isEmpty || url.isEmpty) {
      throw FormatException('"$piece" boş kod ya da yol içeriyor');
    }
    if (entries.any((entry) => entry.code == code)) {
      throw FormatException('"$code" iki kez verildi');
    }

    entries.add(FeedLanguage(code: code, url: url));
  }
  return List.unmodifiable(entries);
}

/// Çıkış kodları: 0 tam başarı, 2 kısmi (bazı kaynaklar okunamadı ama feed
/// yazıldı), 1 çalışma hatası. Barındırma iş akışı 2'yi nasıl yorumlayacağına
/// kendi karar verir — sessizce başarı saymasın diye ayrıldı.
/// Özet sağlayıcısını ortamdaki anahtarlardan kurar.
///
/// Hiç anahtar yoksa katman tamamen kapalıdır ve feed **yine eksiksiz**
/// üretilir — anahtar bir kolaylıktır, koşul değil.
///
/// İkisi de varsa sıralı yedekleme kurulur: Anthropic birincil, NVIDIA yedek.
/// Bu sıra **geçicidir ve ölçümle değişecektir**; karşılaştırma için
/// `--summarizer anthropic|nvidia` ile tek sağlayıcı zorlanabilir.
Summarizer _buildSummarizer(String provider) {
  // `none`: anahtar **olsa bile** çağrı yapılmaz.
  //
  // İngilizce yayın için doğru mod ve bedeli sıfır: kaynaklar zaten
  // İngilizce, yani özetlenmemiş kayıt ([SummaryOrigin.original]) hem doğru
  // hem de kaynağın kendi cümlesi. Bunu gizli bir özel duruma çevirmek
  // (`--language en` görünce özetlemeyi kendiliğinden kapatmak) daha kolay
  // olurdu ama yanlış: kaynak listesine bir gün İngilizce olmayan bir kaynak
  // eklenirse o özel durum sessizce yanlışa döner. Karar operatörde kalıyor.
  if (provider == 'none') {
    stdout.writeln('  özet · kapalı (--summarizer none).');
    return const DisabledSummarizer();
  }

  final anthropicKey = Platform.environment['ANTHROPIC_API_KEY'];
  final nvidiaKey = Platform.environment['NVIDIA_API_KEY'];

  final providers = <Summarizer>[
    if (provider != 'nvidia' && (anthropicKey?.isNotEmpty ?? false))
      AnthropicSummarizer(apiKey: anthropicKey!),
    if (provider != 'anthropic' && (nvidiaKey?.isNotEmpty ?? false))
      NvidiaSummarizer(
        apiKey: nvidiaKey!,
        model:
            Platform.environment['NVIDIA_MODEL'] ??
            'meta/llama-3.3-70b-instruct',
      ),
  ];

  if (providers.isEmpty) {
    stdout.writeln(
      '  özet · anahtar yok (ANTHROPIC_API_KEY / NVIDIA_API_KEY) — '
      'kayıtlar kaynağın kendi metniyle kalıyor.',
    );
    return const DisabledSummarizer();
  }

  stdout.writeln('  özet · ${providers.length} sağlayıcı hazır.');
  return providers.length == 1
      ? providers.single
      : FallbackSummarizer(providers);
}

/// Yayımdaki feed'i okur; okunamazsa **boş liste**.
///
/// Taşıma bir iyileştirmedir, koşulun kendisi değil. Dosya yoksa (ilk yayım),
/// indirilememişse ya da bozuksa üretim eksiksiz sürer — yalnız o koşuda
/// özetler yeniden üretilir. Bu yüzden burada hiçbir hata yukarı taşınmaz.
List<FeedItem> _readPreviousItems(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    stdout.writeln('  taşıma · $path yok, özetler sıfırdan üretilecek.');
    return const [];
  }
  try {
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('feed bir nesne değil');
    }
    return Feed.fromJson(decoded).items;
  } catch (error) {
    stdout.writeln('  taşıma · $path okunamadı ($error); taşıma kapalı.');
    return const [];
  }
}

Future<int> run(List<String> args, {FeedFetcher? fetcher}) async {
  String? output = 'assets/feed/feed.json';
  String? previousPath;
  var limit = 200;
  var summaryBudget = defaultSummaryBudget;
  var provider = 'auto';
  var language = feedDefaultLanguage;
  var availableLanguages = const <FeedLanguage>[];
  var dryRun = false;

  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--language':
        language = i + 1 < args.length ? args[++i] : language;
      case '--languages':
        final raw = i + 1 < args.length ? args[++i] : '';
        try {
          availableLanguages = parseLanguageList(raw);
        } on FormatException catch (error) {
          stderr.writeln('--languages: ${error.message}');
          return 1;
        }
      case '--out':
        output = i + 1 < args.length ? args[++i] : null;
      case '--previous':
        previousPath = i + 1 < args.length ? args[++i] : null;
      case '--limit':
        limit = int.tryParse(i + 1 < args.length ? args[++i] : '') ?? limit;
      case '--summary-budget':
        summaryBudget =
            int.tryParse(i + 1 < args.length ? args[++i] : '') ?? summaryBudget;
      case '--summarizer':
        provider = i + 1 < args.length ? args[++i] : provider;
      case '--dry-run':
        dryRun = true;
      case '--help':
        stdout.writeln(
          'Kullanım: dart run tool/feed/generate.dart '
          '[--out <yol>] [--previous <yol>] [--limit <n>] '
          '[--summary-budget <n>] '
          '[--summarizer auto|anthropic|nvidia|none] '
          '[--language <kod>] [--languages <kod>=<yol>,...] '
          '[--dry-run]',
        );
        return 0;
    }
  }

  // Yayımdaki kopya: özetleri taşımak için. Okunamaması **hata değildir** —
  // ilk yayımda dosya yoktur, sonrasında indirme başarısız olabilir. Her iki
  // durumda da üretim eksiksiz sürer, yalnız taşıma devre dışı kalır.
  final previous = previousPath == null
      ? const <FeedItem>[]
      : _readPreviousItems(previousPath);

  final summarizer = _buildSummarizer(provider);

  final report = await generateFeed(
    fetcher:
        fetcher ??
        HttpFeedFetcher(githubToken: Platform.environment['GITHUB_TOKEN']),
    sources: defaultSources(),
    now: DateTime.now().toUtc(),
    limit: limit,
    summaryBudget: summaryBudget,
    previous: previous,
    summarizer: summarizer,
    language: language,
    availableLanguages: availableLanguages,
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
          summaries.carried > 0 ||
          summaries.rejected.isNotEmpty ||
          summaries.failed > 0)) {
    stdout.writeln(
      '  özet · ${summaries.summarized} Türkçeleştirildi'
      '${summaries.carried > 0 ? ', ${summaries.carried} taşındı' : ''}'
      '${summaries.failed > 0 ? ', ${summaries.failed} çağrı hatası' : ''}'
      '${summaries.budgetExhausted ? ', bütçe doldu' : ''}',
    );
    for (final entry in summaries.rejected.entries) {
      stdout.writeln('  özet · reddedildi (${entry.key.name}): ${entry.value}');
    }
    // Sayı "bir şey oldu" der, sebep "ne oldu" der. İkincisi olmadan teşhis
    // koşu süresinden geriye hesaplanmak zorunda kalıyor.
    final failure = summaries.firstFailure;
    if (failure != null) {
      stdout.writeln('  özet · ilk hata: $failure');
    }
    if (summaries.abandoned) {
      stdout.writeln(
        '  özet · sağlayıcı düştü, kalan çağrılar yapılmadı '
        '($summaryFailureStreakLimit ardışık hata, hiç başarı yok)',
      );
    }
    if (summaries.timeBudgetExhausted) {
      stdout.writeln(
        '  özet · süre bütçesi doldu (${summaryTimeBudget.inMinutes} dk); '
        'kalan kayıtlar sonraki koşuda denenecek',
      );
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

/// `runZonedGuarded`: `try/catch`'in **göremediği** hatayı görür.
///
/// Ayrım burada işin özü. `try/catch` yalnız `await`'i beklenen bir future'ın
/// hatasını yakalar. Kimsenin dinlemediği bir asenkron hata — sözgelimi
/// zaman aşımına uğradıktan sonra kendi hatasıyla tamamlanan bir soket, ya da
/// bir `Stream` aboneliğinin ardından gelen bir kesinti — `try/catch`'e hiç
/// uğramaz; doğruca bölgeye (zone) gider ve varsayılan bölge onu yazıp
/// süreci **255** ile bitirir.
///
/// 255 tam olarak buydu: yakalanamayan bir hata değil, **yakalanmamış** bir
/// hata. Bu yüzden bir alttaki `catch` bloğu tek başına yetmezdi — kusur
/// oraya hiç uğramıyordu.
///
/// Bölge içindeyken süreç 255 ile ölmüyor; hata yazılıyor ve çıkış kodu
/// belgelenmiş **1**'e (çalışma hatası) çekiliyor. İş akışı 1'i zaten hata
/// sayıyor, yani davranış değişmiyor — değişen tek şey **sebebin görünür
/// olması**.
Future<void> main(List<String> args) async {
  await runZonedGuarded(() => _main(args), (error, stackTrace) {
    stderr
      ..writeln('YAKALANMAMIŞ ASENKRON HATA · ${error.runtimeType}')
      ..writeln(error)
      ..writeln(stackTrace);
    exitCode = 1;
  });
}

Future<void> _main(List<String> args) async {
  try {
    exitCode = await run(args);
  } on GenerationException catch (error) {
    stderr.writeln(error.message);
    exitCode = 1;
  } catch (error, stackTrace) {
    // **Beklenmeyen** istisna. Buranın var olma sebebi ölçüldü: yayın iş
    // akışı 12 Ağustos 2026'da son sekiz koşunun ikisinde (#96, #99) "Feed
    // üret" adımında **255** ile düştü. 255, Dart'ın yakalanmamış istisna
    // kodu — yani üreticinin kendi belgelediği hiçbir çıkış kodu değil
    // (0 tam · 2 kısmi · 1 çalışma hatası) ve tek başına hiçbir şey
    // söylemiyor. Koşu logu jetonsuz okunamadığı için sebep iki koşu boyunca
    // görünmez kaldı.
    //
    // İstisnanın **tipi ve yığını** yazılıyor: kusur kararsız (aynı kod
    // yerelde ve diğer altı koşuda çalışıyor), yani bir dahaki sefere
    // yakalanması gereken şey tam olarak bu satırlar.
    //
    // Çıkış kodu 1: belgelenmiş "çalışma hatası". 255'i olduğu gibi bırakmak,
    // iş akışının `status -ne 0 && status -ne 2` kuralında zaten hataya
    // düşüyordu ama okunabilir bir iz bırakmıyordu.
    stderr
      ..writeln('BEKLENMEYEN HATA · ${error.runtimeType}')
      ..writeln(error)
      ..writeln(stackTrace);
    exitCode = 1;
  }
}
