import 'package:flutter_test/flutter_test.dart';
import 'package:teknoakis/data/feed/feed_endpoint.dart';

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
}
