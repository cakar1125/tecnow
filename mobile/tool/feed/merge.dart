/// Kopya birleştirme.
///
/// `docs/CONTENT_TRUST_POLICY.md`: *"Aynı gelişmenin kopyaları tek kayıt
/// altında birleştirilir."*
///
/// Birleştirme **muhafazakârdır**. Bulanık başlık benzerliğiyle eşleştirme
/// bilinçli olarak yapılmaz: yanlış birleştirme iki farklı gelişmeden birini
/// tamamen gizler ve bu, birkaç kopya göstermekten daha kötüdür. Yalnız iki
/// kesin sinyal kabul edilir:
///
/// 1. Kanonik URL aynı (`feedItemId` eşit).
/// 2. Aynı tür **ve** normalleştirilmiş başlık birebir aynı.
library;

import 'package:teknoakis/data/feed/feed_schema.dart';

/// İki kaydın aynı gelişme sayılması için kullanılan başlık biçimi.
///
/// Küçük harfe iner, noktalama ve fazla boşluk atılır. "Nexus-7B Released!"
/// ile "nexus 7b released" aynı sayılır; "Nexus-7B" ile "Nexus-13B" sayılmaz.
String normalizeTitle(String title) => title
    .toLowerCase()
    .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
    .trim()
    .replaceAll(RegExp(r'\s+'), ' ');

/// Aynı gelişmenin kopyalarını tek kayda indirger.
///
/// Kazanan seçimi sırayla: **daha yüksek güven puanı** → *resmi kaynak* →
/// *daha erken yayın tarihi* (orijinal duyuru, aktarımı değil). Sıra
/// belirlenimcidir; aynı girdi her zaman aynı çıktıyı verir.
///
/// Kaybedenlerin adresleri kazananın [FeedItem.mergedUrls] alanına yazılır —
/// kaynak şeffaflığı korunur, kopyalar sessizce yok olmaz.
///
/// Kopyalardan **herhangi biri** geri çekilmişse birleşik kayıt da geri
/// çekilmiş sayılır: güvenli yön, şüpheli içeriği göstermemektir.
List<FeedItem> mergeDuplicates(List<FeedItem> items) {
  final groups = <String, List<FeedItem>>{};
  final keyOfId = <String, String>{};

  for (final item in items) {
    final id = feedItemId(item.url);
    final titleKey = '${item.kind.name}|${normalizeTitle(item.title)}';
    // Aynı URL daha önce başka bir başlıkla görüldüyse o grubu izle: URL
    // eşleşmesi başlık eşleşmesinden güçlüdür.
    final key = keyOfId[id] ?? titleKey;
    keyOfId[id] = key;
    (groups[key] ??= []).add(item);
  }

  final merged = <FeedItem>[];
  for (final group in groups.values) {
    merged.add(group.length == 1 ? group.single : _mergeGroup(group));
  }

  // Çıktı sırası girdiden bağımsız olmalı ki üretici her koşuda aynı dosyayı
  // yazsın: yeni → eski, eşitlikte kimliğe göre.
  merged.sort((a, b) {
    final byDate = b.publishedAt.compareTo(a.publishedAt);
    return byDate != 0 ? byDate : a.id.compareTo(b.id);
  });
  return List.unmodifiable(merged);
}

FeedItem _mergeGroup(List<FeedItem> group) {
  final ordered = [...group]..sort(_byPreference);
  final winner = ordered.first;

  final winnerId = feedItemId(winner.url);
  final extras = <String, Uri>{};
  for (final item in ordered.skip(1)) {
    if (feedItemId(item.url) != winnerId) {
      extras[feedItemId(item.url)] = item.url;
    }
    for (final url in item.mergedUrls) {
      if (feedItemId(url) != winnerId) extras[feedItemId(url)] = url;
    }
  }
  for (final url in winner.mergedUrls) {
    if (feedItemId(url) != winnerId) extras[feedItemId(url)] = url;
  }

  final retraction = ordered
      .map((item) => item.retractedAt)
      .nonNulls
      .fold<DateTime?>(
        null,
        (earliest, date) =>
            earliest == null || date.isBefore(earliest) ? date : earliest,
      );

  return FeedItem(
    id: winner.id,
    kind: winner.kind,
    title: winner.title,
    summary: winner.summary,
    summaryOrigin: winner.summaryOrigin,
    sourceName: winner.sourceName,
    sourceKind: winner.sourceKind,
    url: winner.url,
    publishedAt: winner.publishedAt,
    checkedAt: winner.checkedAt,
    language: winner.language,
    trust: winner.trust,
    topics: {
      ...winner.topics,
      for (final item in ordered.skip(1)) ...item.topics,
    }.toList(growable: false),
    mergedUrls: (extras.values.toList()
      ..sort((a, b) => a.toString().compareTo(b.toString()))),
    retractedAt: retraction,
    correctionNote:
        winner.correctionNote ??
        ordered.map((item) => item.correctionNote).nonNulls.firstOrNull,
  );
}

int _byPreference(FeedItem a, FeedItem b) {
  final byScore = b.trust.score.compareTo(a.trust.score);
  if (byScore != 0) return byScore;

  final byOfficial = (b.trust.officialSource ? 1 : 0).compareTo(
    a.trust.officialSource ? 1 : 0,
  );
  if (byOfficial != 0) return byOfficial;

  final byDate = a.publishedAt.compareTo(b.publishedAt);
  if (byDate != 0) return byDate;

  // Son çare: kimlik. Eşit adayların sırası da belirlenimci olmalı.
  return a.id.compareTo(b.id);
}
