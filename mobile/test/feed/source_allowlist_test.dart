import 'package:flutter_test/flutter_test.dart';

import '../../tool/feed/source_allowlist.dart';

void main() {
  group('allowlist kapalı bir listedir', () {
    test('listede olmayan host reddedilir', () {
      for (final url in [
        'https://medium.com/@biri/yazi',
        'https://twitter.com/biri/status/1',
        'https://rastgele-blog.test/haber',
        'https://reddit.com/r/MachineLearning',
      ]) {
        expect(
          SourceAllowlist.isAllowed(Uri.parse(url)),
          isFalse,
          reason: '$url allowlist dışı olmalı',
        );
      }
    });

    test('resmi kaynaklar ve platformlar kabul edilir', () {
      for (final url in [
        'https://openai.com/blog/duyuru',
        'https://www.anthropic.com/news/duyuru',
        'https://github.com/biri/depo',
        'https://huggingface.co/nexus/Nexus-7B',
        'https://dart.dev/guides',
      ]) {
        expect(
          SourceAllowlist.isAllowed(Uri.parse(url)),
          isTrue,
          reason: '$url kabul edilmeli',
        );
      }
    });

    test('alt alan adları resmi hosta bağlıysa kabul edilir', () {
      expect(
        SourceAllowlist.isAllowed(Uri.parse('https://blog.pytorch.org/yazi')),
        isTrue,
      );
    });

    /// Benzer görünen ama farklı bir alan adı sızmamalı.
    test('sahte alan adı reddedilir', () {
      for (final url in [
        'https://openai.com.kotu.test/duyuru',
        'https://notopenai.com/duyuru',
        'https://github.com.evil.test/depo',
      ]) {
        expect(
          SourceAllowlist.isAllowed(Uri.parse(url)),
          isFalse,
          reason: '$url reddedilmeli',
        );
      }
    });

    test('https olmayan adres reddedilir', () {
      expect(
        SourceAllowlist.isAllowed(Uri.parse('http://openai.com/blog/duyuru')),
        isFalse,
      );
    });
  });

  group('resmi kaynak ayrımı', () {
    /// GitHub bir depoyu yayımlamaz, barındırır: resmilik **sahibe** bakar.
    test('platformda sahibi kuruma ait olan depo resmidir', () {
      expect(
        SourceAllowlist.isOfficial(
          Uri.parse('https://github.com/anthropics/x'),
        ),
        isTrue,
      );
      expect(
        SourceAllowlist.isOfficial(
          Uri.parse('https://huggingface.co/meta-llama/Llama-3'),
        ),
        isTrue,
      );
    });

    test('platformda üçüncü tarafa ait depo resmi değildir', () {
      expect(
        SourceAllowlist.isOfficial(Uri.parse('https://github.com/biri/depo')),
        isFalse,
      );
      expect(
        SourceAllowlist.isOfficial(
          Uri.parse('https://huggingface.co/biri/model'),
        ),
        isFalse,
      );
    });

    test('kurumun kendi alan adı resmidir', () {
      expect(
        SourceAllowlist.isOfficial(Uri.parse('https://openai.com/blog/x')),
        isTrue,
      );
    });

    test('allowlist dışı host resmi değildir', () {
      expect(
        SourceAllowlist.isOfficial(Uri.parse('https://medium.com/@biri/x')),
        isFalse,
      );
    });
  });

  group('RSS listesi', () {
    /// Feed listesi allowlist'i dolanmanın arka kapısı olmamalı.
    test('her resmi feed allowlist içindedir', () {
      for (final feed in officialFeeds) {
        final url = Uri.parse(feed);
        expect(
          SourceAllowlist.isAllowed(url),
          isTrue,
          reason: '$feed allowlist dışında',
        );
        expect(
          SourceAllowlist.isOfficial(url),
          isTrue,
          reason: '$feed resmi sayılmıyor',
        );
      }
    });

    test('feed listesinde kopya yok', () {
      expect(officialFeeds.toSet(), hasLength(officialFeeds.length));
    });
  });

  test('ayıklananlar raporlanabilir', () {
    final rejected = SourceAllowlist.rejected([
      Uri.parse('https://github.com/biri/depo'),
      Uri.parse('https://medium.com/@biri/yazi'),
    ]).toList();
    expect(rejected, hasLength(1));
    expect(rejected.single.host, 'medium.com');
  });
}
