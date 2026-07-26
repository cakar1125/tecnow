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
