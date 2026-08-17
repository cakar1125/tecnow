/// Kaynak belgeleri — README ve model kartı.
///
/// **Neden var.** 17 Ağustos 2026'da ölçüldü: yayımlanan 200 kaydın özet
/// ortalaması 175 karakter, Hugging Face tarafında 97; kapının üst sınırı
/// 400. Sebep model ya da yönerge değil, **girdi**. Özetleyiciye yalnız
/// başlık ve tek satırlık açıklama gidiyordu:
///
///     lexmount/moli
///     An AI-native browser for agents
///
/// Bu iki satırdan derin bir özet çıkmaz. Çıkarsa uydurmadır ve kapı zaten
/// reddeder. Depoların README'si ve modellerin kartı ise gerçek metindir:
/// ne yaptığı, neyi çözdüğü, neye bağlandığı orada yazar.
///
/// **Yalnız GitHub deposu ve Hugging Face modeli için çekilir.** Blog ve
/// duyuru kayıtları besleme akışından zaten düzyazı getiriyor; onlar için ek
/// istek, kazanç getirmeyen bir ağ maliyeti olurdu.
///
/// **Belge feed'e yazılmaz.** Yalnız üretim anında yaşar ve özetleyiciye
/// verilir; `feed.json` her kaydın README'sini taşısaydı dosya megabaytlara
/// çıkardı.
library;

import 'dart:convert';

import 'package:tecos/data/feed/feed_schema.dart';

import 'connectors/connector_support.dart';
import 'fetch.dart';

/// Bir belgeden alınacak en fazla karakter.
///
/// README'ler on binlerce karakter olabiliyor. Tamamını göndermek jeton
/// harcamaktan çok **üretim süresini** uzatır: uç nokta akış kullanmadığı
/// için cevap ancak üretim bitince geliyor ve çağrılar hâlihazırda 90 saniye
/// sınırına dayanıyor.
///
/// 2000 karakter, bir README'nin "bu nedir / ne işe yarar" bölümünü
/// kapsayan uzunluk. Kurulum yönergeleri ve katkı rehberi zaten özete
/// girmemeli.
const documentCharLimit = 2000;

/// Bir koşuda çekilecek en fazla belge.
///
/// Özet bütçesiyle aynı büyüklük sırasında tutuluyor: özetlenmeyecek bir
/// kaydın belgesini indirmenin faydası yok.
const documentFetchLimit = 120;

/// [items] içinden belgesi olabilecek kayıtlar için belgeyi çeker.
///
/// Dönen harita **kayıt kimliğinden** belgeye. Çekilemeyen kayıtlar haritada
/// yoktur; bu bir hata değildir — README'si olmayan depo vardır ve o kayıt
/// eldeki açıklamayla özetlenir.
///
/// Hiçbir hata yukarı taşınmaz. Belge bir **iyileştirme**dir; yokluğu feed'i
/// düşürmemeli.
Future<Map<String, String>> fetchDocuments(
  List<FeedItem> items, {
  required FeedFetcher fetcher,
  int limit = documentFetchLimit,
  int charLimit = documentCharLimit,
}) async {
  final documents = <String, String>{};
  var fetched = 0;

  for (final item in items) {
    if (fetched >= limit) break;
    final url = documentUrlFor(item);
    if (url == null) continue;

    fetched++;
    final FetchResponse response;
    try {
      response = await fetcher.fetch(url);
    } on Object {
      continue;
    }
    if (!response.isOk) continue;

    final raw = item.sourceKind == FeedSourceKind.github
        ? _decodeGitHubReadme(response.body)
        : response.body;
    if (raw == null) continue;

    final text = cleanDocument(raw, charLimit: charLimit);
    if (text.isEmpty) continue;
    documents[item.id] = text;
  }

  return documents;
}

