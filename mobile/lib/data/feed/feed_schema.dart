/// TeknoAkış içerik feed'inin sözleşmesi.
///
/// Bu dosya **hem üretici hem uygulama** tarafından kullanılır: üretici
/// (`tool/feed/`) buradaki tiplerle JSON yazar, uygulama aynı tiplerle okur.
/// Sözleşmenin tek kaynağı burasıdır; iki tarafta elle senkronlanan bir şema
/// yoktur.
///
/// Alanlar `docs/CONTENT_TRUST_POLICY.md` maddelerinden türetilmiştir:
/// her içerikte orijinal URL, kaynak türü, yayın tarihi ve son kontrol zamanı
/// tutulur; TeknoAkış özeti orijinal kaynaktan görsel olarak ayrılır
/// ([FeedItem.summaryOrigin]); kopyalar tek kayıt altında birleştirilir
/// ([FeedItem.mergedUrls]); yanlış içerik geri çekme kaydıyla yönetilir
/// ([FeedItem.retractedAt]).
library;

/// Şema sürümü. Uyumsuz bir değişiklikte artar; uygulama bilmediği bir
/// sürümü **okumayı reddeder**, sessizce yanlış ayrıştırmaz.
const feedSchemaVersion = 1;

enum FeedItemKind { repository, aiModel, tool, skill, mcp, announcement }

enum FeedSourceKind { github, huggingFace, officialBlog, documentation }

/// Özetin nereden geldiği. Politika, TeknoAkış özetinin orijinal kaynaktan
/// **görsel olarak ayrılmasını** şart koşar; arayüz bu alana bakarak ayırır.
enum SummaryOrigin {
  /// Kaynağın kendi açıklaması, olduğu gibi.
  original,

  /// Derleme anında üretilmiş TeknoAkış özeti (doğrulama kapısından geçmiş).
  teknoakis,

  /// Elle yazılmış özet.
  manual,
}

/// Güvenilirlik yalnız popülerlik değildir: bakım durumu, kaynak sahipliği,
/// lisans ve güncellik ayrıca değerlendirilir.
final class TrustSignals {
  const TrustSignals({
    required this.officialSource,
    required this.hasLicense,
    required this.recentlyUpdated,
    required this.maintained,
    this.popularity,
  });

  /// Kaynak, içeriğin sahibi mi (resmi blog, resmi repo) yoksa üçüncü taraf mı.
  final bool officialSource;
  final bool hasLicense;
  final bool recentlyUpdated;
  final bool maintained;

  /// Yıldız/indirme gibi ham popülerlik. **Tek başına güven ölçütü değildir**,
  /// bu yüzden opsiyonel ve puana katkısı sınırlıdır.
  final int? popularity;

  /// 0–100. Popülerlik en fazla 10 puan getirir; kalan 90 puan bakım, sahiplik,
  /// lisans ve güncellikten gelir.
  int get score {
    var total = 0;
    if (officialSource) total += 30;
    if (maintained) total += 25;
    if (recentlyUpdated) total += 20;
    if (hasLicense) total += 15;
    if ((popularity ?? 0) > 0) total += 10;
    return total;
  }

  Map<String, Object?> toJson() => {
    'officialSource': officialSource,
    'hasLicense': hasLicense,
    'recentlyUpdated': recentlyUpdated,
    'maintained': maintained,
    if (popularity != null) 'popularity': popularity,
  };

  static TrustSignals fromJson(Map<String, Object?> json) => TrustSignals(
    officialSource: json['officialSource'] as bool? ?? false,
    hasLicense: json['hasLicense'] as bool? ?? false,
    recentlyUpdated: json['recentlyUpdated'] as bool? ?? false,
    maintained: json['maintained'] as bool? ?? false,
    popularity: json['popularity'] as int?,
  );
}

