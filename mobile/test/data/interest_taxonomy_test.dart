import 'package:flutter_test/flutter_test.dart';
import 'package:tecnow/data/feed/feed_schema.dart';
import 'package:tecnow/data/interests/interest_taxonomy.dart';

import '../support/test_overrides.dart';

FeedItem itemWithTopics(String id, List<String> topics) => testFeedItem(
  id: id,
  kind: FeedItemKind.announcement,
  title: 'Kayıt $id',
  topics: topics,
);

/// Bu dosya cihazda bulunan bir kusurun kilidi.
///
/// "Sana Özel" sekmesi ilgi alanı **etiketini** feed'in konu slug'larıyla
/// doğrudan karşılaştırıyordu. İki sözcük dağarcığı hiç kesişmediği için
/// onboarding'i tamamlayan her kullanıcıda açılış sekmesi boştu.
void main() {
  group('sözlük', () {
    /// Onaylı tasarımdaki sekiz çip.
    test('sekiz ilgi alanı var ve kimlikleri benzersiz', () {
      expect(interestTaxonomy, hasLength(8));
      expect(
        interestTaxonomy.map((interest) => interest.id).toSet(),
        hasLength(8),
      );
    });

    /// Anahtarsız bir ilgi alanı, hiçbir zaman sonuç veremeyen bir çiptir.
    test('her ilgi alanının anahtar kelimesi var', () {
      for (final interest in interestTaxonomy) {
        expect(interest.keywords, isNotEmpty, reason: interest.id);
      }
    });

    test('kimlikler aksansız ve küçük harf', () {
      for (final interest in interestTaxonomy) {
        expect(interest.id, matches(RegExp(r'^[a-z0-9-]+$')));
      }
    });
  });

  group('konu eşleşmesi', () {
    /// Kaynakların konu biçimi tek tip değil.
    test('farklı ayraçlar aynı biçime iner', () {
      expect(normalizeTopic('ai-tools'), 'ai tools');
      expect(normalizeTopic('mcp_server'), 'mcp server');
      expect(
        normalizeTopic('agentic ai / generative ai'),
        'agentic ai generative ai',
      );
      expect(
        normalizeTopic('developer tools &amp; techniques'),
        'developer tools amp techniques',
      );
    });

    /// **Asıl tuzak.** Alt dize araması yapılsaydı `ai` anahtarı `training`
    /// ve `available` gibi konularla eşleşir, kullanıcı "Yapay Zekâ"
    /// seçtiğinde alakasız kayıtlar gelirdi.
    test('eşleşme belirteç sınırında yapılır', () {
      expect(topicMatchesKeyword('ai-tools', 'ai'), isTrue);
      expect(topicMatchesKeyword('agentic ai / generative ai', 'ai'), isTrue);
      expect(topicMatchesKeyword('training', 'ai'), isFalse);
      expect(topicMatchesKeyword('available', 'ai'), isFalse);
      expect(topicMatchesKeyword('chain', 'ai'), isFalse);
    });

    test('çok kelimeli anahtar tam sırayla eşleşir', () {
      expect(topicMatchesKeyword('open-source', 'open source'), isTrue);
      expect(
        topicMatchesKeyword('machine-learning', 'machine learning'),
        isTrue,
      );
      expect(topicMatchesKeyword('source open', 'open source'), isFalse);
    });

    test('boş konu hiçbir şeyle eşleşmez', () {
      expect(topicMatchesKeyword('', 'ai'), isFalse);
      expect(topicMatchesKeyword('---', 'ai'), isFalse);
    });
  });

  group('süzme', () {
    final items = [
      itemWithTopics('0000000000000001', const ['ai-tools', 'claude']),
      itemWithTopics('0000000000000002', const ['flutter', 'android']),
      itemWithTopics('0000000000000003', const ['blog', 'release']),
      itemWithTopics('0000000000000004', const []),
    ];

    /// Gerçek kusurun kilidi: ilgi alanı seçiliyken sekme dolu olmalı.
    test('kimlik feed konularıyla eşleşir', () {
      final filtered = filterByInterests(items, const {'yapay-zeka'});

      expect(filtered.map((item) => item.id), ['0000000000000001']);
    });

    test('birden çok ilgi alanı birleşim verir', () {
      final filtered = filterByInterests(items, const {'yapay-zeka', 'mobil'});

      expect(filtered.map((item) => item.id), [
        '0000000000000001',
        '0000000000000002',
      ]);
    });

    /// Boş bir "Sana Özel" sekmesi kullanıcıya bir şey seçmediğini
    /// anlatmaz, yalnız bozuk görünür.
    test('hiç seçim yoksa akışın tamamı döner', () {
      expect(filterByInterests(items, const {}), hasLength(4));
    });

    /// Eski bir sürümden kalmış tanınmayan bir değer, kullanıcıyı boş bir
    /// açılış sekmesiyle karşılamamalı.
    test('tanınmayan kimlik akışı boşaltmaz', () {
      expect(filterByInterests(items, const {'bilinmeyen'}), hasLength(4));
    });

    test(
      'geçerli ve tanınmayan kimlik birlikteyken geçerli olan uygulanır',
      () {
        final filtered = filterByInterests(items, const {
          'mobil',
          'bilinmeyen',
        });

        expect(filtered.map((item) => item.id), ['0000000000000002']);
      },
    );

    test('eşleşme yoksa boş liste döner', () {
      expect(filterByInterests(items, const {'oyun'}), isEmpty);
    });

    /// Cihazdaki gerçek durum: bu üç ilgi alanı seçiliyken sekme boştu.
    test('cihazda seçili olan üçlü kayıt getirir', () {
      final filtered = filterByInterests(items, const {
        'yapay-zeka',
        'mobil',
        'acik-kaynak',
      });

      expect(filtered, isNotEmpty);
    });
  });
}
