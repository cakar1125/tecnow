/// Keşfet ekranının arama modeli.
///
/// Ekrandan ayrı duruyor çünkü asıl karar burada: hangi kayıt eşleşti, neden
/// eşleşti ve hangi sırayla gösterilecek. Widget testiyle değil, doğrudan
/// birim testiyle ölçülmesi gereken şey bu.
///
/// "NEDEN EŞLEŞTİ?" kutusu tasarımın parçası ve içeriği **uydurulmuyor**:
/// eşleşmenin kaydın neresinde olduğundan türetiliyor.
library;

import '../data/feed/feed_schema.dart';

enum ExploreFilter { github, aiModelleri, aiAraclari, skills, mcp }

/// Çip etiketleri. Ekran ve eşleşme gerekçesi aynı listeden okur; iki ayrı
/// liste er geç birbirinden sapar.
const exploreFilterLabels = {
  ExploreFilter.github: 'GitHub',
  ExploreFilter.aiModelleri: 'AI Modelleri',
  ExploreFilter.aiAraclari: 'AI Araçları',
  ExploreFilter.skills: 'Skills',
  ExploreFilter.mcp: 'MCP',
};

/// Süzgeç eşlemesi.
///
/// **GitHub** türe değil kaynağa bakar: etiket bir platform adı ve Ana
/// Sayfa'daki `GİTHUB` sekmesi de aynı anlamda kullanılıyor. Kalan dördü
/// içerik türüdür.
bool matchesFilter(FeedItem item, ExploreFilter filter) => switch (filter) {
  ExploreFilter.github => item.sourceKind == FeedSourceKind.github,
  ExploreFilter.aiModelleri => item.kind == FeedItemKind.aiModel,
  ExploreFilter.aiAraclari => item.kind == FeedItemKind.tool,
  ExploreFilter.skills => item.kind == FeedItemKind.skill,
  ExploreFilter.mcp => item.kind == FeedItemKind.mcp,
};

/// Türkçe arama katlaması.
///
/// `toLowerCase()` tek başına yetmiyor. Unicode'un varsayılan kuralında
/// `'I'` → `'i'` ve `'İ'` → `'i̇'` (i + birleşen nokta) olur; yani Türkçe
/// metinde büyük/küçük eşleşmesi sessizce bozulur. Ayrıca kullanıcı
/// aksansız yazar: "mühendislik" aranırken "muhendislik" de yazılır.
///
/// Bu yüzden arama için ayrı bir katlama var: `{i, ı, İ, I}` tek harfe
/// iner, `ş ğ ü ö ç` aksansız karşılıklarına düşer. Katlama **yalnız
/// aramada** kullanılır; ekranda gösterilen metne dokunulmaz.
String foldForSearch(String value) {
  const folded = {
    'ı': 'i',
    'İ': 'i',
    'I': 'i',
    'ş': 's',
    'Ş': 's',
    'ğ': 'g',
    'Ğ': 'g',
    'ü': 'u',
    'Ü': 'u',
    'ö': 'o',
    'Ö': 'o',
    'ç': 'c',
    'Ç': 'c',
    'â': 'a',
    'Â': 'a',
    'î': 'i',
    'Î': 'i',
    'û': 'u',
    'Û': 'u',
  };

  final buffer = StringBuffer();
  for (final rune in value.runes) {
    final character = String.fromCharCode(rune);
    buffer.write(folded[character] ?? character.toLowerCase());
  }
  return buffer.toString();
}

/// Eşleşmenin kaydın neresinde olduğu. Sıralama ağırlığı da buradan gelir:
/// başlıkta geçen bir sonuç, özette geçenden daha alakalıdır.
enum ExploreMatchField {
  title(4),
  topic(3),
  source(2),
  summary(1),

  /// Sorgu boş; kayıt yalnız süzgeçten geldi.
  filter(0),

  /// Ne sorgu ne süzgeç var — akışın kendisi listeleniyor.
  listing(0);

  const ExploreMatchField(this.weight);
  final int weight;
}

final class ExploreMatch {
  const ExploreMatch({
    required this.item,
    required this.field,
    required this.reason,
  });

  final FeedItem item;
  final ExploreMatchField field;

  /// Kullanıcıya gösterilen gerekçe ("NEDEN EŞLEŞTİ?").
  final String reason;
}

/// Feed'de arama yapar.
///
/// Sıralama: önce eşleşme ağırlığı, sonra yayın tarihi, sonra kimlik. Son
/// ölçüt belirlenimcilik için: aynı girdi her koşuda aynı sırayı vermeli,
/// yoksa test bugün geçip yarın kalır.
List<ExploreMatch> searchFeed(
  List<FeedItem> items, {
  String query = '',
  ExploreFilter? filter,
}) {
  final trimmed = query.trim();
  final needle = foldForSearch(trimmed);

  final matches = <ExploreMatch>[];
  for (final item in items) {
    if (filter != null && !matchesFilter(item, filter)) continue;

    if (needle.isEmpty) {
      matches.add(
        ExploreMatch(
          item: item,
          field: filter == null
              ? ExploreMatchField.listing
              : ExploreMatchField.filter,
          reason: filter == null
              ? 'Arama boş; akıştaki en yeni kayıtlar listeleniyor.'
              : 'Süzgeç: ${exploreFilterLabels[filter]}.',
        ),
      );
      continue;
    }

    if (_match(item, needle, trimmed) case final match?) matches.add(match);
  }

  matches.sort((a, b) {
    final byWeight = b.field.weight.compareTo(a.field.weight);
    if (byWeight != 0) return byWeight;
    final byDate = b.item.publishedAt.compareTo(a.item.publishedAt);
    return byDate != 0 ? byDate : a.item.id.compareTo(b.item.id);
  });
  return List.unmodifiable(matches);
}

ExploreMatch? _match(FeedItem item, String needle, String shown) {
  if (foldForSearch(item.title).contains(needle)) {
    return ExploreMatch(
      item: item,
      field: ExploreMatchField.title,
      reason: 'Başlıkta "$shown" geçiyor.',
    );
  }

  for (final topic in item.topics) {
    if (foldForSearch(topic).contains(needle)) {
      return ExploreMatch(
        item: item,
        field: ExploreMatchField.topic,
        reason: 'Konu etiketi: $topic.',
      );
    }
  }

  if (foldForSearch(item.sourceName).contains(needle)) {
    return ExploreMatch(
      item: item,
      field: ExploreMatchField.source,
      reason: 'Kaynak: ${item.sourceName}.',
    );
  }

  if (foldForSearch(item.summary).contains(needle)) {
    return ExploreMatch(
      item: item,
      field: ExploreMatchField.summary,
      reason: 'Özette "$shown" geçiyor.',
    );
  }

  return null;
}

/// "Popüler" bölümü.
///
/// Popülerlik **ölçülen** bir sinyal (yıldız, indirme); uydurulmuyor.
/// Sinyali olmayan kayıt bu listeye hiç girmez — sıfır sayılıp en sona
/// konsaydı, ölçülmemiş bir kaydı "popüler değil" diye sunmuş olurduk.
List<FeedItem> popularItems(List<FeedItem> items, {int limit = 5}) {
  final ranked =
      items.where((item) => (item.trust.popularity ?? 0) > 0).toList()
        ..sort((a, b) {
          final byPopularity = (b.trust.popularity ?? 0).compareTo(
            a.trust.popularity ?? 0,
          );
          return byPopularity != 0 ? byPopularity : a.id.compareTo(b.id);
        });
  return List.unmodifiable(ranked.take(limit));
}
