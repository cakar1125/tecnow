/// Bağlayıcıların ortak yardımcıları.
///
/// Bağlayıcılar **saf ayrıştırıcılardır**: ham yanıt gövdesi girer, `FeedItem`
/// listesi çıkar. Ağ erişimi burada değil, üretici katmanındadır — böylece
/// ayrıştırma mantığı fixture'larla, ağa hiç çıkmadan test edilebilir ve
/// testler ne yavaşlar ne de dış servisin o günkü içeriğine bağlı olur.
library;

import 'dart:convert';

import 'package:tecnow/data/feed/feed_schema.dart';

/// Bir kaydın neden feed'e alınmadığı.
///
/// Ayıklanan kayıtlar **sessizce kaybolmaz**: üretici bunları günlüğe yazar.
/// Bir kaynağın aniden boşalması ancak böyle fark edilir.
enum SkipReason {
  /// Kayıt beklenen biçimde değil (nesne değil, alanlar okunamıyor).
  malformed,

  /// Adres allowlist dışı. Feed listesi allowlist'i dolanamaz.
  notAllowed,
  missingUrl,
  missingTitle,

  /// Açıklaması olmayan kayıt yayımlanmaz: tanımlayamadığımız bir şeyi
  /// rehberde göstermek, kullanıcıya bilgi değil gürültü verir.
  missingSummary,
  missingDate,

  /// Yayımlanmamış taslak sürüm.
  draft,

  /// Özel/erişilemez kayıt.
  private,

  /// Yayımlanabilirlik kapısından geçemedi — bkz. `meetsQualityBar`.
  ///
  /// Ayrıştırma hatası **değildir**: kayıt düzgün okundu, editoryal olarak
  /// yayımlanmadı. Rapor ikisini ayırt edebilsin diye ayrı bir sebep.
  lowSignal,
}

final class SkippedRecord {
  const SkippedRecord(this.identifier, this.reason);

  /// Kaydı insanın tanıyabileceği bir etiket: depo adı, model kimliği ya da
  /// adres. Günlükte "3 kayıt elendi" değil, *hangileri* yazsın diye.
  final String identifier;
  final SkipReason reason;

  @override
  String toString() => '$identifier (${reason.name})';
}

/// Bir bağlayıcının çıktısı: alınanlar **ve** elenenler.
final class ConnectorResult {
  const ConnectorResult({this.items = const [], this.skipped = const []});

  final List<FeedItem> items;
  final List<SkippedRecord> skipped;

  static ConnectorResult combine(Iterable<ConnectorResult> results) =>
      ConnectorResult(
        items: [for (final result in results) ...result.items],
        skipped: [for (final result in results) ...result.skipped],
      );
}

/// Yanıtın bütünü okunamadığında atılır. Tek bir bozuk kayıt elenir, ama
/// gövdenin tamamı bozuksa bu bir çalışma hatasıdır ve sessizce boş feed
/// üretilmemelidir.
class ConnectorException implements Exception {
  const ConnectorException(this.message);
  final String message;
  @override
  String toString() => 'ConnectorException: $message';
}

/// "Yakın zamanda güncellendi" penceresi.
const recentWindow = Duration(days: 90);

/// "Bakımı sürüyor" penceresi. Bir yıldır dokunulmamış proje bakımsız sayılır.
const maintainedWindow = Duration(days: 365);

/// [date], [reference] tarihine göre [window] içinde mi?
///
/// Gelecek tarihler içeride sayılır: kaynak saat farkıyla birkaç saat ileri
/// bir tarih verebilir ve bu, yeni yayımlanmış bir içeriği eskitmemelidir.
bool isWithin(DateTime date, DateTime reference, Duration window) =>
    reference.difference(date) <= window;

/// Ardışık boşlukları teke indirir, baştaki/sondaki boşluğu atar.
String normalizeSpaces(String value) =>
    value.replaceAll(RegExp(r'\s+'), ' ').trim();

const _namedEntities = <String, String>{
  'amp': '&',
  'lt': '<',
  'gt': '>',
  'quot': '"',
  'apos': "'",
  'nbsp': ' ',
  'hellip': '…',
  'mdash': '—',
  'ndash': '–',
  'lsquo': '‘',
  'rsquo': '’',
  'ldquo': '“',
  'rdquo': '”',
};

