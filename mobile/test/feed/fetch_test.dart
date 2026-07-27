import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/feed/fetch.dart';

void main() {
  group('token kapsamı', () {
    /// Güvenlik davranışı: aynı `Authorization` başlığını her hosta göndermek,
    /// GitHub kimlik bilgisini üçüncü taraflara sızdırmaktır.
    final fetcher = HttpFeedFetcher(githubToken: 'gizli-token');

    test('token yalnız GitHub API ucuna gider', () {
      final headers = fetcher.headersFor(
        Uri.https('api.github.com', '/search/repositories'),
      );
      expect(headers[HttpHeaders.authorizationHeader], 'Bearer gizli-token');
      expect(headers[HttpHeaders.acceptHeader], 'application/vnd.github+json');
    });

    test('başka hiçbir hosta gitmez', () {
      for (final url in [
        Uri.https('huggingface.co', '/api/models'),
        Uri.https('openai.com', '/blog/rss.xml'),
        Uri.https('developer.nvidia.com', '/blog/feed/'),
        // Benzer görünen ama farklı bir alan adı da token almamalı.
        Uri.https('api.github.com.kotu.test', '/x'),
        Uri.https('github.com', '/anthropics/claude-code'),
      ]) {
        expect(
          fetcher.headersFor(url).containsKey(HttpHeaders.authorizationHeader),
          isFalse,
          reason: '$url token almamalı',
        );
      }
    });

    test('User-Agent her istekte var', () {
      // GitHub, User-Agent taşımayan kimliksiz istekleri reddediyor.
      for (final url in [
        Uri.https('api.github.com', '/x'),
        Uri.https('huggingface.co', '/x'),
      ]) {
        expect(
          fetcher.headersFor(url)[HttpHeaders.userAgentHeader],
          'TeknoAkis-feed-generator',
        );
      }
    });

    test('token yoksa yetkilendirme başlığı hiç eklenmez', () {
      final headers = HttpFeedFetcher().headersFor(
        Uri.https('api.github.com', '/x'),
      );
      expect(headers.containsKey(HttpHeaders.authorizationHeader), isFalse);
    });

    /// Ortam değişkeni tanımlı ama boşsa `Bearer ` gönderilmemeli.
    test('boş token yok sayılır', () {
      final headers = HttpFeedFetcher(
        githubToken: '',
      ).headersFor(Uri.https('api.github.com', '/x'));
      expect(headers.containsKey(HttpHeaders.authorizationHeader), isFalse);
    });
  });

  group('yanıt', () {
    test('2xx başarılı sayılır, diğerleri değil', () {
      expect(const FetchResponse(statusCode: 200, body: '').isOk, isTrue);
      expect(const FetchResponse(statusCode: 204, body: '').isOk, isTrue);
      expect(const FetchResponse(statusCode: 301, body: '').isOk, isFalse);
      expect(const FetchResponse(statusCode: 404, body: '').isOk, isFalse);
      expect(const FetchResponse(statusCode: 500, body: '').isOk, isFalse);
    });
  });

  group('gerçek HTTP', () {
    /// Ağa çıkmaz: 127.0.0.1'de kendi sunucumuzu açıp gerçek `HttpClient`
    /// yolunu ölçeriz. Başlıkların **kabloya** gerçekten yazıldığını
    /// `headersFor` tek başına gösteremez.
    late HttpServer server;
    late List<String> seenUserAgents;

    setUp(() async {
      seenUserAgents = [];
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        seenUserAgents.add(request.headers.value(HttpHeaders.userAgentHeader)!);
        request.response.statusCode = request.uri.path == '/yok' ? 404 : 200;
        request.response.write('{"ok": true}');
        await request.response.close();
      });
    });

    tearDown(() => server.close(force: true));

    test('gövde ve durum kodu okunur', () async {
      final fetcher = HttpFeedFetcher(githubToken: 'gizli-token');
      final response = await fetcher.fetch(
        Uri.parse('http://127.0.0.1:${server.port}/veri'),
      );

      expect(response.statusCode, 200);
      expect(response.body, '{"ok": true}');
      expect(response.isOk, isTrue);
      expect(seenUserAgents.single, 'TeknoAkis-feed-generator');
    });

    test('hata kodu istisna değil, sonuç olarak döner', () async {
      final response = await HttpFeedFetcher().fetch(
        Uri.parse('http://127.0.0.1:${server.port}/yok'),
      );
      expect(response.statusCode, 404);
      expect(response.isOk, isFalse);
    });
  });
}
