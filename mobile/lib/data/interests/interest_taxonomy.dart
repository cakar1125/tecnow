/// İlgi alanları sözlüğü.
///
/// Bu dosya 28 Temmuz 2026'da **cihazda bulunan bir kusur** yüzünden yazıldı.
/// "Sana Özel" sekmesi şöyle süzüyordu:
///
/// ```dart
/// items.where((item) => item.topics.any(
///   (topic) => interests.contains(topic.toLowerCase())))
/// ```
///
/// İlgi alanları ekranı Türkçe **etiketleri** saklıyor (`Yapay Zekâ`,
/// `Açık Kaynak`), feed'in konuları ise kaynakların kendi İngilizce
/// slug'ları (`ai-tools`, `llm`, `mcp-server`). İki sözcük dağarcığı
/// **hiçbir zaman kesişmiyor**. Yani onboarding'i tamamlayan her kullanıcı
/// için uygulamanın açılış sekmesi kalıcı olarak boştu; ilgi alanı seçmeyen
/// kullanıcı ise akışın tamamını görüyordu.
///
/// Widget testleri göremedi çünkü ilgi alanı olarak feed'in kendi
/// slug'larını (`['dart']`) veriyorlardı — ürünün hiçbir yerinde
/// üretilmeyen bir değer.
///
/// Çözüm: ilgi alanı artık kalıcı bir kimlik, görünen bir etiket ve feed
/// konularıyla eşleşen anahtar kelimelerden oluşuyor.
library;

import '../feed/feed_schema.dart';
import '../../ui/explore_search.dart' show foldForSearch;

final class Interest {
  const Interest({
    required this.id,
    required this.label,
    required this.keywords,
  });

  /// Kalıcı kimlik. Veritabanına **bu** yazılır; etiket değişse bile
  /// kullanıcının seçimi bozulmaz.
  final String id;

  /// Ekranda görünen ad.
  final String label;

  /// Feed konularıyla eşleştirilen anahtar kelimeler.
  ///
  /// Hepsi küçük harf ve aksansız; eşleşme **belirteç sınırında** yapılıyor
  /// (bkz. [topicMatchesKeyword]). Alt dize araması yapılsaydı `ai` anahtarı
  /// `training` ve `available` gibi konularla eşleşirdi.
  final Set<String> keywords;
}

/// Sekiz ilgi alanı — onaylı tasarımdaki listeyle birebir aynı.
///
/// Anahtar kelimeler feed'in **gerçek** konu dağarcığından seçildi
/// (28 Temmuz koşusunda 650 farklı konu ölçüldü), tahminle değil.
const interestTaxonomy = <Interest>[
  Interest(
    id: 'yapay-zeka',
    label: 'Yapay Zekâ',
    keywords: {
      'ai',
      'genai',
      'llm',
      'llms',
      'gpt',
      'claude',
      'anthropic',
      'openai',
      'gemini',
      'mistral',
      'deepseek',
      'qwen',
      'llama',
      'model',
      'models',
      'transformers',
      'transformer',
      'agent',
      'agents',
      'agentic',
      'copilot',
      'nlp',
      'diffusion',
      'mcp',
      'machine learning',
      'deep learning',
      'generative ai',
      'agentic ai',
    },
  ),
  Interest(
    id: 'mobil',
    label: 'Mobil',
    keywords: {
      'android',
      'ios',
      'flutter',
      'mobile',
      'kotlin',
      'swift',
      'react native',
    },
  ),
  Interest(
    id: 'acik-kaynak',
    label: 'Açık Kaynak',
    keywords: {'open source', 'opensource', 'oss', 'foss', 'license'},
  ),
  Interest(
    id: 'siber-guvenlik',
    label: 'Siber Güvenlik',
    keywords: {
      'security',
      'cve',
      'vulnerability',
      'cryptography',
      'privacy',
      'sandbox',
      'authentication',
      'malware',
    },
  ),
  Interest(
    id: 'bulut',
    label: 'Bulut',
    keywords: {
      'cloud',
      'aws',
      'amazon bedrock',
      'bedrock',
      'azure',
      'gcp',
      'kubernetes',
      'docker',
      'serverless',
      'devops',
      'deployment',
      'infrastructure',
    },
  ),
  Interest(
    id: 'donanim',
    label: 'Donanım',
    keywords: {
      'hardware',
      'gpu',
      'gpus',
      'cuda',
      'nvidia',
      'chip',
      'robotics',
      'jetson',
      'edge',
      'silicon',
    },
  ),
  Interest(
    id: 'oyun',
    label: 'Oyun',
    keywords: {'game', 'games', 'gaming', 'unity', 'unreal', 'godot'},
  ),
  Interest(
    id: 'veri-bilimi',
    label: 'Veri Bilimi',
    keywords: {
      'data',
      'dataset',
      'datasets',
      'pandas',
      'analytics',
      'sql',
      'visualization',
      'jupyter',
      'notebook',
      'embeddings',
      'vector',
    },
  ),
];

Interest? interestById(String id) {
  for (final interest in interestTaxonomy) {
    if (interest.id == id) return interest;
  }
  return null;
}

/// Konuyu belirteçlere ayırıp boşlukla birleştirir.
///
/// Kaynakların konu biçimi tek tip değil: `ai-tools`, `mcp_server`,
/// `agentic ai / generative ai`, `developer tools & techniques`. Hepsi aynı
/// biçime indirilir.
String normalizeTopic(String topic) => foldForSearch(
  topic,
).split(RegExp(r'[^a-z0-9]+')).where((token) => token.isNotEmpty).join(' ');

/// Eşleşme **belirteç sınırında** yapılır.
///
/// Alt dize araması yapılsaydı `ai` anahtarı `training` ve `available` ile
/// eşleşirdi; kullanıcı "Yapay Zekâ" seçtiğinde alakasız kayıtlar gelirdi.
bool topicMatchesKeyword(String topic, String keyword) {
  final normalized = normalizeTopic(topic);
  if (normalized.isEmpty) return false;
  return ' $normalized '.contains(' ${foldForSearch(keyword)} ');
}

bool itemMatchesInterest(FeedItem item, Interest interest) => item.topics.any(
  (topic) =>
      interest.keywords.any((keyword) => topicMatchesKeyword(topic, keyword)),
);

/// Seçili ilgi alanlarına göre süzer.
///
/// Hiç seçim yoksa akışın tamamı döner: boş bir "Sana Özel" sekmesi
/// kullanıcıya bir şey seçmediğini anlatmaz, yalnız bozuk görünür.
/// Tanınmayan kimlik sessizce yok sayılır.
List<FeedItem> filterByInterests(List<FeedItem> items, Set<String> ids) {
  if (ids.isEmpty) return items;

  final selected = [for (final id in ids) ?interestById(id)];
  if (selected.isEmpty) return items;

  return items
      .where(
        (item) =>
            selected.any((interest) => itemMatchesInterest(item, interest)),
      )
      .toList(growable: false);
}
