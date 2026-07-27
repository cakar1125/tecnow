import 'package:flutter_test/flutter_test.dart';
import 'package:teknoakis/data/feed/feed_schema.dart';

import '../../../tool/feed/connectors/connector_support.dart';
import '../../../tool/feed/connectors/hugging_face.dart';
import '../fixtures.dart';

final _checkedAt = DateTime.utc(2026, 7, 27);

ConnectorResult _models() => parseHuggingFaceModels(
  feedFixture('huggingface_models.json'),
  checkedAt: _checkedAt,
);

FeedItem _byTitle(String title) =>
    _models().items.firstWhere((item) => item.title == title);

void main() {
  group('model listesi', () {
    test('yayımlanabilir kayıtlar alınır', () {
      expect(_models().items.map((item) => item.title), [
        'meta-llama/Llama-4-8B-Instruct',
        'birisi/nexus-7b',
        'birisi/aciklamali-model',
        'birisi/eski-model',
        'birisi/expand-parametresiz',
      ]);
    });

    test('adres model kimliğinden kurulur', () {
      final item = _byTitle('meta-llama/Llama-4-8B-Instruct');
      expect(
        item.url,
        Uri.parse('https://huggingface.co/meta-llama/Llama-4-8B-Instruct'),
      );
      expect(item.id, feedItemId(item.url));
      expect(item.kind, FeedItemKind.aiModel);
      expect(item.sourceKind, FeedSourceKind.huggingFace);
      expect(item.publishedAt, DateTime.utc(2026, 6, 1, 8));
    });
  });

  group('özet kaynağı', () {
    /// Liste uç noktası açıklama alanı **döndürmez**. Uydurmak yerine
    /// yanıttaki yapısal veriden Türkçe bir satır kurulur ve TeknoAkış özeti
    /// olarak işaretlenir; arayüz bunu kaynağın kendi metninden ayırır.
    test('açıklama gelmediğinde yapısal veriden cümle kurulur', () {
      final item = _byTitle('meta-llama/Llama-4-8B-Instruct');
      expect(
        item.summary,
        'Hugging Face üzerinde meta-llama tarafından yayımlanan model. '
        'Görev: text-generation. Lisans: llama4.',
      );
      expect(item.summaryOrigin, SummaryOrigin.teknoakis);
      expect(item.language, 'tr', reason: 'kurulan cümle Türkçe');
    });

    test('bilinmeyen alan cümleden çıkarılır', () {
      final item = _byTitle('birisi/eski-model');
      expect(
        item.summary,
        'Hugging Face üzerinde birisi tarafından yayımlanan model. '
        'Görev: translation.',
        reason: 'license:other gerçek bir lisans değil, cümleye girmez',
      );
    });

    test('kaynağın kendi açıklaması varsa olduğu gibi kullanılır', () {
      final item = _byTitle('birisi/aciklamali-model');
      expect(
        item.summary,
        'A compact image classifier trained on a public dataset.',
      );
      expect(item.summaryOrigin, SummaryOrigin.original);
      expect(item.language, 'en');
    });

    /// Hiçbir yapısal veri yoksa cümle "model" demekten ibaret kalırdı;
    /// kullanıcıya hiçbir şey anlatmayan kayıt yayımlanmaz.
    test('anlatacak hiçbir şey yoksa kayıt elenir', () {
      final skipped = _models().skipped;
      expect(
        skipped.firstWhere((r) => r.identifier == 'tekbasina-model').reason,
        SkipReason.missingSummary,
      );
    });
  });

  group('güven sinyalleri', () {
    test('kurumun kendi hesabı resmi sayılır', () {
      final item = _byTitle('meta-llama/Llama-4-8B-Instruct');
      expect(item.trust.officialSource, isTrue);
      expect(item.trust.hasLicense, isTrue);
      expect(item.trust.recentlyUpdated, isTrue);
      expect(item.trust.maintained, isTrue);
      expect(item.trust.popularity, 912345);
    });

    test('üçüncü tarafın modeli resmi sayılmaz', () {
      final item = _byTitle('birisi/nexus-7b');
      expect(item.trust.officialSource, isFalse);
      expect(item.trust.hasLicense, isTrue);
    });

    /// Gerçek yanıtta yakalandı: varsayılan `/api/models` `lastModified`
    /// döndürmüyor. Bu alan olmadan bakım durumu oluşturulma tarihinden
    /// hesaplanır ve 253 milyon indirmeli, güncel bir model bakımsız görünür.
    /// Üretici [huggingFaceModelsQuery] kullanmak zorunda; bu test, alan
    /// gelmediğinde ne olduğunu belgeler.
    test('lastModified gelmezse oluşturulma tarihine düşülür', () {
      final item = _byTitle('birisi/expand-parametresiz');
      expect(item.trust.maintained, isFalse);
      expect(item.trust.popularity, 253094980);
      expect(
        item.trust.score,
        25,
        reason: 'eksik sorgunun bedeli: 70 yerine 25 puan',
      );
      // `expand[]=lastModified` denendi ve `createdAt`'i düşürdü: dışlayıcı
      // bir parametre. `full=true` iki tarihi birden verir.
      expect(huggingFaceModelsQuery, {'full': 'true'});
    });

    test('bir yıldır dokunulmamış model bakımsızdır', () {
      final item = _byTitle('birisi/eski-model');
      expect(item.trust.maintained, isFalse);
      expect(item.trust.recentlyUpdated, isFalse);
      expect(item.trust.hasLicense, isFalse);
    });
  });

  group('etiketler', () {
    test('ad alanı taşıyan etiketler gösterilmez', () {
      final topics = _byTitle('meta-llama/Llama-4-8B-Instruct').topics;
      expect(topics, ['text-generation', 'transformers', 'conversational']);
      expect(
        topics.any((topic) => topic.contains(':')),
        isFalse,
        reason: 'license:, arxiv:, base_model:, region: iç bilgidir',
      );
    });
  });

  group('elenen kayıtlar', () {
    test('özel model alınmaz', () {
      expect(
        _models().skipped
            .firstWhere((r) => r.identifier == 'birisi/gizli-model')
            .reason,
        SkipReason.private,
      );
    });

    test('gövde bozuksa çalışma hata verir', () {
      expect(
        () => parseHuggingFaceModels('nope', checkedAt: _checkedAt),
        throwsA(isA<ConnectorException>()),
      );
    });
  });
}