final class FeedItem {
  const FeedItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.summary,
    required this.summaryOrigin,
    required this.sourceName,
    required this.sourceKind,
    required this.url,
    required this.publishedAt,
    required this.checkedAt,
    required this.language,
    required this.trust,
    this.topics = const [],
    this.mergedUrls = const [],
    this.retractedAt,
    this.correctionNote,
  });

  /// Kanonik URL'den türetilen kararlı kimlik ([feedItemId]).
  final String id;
  final FeedItemKind kind;
  final String title;
  final String summary;
  final SummaryOrigin summaryOrigin;

  /// İnsan tarafından okunur kaynak adı: "GitHub", "Hugging Face",
  /// "Anthropic Blog".
  final String sourceName;
  final FeedSourceKind sourceKind;

  /// Orijinal içeriğin adresi. Her kayıtta **zorunludur**.
  final Uri url;
  final DateTime publishedAt;
  final DateTime checkedAt;

  /// Özetin dili (`tr`, `en`). Akış karma dilli olabilir; arayüz bunu
  /// gösterebilmek için bilmek zorundadır.
  final String language;
  final TrustSignals trust;
  final List<String> topics;

  /// Aynı gelişmenin birleştirilen kopyaları. Boş değilse bu kayıt bir
  /// birleştirme sonucudur ve şeffaflık için kaynaklar burada durur.
  final List<Uri> mergedUrls;

  /// Geri çekilmiş içerik. Uygulama bunları göstermez ama kayıt silinmez —
  /// politika düzeltmeyi **kayıtla** yönetmeyi şart koşar.
  final DateTime? retractedAt;
  final String? correctionNote;

  bool get isRetracted => retractedAt != null;

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'title': title,
    'summary': summary,
    'summaryOrigin': summaryOrigin.name,
    'sourceName': sourceName,
    'sourceKind': sourceKind.name,
    'url': url.toString(),
    'publishedAt': publishedAt.toUtc().toIso8601String(),
    'checkedAt': checkedAt.toUtc().toIso8601String(),
    'language': language,
    'trust': trust.toJson(),
    if (topics.isNotEmpty) 'topics': topics,
    if (mergedUrls.isNotEmpty)
      'mergedUrls': mergedUrls.map((url) => url.toString()).toList(),
    if (retractedAt != null)
      'retractedAt': retractedAt!.toUtc().toIso8601String(),
    if (correctionNote != null) 'correctionNote': correctionNote,
  };

  static FeedItem fromJson(Map<String, Object?> json) => FeedItem(
    id: _requireString(json, 'id'),
    kind: _requireEnum(json, 'kind', FeedItemKind.values),
    title: _requireString(json, 'title'),
    summary: _requireString(json, 'summary'),
    summaryOrigin: _requireEnum(json, 'summaryOrigin', SummaryOrigin.values),
    sourceName: _requireString(json, 'sourceName'),
    sourceKind: _requireEnum(json, 'sourceKind', FeedSourceKind.values),
    url: _requireUri(json, 'url'),
    publishedAt: _requireDate(json, 'publishedAt'),
    checkedAt: _requireDate(json, 'checkedAt'),
    language: _requireString(json, 'language'),
    trust: TrustSignals.fromJson(
      (json['trust'] as Map?)?.cast<String, Object?>() ?? const {},
    ),
    topics:
        (json['topics'] as List?)?.map((topic) => '$topic').toList() ??
        const [],
    mergedUrls:
        (json['mergedUrls'] as List?)
            ?.map((url) => Uri.parse('$url'))
            .toList() ??
        const [],
    retractedAt: json['retractedAt'] == null
        ? null
        : _requireDate(json, 'retractedAt'),
    correctionNote: json['correctionNote'] as String?,
  );
}

final class Feed {
  const Feed({
    required this.schemaVersion,
    required this.generatedAt,
    required this.items,
  });

  final int schemaVersion;
  final DateTime generatedAt;
  final List<FeedItem> items;

