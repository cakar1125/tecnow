import 'package:flutter_test/flutter_test.dart';
import 'package:teknoakis/data/feed/feed_schema.dart';

import '../../../tool/feed/connectors/connector_support.dart';
import '../../../tool/feed/connectors/github.dart';
import '../fixtures.dart';

final _checkedAt = DateTime.utc(2026, 7, 27);

ConnectorResult _repositories() => parseGitHubRepositories(
  feedFixture('github_repositories.json'),
  checkedAt: _checkedAt,
);

ConnectorResult _releases() => parseGitHubReleases(
  feedFixture('github_releases.json'),
  checkedAt: _checkedAt,
);

FeedItem _byTitle(ConnectorResult result, String title) =>
    result.items.firstWhere((item) => item.title == title);

void main() {
  group('depo listesi', () {
    test('yayımlanabilir kayıtlar alınır', () {
      final result = _repositories();
      expect(result.items.map((item) => item.title), [
        'anthropics/claude-code',
        'modelcontextprotocol/servers',
        'birisi/awesome-claude-skills',
        'birisi/eski-arac',
        'birisi/sinyalsiz-depo',
      ]);
    });

    test('alanlar sözleşmeye taşınır', () {
      final item = _byTitle(_repositories(), 'anthropics/claude-code');

      expect(item.url, Uri.parse('https://github.com/anthropics/claude-code'));
      expect(item.id, feedItemId(item.url));
      expect(item.kind, FeedItemKind.repository);
      expect(item.sourceKind, FeedSourceKind.github);
      expect(item.sourceName, 'GitHub');
      expect(
        item.summary,
        'Claude Code is an agentic coding tool that lives in your terminal.',
      );
      expect(
        item.summaryOrigin,
        SummaryOrigin.original,
        reason: 'depo açıklaması kaynağın kendi metnidir',
      );
      expect(item.language, 'en');
      expect(item.publishedAt, DateTime.utc(2026, 2, 10, 9, 15));
      expect(item.checkedAt, _checkedAt);
      expect(item.topics, ['cli', 'agents', 'developer-tools']);
    });

    test('açıklamanın baştaki ve sondaki boşluğu atılır', () {
      final item = _byTitle(_repositories(), 'birisi/awesome-claude-skills');
      expect(item.summary, 'A curated list of Claude skills.');
    });
  });

  group('güven sinyalleri', () {
    test('kurumun kendi deposu resmi sayılır', () {
      final item = _byTitle(_repositories(), 'anthropics/claude-code');
      expect(item.trust.officialSource, isTrue);
      expect(item.trust.hasLicense, isTrue);
      expect(item.trust.maintained, isTrue);
      expect(item.trust.recentlyUpdated, isTrue);
      expect(item.trust.popularity, 31240);
      expect(item.trust.score, 100);
    });

    test('üçüncü tarafın deposu resmi sayılmaz', () {
      final item = _byTitle(_repositories(), 'birisi/awesome-claude-skills');
      expect(item.trust.officialSource, isFalse);
      expect(
        item.trust.hasLicense,
        isFalse,
        reason: 'license alanı null geldi',
      );
    });

    /// Popülerlik tek başına güven değildir: arşivlenmiş bir depo, yıldızı ne
    /// olursa olsun bakımlı sayılmamalı.
    test('arşivlenmiş depo bakımsızdır ve güncel değildir', () {
      final item = _byTitle(_repositories(), 'birisi/eski-arac');
      expect(item.trust.maintained, isFalse);
      expect(item.trust.recentlyUpdated, isFalse);
      expect(item.trust.score, 15, reason: 'yalnız lisans puanı kalır');
    });
  });

  group('tür çıkarımı', () {
    /// Skill ve MCP için dizin API'si yok; tür deponun kendi konularından
    /// çıkarılır, addan ya da açıklamadan tahmin edilmez.
    test('konular MCP diyorsa tür mcp olur', () {
      expect(
        _byTitle(_repositories(), 'modelcontextprotocol/servers').kind,
        FeedItemKind.mcp,
      );
    });

    test('konular skill diyorsa tür skill olur', () {
      expect(
        _byTitle(_repositories(), 'birisi/awesome-claude-skills').kind,
        FeedItemKind.skill,
      );
    });

    test('eşleşme yoksa tür repository kalır', () {
      expect(
        _byTitle(_repositories(), 'anthropics/claude-code').kind,
        FeedItemKind.repository,
      );
      expect(
        _byTitle(_repositories(), 'birisi/eski-arac').kind,
        FeedItemKind.repository,
      );
    });
  });

  group('elenen kayıtlar', () {
    test('sebepleriyle birlikte raporlanır', () {
      final skipped = {
        for (final record in _repositories().skipped)
          record.identifier: record.reason,
      };
      expect(skipped, {
        'birisi/aciklamasiz': SkipReason.missingSummary,
        'birisi/gizli': SkipReason.private,
        '<kayıt>': SkipReason.malformed,
      });
    });

    /// Tek bozuk kayıt tüm çalışmayı düşürmemeli.
    test('bozuk kayıt diğerlerini etkilemez', () {
      expect(_repositories().items, hasLength(5));
    });

    /// Yanıt gövdesine güvenilmez: adres allowlist'ten geçmeden feed'e giremez.
    test('allowlist dışı adres alınmaz', () {
      final result = parseGitHubRepositories('''
        {"items": [{
          "full_name": "birisi/depo",
          "html_url": "https://gitlab.example.test/birisi/depo",
          "description": "Bir depo.",
          "created_at": "2026-07-01T00:00:00Z"
        }]}
      ''', checkedAt: _checkedAt);

      expect(result.items, isEmpty);
      expect(result.skipped.single.reason, SkipReason.notAllowed);
    });

    test('gövde bozuksa çalışma hata verir, sessizce boşalmaz', () {
      expect(
        () => parseGitHubRepositories('<html>', checkedAt: _checkedAt),
        throwsA(isA<ConnectorException>()),
      );
      expect(
        () => parseGitHubRepositories(
          '{"message": "rate limited"}',
          checkedAt: _checkedAt,
        ),
        throwsA(isA<ConnectorException>()),
      );
    });
  });

  group('sürüm listesi', () {
    test('yayımlanmış sürüm duyuruya dönüşür', () {
      final item = _releases().items.single;

      expect(item.title, 'flutter/flutter 3.44.8');
      expect(item.kind, FeedItemKind.announcement);
      expect(item.trust.officialSource, isTrue);
      expect(item.publishedAt, DateTime.utc(2026, 7, 15, 14));
      expect(
        item.summary,
        'The release of the Flutter 3.44 hotfix contains the changes noted '
        'below. To try it out run:',
        reason:
            'değişiklik günlüğünün ilk 320 karakteri özet değildir; yalnız '
            'kaynağın kendi giriş paragrafı alınır',
      );
      expect(
        item.trust.hasLicense,
        isFalse,
        reason: 'sürüm yanıtı lisans taşımaz; bilinmeyen "var" sayılmaz',
      );
    });

    test('taslak sürüm alınmaz', () {
      final skipped = _releases().skipped;
      expect(
        skipped.map((record) => record.reason),
        containsAll([SkipReason.draft, SkipReason.missingSummary]),
      );
      expect(
        skipped.firstWhere((r) => r.reason == SkipReason.draft).identifier,
        '3.45.0-beta',
      );
    });
  });
}
