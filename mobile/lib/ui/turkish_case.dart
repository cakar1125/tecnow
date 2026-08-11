/// Türkçe büyük harf.
///
/// `String.toUpperCase()` Unicode'un **varsayılan** kuralını uygular ve orada
/// `i`'nin büyüğü `I`'dır. Türkçede değil: `i` → `İ`, `ı` → `I`. İki harf ayrı
/// harftir, biri diğerinin noktasız hâli değildir.
///
/// Ölçüldü (2026-08-11, `dart` ile doğrudan):
///
/// | girdi | `toUpperCase()` | doğrusu |
/// |---|---|---|
/// | `Mobil` | `MOBIL` | `MOBİL` |
/// | `Veri Bilimi` | `VERI BILIMI` | `VERİ BİLİMİ` |
/// | `Siber Güvenlik` | `SIBER GÜVENLIK` | `SİBER GÜVENLİK` |
///
/// ## Nerede kullanılır, nerede kullanılmaz
///
/// Yalnız **bizim yazdığımız Türkçe** metinde: sekme etiketleri, başlıklar.
/// Orada dil belli ve kural tek.
///
/// Üçüncü tarafın adında **kullanılmaz** — ve o adlar zaten büyütülmüyor.
/// Denendi ve ölçüm reddetti: gerçek kaynak adlarının onu iki dilli
/// (`NVIDIA Geliştirici`, `GitHub Değişiklikler`), yani hiçbir büyütme kuralı
/// dizginin tamamı için doğru olamıyor. Gerekçesi `feed_items.dart` →
/// `FeedMetaLine` başlığında tabloyla yazılı.
///
/// Küçültme karşılığı burada **yok**: uygulamanın küçültmeye ihtiyacı olan tek
/// yeri arama ve orası kendi katlamasını kullanıyor
/// (`explore_search.dart` → `foldForSearch`), çünkü orada `İ` ile `I` aynı
/// harfe inmeli. Görünen metinle aranan metin farklı kurallara tabi; ikisini
/// tek işlevde birleştirmek er geç birini bozar.
library;

/// [value]'yu Türkçe kurallarıyla büyütür.
///
/// `i` dışındaki her karakter Unicode varsayılanına bırakılır — `ı → I`,
/// `ş → Ş`, `ğ → Ğ`, `â → Â` zaten doğru çalışıyor, yalnız `i` yanlış.
String toUpperCaseTr(String value) {
  final buffer = StringBuffer();
  for (final rune in value.runes) {
    final character = String.fromCharCode(rune);
    buffer.write(character == 'i' ? 'İ' : character.toUpperCase());
  }
  return buffer.toString();
}