  /// Geri çekilmemiş kayıtlar — arayüzün göstereceği küme.
  List<FeedItem> get visibleItems =>
      items.where((item) => !item.isRetracted).toList(growable: false);

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'generatedAt': generatedAt.toUtc().toIso8601String(),
    'items': items.map((item) => item.toJson()).toList(),
  };

  /// Bilinmeyen bir şema sürümü **reddedilir**: yanlış ayrıştırıp sessizce
  /// bozuk içerik göstermektense okumamak doğrudur.
  static Feed fromJson(Map<String, Object?> json) {
    final version = json['schemaVersion'];
    if (version is! int) {
      throw const FeedFormatException(
        'schemaVersion alanı eksik veya sayı değil',
      );
    }
    if (version > feedSchemaVersion) {
      throw FeedFormatException(
        'Feed şeması v$version, bu sürüm en fazla v$feedSchemaVersion okuyabilir',
      );
    }
    final rawItems = json['items'];
    if (rawItems is! List) {
      throw const FeedFormatException('items alanı eksik veya liste değil');
    }
    return Feed(
      schemaVersion: version,
      generatedAt: _requireDate(json, 'generatedAt'),
      items: rawItems
          .map(
            (item) => FeedItem.fromJson((item as Map).cast<String, Object?>()),
          )
          .toList(growable: false),
    );
  }
}

class FeedFormatException implements Exception {
  const FeedFormatException(this.message);
  final String message;
  @override
  String toString() => 'FeedFormatException: $message';
}

/// Kanonik URL'den kararlı bir kimlik üretir.
///
/// `String.hashCode` kullanılmaz: Dart sürümleri ve platformlar arasında
/// kararlılığı garanti değildir, oysa kimliğin her üretimde aynı çıkması
/// gerekir (kopya birleştirme ve okuma geçmişi buna bağlı).
/// FNV-1a 64-bit, bağımlılıksız ve belirlenimcidir.
///
/// Sonuç **her zaman 16 haneli küçük harf onaltılıktır**. Dart tam sayıları
/// 64-bit işaretli olduğu için karışım sonucu negatif olabilir ve
/// `toRadixString(16)` başa `-` koyar; bu yüzden değer iki 32-bit yarıya
/// bölünüp maskelenerek yazılır.
String feedItemId(Uri url) {
  final canonical = canonicalizeUrl(url).toString();
  var hash = 0xcbf29ce484222325;
  for (final unit in canonical.codeUnits) {
    hash ^= unit;
    hash = hash * 0x100000001b3;
  }
  final high = (hash >> 32) & 0xFFFFFFFF;
  final low = hash & 0xFFFFFFFF;
  return high.toRadixString(16).padLeft(8, '0') +
      low.toRadixString(16).padLeft(8, '0');
}

/// Aynı gelişmenin farklı adreslerini eşleştirebilmek için URL'yi sadeleştirir:
/// şema https'e çekilir, `www.` ve izleme parametreleri atılır, sondaki `/`
/// kaldırılır.
Uri canonicalizeUrl(Uri url) {
  final host = url.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
  var path = url.path;
  if (path.length > 1 && path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }
  final query = Map<String, String>.from(url.queryParameters)
    ..removeWhere(
      (key, _) =>
          key.startsWith('utm_') ||
          const {'ref', 'source', 'fbclid', 'gclid'}.contains(key),
    );
  return Uri(
    scheme: 'https',
    host: host,
    path: path,
    queryParameters: query.isEmpty ? null : query,
  );
}

// --- ayrıştırma yardımcıları -------------------------------------------------

String _requireString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FeedFormatException('$key alanı eksik veya boş');
  }
  return value;
}

Uri _requireUri(Map<String, Object?> json, String key) {
  final value = Uri.tryParse(_requireString(json, key));
  if (value == null || !value.isAbsolute) {
    throw FeedFormatException('$key alanı mutlak bir URL olmalı');
  }
  return value;
}

DateTime _requireDate(Map<String, Object?> json, String key) {
  final value = DateTime.tryParse(_requireString(json, key));
  if (value == null) {
    throw FeedFormatException('$key alanı ISO-8601 tarih olmalı');
  }
  return value.toUtc();
}

T _requireEnum<T extends Enum>(
  Map<String, Object?> json,
  String key,
  List<T> values,
) {
  final raw = _requireString(json, key);
  for (final value in values) {
    if (value.name == raw) return value;
  }
  throw FeedFormatException('$key alanı bilinmeyen değer taşıyor: $raw');
}
