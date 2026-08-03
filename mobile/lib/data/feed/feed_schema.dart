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
///
/// **Katkı için artırılmaz.** Yeni bir kayıt türü ya da yeni bir alan eklemek
/// uyumsuz değişiklik değildir ve sürümü artırmak kurulu her uygulamayı
/// akıştan koparırdı. İleri uyumluluk kayıt seviyesinde çözülür; bkz.
/// [FeedItemUnsupportedException].
const feedSchemaVersion = 1;

enum FeedItemKind { repository, aiModel, tool, skill, mcp, announcement }

enum FeedSourceKind {
  github,
  huggingFace,
  officialBlog,
  documentation,

  /// Bu uygulama sürümünün **tanımadığı** bir kaynak türü.
  ///
  /// Üretici bunu asla yazmaz; yalnız ayrıştırma sırasında, yayın bu
  /// sürümden yeni bir kaynak türü taşıdığında ortaya çıkar. Kaydı düşürmek
  /// yerine buraya düşürmek bilinçli: kaynağın **adı** (`sourceName`)
  /// küratörlüdür ve zaten görünür, yani kullanıcı içeriği kimin yayımladığını
  /// yine görür. Türü bilmemek, içeriği gizlemek için yeterli sebep değil.
  other,
}

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
    this.summarySourceHash,
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

  /// Özetin **üretildiği kaynak metnin** damgası ([fnv1aHex]).
  ///
  /// Yalnız [SummaryOrigin.teknoakis] kayıtlarda dolu olur ve **yalnız üretici
  /// kullanır**; uygulama bu alanı hiç okumaz.
  ///
  /// Sebebi: üretici her koşuda feed'i kaynaklardan yeniden kuruyor ve geçen
  /// koşuda Türkçeleştirilmiş bir kayıt yeniden `original` olarak geliyordu —
  /// yani aynı özet her koşuda yeniden satın alınıyordu. Özeti taşımak için
  /// "kaynak metin hâlâ aynı mı" sorusunun cevaplanması gerekiyor, ama
  /// yayımlanmış kayıtta artık kaynak metin **yok**: yerinde Türkçe özet
  /// duruyor. Damga o soruyu cevaplayan tek çapa.
  ///
  /// Kaynak metin değişmişse taşıma yapılmaz ve kayıt yeniden özetlenir; eski
  /// özet artık başka bir metni anlatıyor olurdu.
  ///
  /// Şema açısından **katkı niteliğinde bir alan**: `schemaVersion`
  /// artırılmaz ve kurulu uygulamalar tanımadıkları anahtarı yok sayar
  /// (D-012, `feed_schema_test.dart` → "tanınmayan opsiyonel alan yok sayılır").
  final String? summarySourceHash;

  bool get isRetracted => retractedAt != null;

  /// Özet katmanı için: yalnız özetle ilgili üç alan değişir.
  ///
  /// Kasıtlı olarak dar: kaynak, adres, tarih ve güven sinyalleri üretim
  /// hattının hiçbir adımında **değiştirilemez**. Özet yeniden yazılabilir,
  /// gerçekler yazılamaz.
  FeedItem withSummary({
    required String summary,
    required SummaryOrigin summaryOrigin,
    required String language,
    String? summarySourceHash,
  }) => FeedItem(
    id: id,
    kind: kind,
    title: title,
    summary: summary,
    summaryOrigin: summaryOrigin,
    sourceName: sourceName,
    sourceKind: sourceKind,
    url: url,
    publishedAt: publishedAt,
    checkedAt: checkedAt,
    language: language,
    trust: trust,
    topics: topics,
    mergedUrls: mergedUrls,
    retractedAt: retractedAt,
    correctionNote: correctionNote,
    summarySourceHash: summarySourceHash,
  );

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
    // Üreticinin kendi defteri: uygulama okumaz, ama bir sonraki koşu bu
    // damgaya bakıp özeti yeniden satın almak yerine taşır.
    if (summarySourceHash != null) 'summarySourceHash': summarySourceHash,
  };

  static FeedItem fromJson(Map<String, Object?> json) => FeedItem(
    id: _requireString(json, 'id'),
    // Tür, ekranı ve rotayı belirliyor — uydurulamaz, kayıt atlanır.
    kind: _requireKnownEnum(json, 'kind', FeedItemKind.values),
    title: _requireString(json, 'title'),
    summary: _requireString(json, 'summary'),
    // Dürüstlük kuralı: özetin kaynağı bilinmiyorsa kayıt **gösterilmez**.
    // Tanınmayan bir değeri `original`a düşürmek, TeknoAkış özetini kaynağın
    // kendi metniymiş gibi sunmak olurdu; politika bunu yasaklıyor.
    summaryOrigin: _requireKnownEnum(
      json,
      'summaryOrigin',
      SummaryOrigin.values,
    ),
    sourceName: _requireString(json, 'sourceName'),
    // Kaynak türü yalnız etiket/süzgeç sürüyor ve küratörlü `sourceName`
    // zaten görünüyor — bilinmeyen değer kaydı düşürmez.
    sourceKind: _enumOrElse(
      json,
      'sourceKind',
      FeedSourceKind.values,
      FeedSourceKind.other,
    ),
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
    summarySourceHash: json['summarySourceHash'] as String?,
  );
}

final class Feed {
  const Feed({
    required this.schemaVersion,
    required this.generatedAt,
    required this.items,
    this.unsupportedItemCount = 0,
  });

