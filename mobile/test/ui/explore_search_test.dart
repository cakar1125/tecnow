import 'package:flutter_test/flutter_test.dart';
import 'package:teknoakis/data/feed/feed_schema.dart';
import 'package:teknoakis/ui/explore_search.dart';

import '../support/test_overrides.dart';

/// Keşfet'in kararı burada veriliyor: hangi kayıt eşleşti, neden eşleşti,
/// hangi sırayla. Widget testiyle değil, doğrudan ölçülür.
void main() {
  group('Türkçe katlama', () {
    /// `toLowerCase()` tek başına yetmiyor: Unicode'un varsayılan kuralında
    /// `'İ'` küçültülünce `i` + birleşen nokta oluyor ve eşleşme sessizce
    /// bozuluyor. Bu, Türkçe bir uygulamada arama kutusunun görünmez
    /// biçimde yanlış çalışması demek.
    test('büyük İ ve I aynı harfe iner', () {
      expect(foldForSearch('İLGİ'), foldForSearch('ilgi'));
      expect(foldForSearch('IŞIK'), foldForSearch('ışık'));
    });

    /// Kullanıcı aksansız yazar: "mühendislik" yerine "muhendislik".
    test('aksanlar aksansız karşılığına düşer', () {
      expect(foldForSearch('Mühendislik'), 'muhendislik');
      expect(foldForSearch('GÜVENLİK'), 'guvenlik');
      expect(foldForSearch('çağrı'), 'cagri');
    });

    test('katlama yalnız aramada; gösterilen metin değişmez', () {
      const original = 'Güvenlik Açığı';
      expect(foldForSearch(original), 'guvenlik acigi');
      expect(original, 'Güvenlik Açığı');
    });
  });

  group('arama', () {
    List<FeedItem> items() => [
      testFeedItem(
        id: '0000000000000001',
        kind: FeedItemKind.repository,
        title: 'ornek/güvenlik-tarayıcı',
        summary: 'Depo açıklaması.',
        topics: const ['dart'],
        publishedAt: DateTime.utc(2026, 7, 20),
      ),
      testFeedItem(
        id: '0000000000000002',
        kind: FeedItemKind.aiModel,
        title: 'ornek/model',
        summary: 'Güvenlik değerlendirmesi içeren model.',
        sourceKind: FeedSourceKind.huggingFace,
        sourceName: 'Hugging Face',
        topics: const ['llm'],
        publishedAt: DateTime.utc(2026, 7, 25),
      ),
      testFeedItem(
        id: '0000000000000003',
        kind: FeedItemKind.announcement,
        title: 'Bir duyuru',
        summary: 'Duyuru metni.',
        sourceKind: FeedSourceKind.officialBlog,
        sourceName: 'OpenAI Blog',
        topics: const ['guvenlik'],
        publishedAt: DateTime.utc(2026, 7, 26),
      ),
    ];

    test('aksansız sorgu aksanlı başlığı bulur', () {
      final matches = searchFeed(items(), query: 'guvenlik-tarayici');

      expect(matches.map((match) => match.item.id), ['0000000000000001']);
    });

    /// Sıralamanın asıl işi bu: başlıkta geçen kayıt, özette geçenden önce
    /// gelmeli — tarihi daha eski olsa bile.
    test('başlık eşleşmesi özet eşleşmesini geçer', () {
      final matches = searchFeed(items(), query: 'güvenlik');

      expect(matches.map((match) => match.item.id), [
        // Başlık (20 Temmuz) — konu etiketi (26 Temmuz) — özet (25 Temmuz)
        '0000000000000001',
        '0000000000000003',
        '0000000000000002',
      ]);
      expect(matches.map((match) => match.field), [
        ExploreMatchField.title,
        ExploreMatchField.topic,
        ExploreMatchField.summary,
      ]);
    });

    /// "NEDEN EŞLEŞTİ?" uydurulmuyor: eşleşmenin **yerinden** türetiliyor.
    test('gerekçe eşleşmenin yerini söyler', () {
      final byTitle = searchFeed(items(), query: 'duyuru').single;
      expect(byTitle.reason, 'Başlıkta "duyuru" geçiyor.');

      final byTopic = searchFeed(items(), query: 'llm').single;
      expect(byTopic.reason, 'Konu etiketi: llm.');

      final bySource = searchFeed(items(), query: 'hugging').single;
      expect(bySource.reason, 'Kaynak: Hugging Face.');
    });

    test('sorgu boşken gerekçe listeleme olduğunu söyler', () {
      final matches = searchFeed(items());

      expect(matches, hasLength(3));
      expect(
        matches.first.reason,
        'Arama boş; akıştaki en yeni kayıtlar listeleniyor.',
      );
      // Tarih sırası: 26, 25, 20 Temmuz.
      expect(matches.map((match) => match.item.id), [
        '0000000000000003',
        '0000000000000002',
        '0000000000000001',
      ]);
    });

    test('sorgu boş ve süzgeç varken gerekçe süzgeci söyler', () {
      final matches = searchFeed(items(), filter: ExploreFilter.aiModelleri);

      expect(matches.single.reason, 'Süzgeç: AI Modelleri.');
    });

    test('eşleşmeyen sorgu boş liste verir', () {
      expect(searchFeed(items(), query: 'kuantum'), isEmpty);
    });

    test('süzgeç ve sorgu birlikte uygulanır', () {
      final matches = searchFeed(
        items(),
        query: 'güvenlik',
        filter: ExploreFilter.aiModelleri,
      );

      expect(matches.map((match) => match.item.id), ['0000000000000002']);
    });

    /// **GitHub** çipi türe değil kaynağa bakar: etiket bir platform adı.
    test('GitHub süzgeci kaynağa bakar, türe değil', () {
      final matches = searchFeed(items(), filter: ExploreFilter.github);

      expect(matches.map((match) => match.item.id), ['0000000000000001']);
    });

    /// Aynı girdi her koşuda aynı sırayı vermeli.
    test('sıralama belirlenimci', () {
      final first = searchFeed(items(), query: 'güvenlik');
      final second = searchFeed(items().reversed.toList(), query: 'güvenlik');

      expect(
        first.map((match) => match.item.id),
        second.map((match) => match.item.id),
      );
    });
  });

  group('popüler', () {
    test('popülerlik sırasına dizer', () {
      final ranked = popularItems([
        testFeedItem(
          id: '0000000000000001',
          kind: FeedItemKind.repository,
          title: 'az',
          popularity: 5,
        ),
        testFeedItem(
          id: '0000000000000002',
          kind: FeedItemKind.repository,
          title: 'çok',
          popularity: 900,
        ),
      ]);

      expect(ranked.map((item) => item.title), ['çok', 'az']);
    });

    /// Sinyali olmayan kayıt listeye **girmez**. Sıfır sayıp en sona koymak,
    /// ölçülmemiş bir kaydı "popüler değil" diye sunmak olurdu.
    test('popülerlik sinyali olmayan kayıt listeye girmez', () {
      final ranked = popularItems([
        testFeedItem(
          id: '0000000000000001',
          kind: FeedItemKind.announcement,
          title: 'ölçülmemiş',
          popularity: null,
        ),
        testFeedItem(
          id: '0000000000000002',
          kind: FeedItemKind.announcement,
          title: 'sıfır',
          popularity: 0,
        ),
      ]);

      expect(ranked, isEmpty);
    });

    test('sınırı aşmaz', () {
      final ranked = popularItems([
        for (var index = 0; index < 12; index++)
          testFeedItem(
            id: '00000000000000${index.toString().padLeft(2, '0')}',
            kind: FeedItemKind.repository,
            title: 'kayıt $index',
            popularity: index + 1,
          ),
      ], limit: 5);

      expect(ranked, hasLength(5));
      expect(ranked.first.title, 'kayıt 11');
    });
  });
}
