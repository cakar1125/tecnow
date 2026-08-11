/// Uygulamanın **tek** ağ çıkışı.
///
/// Kapsamı bilinçli olarak dar: tek bir JSON dosyasını `GET` eder. Kimlik
/// bilgisi taşımaz, çerez tutmaz, gövde göndermez, hiçbir yere veri yazmaz.
/// Uygulamada başka ağ kodu yoktur; bir istek eklenecekse bu dosyadan geçer
/// ve buradaki sınırlara tabi olur.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

final class FeedHttpResponse {
  const FeedHttpResponse({
    required this.statusCode,
    required this.body,
    this.etag,
    this.lastModified,
  });

  final int statusCode;
  final String body;

  /// Sunucunun verdiği doğrulayıcılar. Bir sonraki istekte geri gönderilirler;
  /// sunucu vermezse `null` kalırlar ve koşullu istek yapılmaz.
  final String? etag;
  final String? lastModified;

  bool get isOk => statusCode >= 200 && statusCode < 300;

  /// İçerik değişmemiş: gövde yok, elimizdeki kopya hâlâ geçerli.
  bool get isNotModified => statusCode == HttpStatus.notModified;
}

/// Bir önceki yanıttan saklanan doğrulayıcılar.
///
/// İkisi birden tutuluyor çünkü sunucular ikisini de her zaman vermiyor:
/// ölçüldü (2026-07-28) `pages.github.com` ve `microsoft.github.io` ikisini de
/// verdi, `pytorch.github.io` hiçbirini vermedi. Elde ne varsa o gönderilir.
final class FeedValidators {
  const FeedValidators({this.etag, this.lastModified});

  final String? etag;
  final String? lastModified;

  bool get isEmpty => etag == null && lastModified == null;
}

/// Ağ katmanının başarısızlıkları. Ayrı bir tip: çağıran taraf bunu bir
/// **beklenen** durum olarak ele alır (çevrimdışı kalmak hata değildir),
/// ayrıştırma hatalarından ayırt edebilmesi gerekir.
final class FeedTransportException implements Exception {
  const FeedTransportException(this.message);

  final String message;

  @override
  String toString() => 'FeedTransportException: $message';
}

abstract interface class FeedHttpClient {
  /// [validators] verilirse **koşullu** istek yapılır: içerik değişmemişse
  /// sunucu gövdesiz `304` döner.
  Future<FeedHttpResponse> get(Uri url, {FeedValidators? validators});
}

/// Yönlendirme hedefini çözer; kabul edilmiyorsa `null`.
///
/// `HttpClient` yönlendirmeleri kendi takip eder ama **şema düşüşünü
/// engellemez**: `https` ile başlayan bir istek `http`'ye yönlendirilebilir ve
/// içerik o noktadan sonra aradaki herhangi bir ağ tarafından değiştirilebilir.
/// Bu uygulamanın bütün güven anlatısı içeriğin denetlenmiş bir hattan
/// gelmesine dayandığı için yönlendirme elle çözülür.
///
/// Ayrı ve saf bir fonksiyon çünkü **sınanabilir olması şart**: gerçek bir
/// `https` düşüşünü ağa çıkmadan üretmek mümkün değil, karar burada ölçülür.
Uri? resolveRedirect(Uri from, String? location) {
  if (location == null || location.trim().isEmpty) return null;

  final target = Uri.tryParse(location.trim());
  if (target == null) return null;

  // Göreli adresler ("/v2/feed.json") de geçerli bir yönlendirmedir.
  final resolved = from.resolveUri(target);
  if (resolved.host.isEmpty) return null;

  // `ftp:`, `file:`, `javascript:` gibi şemalar hiçbir koşulda izlenmez.
  if (resolved.scheme != 'https' && resolved.scheme != 'http') return null;

  // Şema düşüşü yok. Yükselme (http → https) serbest.
  if (from.scheme == 'https' && resolved.scheme != 'https') return null;

  return resolved;
}

final class IoFeedHttpClient implements FeedHttpClient {
  IoFeedHttpClient({
    this.userAgent = 'tecOS',
    this.timeout = const Duration(seconds: 20),
    this.maxBytes = defaultMaxBytes,
  });

  final String userAgent;

