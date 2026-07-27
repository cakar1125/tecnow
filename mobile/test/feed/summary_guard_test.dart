import 'package:flutter_test/flutter_test.dart';

import '../../tool/feed/summary_guard.dart';

/// Kaynakta rakamla geçmeyen hiçbir sayı özete giremez.
///
/// Dikkat: burada **yayın tarihi yok**. Kapının sözleşmesi gereği tarih,
/// kimlik ve yıldız gibi makine alanları kaynak metne katılmaz — katılsaydı
/// tarihin rakamları izin verilen sayı havuzuna girer ve uydurulmuş bir fiyat
/// kapıdan geçerdi.
const _source = '''
Nexus-7B is an open weights language model.
It has 7 billion parameters and scores 71.4 on the MMLU benchmark.
Docs: https://example.test/nexus/docs
''';

void main() {
  group('kabul', () {
    test('kaynaktaki sayıları kullanan özet geçer', () {
      const summary =
          'Nexus-7B açık ağırlıklı bir dil modeli; 7 milyar parametreli ve '
          'MMLU üzerinde 71.4 puan alıyor.';
      expect(
        verifySummary(summary: summary, sourceText: _source).isAccepted,
        isTrue,
      );
    });

    test('hiç sayı içermeyen özet geçer', () {
      const summary =
          'Açık ağırlıklı bir dil modeli; dokümantasyonu yayımlandı.';
      expect(
        verifySummary(summary: summary, sourceText: _source).isAccepted,
        isTrue,
      );
    });

    test('kaynaktaki bağlantı özete konabilir', () {
      const summary = 'Ayrıntılar: https://example.test/nexus/docs';
      expect(
        verifySummary(summary: summary, sourceText: _source).isAccepted,
        isTrue,
      );
    });
  });

  group('ret — uydurulmuş sayı', () {
    test('kaynakta olmayan benchmark puanı reddedilir', () {
      const summary = 'Model MMLU üzerinde 82.9 puan alıyor.';
      final verdict = verifySummary(summary: summary, sourceText: _source);
      expect(verdict.isAccepted, isFalse);
      expect(verdict.rejection, SummaryRejection.unsourcedNumber);
      expect(verdict.detail, '829');
    });

    test('kaynakta olmayan fiyat reddedilir', () {
      const summary = 'Aylık 20 dolara sunuluyor.';
      final verdict = verifySummary(summary: summary, sourceText: _source);
      expect(verdict.rejection, SummaryRejection.unsourcedNumber);
      expect(verdict.detail, '20');
    });

    /// Bu test kapının sözleşmesini korur: tarih kaynak metne karışırsa
    /// rakamları izin verilen havuza girer ve uydurulmuş fiyat geçer.
    test('tarih kaynak metne katılırsa uydurulmuş fiyat sızar', () {
      const withDate = '$_source\nReleased on 2026-07-20.';
      expect(
        verifySummary(
          summary: 'Aylık 20 dolara sunuluyor.',
          sourceText: withDate,
        ).isAccepted,
        isTrue,
        reason:
            'kapı bunu yakalayamaz; bu yüzden çağıran tarihi kaynak metne '
            'koymamalıdır',
      );
    });

    test('kaynakta olmayan parametre sayısı reddedilir', () {
      const summary = '13 milyar parametreli bir model.';
      final verdict = verifySummary(summary: summary, sourceText: _source);
      expect(verdict.rejection, SummaryRejection.unsourcedNumber);
      expect(verdict.detail, '13');
    });
  });

  group('ret — diğer', () {
    test('boş özet reddedilir', () {
      expect(
        verifySummary(summary: '   ', sourceText: _source).rejection,
        SummaryRejection.empty,
      );
    });

    test('çok uzun özet reddedilir', () {
      final summary = 'a' * (summaryMaxLength + 1);
      final verdict = verifySummary(summary: summary, sourceText: _source);
      expect(verdict.rejection, SummaryRejection.tooLong);
    });

    test('kaynakta olmayan bağlantı reddedilir', () {
      const summary = 'Ayrıntılar: https://baska-site.test/sayfa';
      final verdict = verifySummary(summary: summary, sourceText: _source);
      expect(verdict.rejection, SummaryRejection.unsourcedLink);
      expect(verdict.detail, 'https://baska-site.test/sayfa');
    });
  });

  group('sayı normalleştirme', () {
    test('ondalık ayracı biçimi eşleşmeyi bozmaz', () {
      // Kaynak 71.4, özet 71,4 yazıyor: aynı sayı.
      const summary = 'MMLU 71,4.';
      expect(
        verifySummary(summary: summary, sourceText: _source).isAccepted,
        isTrue,
      );
    });

    test('binlik ayracı eşleşmeyi bozmaz', () {
      expect(
        verifySummary(
          summary: '1.000 indirme.',
          sourceText: 'downloaded 1000 times',
        ).isAccepted,
        isTrue,
      );
    });

    test('cümle sonu noktası sayıya karışmaz', () {
      expect(extractNumbers('sürüm 2.'), {'2'});
    });

    test('baştaki sıfırlar atılır', () {
      expect(extractNumbers('007'), {'7'});
    });

    test('tarih parçaları ayrı ayrı sayı sayılır', () {
      expect(extractNumbers('2026-07-20'), {'2026', '7', '20'});
    });
  });

  /// Bilinen ve kabul edilen yanlış-pozitif: kaynak sayıyı yazıyla yazarsa
  /// özet reddedilir ve kayıt orijinal metinle yayımlanır. Ters yönde hata
  /// yapmaktansa (uydurulmuş sayıyı yayımlamak) bu yeğdir.
  test('kaynakta yazıyla geçen sayı rakamla yazılırsa reddedilir', () {
    final verdict = verifySummary(
      summary: '7 milyar parametre.',
      sourceText: 'It has seven billion parameters.',
    );
    expect(verdict.rejection, SummaryRejection.unsourcedNumber);
  });
}