final _entityPattern = RegExp(r'&(#x[0-9a-fA-F]+|#[0-9]+|[a-zA-Z]+);');

/// HTML/XML varlıklarını çözer (`&amp;` → `&`).
String decodeEntities(String value) =>
    value.replaceAllMapped(_entityPattern, (match) {
      final body = match[1]!;
      if (body.startsWith('#x') || body.startsWith('#X')) {
        final code = int.tryParse(body.substring(2), radix: 16);
        return code == null ? match[0]! : String.fromCharCode(code);
      }
      if (body.startsWith('#')) {
        final code = int.tryParse(body.substring(1));
        return code == null ? match[0]! : String.fromCharCode(code);
      }
      return _namedEntities[body.toLowerCase()] ?? match[0]!;
    });

/// Etiket kalıbı bilinçli olarak **dar**: `<` işaretinden sonra harf şart.
/// Böylece "1 < 2 ve 3 > 4" gibi düz metin, etiket sanılıp silinmez.
final _tagPattern = RegExp(r'</?[a-zA-Z][^>]*>');

/// Noktalamadan önce kalan boşluk.
final _spaceBeforePunctuation = RegExp(r' +([,.;:!?…])');

/// RSS açıklamaları çoğu zaman HTML taşır. Uygulama HTML **render etmez**,
/// bu yüzden metin burada düzleştirilir.
///
/// Etiketin yerine **boşluk** konur, boşluk silinmez: `<p>Bir</p><p>İki</p>`
/// aksi hâlde "BirİKi" olurdu. Bunun bedeli `rollout</a>.` gibi yerlerde
/// noktalamadan önce kalan boşluktur; son adım onu geri alır.
String stripHtml(String value) => normalizeSpaces(
  decodeEntities(value).replaceAll(_tagPattern, ' '),
).replaceAllMapped(_spaceBeforePunctuation, (match) => match[1]!);

final _fencedCode = RegExp(r'```[\s\S]*?```');
final _listMarker = RegExp(r'^([*\-+]|\d+\.)\s');
final _markdownLink = RegExp(r'!?\[([^\]]*)\]\([^)]*\)');
final _emphasis = RegExp(r'(\*\*|__|`)');
final _headingMarker = RegExp(r'^#{1,6}\s*', multiLine: true);

/// Sürüm notlarının **giriş paragrafını** düz metne çevirir.
///
/// Bir değişiklik günlüğünün ilk 320 karakteri özet değildir: kod bloğu,
/// başlık ve madde listesiyle dolu bir metin karta konduğunda okunmaz.
/// Gerçek `flutter/flutter` yanıtında ölçüldü — ham gövde şöyle başlıyordu:
/// "... ``` flutter channel beta flutter upgrade ``` # Flutter 3.19 beta ...".
///
/// Bu yüzden yalnız ilk paragraf alınır: başlık, madde listesi ya da boş satır
/// görüldüğünde durulur. Kaynağın kendi giriş cümlesidir — kısaltılır ama
/// yeniden yazılmaz.
String flattenReleaseNotes(String body) {
  final lines = body.replaceAll(_fencedCode, '\n\n').split(RegExp(r'\r?\n'));
  final lead = <String>[];

  for (final line in lines) {
    final text = line.trim();
    if (text.startsWith('#')) break;
    if (_listMarker.hasMatch(text)) break;
    if (text.isEmpty) {
      if (lead.isNotEmpty) break;
      continue;
    }
    lead.add(text);
  }

  // Gövde doğrudan başlıkla başlıyorsa giriş paragrafı yoktur; bu durumda
  // metnin tamamı düzleştirilir (hiç özet olmamasından iyidir).
  final source = lead.isEmpty
      ? body.replaceAll(_fencedCode, ' ')
      : lead.join(' ');
  return stripHtml(
    source
        .replaceAll(_headingMarker, '')
        .replaceAllMapped(_markdownLink, (match) => match[1] ?? '')
        .replaceAll(_emphasis, ''),
  );
}

/// Özeti kart boyutuna indirir; kelime ortasından kesmez.
String truncateSummary(String value, {int limit = 320}) {
  if (value.length <= limit) return value;
  final cut = value.substring(0, limit);
  final lastSpace = cut.lastIndexOf(' ');
  final trimmed = lastSpace > limit ~/ 2 ? cut.substring(0, lastSpace) : cut;
  return '${trimmed.trimRight()}…';
}