  /// İki veri parçası arasındaki azami bekleme. Toplam süre değil: takılıp
  /// kalmış bir bağlantı ile yavaş ama ilerleyen bir indirme farklı şeylerdir.
  final Duration timeout;

  /// Gövde sınırı. Bugünkü feed 184 KB; 4 MB bolca pay bırakır.
  ///
  /// Sınır olmasaydı bozuk ya da kötü niyetli bir uç, cihazın belleğini
  /// dolduran sonsuz bir gövde akıtabilirdi — istemci gelen her baytı
  /// biriktirdiği için bu bir çökme demek olurdu.
  static const defaultMaxBytes = 4 * 1024 * 1024;

  /// Testler küçük bir sınır verip davranışı gerçekten ölçebilsin diye alan;
  /// 4 MB'lık bir gövde üretmek testi ölçtüğü şeyden daha pahalı yapardı.
  final int maxBytes;

  /// Azami yönlendirme adımı.
  static const maxRedirects = 5;

  @override
  Future<FeedHttpResponse> get(Uri url, {FeedValidators? validators}) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      var target = url;
      for (var hop = 0; hop <= maxRedirects; hop++) {
        final request = await client.getUrl(target);
        request.followRedirects = false;
        request.headers.set(HttpHeaders.userAgentHeader, userAgent);
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');

        // Koşullu başlıklar. Elde olan gönderilir; ikisi de yoksa istek
        // koşulsuzdur ve sunucu her zaman gövde döner.
        if (validators?.etag case final etag?) {
          request.headers.set(HttpHeaders.ifNoneMatchHeader, etag);
        }
        if (validators?.lastModified case final lastModified?) {
          request.headers.set(HttpHeaders.ifModifiedSinceHeader, lastModified);
        }

        final response = await request.close().timeout(timeout);

        if (response.isRedirect) {
          final next = resolveRedirect(
            target,
            response.headers.value(HttpHeaders.locationHeader),
          );
          // Gövde okunmadan bırakılan bağlantı soketi açık tutar.
          await response.drain<void>();
          if (next == null) {
            throw const FeedTransportException('Yönlendirme kabul edilmedi');
          }
          target = next;
          continue;
        }

        // `304` gövdesizdir; okumaya çalışmak yerine bağlantı boşaltılır.
        // Doğrulayıcılar yine de okunur: sunucu 304 ile yeni bir `ETag`
        // gönderebilir ve onu atmak, bir sonraki isteği koşulsuz yapardı.
        if (response.statusCode == HttpStatus.notModified) {
          await response.drain<void>();
          return FeedHttpResponse(
            statusCode: response.statusCode,
            body: '',
            etag:
                response.headers.value(HttpHeaders.etagHeader) ??
                validators?.etag,
            lastModified:
                response.headers.value(HttpHeaders.lastModifiedHeader) ??
                validators?.lastModified,
          );
        }

        return FeedHttpResponse(
          statusCode: response.statusCode,
          body: await _readBody(response),
          etag: response.headers.value(HttpHeaders.etagHeader),
          lastModified: response.headers.value(HttpHeaders.lastModifiedHeader),
        );
      }
      throw const FeedTransportException('Çok fazla yönlendirme');
    } on SocketException catch (error) {
      // Çevrimdışı olmak beklenen bir durumdur; çağıran tarafın bunu ağ
      // hatası olarak tanıması için tek tipe indirgenir.
      throw FeedTransportException('Bağlantı kurulamadı: ${error.message}');
    } on HttpException catch (error) {
      throw FeedTransportException('Bağlantı hatası: ${error.message}');
    } on TimeoutException {
      throw const FeedTransportException('Bağlantı zaman aşımına uğradı');
    } finally {
      client.close(force: true);
    }
  }

  Future<String> _readBody(HttpClientResponse response) async {
    if (response.contentLength > maxBytes) {
      throw const FeedTransportException('İçerik çok büyük');
    }

    final bytes = BytesBuilder(copy: false);
    await for (final chunk in response.timeout(timeout)) {
      bytes.add(chunk);
      if (bytes.length > maxBytes) {
        throw const FeedTransportException('İçerik çok büyük');
      }
    }
    return utf8.decode(bytes.takeBytes());
  }
}
