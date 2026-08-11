import 'package:flutter_test/flutter_test.dart';
import 'package:tecos/ui/turkish_case.dart';

void main() {
  /// Kusurun kendisi: `toUpperCase()` `i`'yi `I` yapıyor. Bu kelimeler
  /// Ana Sayfa'nın sekme şeridinde görünüyor.
  group('varsayılan büyütmenin bozduğu kelimeler', () {
    const cases = {
      'Mobil': 'MOBİL',
      'Veri Bilimi': 'VERİ BİLİMİ',
      'Siber Güvenlik': 'SİBER GÜVENLİK',
    };

    cases.forEach((input, expected) {
      test('"$input" → "$expected"', () {
        expect(toUpperCaseTr(input), expected);
        expect(
          input.toUpperCase(),
          isNot(expected),
          reason:
              'bu satır kusuru kanıtlıyor — geçerse Dart davranışı değişmiş '
              've yardımcı gereksizleşmiş demektir',
        );
      });
    });
  });

  /// Düzeltme yalnız `i`'ye dokunmalı. `ı → I`, `ş → Ş`, `â → Â` zaten doğru
  /// çalışıyor ve bir "düzeltme" onları bozabilirdi.
  group('doğru çalışan harfler bozulmaz', () {
    const cases = {
      'Donanım': 'DONANIM',
      'Açık Kaynak': 'AÇIK KAYNAK',
      'Yapay Zekâ': 'YAPAY ZEKÂ',
      'Oyun': 'OYUN',
      'ığüşöç': 'IĞÜŞÖÇ',
    };

    cases.forEach((input, expected) {
      test('"$input" → "$expected"', () {
        expect(toUpperCaseTr(input), expected);
      });
    });
  });

  test('zaten büyük metin değişmez', () {
    expect(toUpperCaseTr('TÜMÜ'), 'TÜMÜ');
    expect(toUpperCaseTr('İSTANBUL'), 'İSTANBUL');
  });

  test('boş metin ve rakamlar', () {
    expect(toUpperCaseTr(''), '');
    expect(toUpperCaseTr('gpt-4 · 2026'), 'GPT-4 · 2026');
  });

  /// Katlama **ayrı** kalmalı: arama `İ` ile `I`'yı aynı harfe indiriyor,
  /// görünen metin indirmemeli. İkisi tek işlevde birleşirse biri bozulur.
  test('büyütme aksanları düşürmez', () {
    expect(toUpperCaseTr('Zekâ'), 'ZEKÂ');
    expect(toUpperCaseTr('Güvenlik'), contains('Ü'));
  });
}
