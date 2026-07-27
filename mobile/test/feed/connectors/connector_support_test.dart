import 'package:flutter_test/flutter_test.dart';

import '../../../tool/feed/connectors/connector_support.dart';

void main() {
  group('tarih çözme', () {
    test('ISO-8601 okunur ve UTC\'ye çevrilir', () {
      expect(
        parseFeedDate('2026-07-20T13:00:00+03:00'),
        DateTime.utc(2026, 7, 20, 10),
      );
      expect(
        parseFeedDate('2026-07-20T10:00:00Z'),
        DateTime.utc(2026, 7, 20, 10),
      );
    });

    /// RSS 2.0 RFC 822 kullanır; `DateTime.parse` bu biçimi bilmez.
    test('RFC 822 okunur', () {
      expect(
        parseFeedDate('Mon, 20 Jul 2026 10:00:00 GMT'),
        DateTime.utc(2026, 7, 20, 10),
      );
      expect(
        parseFeedDate('20 Jul 2026 10:00:00 +0000'),
        DateTime.utc(2026, 7, 20, 10),
        reason: 'gün adı zorunlu değildir',
      );
      expect(
        parseFeedDate('Tue, 21 Jul 2026 08:30:00 +0300'),
        DateTime.utc(2026, 7, 21, 5, 30),
      );
      expect(
        parseFeedDate('Sat, 01 Jan 2000 00:00:00 -0500'),
        DateTime.utc(2000, 1, 1, 5),
      );
      expect(
        parseFeedDate('Mon, 20 Jul 26 10:00:00 GMT'),
        DateTime.utc(2026, 7, 20, 10),
        reason: 'RFC 822 iki haneli yıla izin verir',
      );
    });

    test('okunamayan değer null döner', () {
      expect(parseFeedDate(null), isNull);
      expect(parseFeedDate(''), isNull);
      expect(parseFeedDate('yakında'), isNull);
      expect(parseFeedDate('Mon, 20 Foo 2026 10:00:00 GMT'), isNull);
    });
  });

  group('metin düzleştirme', () {
    test('HTML etiketleri atılır', () {
      expect(stripHtml('<p>Merhaba <b>dünya</b></p>'), 'Merhaba dünya');
    });

    /// İki ayrı hata: etiketi silmek kelimeleri yapıştırır, boşlukla
    /// değiştirmek noktalamayı iter. İkisi de kilitli.
    test('kelimeler yapışmaz, noktalama itilmez', () {
      expect(stripHtml('<p>Bir</p><p>İki</p>'), 'Bir İki');
      expect(stripHtml('the <a href="#">rollout</a>.'), 'the rollout.');
    });

    test('varlıklar çözülür', () {
      expect(stripHtml('Yeni &amp; hızlı&hellip;'), 'Yeni & hızlı…');
      expect(stripHtml('&#39;tırnak&#x27;'), "'tırnak'");
    });

    /// Etiket kalıbı dar tutulur: `<` işaretinden sonra harf şarttır.
    /// Aksi hâlde "1 < 2 ve 3 > 4" metninin ortası silinirdi.
    test('karşılaştırma işareti etiket sanılmaz', () {
      expect(stripHtml('1 &lt; 2 ve 3 &gt; 4'), '1 < 2 ve 3 > 4');
    });

    test('boşluklar teke iner', () {
      expect(normalizeSpaces('  iki\n\n satır  '), 'iki satır');
    });
  });

  group('özet kısaltma', () {
    test('sınırın altındaki metne dokunulmaz', () {
      expect(truncateSummary('kısa metin'), 'kısa metin');
    });

    test('kelime ortasından kesilmez', () {
      final summary = truncateSummary(List.filled(80, 'kelime').join(' '));
      expect(summary.endsWith('…'), isTrue);
      expect(summary.length, lessThanOrEqualTo(321));
      expect(summary, endsWith('kelime…'));
    });
  });

  group('zaman penceresi', () {
    final reference = DateTime.utc(2026, 7, 27);

    test('pencere içi', () {
      expect(
        isWithin(DateTime.utc(2026, 7, 1), reference, recentWindow),
        isTrue,
      );
    });

    test('pencere dışı', () {
      expect(
        isWithin(DateTime.utc(2025, 1, 1), reference, recentWindow),
        isFalse,
      );
    });

    /// Kaynak saat farkıyla birkaç saat ileri tarih verebilir; bu, yeni
    /// yayımlanmış içeriği eskitmemeli.
    test('gelecek tarih içeride sayılır', () {
      expect(
        isWithin(DateTime.utc(2026, 7, 28), reference, recentWindow),
        isTrue,
      );
    });
  });

  test('bağlayıcı sonuçları birleştirilebilir', () {
    final combined = ConnectorResult.combine([
      const ConnectorResult(skipped: [SkippedRecord('a', SkipReason.private)]),
      const ConnectorResult(skipped: [SkippedRecord('b', SkipReason.draft)]),
    ]);
    expect(combined.items, isEmpty);
    expect(combined.skipped.map((r) => r.identifier), ['a', 'b']);
  });
}
