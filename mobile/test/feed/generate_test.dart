import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:teknoakis/data/feed/feed_schema.dart';

import '../../tool/feed/connectors/connector_support.dart';
import '../../tool/feed/connectors/github.dart';
import '../../tool/feed/connectors/syndication.dart';
import '../../tool/feed/fetch.dart';
import '../../tool/feed/generate.dart';
import '../../tool/feed/source_allowlist.dart';
import '../../tool/feed/sources.dart';
import 'fixtures.dart';

final _now = DateTime.utc(2026, 7, 27);

/// Hat, ağa hiç çıkmadan uçtan uca çalıştırılır.
final class FakeFetcher implements FeedFetcher {
  FakeFetcher(this.responses);

  final Map<String, FetchResponse> responses;
  final requested = <Uri>[];

  @override
  Future<FetchResponse> fetch(Uri url) async {
    requested.add(url);
    final response = responses[url.path];
    if (response == null) {
      throw StateError('Beklenmeyen adres: $url');
    }
    return response;
  }
}

FetchResponse _ok(String body) => FetchResponse(statusCode: 200, body: body);

FeedSource _source(String name, String path, FeedParser parse) =>
    FeedSource(name: name, url: Uri.https('test.invalid', path), parse: parse);

List<FeedSource> _sources() => [
  _source('depolar', '/repos', parseGitHubRepositories),
  _source('blog', '/rss', parseSyndicationFeed),
];

FakeFetcher _fetcher() => FakeFetcher({
  '/repos': _ok(feedFixture('github_repositories.json')),
  '/rss': _ok(feedFixture('rss_feed.xml')),
});

