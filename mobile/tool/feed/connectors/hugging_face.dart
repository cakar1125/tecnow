/// Hugging Face bağlayıcısı.
///
/// Ağ yok; `/api/models` yanıt gövdesini `FeedItem`'a çevirir.
///
/// **Özet sorunu.** Model listesi uç noktası açıklama alanı döndürmez —
/// modelin açıklaması yok değildir, listeleme yanıtı taşımaz. Gerçek yanıtta
/// doğrulandı (2026-07-27): `full=true` bile `description` ya da `cardData`
/// vermiyor; açıklama ancak model kartı ayrıca çekilirse gelir. Bu yüzden
/// açıklama geldiğinde ([SummaryOrigin.original]) olduğu gibi kullanılır;
/// gelmediğinde yanıttaki **yapısal veriden** Türkçe bir satır kurulur ve
/// [SummaryOrigin.generated] ile işaretlenir; arayüz bunu kaynağın kendi
/// metninden görsel olarak ayırır. Uydurma yapılmaz: cümledeki her öğe
/// (sahip, görev, lisans) yanıtta vardır, yoksa cümleden çıkarılır.
///
/// GitHub'da davranış farklı: orada açıklama alanı **vardır** ve boşsa depo
/// sahibi gerçekten yazmamıştır — o kayıt elenir.
library;

import 'package:tecos/data/feed/feed_schema.dart';

import '../source_allowlist.dart';
import 'connector_support.dart';

/// Üreticinin **kullanmak zorunda olduğu** sorgu parametreleri.
///
/// Varsayılan `/api/models` yanıtı `lastModified` **döndürmez** — gerçek
/// yanıtta ölçüldü (2026-07-27): dönen alanlar `_id, id, likes, private,
/// downloads, tags, pipeline_tag, library_name, createdAt, modelId`.
///
/// Bu alan olmadan bakım durumu **oluşturulma tarihinden** hesaplanır ve her
/// eski model bakımsız görünür: `sentence-transformers/all-MiniLM-L6-v2`
/// (253 milyon indirme) 2022'de oluşturulduğu için 25 puan alıyordu; oysa
/// gerçekten 2026-06-01'de güncellenmiş ve 70 puan alması gerekiyor.
///
/// `expand[]=lastModified` **yanlış çözümdür**: bu parametre dışlayıcıdır,
/// yalnız sayılan alanları döndürür ve `createdAt`'i düşürür — denendi,
/// bütün kayıtlar `missingDate` ile elendi. `full=true` ikisini de verir.
///
/// Sessiz bir bozulma olduğu için sorgu burada, bağlayıcının yanında durur.
const huggingFaceModelsQuery = <String, String>{'full': 'true'};

/// Kullanıcıya etiket olarak gösterilmeyecek, iç kullanım için ad alanı
/// taşıyan Hugging Face etiketleri (`license:mit`, `arxiv:2401.1` gibi).
const _namespacedTagPrefixes = <String>[
  'arxiv:',
  'base_model:',
  'dataset:',
  'doi:',
  'license:',
  'region:',
];

/// Bir kayıtta gösterilecek en fazla etiket sayısı.
const _maxTopics = 8;