  final int schemaVersion;
  final DateTime generatedAt;
  final List<FeedItem> items;

  /// Bu sürümün tanımadığı için **atlanan** kayıt sayısı.
  ///
  /// Ayrıştırma anında gözlemlenir, feed'in içeriği değildir — bu yüzden
  /// [toJson] onu yazmaz. Sayılmasının sebebi: atlanan kayıt sessizce
  /// kaybolmamalı. Sıfırdan büyük olması "yayın bu uygulamadan yeni" demektir
  /// ve bu, güncelleme çağrısı gibi bir davranışın ölçülebilir tek dayanağı.
  final int unsupportedItemCount;

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
  ///
  /// Tanınmayan **kayıt** ise reddedilmez, atlanır — ikisi ayrı sorun. Sürüm
  /// uyumsuzluğu yapının değiştiğini söyler; tek bir kaydın bilinmeyen bir tür
  /// taşıması ise yalnız o kaydın yeni olduğunu söyler. Bkz.
  /// [FeedItemUnsupportedException].
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

    // `map` yerine döngü: atlanan kayıt sayılabilmeli ve tek bir tanınmayan
    // kayıt listenin geri kalanını düşürmemeli.
    final items = <FeedItem>[];
    var unsupported = 0;
    for (final raw in rawItems) {
      try {
        items.add(FeedItem.fromJson((raw as Map).cast<String, Object?>()));
      } on FeedItemUnsupportedException {
        unsupported++;
      }
    }

    return Feed(
      schemaVersion: version,
      generatedAt: _requireDate(json, 'generatedAt'),
      items: List.unmodifiable(items),
      unsupportedItemCount: unsupported,
    );
  }
}

class FeedFormatException implements Exception {
  const FeedFormatException(this.message);
  final String message;
  @override
  String toString() => 'FeedFormatException: $message';
}

/// Kayıt **bozuk değil, bu sürümden yeni**.
///
/// [FeedFormatException]'dan ayrı olması işin özü. İkisi de "ayrıştıramadım"
/// diyor ama sonuçları zıt:
///
/// - `FeedFormatException` → yayın bozuk. Feed **reddedilir**; sessizce yanlış
///   ayrıştırıp bozuk içerik göstermek daha kötü olurdu.
/// - `FeedItemUnsupportedException` → yayın ileri. Kayıt **atlanır**, feed'in
///   geri kalanı okunur.
///
/// Ayrım neden şart, ölçüldü (2026-07-29): paketlenmiş 200 kayıttan **tek
/// birine** bilinmeyen bir `kind` yazıldığında bugünkü kod 200'ünü birden
/// reddediyordu. Yayımlanmış bir uygulamada bunun anlamı, güncellemeyen
/// kullanıcının yeni türü değil **hiçbir şeyi** bir daha alamamasıdır:
/// tazeleme başarısız olur, önbellek korunur ve ekran sonsuza dek
/// "Güncellenemedi · N gün önce" der. Çökme yok, veri kaybı yok — sessiz ölüm.
class FeedItemUnsupportedException implements Exception {
  const FeedItemUnsupportedException(this.field, this.value);

  /// Tanınmayan değeri taşıyan alan (`kind`, `summaryOrigin`).
  final String field;
  final String value;

  @override
  String toString() =>
      'FeedItemUnsupportedException: $field alanı bu sürümün tanımadığı bir '
      'değer taşıyor: $value';
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
String feedItemId(Uri url) => fnv1aHex(canonicalizeUrl(url).toString());

/// FNV-1a 64-bit, **16 haneli küçük harf onaltılık**.
///
/// [feedItemId] ile [FeedItem.summarySourceHash] aynı işlevi paylaşıyor;
/// ikisinin ayrı ayrı yazılması, birinin değişip diğerinin unutulduğu bir
/// gelecek demekti.
///
/// Dart tam sayıları 64-bit **işaretli** olduğu için karışım sonucu negatif
/// olabilir ve `toRadixString(16)` başa `-` koyar; bu yüzden değer iki 32-bit
/// yarıya bölünüp maskelenerek yazılır.
String fnv1aHex(String input) {
  var hash = 0xcbf29ce484222325;
  for (final unit in input.codeUnits) {
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

/// Alan **zorunlu**; değeri tanınmıyorsa kayıt atlanabilir.
///
/// İki ayrı hata fırlatır ve fark kasıtlı:
/// - alan yok / metin değil → [FeedFormatException] (üretici kusuru, ölümcül)
/// - alan var ama değer bilinmiyor → [FeedItemUnsupportedException] (ileri
///   yayın, kayıt atlanır)
T _requireKnownEnum<T extends Enum>(
  Map<String, Object?> json,
  String key,
  List<T> values,
) {
  final raw = _requireString(json, key);
  for (final value in values) {
    if (value.name == raw) return value;
  }
  throw FeedItemUnsupportedException(key, raw);
}

/// Tanınmayan değerde kaydı düşürmeyen alan: [fallback]'e düşer.
///
/// Yalnız kaydın **gösterilebilirliğini** bozmayan alanlarda kullanılır.
/// Alanın kendisi yine zorunlu — eksikse üretici kusurudur ve ölümcül kalır.
T _enumOrElse<T extends Enum>(
  Map<String, Object?> json,
  String key,
  List<T> values,
  T fallback,
) {
  final raw = _requireString(json, key);
  for (final value in values) {
    if (value.name == raw) return value;
  }
  return fallback;
}
