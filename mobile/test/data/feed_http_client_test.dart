import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tecos/data/feed/feed_http_client.dart';

void main() {
  group('resolveRedirect', () {
    final secure = Uri.https('ornek.test', '/feed.json');

    /// Güvenlik davranışı: `HttpClient` yönlendirmeleri kendi takip eder ama
    /// şema düşüşünü engellemez. `https` ile başlayan bir isteğin `http`'ye
    /// düşmesi, içeriğin aradaki ağ tarafından değiştirilebilmesi demektir —
    /// bu uygulamanın bütün güven anlatısı içeriğin denetlenmiş bir hattan
    /// gelmesine dayanıyor.
    test('https bir isteği http hedefine düşüremez', () {
      expect(resolveRedirect(secure, 'http://ornek.test/feed.json'), isNull);
      expect(resolveRedirect(secure, 'http://baska.test/feed.json'), isNull);
    });

    test('https hedefi izlenir', () {
      expect(
        resolveRedirect(secure, 'https://cdn.ornek.test/v2/feed.json'),
        Uri.https('cdn.ornek.test', '/v2/feed.json'),
      );
    });

    test('göreli adres kaynak adrese göre çözülür', () {
      expect(
        resolveRedirect(secure, '/v2/feed.json'),
        Uri.https('ornek.test', '/v2/feed.json'),
      );
    });

    /// Yükselme serbest: http ile başlayan bir istek https'ye çıkabilir.
    test('http bir istek https hedefine yükselebilir', () {
      expect(
        resolveRedirect(
          Uri.parse('http://ornek.test/feed.json'),
          'https://ornek.test/feed.json',
        ),
        Uri.https('ornek.test', '/feed.json'),
      );
    });

    test('http dışı şemalar hiçbir koşulda izlenmez', () {
      for (final location in [
        'file:///sdcard/feed.json',
        'ftp://ornek.test/feed.json',
        'javascript:alert(1)',
      ]) {
        expect(
          resolveRedirect(secure, location),
          isNull,
          reason: '$location izlenmemeli',
        );
      }
    });

    test('eksik veya boş Location reddedilir', () {
      expect(resolveRedirect(secure, null), isNull);
      expect(resolveRedirect(secure, '   '), isNull);
    });
  });

  group('gerçek HTTP', () {
    /// Ağa çıkmaz: 127.0.0.1'de kendi sunucumuzu açıp gerçek `HttpClient`
    /// yolunu ölçeriz. Saf fonksiyonlar başlıkların **kabloya** yazıldığını
    /// ya da gövde sınırının gerçekten uygulandığını gösteremez.
    late HttpServer server;
    late List<String?> seenUserAgents;

    Uri url(String path) => Uri.parse('http://127.0.0.1:${server.port}$path');

    setUp(() async {
      seenUserAgents = [];
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        seenUserAgents.add(request.headers.value(HttpHeaders.userAgentHeader));
        final response = request.response;
        switch (request.uri.path) {
          case '/feed.json':
            response.write('{"ok": true}');
          case '/yok':
            response.statusCode = 404;
            response.write('bulunamadi');
          case '/tasi':
            response.statusCode = 302;
            response.headers.set(HttpHeaders.locationHeader, '/feed.json');
          case '/dongu':
            response.statusCode = 302;
            response.headers.set(HttpHeaders.locationHeader, '/dongu');
          case '/dusur':
            // Yerel sunucu https konuşamaz; şema düşüşü `resolveRedirect`
            // testlerinde ölçülüyor. Buradaki hedef izlenemeyen bir şema.
            response.statusCode = 302;
            response.headers.set(
              HttpHeaders.locationHeader,
              'ftp://ornek.test/feed.json',
            );
          case '/asili':
            // Bağlantı kabul edilir ama yanıt hiç kapatılmaz.
            return;
          case '/buyuk':
            response.write('x' * 4096);
          case '/akan':
            // Content-Length **bildirmeyen** gövde: boyut ancak akış
            // ilerledikçe anlaşılır.
            response.headers.chunkedTransferEncoding = true;
            for (var chunk = 0; chunk < 8; chunk++) {
              response.write('x' * 512);
            }
          default:
            response.statusCode = 500;
        }
        await response.close();
      });
    });

    tearDown(() => server.close(force: true));

    test('gövde ve durum kodu okunur', () async {
      final response = await IoFeedHttpClient().get(url('/feed.json'));

      expect(response.statusCode, 200);
      expect(response.body, '{"ok": true}');
      expect(response.isOk, isTrue);
      expect(seenUserAgents.single, 'tecOS');
    });

    /// Hata kodu istisna değil: çağıran taraf bunu "içerik değişmedi" olarak
    /// ele alır ve önbellekteki kopyayı göstermeye devam eder.
    test('404 sonuç olarak döner', () async {
      final response = await IoFeedHttpClient().get(url('/yok'));

      expect(response.statusCode, 404);
      expect(response.isOk, isFalse);
    });

    test('kabul edilebilir yönlendirme izlenir', () async {
      final response = await IoFeedHttpClient().get(url('/tasi'));

      expect(response.body, '{"ok": true}');
      expect(seenUserAgents, hasLength(2));
    });

    test('kabul edilmeyen yönlendirme hata verir', () async {
      await expectLater(
        IoFeedHttpClient().get(url('/dusur')),
        throwsA(isA<FeedTransportException>()),
      );
    });

    test('sonsuz yönlendirme döngüsü durdurulur', () async {
      await expectLater(
        IoFeedHttpClient().get(url('/dongu')),
        throwsA(isA<FeedTransportException>()),
      );
      expect(seenUserAgents.length, IoFeedHttpClient.maxRedirects + 1);
    });

    /// Sınır olmasaydı bozuk ya da kötü niyetli bir uç, cihazın belleğini
    /// dolduran bir gövde akıtabilirdi.
    test('bildirilen boyut sınırı aşıyorsa hiç indirilmez', () async {
      await expectLater(
        IoFeedHttpClient(maxBytes: 512).get(url('/buyuk')),
        throwsA(isA<FeedTransportException>()),
      );
    });

    /// İki ayrı kapı: `Content-Length` **bildirilmeyebilir** ya da yalan
    /// olabilir. Sınır o yüzden akış ilerlerken de ölçülür.
    test('boyut bildirilmese de akış sınırda kesilir', () async {
      await expectLater(
        IoFeedHttpClient(maxBytes: 512).get(url('/akan')),
        throwsA(isA<FeedTransportException>()),
      );
    });

    test('sınırın altındaki gövde okunur', () async {
      final response = await IoFeedHttpClient(
        maxBytes: 8192,
      ).get(url('/buyuk'));

      expect(response.body, hasLength(4096));
    });

    /// Takılı kalmış bir bağlantı, zaman aşımı olmadan tazelemeyi süresiz
    /// bekletirdi: durum satırı sonsuza dek "Güncelleniyor…" kalır ve ikinci
    /// deneme de engellenmiş olurdu.
    test('yanıt vermeyen sunucu zaman aşımına uğrar', () async {
      await expectLater(
        IoFeedHttpClient(
          timeout: const Duration(milliseconds: 300),
        ).get(url('/asili')),
        throwsA(isA<FeedTransportException>()),
      );
    });

    /// Çevrimdışı olmak beklenen bir durumdur; tek bir tipe indirgenir ki
    /// çağıran taraf onu ayrıştırma hatasından ayırabilsin.
    test('bağlantı kurulamazsa taşıma hatası döner', () async {
      final port = server.port;
      await server.close(force: true);

      await expectLater(
        IoFeedHttpClient().get(Uri.parse('http://127.0.0.1:$port/feed.json')),
        throwsA(isA<FeedTransportException>()),
      );
    });
  });
}