void main() {
  group('hat', () {
    test('bütün kaynakları toplar', () async {
      final report = await generateFeed(
        fetcher: _fetcher(),
        sources: _sources(),
        now: _now,
      );

      expect(report.feed.schemaVersion, feedSchemaVersion);
      expect(report.feed.generatedAt, _now);
      expect(report.feed.items, hasLength(7), reason: '5 depo + 2 blog yazısı');
      expect(report.failures, isEmpty);
    });

    test('kaynak raporu alınan ve eleneni ayrı sayar', () async {
      final report = await generateFeed(
        fetcher: _fetcher(),
        sources: _sources(),
        now: _now,
      );

      final byName = {for (final o in report.outcomes) o.name: o};
      expect(byName['depolar']!.items, 5);
      expect(
        byName['depolar']!.skipped,
        hasLength(4),
        reason: '3 ayrıştırma elemesi + 1 kalite kapısı',
      );
      expect(byName['blog']!.items, 2);
      expect(report.skipped, hasLength(6), reason: 'rapor toplamı');
    });

    test('kayıtlar yeniden eskiye sıralanır', () async {
      final report = await generateFeed(
        fetcher: _fetcher(),
        sources: _sources(),
        now: _now,
      );
      final dates = report.feed.items.map((item) => item.publishedAt).toList();
      expect(dates, orderedEquals([...dates]..sort((a, b) => b.compareTo(a))));
    });

    /// Ölçüldü: `openai.com/blog/rss.xml` tek istekte 943 kayıt döndürüyor.
    /// Tavan olmadan tek kaynak feed'i doldurur.
    test('kaynak başı tavan en yenileri tutar', () async {
      final report = await generateFeed(
        fetcher: _fetcher(),
        sources: [
          FeedSource(
            name: 'depolar',
            url: Uri.https('test.invalid', '/repos'),
            parse: parseGitHubRepositories,
            maxItems: 2,
          ),
          _source('blog', '/rss', parseSyndicationFeed),
        ],
        now: _now,
      );

      final outcome = report.outcomes.first;
      expect(outcome.items, 2);
      expect(outcome.available, 6, reason: 'rapor kırpmayı göstermeli');

      // Fixture'daki en yeni iki depo: 2026-07-10 ve 2026-05-30 elenmiş
      // olanlar hariç, kalan en yeniler.
      final titles = report.feed.items.map((item) => item.title).toList();
      expect(titles, contains('birisi/awesome-claude-skills'));
      expect(
        titles,
        isNot(contains('birisi/eski-arac')),
        reason: '2022 tarihli kayıt tavana takılmalı',
      );
    });

    test('limit uygulanır', () async {
      final report = await generateFeed(
        fetcher: _fetcher(),
        sources: _sources(),
        now: _now,
        limit: 2,
      );
      expect(report.feed.items, hasLength(2));
    });
  });

  group('yayımlanabilirlik kapısı', () {
    FeedItem itemWith({
      bool official = false,
      bool license = false,
      int? popularity,
    }) => FeedItem(
      id: 'x',
      kind: FeedItemKind.repository,
      title: 'x',
      summary: 'x',
      summaryOrigin: SummaryOrigin.original,
      sourceName: 'GitHub',
      sourceKind: FeedSourceKind.github,
      url: Uri.parse('https://github.com/a/b'),
      publishedAt: _now,
      checkedAt: _now,
      language: 'en',
      trust: TrustSignals(
        officialSource: official,
        hasLicense: license,
        // Bakım ve güncellik bilerek `true`: bunlar dün açılmış boş bir
        // depoda da sağlanır, o yüzden kapıya sayılmazlar.
        recentlyUpdated: true,
        maintained: true,
        popularity: popularity,
      ),
    );

    test('resmi kaynak koşulsuz geçer', () {
      expect(meetsQualityBar(itemWith(official: true)), isTrue);
    });

    test('üçüncü tarafa lisans ya da popülerlik yeter', () {
      expect(meetsQualityBar(itemWith(license: true)), isTrue);
      expect(meetsQualityBar(itemWith(popularity: 3)), isTrue);
    });

    test('ikisi de yoksa geçemez', () {
      expect(meetsQualityBar(itemWith()), isFalse);
      expect(meetsQualityBar(itemWith(popularity: 0)), isFalse);
    });

    test('elenen kayıt raporda sebebiyle görünür', () async {
      final report = await generateFeed(
        fetcher: _fetcher(),
        sources: _sources(),
        now: _now,
      );

      final titles = report.feed.items.map((item) => item.title);
      expect(titles, isNot(contains('birisi/sinyalsiz-depo')));
      expect(
        report.skipped
            .where((record) => record.reason == SkipReason.lowSignal)
            .map((record) => record.identifier),
        ['birisi/sinyalsiz-depo'],
      );
    });

    /// Kapı tavandan önce işlemezse tavan, yayımlanmayacak kayıtlarla dolar
    /// ve iyi olanlar dışarıda kalır.
    test('kapı tavandan önce işler', () async {
      final report = await generateFeed(
        fetcher: _fetcher(),
        sources: [
          FeedSource(
            name: 'depolar',
            url: Uri.https('test.invalid', '/repos'),
            parse: parseGitHubRepositories,
            maxItems: 1,
          ),
        ],
        now: _now,
      );

      // Fixture'daki en yeni kayıt sinyalsiz olan (2026-07-26). Kapı sonra
      // işleseydi tavan onu alır ve feed boş kalırdı.
      expect(report.feed.items, hasLength(1));
      expect(report.feed.items.single.title, isNot('birisi/sinyalsiz-depo'));
    });
  });

  group('kaynak arızası', () {
    /// Bir kaynağın düşmesi diğerlerini götürmemeli.
    test('tek kaynak düşerse koşu sürer', () async {
      final report = await generateFeed(
        fetcher: FakeFetcher({
          '/repos': const FetchResponse(statusCode: 503, body: ''),
          '/rss': _ok(feedFixture('rss_feed.xml')),
        }),
        sources: _sources(),
        now: _now,
      );

      expect(report.feed.items, hasLength(2));
      expect(report.failures.single.name, 'depolar');
      expect(report.failures.single.error, 'HTTP 503');
    });

    test('bozuk gövde o kaynağı düşürür, koşuyu değil', () async {
      final report = await generateFeed(
        fetcher: FakeFetcher({
          '/repos': _ok('<html>bu JSON değil</html>'),
          '/rss': _ok(feedFixture('rss_feed.xml')),
        }),
        sources: _sources(),
        now: _now,
      );
      expect(report.feed.items, hasLength(2));
      expect(report.failures.single.name, 'depolar');
    });

    /// Boş bir dosyayla iyi bir feed'in üzerine yazmak, güncellememekten
    /// kötüdür.
    test('hiçbiri okunamazsa yazılmaz', () async {
      expect(
        () => generateFeed(
          fetcher: FakeFetcher({
            '/repos': const FetchResponse(statusCode: 500, body: ''),
            '/rss': const FetchResponse(statusCode: 500, body: ''),
          }),
          sources: _sources(),
          now: _now,
        ),
        throwsA(isA<GenerationException>()),
      );
    });
  });

  group('belirlenimcilik', () {
    /// Cron her koşuda aynı dosyayı yazmalı; yoksa her çalışmada anlamsız bir
    /// değişiklik commit'lenir.
    test('aynı girdi aynı JSON\'u verir', () async {
      final first = await generateFeed(
        fetcher: _fetcher(),
        sources: _sources(),
        now: _now,
      );
      final second = await generateFeed(
        fetcher: _fetcher(),
        sources: _sources().reversed.toList(),
        now: _now,
      );
      expect(encodeFeed(first.feed), encodeFeed(second.feed));
    });

    test('yazılan JSON tekrar okunabilir', () async {
      final report = await generateFeed(
        fetcher: _fetcher(),
        sources: _sources(),
        now: _now,
      );
      final encoded = encodeFeed(report.feed);

      final decoded = Feed.fromJson(
        (jsonDecode(encoded) as Map).cast<String, Object?>(),
      );
      expect(decoded.items, hasLength(report.feed.items.length));
      expect(decoded.generatedAt, _now);
      expect(encoded, endsWith('\n'));
    });
  });

  group('varsayılan kaynaklar', () {
    /// Üretici, listelenmemiş bir hosta **istek bile atmamalı**.
    test('hiçbir kaynak listelenmemiş hosta istek atmaz', () {
      for (final source in defaultSources()) {
        expect(
          SourceAllowlist.isFetchable(source.url),
          isTrue,
          reason: '${source.name} → ${source.url}',
        );
      }
    });

    /// *Nereden çekiyoruz* ile *neyi gösteriyoruz* ayrı sorular: bir API ucu
    /// içerik allowlist'ine girseydi, API yanıtı yayımlanabilir bir kaynak
    /// hâline gelirdi.
    test('API ucu içerik olarak gösterilebilir değildir', () {
      final api = Uri.https('api.github.com', '/search/repositories');
      expect(SourceAllowlist.isFetchable(api), isTrue);
      expect(SourceAllowlist.isAllowed(api), isFalse);
      expect(SourceAllowlist.isOfficial(api), isFalse);
    });

    /// Ölçüldü: `full=true` olmadan `lastModified` gelmiyor ve her model
    /// bakımsız görünüyor.
    test('Hugging Face sorgusu full=true taşır', () {
      final source = defaultSources().firstWhere(
        (source) => source.url.host == 'huggingface.co',
      );
      expect(source.url.queryParameters['full'], 'true');
    });

    test('kaynak adları tekil', () {
      final names = defaultSources().map((source) => source.name).toList();
      expect(names.toSet(), hasLength(names.length));
    });
  });
}