// --- JSON okuma yardımcıları -------------------------------------------------

/// Gövdeyi çözüp kayıt listesini verir. [key] verilirse yanıtın o alanı, yoksa
/// gövdenin kendisi liste olarak beklenir.
///
/// Nesne olmayan öğeler `null` döner: tek bozuk kayıt tüm çalışmayı
/// düşürmemeli, ama sayılabilmesi için de yutulmamalıdır.
List<Map<String, Object?>?> jsonEntries(
  String body,
  String? key, {
  required String sourceLabel,
}) {
  final Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException catch (error) {
    throw ConnectorException(
      '$sourceLabel yanıtı JSON değil: ${error.message}',
    );
  }

  final Object? raw = key != null && decoded is Map ? decoded[key] : decoded;
  if (raw is! List) {
    throw ConnectorException(
      '$sourceLabel yanıtında liste bulunamadı${key == null ? '' : ' ($key)'}',
    );
  }
  return raw
      .map((entry) => entry is Map ? entry.cast<String, Object?>() : null)
      .toList(growable: false);
}

/// Boş ve boşluktan ibaret değerleri `null` sayar: JSON'daki `""` ile alanın
/// hiç olmaması aynı şeydir.
String? jsonString(Map<String, Object?> entry, String key) {
  final value = entry[key];
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

int? jsonInt(Map<String, Object?> entry, String key) {
  final value = entry[key];
  if (value is int) return value;
  if (value is double) return value.round();
  return null;
}

Uri? jsonUrl(Map<String, Object?> entry, String key) {
  final raw = jsonString(entry, key);
  if (raw == null) return null;
  final url = Uri.tryParse(raw);
  return url != null && url.isAbsolute ? url : null;
}

/// Etiket listesi: küçük harfe iner, boşlar atılır, sıra korunur.
List<String> jsonStringList(Map<String, Object?> entry, String key) {
  final value = entry[key];
  if (value is! List) return const [];
  return value
      .whereType<String>()
      .map((item) => item.trim().toLowerCase())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

const _months = <String, int>{
  'jan': 1,
  'feb': 2,
  'mar': 3,
  'apr': 4,
  'may': 5,
  'jun': 6,
  'jul': 7,
  'aug': 8,
  'sep': 9,
  'oct': 10,
  'nov': 11,
  'dec': 12,
};

final _rfc822Pattern = RegExp(
  r'^(?:[A-Za-z]{3},\s*)?(\d{1,2})\s+([A-Za-z]{3})[a-zA-Z]*\s+(\d{2,4})'
  r'\s+(\d{1,2}):(\d{2})(?::(\d{2}))?'
  r'(?:\s+(GMT|UTC?|Z|[+-]\d{4}))?\s*$',
);

/// Besleme tarihlerini çözer.
///
/// Atom ISO-8601 kullanır, RSS 2.0 ise RFC 822 (`Mon, 20 Jul 2026 10:00:00
/// GMT`) — `DateTime.parse` ikincisini okuyamaz, bu yüzden elle çözülür.
/// Sonuç her zaman UTC'dir.
DateTime? parseFeedDate(String? raw) {
  if (raw == null) return null;
  final value = raw.trim();
  if (value.isEmpty) return null;

  final iso = DateTime.tryParse(value);
  if (iso != null) return iso.toUtc();

  final match = _rfc822Pattern.firstMatch(value);
  if (match == null) return null;
  final month = _months[match[2]!.toLowerCase()];
  if (month == null) return null;

  var year = int.parse(match[3]!);
  // RFC 822 iki haneli yıla izin verir; RFC 2822 dört haneyi şart koşar.
  if (year < 100) year += year < 70 ? 2000 : 1900;

  final utc = DateTime.utc(
    year,
    month,
    int.parse(match[1]!),
    int.parse(match[4]!),
    int.parse(match[5]!),
    int.parse(match[6] ?? '0'),
  );

  final zone = match[7];
  if (zone == null || zone == 'Z' || zone.startsWith('U') || zone == 'GMT') {
    return utc;
  }
  final sign = zone[0] == '-' ? -1 : 1;
  final offset = Duration(
    hours: int.parse(zone.substring(1, 3)),
    minutes: int.parse(zone.substring(3, 5)),
  );
  return utc.subtract(offset * sign);
}
