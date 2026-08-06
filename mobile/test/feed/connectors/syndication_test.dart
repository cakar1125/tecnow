import 'package:flutter_test/flutter_test.dart';
import 'package:tecnow/data/feed/feed_schema.dart';

import '../../../tool/feed/connectors/connector_support.dart';
import '../../../tool/feed/connectors/syndication.dart';
import '../fixtures.dart';

final _checkedAt = DateTime.utc(2026, 7, 27);

ConnectorResult _rss() =>
    parseSyndicationFeed(feedFixture('rss_feed.xml'), checkedAt: _checkedAt);

ConnectorResult _atom() =>
    parseSyndicationFeed(feedFixture('atom_feed.xml'), checkedAt: _checkedAt);

void main() {
  group('RSS 2.0', () {
    test('yayımlanabilir kayıtlar alınır', () {
      expect(_rss().items.map((item) => item.title), [
        'Introducing a faster inference stack',
        'Escaped markup and comparisons',
      ]);
    });

    test('alanlar sözleşmeye taşınır', () {
      final item = _rss().items.first;

      expect(item.url, Uri.parse('https://openai.com/blog/faster-inference'));
      expect(item.kind, FeedItemKind.announcement);
      expect(item.sourceKind, FeedSourceKind.officialBlog);
      expect(item.sourceName, 'OpenAI Blog');
      expect(item.language, 'en', reason: 'en-US → en');
      expect(item.summaryOrigin, SummaryOrigin.original);
      expect(item.trust.officialSource, isTrue);
      expect(item.trust.recentlyUpdated, isTrue);
      expect(
        item.trust.hasLicense,
        isFalse,
        reason: 'blog yazısının lisansı yoktur',
      );
    });

    /// RSS 2.0 RFC 822 tarih kullanır; `DateTime.parse` bunu okuyamaz.
    test('RFC 822 tarihi çözülür', () {
      expect(_rss().items.first.publishedAt, DateTime.utc(2026, 7, 20, 10));
    });

    test('CDATA içindeki HTML düzleştirilir', () {
      expect(
        _rss().items.first.summary,
        'The new stack cuts latency for streaming responses. '
        'Read more about the rollout.',
      );
    });

    /// Karşılaştırma işareti etiket sanılıp metin yutulmamalı.
    test('kaçırılmış işaretleme çözülür, düz metin korunur', () {
      expect(
        _rss().items.last.summary,
        'Latency is now 1 < 2 seconds & throughput is up.',
      );
    });

    test('kategoriler tekilleştirilip küçük harfe iner', () {
      expect(_rss().items.first.topics, ['infrastructure', 'inference']);
    });

    /// Resmi bir beslemenin üçüncü tarafa verdiği link, allowlist'i dolanan
    /// bir arka kapı olurdu.
    test('besleme dışarı link verirse o kayıt alınmaz', () {
      final skipped = {
        for (final record in _rss().skipped) record.identifier: record.reason,
      };
      expect(skipped, {
        'A third-party write-up': SkipReason.notAllowed,
        'Post with no description': SkipReason.missingSummary,
      });
    });
  });

  group('Atom', () {
    test('yayımlanabilir kayıtlar alınır', () {
      expect(_atom().items.map((item) => item.title), [
        'Model context window doubled',
        'Documentation refresh',
      ]);
    });

    /// `rel="self"` beslemenin kendi adresidir, içerik değil.
    test('okunacak sayfa rel=alternate bağlantısıdır', () {
      expect(
        _atom().items.first.url,
        Uri.parse('https://www.anthropic.com/news/context-window'),
      );
    });

    test('feed başlığı ve dili kayda geçer', () {
      final item = _atom().items.first;
      expect(item.sourceName, 'Anthropic News');
      expect(item.language, 'en', reason: 'xml:lang="en"');
      expect(item.publishedAt, DateTime.utc(2026, 7, 24, 9));
      expect(item.topics, ['models']);
    });

    test('summary yoksa content kullanılır ve updated tarihe düşer', () {
      final item = _atom().items.last;
      expect(item.summary, 'The language tour was rewritten.');
      expect(item.publishedAt, DateTime.utc(2026, 7, 18, 15, 20));
    });

    /// Host bilgisi tek yerde: dokümantasyon, blogdan ayrılır.
    test('dokümantasyon hostu doğru türe düşer', () {
      expect(_atom().items.last.sourceKind, FeedSourceKind.documentation);
    });

    test('bağlantısız kayıt alınmaz', () {
      expect(_atom().skipped.single.reason, SkipReason.missingUrl);
    });
  });

  test('gövde XML değilse çalışma hata verir', () {
    expect(
      () => parseSyndicationFeed('{"json": true}', checkedAt: _checkedAt),
      throwsA(isA<ConnectorException>()),
    );
  });
}
