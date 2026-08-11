import 'package:flutter_test/flutter_test.dart';
import 'package:tecos/data/feed/feed_endpoint.dart';

void main() {
  group('parseFeedEndpoint', () {
    test('geçerli https adresi kabul edilir', () {
      final url = parseFeedEndpoint('https://ornek.test/feed.json');

      expect(url, isNotNull);
      expect(url!.host, 'ornek.test');
      expect(url.path, '/feed.json');
    });

    test('baştaki ve sondaki boşluklar kırpılır', () {
      // Derleme betiğinden gelen bir değerin sonunda satır sonu kalabilir.
      expect(
        parseFeedEndpoint('  https://ornek.test/feed.json\n'),
        Uri.https('ornek.test', '/feed.json'),
      );
    });

    /// Güvenlik davranışı: düz metin bir feed, aradaki herhangi bir ağın
    /// içeriği değiştirebilmesi demektir.
    test('http reddedilir', () {
      expect(parseFeedEndpoint('http://ornek.test/feed.json'), isNull);
    });

    test('https dışındaki şemalar reddedilir', () {
      for (final raw in [
        'file:///sdcard/feed.json',
        'ftp://ornek.test/feed.json',
        'javascript:alert(1)',
        'content://media/feed.json',
      ]) {
        expect(parseFeedEndpoint(raw), isNull, reason: '$raw reddedilmeli');
      }
    });

    test('adres yoksa null döner — ağ tazelemesi kapalıdır', () {
      expect(parseFeedEndpoint(''), isNull);
      expect(parseFeedEndpoint('   '), isNull);
    });

    /// Yanlış yazılmış bir derleme bayrağı uygulamayı çökertmez: adres yok
    /// sayılır ve paketlenmiş içerikle devam edilir.
    ///
    /// Kapsam bilinçli olarak dar — şema ve host'un **varlığı**. Host'un
    /// biçimi denetlenmez: yarım yamalak bir düzenli ifade, geçerli IDN ve
    /// IPv6 adreslerini de reddederdi. Ulaşılamayan bir host zaten ilk
    /// denemede taşıma hatası olarak görünür.
    test('şemasız veya hostsuz değerler null üretir', () {
      for (final raw in ['https://', 'ornek.test/feed.json', 'https:///yol']) {
        expect(parseFeedEndpoint(raw), isNull, reason: '$raw reddedilmeli');
      }
    });

    /// Varsayılan **yoktur**. Barındırma kararı verilmeden bir adres
    /// gömülseydi, uygulama var olmayan bir sunucuya istek atardı.
    test('derleme bayrağı verilmediğinde varsayılan adres yoktur', () {
      expect(feedUrlFromEnvironment, isEmpty);
      expect(parseFeedEndpoint(feedUrlFromEnvironment), isNull);
    });
  });

  group('parseFeedEndpoints', () {
    const primary = 'https://feed.ornek.test/feed.json';
    const mirror = 'https://ayna.github.io/depo/feed.json';

    test('sıra korunur: önce birincil, sonra yedek', () {
      expect(parseFeedEndpoints(primary, mirror), [
        Uri.parse(primary),
        Uri.parse(mirror),
      ]);
    });

    /// Yedek verilmediğinde davranış, yedek kavramı hiç yokken olduğu gibi
    /// kalmalı: tek adres, tek deneme.
    test('yedek verilmediğinde tek adres kalır', () {
      expect(parseFeedEndpoints(primary, ''), [Uri.parse(primary)]);
    });

    test('ikisi de yoksa liste boştur — ağ tazelemesi kapalıdır', () {
      expect(parseFeedEndpoints('', ''), isEmpty);
    });

    /// Yanlış yazılmış bir birincil, çalışabilecek bir yedeği de kapatmamalı.
    test('geçersiz birincil atlanır, yedek tek başına kullanılır', () {
      expect(parseFeedEndpoints('http://ornek.test/feed.json', mirror), [
        Uri.parse(mirror),
      ]);
    });

    test('geçersiz yedek sessizce atlanır', () {
      expect(parseFeedEndpoints(primary, 'javascript:alert(1)'), [
        Uri.parse(primary),
      ]);
    });

    /// Aynı adres iki kez verilirse çöken bir sunucuya arka arkaya iki istek
    /// atılırdı.
    test('aynı adres iki kez denenmez', () {
      expect(parseFeedEndpoints(primary, ' $primary '), [Uri.parse(primary)]);
    });

    test('derleme bayrakları verilmediğinde liste boştur', () {
      expect(feedFallbackUrlFromEnvironment, isEmpty);
      expect(
        parseFeedEndpoints(
          feedUrlFromEnvironment,
          feedFallbackUrlFromEnvironment,
        ),
        isEmpty,
      );
    });
  });
}
