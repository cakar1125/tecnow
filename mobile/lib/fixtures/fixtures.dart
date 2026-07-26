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

enum FeedSourceKind { github, aiModel, tool, announcement }

enum FeedTab { sanaOzel, gundem, github, aiModelleri }

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

class FeedItemFixture {
  const FeedItemFixture({
    required this.kind,
    required this.id,
    required this.title,
    required this.sourceLabel,
    required this.summary,
    required this.whatItDoes,
    required this.tags,
    required this.tabs,
  });

  final FeedSourceKind kind;
  final String id;
  final String title;
  final String sourceLabel;
  final String summary;
  final String whatItDoes;
  final List<String> tags;
  final Set<FeedTab> tabs;
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

const feedItemFixtures = [
  FeedItemFixture(
    kind: FeedSourceKind.github,
    id: 'hayali-dalga-motoru',
    title: 'örnek-lab/hayali-dalga-motoru',
    sourceLabel: 'ornek-kod.test',
    summary:
        'Hayalî mobil arayüz akışlarını küçük ve anlaşılır parçalara ayıran örnek kod arşivi.',
    whatItDoes:
        'Ekran geçişlerini yerel fixture verileriyle denemek için örnek bir akış iskeleti sunar.',
    tags: ['Dart', 'Mobil', 'Fixture'],
    tabs: {FeedTab.sanaOzel, FeedTab.github},
  ),
  FeedItemFixture(
    kind: FeedSourceKind.github,
    id: 'kurgu-pusula',
    title: 'örnek-lab/kurgu-pusula',
    sourceLabel: 'hayali-arsiv.test',
    summary:
        'Erişilebilir bileşen denemelerini bir araya getiren tamamen hayalî bir repository kaydı.',
    whatItDoes:
        'Klavye odağı, anlam etiketleri ve büyük metin düzenlerini örnek senaryolarla gösterir.',
    tags: ['Erişilebilirlik', 'UI', 'Örnek'],
    tabs: {FeedTab.gundem, FeedTab.github},
  ),
  FeedItemFixture(
    kind: FeedSourceKind.aiModel,
    id: 'kivilcim-mini',
    title: 'Hayalî Kıvılcım Mini',
    sourceLabel: 'ornek-ai.test',
    summary:
        'Cihaz üstü sınıflandırma kartlarını göstermek amacıyla tanımlanmış hayalî model fixture kaydı.',
    whatItDoes:
        'Kısa örnek metinleri önceden tanımlı hayalî konu başlıklarına ayırma akışını temsil eder.',
    tags: ['Hayalî Model', 'Cihaz Üstü', 'Metin'],
    tabs: {FeedTab.sanaOzel, FeedTab.aiModelleri},
  ),
  FeedItemFixture(
    kind: FeedSourceKind.aiModel,
    id: 'yanki-modeli',
    title: 'Örnek Yankı Modeli',
    sourceLabel: 'hayali-model.test',
    summary:
        'Çok adımlı arayüz açıklamalarını sınamak için hazırlanmış, gerçek olmayan bir AI model kartı.',
    whatItDoes:
        'Fixture senaryolarındaki uzun açıklamaları kısa örnek maddelere dönüştürme davranışını temsil eder.',
    tags: ['Örnek AI', 'Özetleme', 'Yerel'],
    tabs: {FeedTab.gundem, FeedTab.aiModelleri},
  ),
  FeedItemFixture(
    kind: FeedSourceKind.tool,
    id: 'iz-atolyesi',
    title: 'Hayalî İz Atölyesi',
    sourceLabel: 'ornek-arac.test',
    summary:
        'Yerel ekran durumlarını inceleme akışını anlatan hayalî bir geliştirici aracı duyurusu.',
    whatItDoes:
        'Fixture tabanlı kullanıcı adımlarını görsel bir kontrol listesi halinde örnekler.',
    tags: ['Araç', 'Arayüz', 'Kontrol'],
    tabs: {FeedTab.gundem},
  ),
  FeedItemFixture(
    kind: FeedSourceKind.tool,
    id: 'akis-cetveli',
    title: 'Örnek Akış Cetveli',
    sourceLabel: 'hayali-atolye.test',
    summary:
        'Mobil yerleşim aralıklarını karşılaştırmak için tasarlanmış gerçek olmayan araç fixture kaydı.',
    whatItDoes:
        'Farklı ekran genişliklerinde boşluk ve kart ölçülerini örnek değerlerle karşılaştırır.',
    tags: ['Mobil', 'Yerleşim', 'Ölçüm'],
    tabs: {FeedTab.gundem},
  ),
  FeedItemFixture(
    kind: FeedSourceKind.announcement,
    id: 'deney-gunlugu',
    title: 'Hayalî Deney Günlüğü',
    sourceLabel: 'ornek-bulten.test',
    summary:
        'Teknoloji arayüzü denemelerinden kurgusal notlar paylaşan örnek bir duyuru kaydı.',
    whatItDoes:
        'Yeni fixture senaryolarındaki değişiklikleri kısa ve açık örnek notlarla özetler.',
    tags: ['Duyuru', 'Deney', 'Fixture'],
    tabs: {FeedTab.gundem},
  ),
  FeedItemFixture(
    kind: FeedSourceKind.announcement,
    id: 'teknoloji-notlari',
    title: 'Örnek Teknoloji Notları',
    sourceLabel: 'hayali-bulten.test',
    summary:
        'Tamamen hayalî geliştirme başlıklarını bir araya getiren yerel duyuru fixture kaydı.',
    whatItDoes:
        'Örnek teknik konuları okunabilir bir gündem listesi halinde sergiler.',
    tags: ['Gündem', 'Teknoloji', 'Örnek'],
    tabs: {FeedTab.gundem},
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
