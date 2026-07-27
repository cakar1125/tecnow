/// Kartların sunum modeli.
///
/// Aynı kart hem tasarım fixture'ını hem paketlenmiş feed'den gelen **gerçek**
/// içeriği gösterir — ama ikisi aynı görünmez. Model bu ayrımı iki alanla
/// taşır:
///
/// * [isSample] — `CLAUDE.md`: *"Kurgusal/tasarım verisi gerçek veya
///   doğrulanmış gibi sunulmaz."* Fixture kartları görünür biçimde
///   işaretlenir; gerçek içerik işaretlenmez, çünkü o işaret orada yalan olur.
/// * [summaryAuthor] — `CONTENT_TRUST_POLICY.md`: *"TeknoAkış özeti orijinal
///   kaynaktan görsel olarak ayrılır."* Kaynağın kendi metni ile bizim
///   yazdığımız özet karıştırılmaz.
///
/// Tür için ayrı bir enum tanımlanmadı: [FeedItemKind] zaten sözleşmenin
/// parçası ve ikinci bir liste er geç ondan sapardı.
library;

import '../data/feed/feed_schema.dart';

/// Özeti kim yazdı?
enum SummaryAuthor {
  /// Kaynağın kendi açıklaması, olduğu gibi.
  source,

  /// TeknoAkış'ın derleme anında ürettiği özet.
  teknoakis,
}

final class ContentCardModel {
  const ContentCardModel({
    required this.id,
    required this.kind,
    required this.title,
    required this.sourceLabel,
    required this.summary,
    this.summaryAuthor = SummaryAuthor.source,
    this.language = 'tr',
    this.isSample = false,
    this.whatItDoes,
    this.tags = const [],
  });

  /// Fixture'dan kurulan kart. [isSample] varsayılan olarak açıktır: örnek
  /// veriyi işaretlemeyi **unutmak** mümkün olmasın diye ayrı bir kurucu.
  const ContentCardModel.sample({
    required this.id,
    required this.kind,
    required this.title,
    required this.sourceLabel,
    required this.summary,
    this.whatItDoes,
    this.tags = const [],
  }) : summaryAuthor = SummaryAuthor.source,
       language = 'tr',
       isSample = true;

  final String id;
  final FeedItemKind kind;
  final String title;

  /// İnsan tarafından okunur kaynak: "GitHub", "OpenAI Blog".
  final String sourceLabel;
  final String summary;
  final SummaryAuthor summaryAuthor;

  /// Özetin dili. Anahtarsız üretilen feed'de özetler kaynağın kendi
  /// dilindedir (çoğunlukla İngilizce); arayüz bunu gösterebilmeli.
  final String language;

  /// Tasarım fixture'ı mı, gerçek içerik mi?
  final bool isSample;

  /// "NE İŞE YARAR?" bölümü. Gerçek feed kayıtlarında **yoktur**: kaynaklar
  /// böyle bir alan vermiyor ve onu biz uydurmayız. `null` olduğunda bölüm
  /// hiç çizilmez — boş bir başlık göstermek de bir şey vaat etmektir.
  final String? whatItDoes;

  /// Etiketler. Feed kaydında konu etiketleridir.
  final List<String> tags;

  /// Feed kaydından kart modeli.
  ///
  /// [SummaryOrigin.manual] da TeknoAkış'ın yazdığı metindir; kaynağın kendi
  /// açıklamasıyla aynı kefeye konmaz.
  factory ContentCardModel.fromFeedItem(FeedItem item) => ContentCardModel(
    id: item.id,
    kind: item.kind,
    title: item.title,
    sourceLabel: item.sourceName,
    summary: item.summary,
    summaryAuthor: item.summaryOrigin == SummaryOrigin.original
        ? SummaryAuthor.source
        : SummaryAuthor.teknoakis,
    language: item.language,
    tags: item.topics,
  );
}
