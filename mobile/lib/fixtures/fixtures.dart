// DESIGN_FIXTURE_ONLY
// NOT_LIVE_DATA
// NOT_VERIFIED

class RepositoryFixture {
  const RepositoryFixture({
    required this.name,
    required this.description,
    required this.language,
    required this.stars,
    required this.forks,
    required this.issues,
  });

  final String name;
  final String description;
  final String language;
  final String stars;
  final String forks;
  final String issues;
}

class AiModelFixture {
  const AiModelFixture({
    required this.name,
    required this.maker,
    required this.summary,
    required this.context,
    required this.architecture,
    required this.modalities,
  });

  final String name;
  final String maker;
  final String summary;
  final String context;
  final String architecture;
  final String modalities;
}

class TechnologyFixture {
  const TechnologyFixture(this.category, this.title, this.summary);
  final String category;
  final String title;
  final String summary;
}

class NotificationFixture {
  const NotificationFixture(this.title, this.detail, this.time);
  final String title;
  final String detail;
  final String time;
}

enum SavedItemKind { repository, aiModel, tool, skill, assistantProject }

enum ExploreFilter { github, aiModelleri, aiAraclari, skills, mcp }

enum ExploreAccentKind { primary, ai, warning }

class ExploreResultFixture {
  const ExploreResultFixture({
    required this.filters,
    required this.id,
    required this.categoryLine,
    required this.title,
    required this.summary,
    required this.matchReason,
    required this.sourceLabel,
  });

  final Set<ExploreFilter> filters;
  final String id;
  final String categoryLine;
  final String title;
  final String summary;
  final String matchReason;
  final String sourceLabel;
}

class ExploreStarterFixture {
  const ExploreStarterFixture({
    required this.categoryLine,
    required this.title,
    required this.summary,
    required this.readingTime,
  });

  final String categoryLine;
  final String title;
  final String summary;
  final String readingTime;
}

class ExplorePopularFixture {
  const ExplorePopularFixture({
    required this.id,
    required this.title,
    required this.summary,
    required this.accentKind,
  });

  final String id;
  final String title;
  final String summary;
  final ExploreAccentKind accentKind;
}

class SavedItemFixture {
  const SavedItemFixture({
    required this.kind,
    required this.id,
    required this.title,
    required this.sourceLabel,
    required this.summary,
  });

  final SavedItemKind kind;
  final String id;
  final String title;
  final String sourceLabel;
  final String summary;
}

const repositoryFixture = RepositoryFixture(
  name: 'örnek-lab/akış-motoru',
  description: 'Mobil teknoloji akışları için hayalî ve yerel bir örnek proje.',
  language: 'Dart',
  stars: '12,8K',
  forks: '842',
  issues: '12',
);

const aiModelFixture = AiModelFixture(
  name: 'Sentez-2 Mini',
  maker: 'Örnek AI Laboratuvarı',
  summary:
      'Cihaz üstü deneyimleri göstermek için hazırlanmış hayalî model kartı.',
  context: '128K örnek',
  architecture: 'MoE örnek',
  modalities: 'Metin · Görsel',
);

const technologyFixtures = [
  TechnologyFixture(
    'MOBİL',
    'Yerel önbellekle daha akıcı deneyimler',
    'Örnek duyuru: ağ bağlantısı olmadan çalışan arayüz ilkeleri.',
  ),
  TechnologyFixture(
    'GELİŞTİRİCİ',
    'Dart ile erişilebilir bileşen tasarımı',
    'Örnek rehber: semantics ve büyük metin ölçeği kontrolü.',
  ),
];

const notificationFixtures = [
  NotificationFixture(
    'Yeni teknoloji özeti',
    'Örnek haftalık seçkin hazır.',
    '2 dk',
  ),
  NotificationFixture(
    'Koleksiyon güncellendi',
    'Mobil geliştirme koleksiyonuna örnek eklendi.',
    '1 sa',
  ),
  NotificationFixture(
    'Takip edilen kaynak',
    'Hayalî Örnek Lab yeni bir not paylaştı.',
    'Dün',
  ),
];

const savedItemFixtures = [
  SavedItemFixture(
    kind: SavedItemKind.repository,
    id: 'akis-motoru',
    title: 'örnek-lab/hayali-akis-motoru',
    sourceLabel: 'Örnek Kod Arşivi',
    summary:
        'Hayalî mobil akışları göstermek için hazırlanmış örnek repository kaydı.',
  ),
  SavedItemFixture(
    kind: SavedItemKind.aiModel,
    id: 'sentez-mini',
    title: 'Hayalî Sentez Mini',
    sourceLabel: 'Örnek AI Laboratuvarı',
    summary:
        'Tamamen hayalî sınıflandırma denemelerini anlatan örnek AI model kaydı.',
  ),
  SavedItemFixture(
    kind: SavedItemKind.tool,
    id: 'akis-pusulasi',
    title: 'Hayalî Akış Pusulası',
    sourceLabel: 'Örnek Araç Atölyesi',
    summary:
        'Yerel arayüz akışlarını taslaklayan hayalî bir geliştirici aracı kaydı.',
  ),
  SavedItemFixture(
    kind: SavedItemKind.skill,
    id: 'erisilebilir-kartlar',
    title: 'Örnek Erişilebilir Kartlar Becerisi',
    sourceLabel: 'Hayalî Öğrenme Alanı',
    summary:
        'Kart erişilebilirliğini çalışmak için hazırlanmış hayalî beceri kaydı.',
  ),
  SavedItemFixture(
    kind: SavedItemKind.assistantProject,
    id: 'taslak-yardimci',
    title: 'Hayalî Taslak Yardımcı',
    sourceLabel: 'Örnek Asistan Stüdyosu',
    summary:
        'Yalnız fixture deneyimi için tanımlanmış hayalî asistan projesi kaydı.',
  ),
];

