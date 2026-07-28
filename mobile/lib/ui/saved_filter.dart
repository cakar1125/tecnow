/// Kaydedilenler ekranının süzgeç modeli.
///
/// Ekrandan ayrı duruyor, `ExploreFilter` ile aynı gerekçeyle: asıl karar
/// "hangi çip hangi türü gösterir" ve bu, widget testiyle değil doğrudan
/// birim testiyle ölçülmesi gereken bir şey.
///
/// Öncesinde bu eşleme `lib/fixtures/fixtures.dart` içindeki `SavedItemKind`
/// üzerinden yapılıyordu — yani üretimdeki süzgeç mantığı `DESIGN_FIXTURE_ONLY`
/// başlıklı bir dosyaya bağlıydı. Aynı kategori hatası Keşfet için zaten
/// düzeltilmişti; burası atlanmıştı.
library;

import '../data/feed/feed_schema.dart';

enum SavedFilter { repository, aiModel, tool, skill, announcement, assistant }

/// Çip etiketleri.
const savedFilterLabels = {
  SavedFilter.repository: 'Repository',
  SavedFilter.aiModel: 'AI',
  SavedFilter.tool: 'Araçlar',
  SavedFilter.skill: 'Skills',
  SavedFilter.announcement: 'Duyurular',
  SavedFilter.assistant: 'Asistan Projeleri',
};

/// Süzgeç → eşleşen feed türleri.
///
/// **Araçlar** hem `tool` hem `mcp` alır: MCP sunucusu bir araçtır ve onaylı
/// tasarımda ayrı bir çipi yok.
///
/// **Asistan Projeleri** bugün boş küme döner, çünkü asistan henüz hiçbir şey
/// yazmıyor. Boş küme "bu çip hiçbir şeyle eşleşemez" demek ve ekran bunu
/// kullanarak çipi hiç göstermiyor (bkz. [visibleSavedFilters]).
Set<FeedItemKind> savedFilterKinds(SavedFilter filter) => switch (filter) {
  SavedFilter.repository => const {FeedItemKind.repository},
  SavedFilter.aiModel => const {FeedItemKind.aiModel},
  SavedFilter.tool => const {FeedItemKind.tool, FeedItemKind.mcp},
  SavedFilter.skill => const {FeedItemKind.skill},
  SavedFilter.announcement => const {FeedItemKind.announcement},
  SavedFilter.assistant => const {},
};

/// Gösterilecek çipler: eşleşebileceği bir tür olanlar.
///
/// Eşleşemeyen bir çip, dokunulduğunda **her zaman** "Bu filtrede kayıt
/// kalmadı." diyen bir düğmedir; yani çalışmayan bir kontrol. Asistan
/// uygulandığında [savedFilterKinds] gerçek bir tür döndürecek ve çip
/// kendiliğinden geri gelecek — burada ayrıca bir bayrak tutmaya gerek yok.
///
/// **Duyurular** çipi 2026-07-28'de eklendi. O gün ölçüldü: üretilen 200
/// kaydın **146'sı** duyuru, yani akışın en büyük kategorisiydi ve
/// kaydedildiğinde yalnız "Tümü" altında görünüyordu. Süzgeç şeridinde
/// hiçbir zaman eşleşmeyen bir çip varken en kalabalık türün çipi yoktu.
List<SavedFilter> get visibleSavedFilters => [
  for (final filter in SavedFilter.values)
    if (savedFilterKinds(filter).isNotEmpty) filter,
];

/// Kaydın türü bu süzgece giriyor mu?
bool savedItemMatchesFilter(FeedItemKind? kind, SavedFilter filter) =>
    kind != null && savedFilterKinds(filter).contains(kind);
