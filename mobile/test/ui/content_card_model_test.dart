import 'package:flutter_test/flutter_test.dart';
import 'package:teknoakis/data/feed/feed_schema.dart';
import 'package:teknoakis/ui/content_card_model.dart';

FeedItem _item({
  SummaryOrigin origin = SummaryOrigin.original,
  String language = 'en',
  List<String> topics = const ['llm'],
}) => FeedItem(
  id: 'abc',
  kind: FeedItemKind.aiModel,
  title: 'ornek/model',
  summary: 'Bir açıklama.',
  summaryOrigin: origin,
  sourceName: 'Hugging Face',
  sourceKind: FeedSourceKind.huggingFace,
  url: Uri.parse('https://huggingface.co/a/b'),
  publishedAt: DateTime.utc(2026, 7, 20),
  checkedAt: DateTime.utc(2026, 7, 27),
  language: language,
  trust: const TrustSignals(
    officialSource: true,
    hasLicense: true,
    recentlyUpdated: true,
    maintained: true,
  ),
  topics: topics,
);

void main() {
  group('feed kaydından kart', () {
    test('alanlar taşınır', () {
      final card = ContentCardModel.fromFeedItem(_item());

      expect(card.id, 'abc');
      expect(card.kind, FeedItemKind.aiModel);
      expect(card.title, 'ornek/model');
      expect(card.sourceLabel, 'Hugging Face');
      expect(card.summary, 'Bir açıklama.');
      expect(card.language, 'en');
      expect(card.tags, ['llm']);
    });

    /// Gerçek içerik **asla** örnek diye işaretlenmez: o etiket orada yanlış
    /// bilgi olur.
    test('gerçek içerik örnek değildir', () {
      expect(ContentCardModel.fromFeedItem(_item()).isSample, isFalse);
    });

    /// Kaynakların "ne işe yarar" alanı yok; uydurulmaz.
    test('açıklama bölümü boş bırakılır', () {
      expect(ContentCardModel.fromFeedItem(_item()).whatItDoes, isNull);
    });
  });

  group('özetin yazarı', () {
    test('kaynağın kendi metni kaynağa yazılır', () {
      expect(
        ContentCardModel.fromFeedItem(_item()).summaryAuthor,
        SummaryAuthor.source,
      );
    });

    test('TeknoAkış özeti ayrı işaretlenir', () {
      expect(
        ContentCardModel.fromFeedItem(
          _item(origin: SummaryOrigin.teknoakis),
        ).summaryAuthor,
        SummaryAuthor.teknoakis,
      );
    });

    /// Elle yazılan özet de TeknoAkış'ın metnidir; kaynağın kendi
    /// açıklamasıyla aynı kefeye konmaz.
    test('elle yazılan özet kaynak sayılmaz', () {
      expect(
        ContentCardModel.fromFeedItem(
          _item(origin: SummaryOrigin.manual),
        ).summaryAuthor,
        SummaryAuthor.teknoakis,
      );
    });

    /// Yeni bir köken eklenirse burada görünsün: sessizce "kaynak" sayılması,
    /// AI metnini kaynağın metni gibi göstermek olurdu.
    test('bilinen bütün kökenler kapsanır', () {
      for (final origin in SummaryOrigin.values) {
        final author = ContentCardModel.fromFeedItem(
          _item(origin: origin),
        ).summaryAuthor;
        expect(
          author,
          origin == SummaryOrigin.original
              ? SummaryAuthor.source
              : SummaryAuthor.teknoakis,
          reason: '$origin',
        );
      }
    });
  });

  /// Örnek veriyi işaretlemeyi **unutmak** mümkün olmasın diye ayrı kurucu.
  test('sample kurucusu her zaman işaretli üretir', () {
    const card = ContentCardModel.sample(
      id: 'a',
      kind: FeedItemKind.repository,
      title: 'Bir kayıt',
      sourceLabel: 'GitHub',
      summary: 'Açıklama.',
    );
    expect(card.isSample, isTrue);
    expect(card.summaryAuthor, SummaryAuthor.source);
  });
}
