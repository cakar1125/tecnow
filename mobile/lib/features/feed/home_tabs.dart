/// Ana Sayfa'nın sekme şeridi — **kullanıcının seçtiği konulardan** kurulur.
///
/// ## Neden değişti
///
/// Sekmeler dört sabit başlıktı: `SANA ÖZEL / GÜNDEM / GİTHUB / AI MODELLERİ`.
/// Üçü içerik **türü** ya da **kaynak** süzgeciydi, yani uygulamanın kendi
/// şeması. Bundle'da sekmeler kullanıcının takip ettiği konulardır ve sıraları
/// kullanıcıya aittir; ana sayfayı "benim" yapan mekanik bu.
///
/// ## Ölçüm — neden `TÜMÜ` sekmesi var
///
/// Sekmeleri **yalnız** ilgi alanlarından kurmak denendi ve ölçüm onu
/// reddetti. Gerçek akışta (2026-08-11 üretimi, 200 kayıt):
///
/// | Konu | Eşleşen |
/// |---|---|
/// | Yapay Zekâ | 119 |
/// | Bulut | 20 |
/// | Veri Bilimi | 13 |
/// | Siber Güvenlik | 9 |
/// | Açık Kaynak | 8 |
/// | Mobil | 4 |
/// | Donanım | 4 |
/// | Oyun | 2 |
///
/// **En az bir konuya giren: 133/200.** Yani 67 kayıt sekiz ilgi alanının
/// hiçbirine girmiyor (31'inin konusu hiç yok, 36'sınınki sözlükte karşılıksız:
/// `blog`, `release`, `company`…). Sekmeler yalnız konudan kurulsaydı akışın
/// **üçte biri Ana Sayfa'dan görünmez** olurdu — üstelik sessizce.
///
/// `TÜMÜ` bunu kapatıyor: sona sabitlenmiş, süzgeçsiz sekme. Kullanıcı bir şey
/// kaçırdığında bakacağı yer var.
///
/// Aynı ölçüm ikinci bir şey daha söylüyor: konular arasında **60 kat** fark
/// var. "Oyun" sekmesi 2 kayıt gösterecek. Bu bir kusur değil, kullanıcının
/// kendi seçimi — ama sekmeyi gizlemek yanlış olurdu: seçtiği bir konunun
/// karşılığını göremeyen kullanıcı, uygulamanın seçimini yok saydığını sanır.
/// Sekme duruyor, boş kaldığında **neden** boş olduğunu söylüyor.
library;

import '../../data/feed/feed_schema.dart';
import '../../data/interests/interest_taxonomy.dart';
import '../../ui/turkish_case.dart';

/// Sekmenin ne yaptığı. Etiket değil **davranış**: süzgeç ve boş durum metni
/// buradan seçiliyor.
enum HomeTabKind {
  /// Seçili konuların **birleşimi**. Hiç seçim yoksa akışın tamamı.
  forYou,

  /// Tek bir konu.
  interest,

  /// Süzgeçsiz. Kapatılmış kaynaklar yine elenir — o kullanıcının kendi
  /// kararı ve `TÜMÜ` onu geçersiz kılmaz.
  all,
}

final class HomeTab {
  const HomeTab._fixed({
    required this.key,
    required this.label,
    required this.kind,
  }) : interest = null;

  HomeTab.ofInterest(Interest this.interest)
    : key = interest.id,
      // Türkçe büyütme: `toUpperCase()` "Mobil"i "MOBIL", "Veri Bilimi"ni
      // "VERI BILIMI" yapıyor (bkz. `turkish_case.dart`).
      label = toUpperCaseTr(interest.label),
      kind = HomeTabKind.interest;

  /// Her zaman **ilk** sekme. Sıralamaya girmez: kullanıcının kendi akışı
  /// açılış ekranıdır, bir seçenek değil.
  static const forYou = HomeTab._fixed(
    key: 'sana-ozel',
    label: 'SANA ÖZEL',
    kind: HomeTabKind.forYou,
  );

  /// Her zaman **son** sekme. Yukarıdaki 67 kayıtlık ölçüm yüzünden var.
  static const all = HomeTab._fixed(
    key: 'tumu',
    label: 'TÜMÜ',
    kind: HomeTabKind.all,
  );

  /// Kalıcı kimlik. Seçili sekme bununla hatırlanıyor — sıra değişince
  /// kullanıcı başka bir sekmeye atlamasın diye indeksle değil.
  final String key;

  final String label;
  final HomeTabKind kind;

  /// [HomeTabKind.interest] dışında `null`.
  final Interest? interest;
}

/// Sekme şeridi: `SANA ÖZEL` + konular (kullanıcı sırasıyla) + `TÜMÜ`.
///
/// Hiç konu seçilmemişse iki sekme kalır ve ikisi de aynı listeyi gösterir
/// (`SANA ÖZEL` seçim yokken her şeyi gösterir). Kopya duruyor çünkü şerit
/// **yapı**: kullanıcı konu seçtiğinde sekmelerin arasına gireceğini görmesi,
/// bir gün ortaya çıkan gizli bir şeridi keşfetmesinden iyi.
List<HomeTab> homeTabsFor(List<Interest> interests) => [
  HomeTab.forYou,
  for (final interest in interests) HomeTab.ofInterest(interest),
  HomeTab.all,
];

/// Sekmenin gösterdiği kayıtlar.
///
/// [items] **kapatılmış kaynaklar elendikten sonra** verilir; bu işlev
/// susturmayı bilmez ve bilmemeli — iki ayrı karar.
List<FeedItem> itemsForTab(
  HomeTab tab,
  List<FeedItem> items,
  Set<String> interests,
) => switch (tab.kind) {
  HomeTabKind.forYou => filterByInterests(items, interests),
  HomeTabKind.interest =>
    items
        .where((item) => itemMatchesInterest(item, tab.interest!))
        .toList(growable: false),
  HomeTabKind.all => items,
};

/// Seçili sekme kimliğini geçerli bir sekmeye çevirir.
///
/// Kullanıcı "Oyun" sekmesindeyken Keşfet'ten o konuyu kapatabilir; sekme
/// listeden düşer ve elde kalan kimlik hiçbir şeye karşılık gelmez. O an ekranı
/// boş bırakmak ya da atmak yerine ilk sekmeye dönülür.
HomeTab resolveHomeTab(List<HomeTab> tabs, String? selectedKey) {
  for (final tab in tabs) {
    if (tab.key == selectedKey) return tab;
  }
  return tabs.first;
}

/// "SANA" gerekçesi bu sekmede bilgi taşır mı?
///
/// Taşımaz: konu sekmesindeki **her** kayıt tanım gereği o konuyla eşleşmiş,
/// `SANA ÖZEL`dekiler de seçimlerin birleşimiyle. Her satırda aynı etiketi
/// yazmak hiçbir kaydı diğerinden ayırmaz. Aynı kusur cihazda bir kez görüldü
/// (2026-08-11) ve `feed_signal.dart` içinde ölçümüyle yazılı.
///
/// `TÜMÜ` sekmesinde tersi doğru: orada eşleşme **istisnadır**, dolayısıyla
/// bilgidir.
bool suppressesInterestSignal(HomeTab tab) => tab.kind != HomeTabKind.all;