const exploreResultFixtures = [
  ExploreResultFixture(
    filters: {ExploreFilter.github, ExploreFilter.aiAraclari},
    id: 'hayali-akis-kiti',
    categoryLine: 'REPOSITORY · MOBİL',
    title: 'örnek-lab/hayali-akis-kiti',
    summary:
        'Yerel teknoloji akışlarını küçük Dart parçalarıyla örnekleyen hayalî '
        'bir repository kaydı.',
    matchReason:
        'Aramanızdaki akış ve mobil geliştirme kavramları başlık ile özette '
        'birlikte yer alıyor.',
    sourceLabel: 'ornek-lab.test/akis-kiti',
  ),
  ExploreResultFixture(
    filters: {ExploreFilter.aiModelleri},
    id: 'kivilcim-model-karti',
    categoryLine: 'AI MODEL · METİN',
    title: 'Hayalî Kıvılcım Model Kartı',
    summary:
        'Kısa Türkçe metinleri konu başlıklarına ayırmayı temsil eden, gerçek '
        'olmayan bir model fixture kaydı.',
    matchReason:
        'Model ve Türkçe metin sorgunuz bu örneğin açıklamasıyla doğrudan '
        'örtüşüyor.',
    sourceLabel: 'hayali-model.test/kivilcim',
  ),
  ExploreResultFixture(
    filters: {ExploreFilter.github, ExploreFilter.skills},
    id: 'arayuz-pusulasi',
    categoryLine: 'SKILL · UI/UX',
    title: 'Örnek Arayüz Pusulası Becerisi',
    summary:
        'Erişilebilir arayüz kartlarını ve farklı ekran genişliklerini '
        'inceleyen hayalî bir öğrenme becerisi.',
    matchReason:
        'Arayüz aramanız ve Skills filtresi bu kaydın beceri alanıyla '
        'eşleşiyor.',
    sourceLabel: 'ornek-beceri.test/arayuz-pusulasi',
  ),
  ExploreResultFixture(
    filters: {ExploreFilter.mcp},
    id: 'baglam-koprusu',
    categoryLine: 'MCP · YEREL BAĞLAM',
    title: 'Hayalî Bağlam Köprüsü',
    summary:
        'Yerel fixture bağlamını araçlara aktarma fikrini açıklayan kurgu bir '
        'MCP tanıtım kaydı.',
    matchReason:
        'Bağlam ve MCP kavramları hem kategori satırında hem açıklamada yer '
        'alıyor.',
    sourceLabel: 'hayali-baglam.test/kopru',
  ),
  ExploreResultFixture(
    filters: {ExploreFilter.aiAraclari},
    id: 'fikir-haritasi',
    categoryLine: 'AI ARACI · PLANLAMA',
    title: 'Örnek Fikir Haritası Aracı',
    summary:
        'Proje fikirlerini yerel örnek adımlara bölen tamamen hayalî bir AI '
        'aracı kaydı.',
    matchReason:
        'Planlama ve AI aracı sorgunuz bu örneğin tanımlanan kullanım amacıyla '
        'eşleşiyor.',
    sourceLabel: 'ornek-arac.test/fikir-haritasi',
  ),
];

const exploreStarterFixtures = [
  ExploreStarterFixture(
    categoryLine: 'SKILL · EĞİTİM',
    title: 'Örnek Erişilebilir Arayüz Başlangıcı',
    summary:
        'Hayalî bir uygulama üzerinden okunabilir kart düzenlerini keşfedin.',
    readingTime: '15 dk okuma',
  ),
  ExploreStarterFixture(
    categoryLine: 'AI MODEL · REHBER',
    title: 'Hayalî Model Kartlarını Okuma',
    summary:
        'Örnek model açıklamalarını ve teknik metadata alanlarını tanıyın.',
    readingTime: '12 dk okuma',
  ),
  ExploreStarterFixture(
    categoryLine: 'MCP · TEMELLER',
    title: 'Örnek Yerel Bağlam Akışı',
    summary:
        'Kurgu bir bağlam akışının araçlar arasında nasıl ilerlediğini görün.',
    readingTime: '10 dk okuma',
  ),
];

const explorePopularFixtures = [
  ExplorePopularFixture(
    id: 'hayali-mobil-notlari',
    title: 'Hayalî Mobil Arayüz Notları',
    summary: 'Kompakt ekranlar için örnek yerleşim kararları.',
    accentKind: ExploreAccentKind.primary,
  ),
  ExplorePopularFixture(
    id: 'ornek-model-rehberi',
    title: 'Örnek Model Seçim Rehberi',
    summary: 'Kurgu ihtiyaçları hayalî model özellikleriyle eşleştirin.',
    accentKind: ExploreAccentKind.ai,
  ),
  ExplorePopularFixture(
    id: 'hayali-arac-kutusu',
    title: 'Hayalî Geliştirici Araç Kutusu',
    summary: 'Yerel geliştirme akışı için örnek araç fikirleri.',
    accentKind: ExploreAccentKind.warning,
  ),
];

const interestFixtures = [
  'Yapay Zekâ',
  'Mobil',
  'Açık Kaynak',
  'Siber Güvenlik',
  'Bulut',
  'Donanım',
  'Oyun',
  'Veri Bilimi',
];
