import '../data/feed/feed_schema.dart';
import '../data/interests/interest_taxonomy.dart';

/// Bir kaydın **neden burada olduğunu** söyleyen tek kelimelik gerekçe.
///
/// Akış satırının altında `KAYNAK · GEREKÇE` biçiminde görünür. Amaç, aynı
/// görünen iki yüz kaydı birbirinden ayırmak: kaynak kaydın nereden geldiğini,
/// gerekçe **neden gösterildiğini** söyler.
///
/// Aynı anda yalnız **bir** gerekçe gösterilir. İki etiket bir arada
/// gürültüdür ve hangisinin önemli olduğunu anlatmaz; sıralama aşağıda
/// **nadirliğe** göre sabitlendi: bir etiket kayıtların çoğuna yapışıyorsa
/// hiçbir kaydı diğerinden ayırmaz.
///
/// Sıra tahminle değil ölçümle kuruluyor —
/// `dart run tool/measure_signals.dart` dağılımı gerçek akış üzerinde basar
/// ve bu sıralama bir kez o çıktı yüzünden değişti.
enum FeedSignal {
  /// Özeti kaynak değil biz yazdık. Sıranın **başında**, çünkü bu bir
  /// kaynak beyanı değil bizim beyanımız: `CONTENT_TRUST_POLICY.md` tecOS
  /// özetinin orijinalinden ayrılmasını şart koşuyor. Ölçüldü: 20/200.
  generatedSummary('tecOS ÖZETİ'),

  /// Son 24 saatte yayımlandı. Ölçüldü (2026-07-28 üretimi): 13/200 —
  /// nadir olduğu için bilgi taşıyor.
  fresh('YENİ'),

  /// Kullanıcının seçtiği ilgi alanlarıyla eşleşti.
  ///
  /// [fresh]'in **altında**, ve bu sıra bir ölçümle düzeltildi (2026-08-11).
  /// Önce üstündeydi; `TÜMÜ` sekmesinde sonuç şuydu:
  ///
  /// | | seçim yok | 3 konu seçili |
  /// |---|---|---|
  /// | SANA | — | 102/200 (%51) |
  /// | YENİ | 13/200 | **4/200** |
  ///
  /// Yani kullanıcı konu seçtiği anda, akışın en taze 13 kaydının dokuzu
  /// "YENİ" etiketini kaybedip akışın yarısında görünen bir etikete
  /// dönüşüyordu. %51'lik bir etiket %6,5'lik bir etiketi yutuyordu — bu
  /// dosyanın kendi ilkesinin (nadirlik = bilgi) tersi.
  matchesInterest('SANA'),

  /// Kaynağın kendi duyurusu.
  ///
  /// Listenin **sonunda**, çünkü en yaygın olan bu: 123/200 kayıt `official`
  /// işaretini taşıyor ve hiç konu seçilmemişken 110/200 satır (%55) bu
  /// etiketle çiziliyor. Çoğunluğun taşıdığı bir etiket ayırt edici değildir;
  /// yalnız başka gerekçe yokken gösteriliyor.
  ///
  /// Sondaki yeri bir maliyet de doğuruyor: kullanıcı konu seçtikçe bu etiket
  /// 110 → 74 → 65'e iniyor, yani `SANA` onun yerini alıyor. Kabul edilebilir,
  /// çünkü ikisi de yaygın; ama `YENİ`'nin (13/200) yutulması kabul edilebilir
  /// değildi ve sıra o yüzden düzeltildi (bkz. [matchesInterest]).
  officialSource('RESMİ KAYNAK');

  const FeedSignal(this.label);

  final String label;
}

/// Kaydın gerekçesini seçer. Hiçbiri uymuyorsa `null` — uydurulmuş bir
/// etiket, etiketsiz bir satırdan kötüdür.
///
/// ## Popülerlik neden burada yok
///
/// `TrustSignals.popularity` bir gerekçe olmaya en yakın alan gibi duruyor
/// ama **iki farklı birimi tek alanda taşıyor.** Ölçüldü (2026-08-11,
/// 200 kayıtlık üretim):
///
/// | Kaynak | n | ortanca | en yüksek |
/// |---|---|---|---|
/// | GitHub (yıldız) | 54 | 209 | 107.031 |
/// | Hugging Face (indirme) | 20 | 16.619.070 | 68.390.818 |
///
/// İki aralık **hiç örtüşmüyor.** Ortak bir eşik ("şu sayının üstü popüler")
/// bütün Hugging Face kayıtlarını etiketler, GitHub'ın en çok yıldızlısını
/// bile etiketlemez — yani sayıyı değil kaynağı ölçer. Karşılaştırılabilir
/// hale gelmesi için şemanın birimi de taşıması gerekir; o gün gelene kadar
/// popülerlik bir gerekçe olarak kullanılmıyor. Detay ekranında ham sayı
/// zaten kaynağıyla birlikte görünüyor, orada yanıltıcı değil.
FeedSignal? feedSignalFor(
  FeedItem item, {
  required Set<String> interests,
  required DateTime now,

  /// "SANA" gerekçesini bastırır.
  ///
  /// Cihazda görüldü (2026-08-11): "Sana Özel" sekmesinde **her satır**
  /// "SANA" diyordu. Doğruydu ama boştu — o sekmedeki her kayıt tanım gereği
  /// ilgi alanlarıyla eşleşiyor, dolayısıyla etiket hiçbir kaydı diğerinden
  /// ayırmıyor ve yalnız gürültü ekliyor. Gerekçe ancak **istisna** olduğunda
  /// bilgi taşır.
  ///
  /// Bastırıldığında sıra bir alta kayar: kayıt varsa "YENİ" ya da
  /// "RESMİ KAYNAK" gösterilir.
  bool suppressInterestSignal = false,
}) {
  if (item.summaryOrigin != SummaryOrigin.original) {
    return FeedSignal.generatedSummary;
  }
  // Tazelik ilgi eşleşmesinin **üstünde**: 13/200'e karşı 102/200. Sıra
  // 2026-08-11'de ölçümle düzeltildi, gerekçesi [FeedSignal.matchesInterest]
  // içinde tabloyla yazılı.
  if (now.difference(item.publishedAt) < const Duration(hours: 24)) {
    return FeedSignal.fresh;
  }
  if (!suppressInterestSignal &&
      interests.isNotEmpty &&
      _matchesAnyInterest(item, interests)) {
    return FeedSignal.matchesInterest;
  }
  if (item.trust.officialSource) return FeedSignal.officialSource;
  return null;
}

bool _matchesAnyInterest(FeedItem item, Set<String> ids) {
  for (final id in ids) {
    final interest = interestById(id);
    // Tanınmayan kimlik sessizce atlanır — `filterByInterests` ile aynı
    // davranış, iki yer aynı seçim kümesini okuyor.
    if (interest == null) continue;
    if (itemMatchesInterest(item, interest)) return true;
  }
  return false;
}