/// Kaydın belge adresi; belgesi olamayacak kayıtlar için `null`.
///
/// Adres **kaydın kendi adresinden** kuruluyor, elde tutulan bir listeden
/// değil: kayıt zaten izin listesinden geçmiş olduğu için türetilen adres de
/// aynı kökenden olur.
Uri? documentUrlFor(FeedItem item) {
  final segments = item.url.pathSegments
      .where((segment) => segment.isNotEmpty)
      .toList(growable: false);
  if (segments.length < 2) return null;

  switch (item.sourceKind) {
    case FeedSourceKind.github:
      // Yalnız depo kökü. `github.com/flutter/flutter/releases/tag/3.0` gibi
      // bir sürüm adresinin README'si yoktur ve zaten sürüm notu kendisi
      // düzyazıdır.
      if (segments.length != 2) return null;
      // API yolu tercih edildi: `githubToken` yalnız `api.github.com`'a
      // gönderiliyor (bkz. `HttpFeedFetcher.headersFor`) ve token saatlik
      // sınırı 60'tan 5000'e çıkarıyor.
      return Uri.https(
        'api.github.com',
        '/repos/${segments[0]}/${segments[1]}/readme',
      );
    case FeedSourceKind.huggingFace:
      if (segments.length != 2) return null;
      return Uri.https(
        'huggingface.co',
        '/${segments[0]}/${segments[1]}/raw/main/README.md',
      );
    case FeedSourceKind.officialBlog:
    case FeedSourceKind.documentation:
    case FeedSourceKind.other:
      return null;
  }
}

/// GitHub `/readme` yanıtı gövdeyi **base64** taşır.
String? _decodeGitHubReadme(String body) {
  final Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException {
    return null;
  }
  if (decoded is! Map) return null;
  if (decoded['encoding'] != 'base64') return null;
  final content = decoded['content'];
  if (content is! String) return null;
  try {
    // GitHub base64'ü satırlara bölerek gönderiyor.
    return utf8.decode(base64.decode(content.replaceAll('\n', '')));
  } on Object {
    return null;
  }
}

/// Ham markdown'ı modele verilebilir düzyazıya indirir.
///
/// Temizlenenler ve **neden**:
/// - **YAML ön bilgisi** — model kartları `---` bloğuyla başlıyor; makine
///   için, okuyucu için değil.
/// - **Kod blokları** — kurulum komutları özete girmemeli ve jetonun büyük
///   kısmını onlar yiyor.
/// - **Rozetler ve görseller** — `[![build](...)](...)` yalnız bağlantı
///   gürültüsü. Kapı ([verifySummary]) kaynakta geçen bağlantıyı geçerli
///   sayar; rozetleri bırakmak modele "bağlantı yazabilirsin" demek olurdu.
/// - **Başlık işaretleri ve tablo çizgileri** — anlam taşımıyor.
///
/// Sıra önemli: kod blokları ön bilgiden **sonra** temizleniyor, çünkü ön
/// bilgi ayracı (`---`) yatay çizgiyle aynı işaret ve önce çizgiler
/// silinseydi ön bilgi bloğu tanınamazdı.
String cleanDocument(String raw, {int charLimit = documentCharLimit}) {
  var text = raw.replaceAll('\r\n', '\n');

  // YAML ön bilgisi: dosyanın en başındaki `---` … `---`.
  if (text.startsWith('---\n')) {
    final end = text.indexOf('\n---', 4);
    if (end != -1) text = text.substring(end + 4);
  }

  text = text
      // Çitli kod blokları.
      .replaceAll(RegExp(r'```[\s\S]*?```'), ' ')
      // Görseller ve rozetler — bağlantılardan **önce**, çünkü rozet bir
      // görselin bağlantıya sarılmış hâli.
      .replaceAll(RegExp(r'!\[[^\]]*\]\([^)]*\)'), ' ')
      // Bağlantı: metni kalır, adresi gider.
      .replaceAllMapped(RegExp(r'\[([^\]]*)\]\([^)]*\)'), (m) => m[1] ?? '')
      // Ham HTML etiketleri.
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      // Başlık, alıntı ve liste işaretleri satır başında.
      .replaceAll(RegExp(r'^[#>\-*+]+\s*', multiLine: true), '')
      // Tablo çizgileri.
      .replaceAll(RegExp(r'^\|?[\s:|-]{4,}\|?$', multiLine: true), ' ')
      // Ters tırnak, yıldız, alt çizgi vurguları.
      .replaceAll(RegExp(r'[`*_]'), '');

  return truncateSummary(normalizeSpaces(text), limit: charLimit);
}
