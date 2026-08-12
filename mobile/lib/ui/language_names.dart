/// Dil kodlarının kullanıcıya gösterilen adları.
///
/// Ad **kendi dilinde** yazılıyor ("Deutsch", "English"), Türkçe karşılığıyla
/// değil ("Almanca", "İngilizce"). Sebep listeyi okuyan kişi: Almanca bir
/// seçenek arayan biri arayüzü anlamıyor olabilir ve "Almanca" ona hiçbir şey
/// söylemez. Bu, dil seçicinin her yerde aynı olan tek kuralı.
///
/// Üretici tarafındaki `tool/feed/summarize.dart` benzer bir tablo taşıyor ama
/// **başka bir iş** için: orada adlar modele verilen yönergenin içinde geçiyor
/// ve Türkçe olmaları gerekiyor. İki tablo bilinçli olarak ayrı; birleştirmek,
/// birinin gereksinimini diğerine dayatmak olurdu.
library;

const _names = <String, String>{
  'tr': 'Türkçe',
  'en': 'English',
  'de': 'Deutsch',
  'fr': 'Français',
  'es': 'Español',
  'ar': 'العربية',
};

/// Bilinmeyen kod **kodun kendisiyle** gösterilir.
///
/// Sunucu bir gün tanımadığımız bir dil eklerse kullanıcı onu yine de görür ve
/// seçebilir. Alternatif — bilinmeyen dili listeden düşürmek — kurulu
/// uygulamayı yeni dillere karşı sağır yapardı ve tam olarak kaçındığımız
/// şey o: dil listesinin sunucudan gelmesinin sebebi, uygulama güncellemesi
/// gerektirmemesi.
String languageName(String code) => _names[code] ?? code;
