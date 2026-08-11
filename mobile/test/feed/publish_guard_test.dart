import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tecos/data/feed/feed_schema.dart';

import '../../tool/feed/publish_guard.dart';
import '../support/test_overrides.dart';

Feed feedWith(int count, {DateTime? generatedAt, String prefix = 'a'}) => Feed(
  schemaVersion: feedSchemaVersion,
  generatedAt: generatedAt ?? DateTime.utc(2026, 7, 28, 12),
  items: [
    for (var index = 0; index < count; index++)
      testFeedItem(
        id: '$prefix${index.toString().padLeft(15, '0')}',
        kind: FeedItemKind.announcement,
        title: 'Kayıt $index',
      ),
  ],
);

/// Üretici tek bir kaynak okunabildiği sürece dosya yazar. **Yayımlamak**
/// ayrı bir karar ve bu dosya o kararı ölçüyor.
void main() {
  test('ilk yayımda önceki yoksa yayımlanır', () {
    final verdict = evaluatePublish(next: feedWith(200));

    expect(verdict.shouldPublish, isTrue);
    expect(verdict.exitCode, 0);
  });

  test('boş feed hiçbir zaman yayımlanmaz', () {
    final verdict = evaluatePublish(next: feedWith(0), previous: feedWith(200));

    expect(verdict.decision, PublishDecision.empty);
    expect(verdict.isFailure, isTrue);
  });

  /// Önceki yokken bile boş dosya yayımlanmaz: ilk yayımın boş olması,
  /// üretimin çalıştığının değil çalışmadığının kanıtıdır.
  test('önceki yokken de boş feed yayımlanmaz', () {
    expect(evaluatePublish(next: feedWith(0)).isFailure, isTrue);
  });

  /// Asıl koruma bu. Ölçülen gerçek risk: 13 kaynağın çoğunun aynı anda
  /// düşmesi (ağ kesintisi, rate limit) ve 200 kayıtlık dosyanın yerine 15
  /// kayıtlık bir dosyanın geçmesi.
  test('kayıt sayısı çökerse yayımlanmaz', () {
    final verdict = evaluatePublish(
      next: feedWith(15, generatedAt: DateTime.utc(2026, 7, 28, 18)),
      previous: feedWith(200),
    );

    expect(verdict.decision, PublishDecision.collapsed);
    expect(verdict.message, contains('200 → 15'));
    expect(verdict.exitCode, 1);
  });

  /// Normal dalgalanma engellenmemeli: kaynakların bir kısmının o koşuda
  /// daha az kayıt döndürmesi olağan.
  test('normal dalgalanma engellenmez', () {
    final verdict = evaluatePublish(
      next: feedWith(150, generatedAt: DateTime.utc(2026, 7, 28, 18)),
      previous: feedWith(200),
    );

    expect(verdict.shouldPublish, isTrue);
  });

  test('eski damgalı dosya yayımdakinin üzerine yazmaz', () {
    final verdict = evaluatePublish(
      next: feedWith(200, generatedAt: DateTime.utc(2026, 7, 28, 6)),
      previous: feedWith(200, generatedAt: DateTime.utc(2026, 7, 28, 12)),
    );

    expect(verdict.decision, PublishDecision.notNewer);
  });

  /// Damga her koşuda değişir. Ona bakarak "değişti" demek, hiç değişmeyen
  /// bir feed'i her altı saatte bir yeniden yayımlamak olurdu.
  test('yalnız damga değiştiyse yayımlanmaz ama hata da değildir', () {
    final verdict = evaluatePublish(
      next: feedWith(200, generatedAt: DateTime.utc(2026, 7, 28, 18)),
      previous: feedWith(200, generatedAt: DateTime.utc(2026, 7, 28, 12)),
    );

    expect(verdict.decision, PublishDecision.unchanged);
    expect(verdict.isFailure, isFalse);
    expect(verdict.exitCode, 3);
  });

  test('kayıtlar değiştiyse yayımlanır', () {
    final verdict = evaluatePublish(
      next: feedWith(
        200,
        generatedAt: DateTime.utc(2026, 7, 28, 18),
        prefix: 'b',
      ),
      previous: feedWith(200),
    );

    expect(verdict.shouldPublish, isTrue);
  });

  /// Üç çıkış kodu üç farklı davranışı temsil ediyor ve zamanlayıcı bunlara
  /// göre dallanıyor; karışmaları sessiz bir yayım hatası olurdu.
  test('çıkış kodları ayrışır', () {
    expect(evaluatePublish(next: feedWith(10)).exitCode, 0);
    expect(
      evaluatePublish(
        next: feedWith(10, generatedAt: DateTime.utc(2026, 7, 28, 18)),
        previous: feedWith(10),
      ).exitCode,
      3,
    );
    expect(
      evaluatePublish(next: feedWith(0), previous: feedWith(10)).exitCode,
      1,
    );
  });

  /// Komut satırı arayüzü.
  ///
  /// İş akışı `case "$status" in 0|3|*` ile dallanıyor; yani saf karar
  /// fonksiyonunu ölçmek yetmez, **CLI'nin** doğru kodu döndürdüğü de
  /// ölçülmeli. Dosya okuma hataları da buradan geçiyor.
  group('CLI', () {
    late Directory workspace;

    setUp(
      () => workspace = Directory.systemTemp.createTempSync('publish_guard'),
    );
    tearDown(() => workspace.deleteSync(recursive: true));

    String write(String name, Feed feed) {
      final path = '${workspace.path}/$name';
      File(path).writeAsStringSync(jsonEncode(feed.toJson()));
      return path;
    }

    test('önceki verilmezse yayımlar', () {
      expect(run(['--next', write('next.json', feedWith(200))]), 0);
    });

    /// İlk koşuda dosya yok; indirme başarısız olduğunda da yok ya da boş
    /// kalıyor. İkisi de "karşılaştıracak bir şey yok" demek, "bozuk" değil.
    test('önceki dosya yoksa yayımı engellemez', () {
      expect(
        run([
          '--next',
          write('next.json', feedWith(200)),
          '--previous',
          '${workspace.path}/yok.json',
        ]),
        0,
      );
    });

    test('önceki dosya boşsa yayımı engellemez', () {
      final empty = '${workspace.path}/bos.json';
      File(empty).writeAsStringSync('');

      expect(
        run(['--next', write('next.json', feedWith(200)), '--previous', empty]),
        0,
      );
    });

    test('çökme reddedilir', () {
      expect(
        run([
          '--next',
          write(
            'next.json',
            feedWith(15, generatedAt: DateTime.utc(2026, 7, 28, 18)),
          ),
          '--previous',
          write('previous.json', feedWith(200)),
        ]),
        1,
      );
    });

    test('değişmemiş içerik 3 döndürür', () {
      expect(
        run([
          '--next',
          write(
            'next.json',
            feedWith(200, generatedAt: DateTime.utc(2026, 7, 28, 18)),
          ),
          '--previous',
          write('previous.json', feedWith(200)),
        ]),
        3,
      );
    });

    test('--next verilmezse hata', () {
      expect(run(const []), 1);
    });
  });
}