ConnectorResult parseHuggingFaceModels(
  String body, {
  required DateTime checkedAt,
}) {
  final entries = jsonEntries(body, null, sourceLabel: 'Hugging Face');
  final items = <FeedItem>[];
  final skipped = <SkippedRecord>[];

  for (final entry in entries) {
    if (entry == null) {
      skipped.add(const SkippedRecord('<kayıt>', SkipReason.malformed));
      continue;
    }

    final modelId = jsonString(entry, 'id') ?? jsonString(entry, 'modelId');
    if (modelId == null) {
      skipped.add(const SkippedRecord('<isimsiz>', SkipReason.missingTitle));
      continue;
    }
    if (entry['private'] == true) {
      skipped.add(SkippedRecord(modelId, SkipReason.private));
      continue;
    }

    final url = Uri.tryParse('https://huggingface.co/$modelId');
    if (url == null || !SourceAllowlist.isAllowed(url)) {
      skipped.add(SkippedRecord(modelId, SkipReason.notAllowed));
      continue;
    }

    final createdAt = parseFeedDate(jsonString(entry, 'createdAt'));
    if (createdAt == null) {
      skipped.add(SkippedRecord(modelId, SkipReason.missingDate));
      continue;
    }
    // `lastModified` yoksa elde yalnız oluşturulma tarihi vardır. Bu, eski
    // ama bakımlı modelleri bakımsız gösterir; [huggingFaceModelsQuery]
    // kullanılmadığında olan budur.
    final lastModified =
        parseFeedDate(jsonString(entry, 'lastModified')) ?? createdAt;

    final tags = jsonStringList(entry, 'tags');
    final license = _license(tags);
    final task = jsonString(entry, 'pipeline_tag');
    final owner = _ownerOf(modelId);

    final description = _description(entry);
    final summary = description ?? _factualSummary(owner, task, license);
    if (summary == null) {
      skipped.add(SkippedRecord(modelId, SkipReason.missingSummary));
      continue;
    }

    items.add(
      FeedItem(
        id: feedItemId(url),
        kind: FeedItemKind.aiModel,
        title: modelId,
        summary: truncateSummary(summary),
        summaryOrigin: description == null
            ? SummaryOrigin.generated
            : SummaryOrigin.original,
        sourceName: 'Hugging Face',
        sourceKind: FeedSourceKind.huggingFace,
        url: url,
        publishedAt: createdAt,
        checkedAt: checkedAt,
        // Kurulan cümle Türkçe, kaynağın kendi açıklaması İngilizce.
        language: description == null ? 'tr' : 'en',
        trust: TrustSignals(
          officialSource: SourceAllowlist.isOfficial(url),
          hasLicense: license != null,
          recentlyUpdated: isWithin(lastModified, checkedAt, recentWindow),
          maintained: isWithin(lastModified, checkedAt, maintainedWindow),
          popularity: jsonInt(entry, 'downloads') ?? jsonInt(entry, 'likes'),
        ),
        topics: _topics(tags, task),
      ),
    );
  }

  return ConnectorResult(items: items, skipped: skipped);
}

/// `meta-llama/Llama-3-8B` → `meta-llama`. Ad alanı yoksa (`gpt2`) sahip yok.
String? _ownerOf(String modelId) {
  final slash = modelId.indexOf('/');
  return slash <= 0 ? null : modelId.substring(0, slash);
}

String? _description(Map<String, Object?> entry) {
  final direct = jsonString(entry, 'description');
  if (direct != null) return normalizeSpaces(direct);
  final card = entry['cardData'];
  if (card is Map) {
    final nested = jsonString(card.cast<String, Object?>(), 'description');
    if (nested != null) return normalizeSpaces(nested);
  }
  return null;
}

String? _license(List<String> tags) {
  for (final tag in tags) {
    if (tag.startsWith('license:')) {
      final value = tag.substring('license:'.length).trim();
      if (value.isNotEmpty && value != 'unknown' && value != 'other') {
        return value;
      }
    }
  }
  return null;
}

/// Yanıttaki yapısal veriden kurulan Türkçe satır.
///
/// Hiçbir öğe bilinmiyorsa `null` döner: "model" demekten ibaret bir cümle
/// kullanıcıya hiçbir şey anlatmaz, o kayıt elenir.
String? _factualSummary(String? owner, String? task, String? license) {
  final sentences = <String>[
    if (owner != null)
      'Hugging Face üzerinde $owner tarafından yayımlanan model.'
    else if (task != null || license != null)
      'Hugging Face üzerinde yayımlanan model.',
    if (task != null) 'Görev: $task.',
    if (license != null) 'Lisans: $license.',
  ];
  return sentences.isEmpty ? null : sentences.join(' ');
}

/// Gösterilecek etiketler: ad alanı taşıyanlar ayıklanır, görev etiketi başa
/// alınır, sayı sınırlanır. Sıra belirlenimcidir.
List<String> _topics(List<String> tags, String? task) {
  final topics = <String>{
    ?task,
    ...tags.where(
      (tag) => !_namespacedTagPrefixes.any((prefix) => tag.startsWith(prefix)),
    ),
  };
  return topics.take(_maxTopics).toList(growable: false);
}
