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
