/// Ağ katmanı — **yalnız üretici tarafında**.
///
/// Uygulamaya hiçbir ağ kodu girmez; burası derleme zamanı çalışan CLI'ın
/// parçasıdır. Arayüz enjekte edilebilir olduğu için hattın tamamı sahte bir
/// getirici ile, ağa çıkmadan test edilir.
library;

import 'dart:convert';
import 'dart:io';

final class FetchResponse {
  const FetchResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;

  bool get isOk => statusCode >= 200 && statusCode < 300;
}

abstract interface class FeedFetcher {
  Future<FetchResponse> fetch(Uri url);
}

/// Gerçek HTTP getiricisi.
final class HttpFeedFetcher implements FeedFetcher {
  HttpFeedFetcher({
    this.userAgent = 'Tecnow-feed-generator',
    this.githubToken,
    this.timeout = const Duration(seconds: 30),
  });

  /// GitHub kimliksiz istekleri **User-Agent olmadan reddeder**.
  final String userAgent;

  /// İsteğe bağlı. Yoksa da çalışır: GitHub kimliksiz saatte 60 istek verir,
  /// token ile 5000. Üretici anahtarsız çalışabilmeli — anahtar bir hız
  /// kolaylığıdır, koşul değil.
  final String? githubToken;

  final Duration timeout;

  static const _githubHost = 'api.github.com';

  /// İsteğe konacak başlıklar.
  ///
  /// Ayrı bir fonksiyon çünkü **sınanabilir olması şart**: token'ın yalnız
  /// GitHub'a gitmesi bir güvenlik davranışıdır. Koşul gövdenin içinde
  /// gömülü kalsaydı, ancak gerçek ağ isteğiyle doğrulanabilirdi — yani
  /// pratikte hiç doğrulanmazdı.
  ///
  /// Aynı `Authorization` başlığını her hosta göndermek, kimlik bilgisini
  /// üçüncü taraflara sızdırmaktır.
  Map<String, String> headersFor(Uri url) {
    final headers = {HttpHeaders.userAgentHeader: userAgent};
    final token = githubToken;
    if (token != null && token.isNotEmpty && url.host == _githubHost) {
      headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
      headers[HttpHeaders.acceptHeader] = 'application/vnd.github+json';
    }
    return headers;
  }

  @override
  Future<FetchResponse> fetch(Uri url) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.getUrl(url);
      headersFor(url).forEach(request.headers.set);

      final response = await request.close().timeout(timeout);
      final body = await response.transform(utf8.decoder).join();
      return FetchResponse(statusCode: response.statusCode, body: body);
    } finally {
      client.close(force: true);
    }
  }
}
