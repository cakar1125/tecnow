import 'package:flutter_test/flutter_test.dart';
import 'package:tecos/data/feed/feed_schema.dart';
import 'package:tecos/ui/feed_signal.dart';

FeedItem _item({
  SummaryOrigin origin = SummaryOrigin.original,
  bool official = false,
  List<String> topics = const [],
  Duration age = const Duration(days: 30),
}) {
  final published = DateTime.utc(2026, 8, 11).subtract(age);
  return FeedItem(
    id: 'x',
    kind: FeedItemKind.announcement,
    title: 'Başlık',
    summary: 'Özet',
    summaryOrigin: origin,
    sourceName: 'GitHub',
    sourceKind: FeedSourceKind.github,
    url: Uri.parse('https://example.com/x'),
    publishedAt: published,
    checkedAt: published,
    language: 'en',
    trust: TrustSignals(
      officialSource: official,
      hasLicense: false,
      recentlyUpdated: false,
      maintained: false,
    ),
    topics: topics,
  );
}

final _now = DateTime.utc(2026, 8, 11);

void main() {
  group('gerekçe seçimi', () {
    test('gerekçe yoksa null döner', () {
      expect(
        feedSignalFor(_item(), interests: const {}, now: _now),
        isNull,
        reason: 'uydurulmuş bir etiket, etiketsiz satırdan kötüdür',
      );
    });

    test('tecOS özeti her şeyin önünde gelir', () {
      final signal = feedSignalFor(
        _item(
          origin: SummaryOrigin.generated,
          official: true,
          age: const Duration(hours: 1),
        ),
        interests: const {'yapay-zeka'},
        now: _now,
      );

      expect(
        signal,
        FeedSignal.generatedSummary,
        reason:
            'kaynak beyanı değil bizim beyanımız; CONTENT_TRUST_POLICY.md '
            'ayrı gösterilmesini şart koşuyor',
      );
    });

    /// Sıra **ters çevrildi** (2026-08-11) ve bu test onunla birlikte
    /// döndü. Önce "ilgi eşleşmesi tazelikten önce gelir" diyordu ve
    /// geçiyordu — yani yanlış davranışı doğruluyordu.
    ///
    /// Ölçüm (`dart run tool/measure_signals.dart`, 200 kayıtlık üretim):
    /// kullanıcı üç konu seçtiğinde `SANA` 102/200'e (%51) çıkıyor ve `YENİ`
    /// 13/200'den **4/200'e** düşüyordu. Akışın en taze dokuz kaydı,
    /// yarısında görünen bir etiket uğruna tazelik bilgisini kaybediyordu.
    ///
    /// Bu dosyanın ilkesi nadirlik: %51'lik bir etiket %6,5'liği yutamaz.
    test('tazelik ilgi eşleşmesinden önce gelir', () {
      final signal = feedSignalFor(
        _item(topics: const ['llm'], age: const Duration(hours: 1)),
        interests: const {'yapay-zeka'},
        now: _now,
      );

      expect(signal, FeedSignal.fresh);
    });

    test('taze değilse ilgi eşleşmesi gösterilir', () {
      final signal = feedSignalFor(
        _item(topics: const ['llm'], age: const Duration(days: 5)),
        interests: const {'yapay-zeka'},
        now: _now,
      );

      expect(signal, FeedSignal.matchesInterest);
    });

    test('24 saatten yeni kayıt YENİ etiketi alır', () {
      expect(
        feedSignalFor(
          _item(age: const Duration(hours: 23)),
          interests: const {},
          now: _now,
        ),
        FeedSignal.fresh,
      );
    });

    test('25 saatlik kayıt YENİ değildir', () {
      expect(
        feedSignalFor(
          _item(age: const Duration(hours: 25)),
          interests: const {},
          now: _now,
        ),
        isNull,
      );
    });

    /// 123/200 kayıt resmi kaynak; çoğunluğun taşıdığı etiket ayırt etmez,
    /// bu yüzden **en sonda**. Başka gerekçe yokken hâlâ doğru bir bilgi.
    test('resmi kaynak yalnız başka gerekçe yokken görünür', () {
      expect(
        feedSignalFor(_item(official: true), interests: const {}, now: _now),
        FeedSignal.officialSource,
      );

      expect(
        feedSignalFor(
          _item(official: true, age: const Duration(hours: 2)),
          interests: const {},
          now: _now,
        ),
        FeedSignal.fresh,
        reason:
            'tazelik 13/200 ile daha nadir, dolayısıyla daha bilgilendirici',
      );
    });

    /// Cihazda görüldü: "Sana Özel" sekmesinde her satır "SANA" diyordu.
    /// Doğru ama boş — o sekmedeki her kayıt tanım gereği eşleşiyor.
    group('bastırma', () {
      /// Kayıt bilinçli olarak **taze değil**: tazelik artık ilgi
      /// eşleşmesinin üstünde ve taze bir kayıt zaten "YENİ" alırdı. Öyle bir
      /// kayıtla ölçseydik test bastırmayı hiç sınamaz, yalnız yeni sırayı
      /// tekrar ederdi — ve bastırma bozulsa bile yeşil kalırdı.
      test('bastırıldığında bir alt gerekçeye düşer', () {
        expect(
          feedSignalFor(
            _item(topics: const ['llm'], official: true),
            interests: const {'yapay-zeka'},
            now: _now,
            suppressInterestSignal: true,
          ),
          FeedSignal.officialSource,
        );
      });

      test('bastırma tazeliği etkilemez', () {
        expect(
          feedSignalFor(
            _item(topics: const ['llm'], age: const Duration(hours: 1)),
            interests: const {'yapay-zeka'},
            now: _now,
            suppressInterestSignal: true,
          ),
          FeedSignal.fresh,
          reason: 'tazelik kişiselleştirmeden bağımsız bir olgu',
        );
      });

      test('bastırma tecOS özetini etkilemez', () {
        expect(
          feedSignalFor(
            _item(origin: SummaryOrigin.generated, topics: const ['llm']),
            interests: const {'yapay-zeka'},
            now: _now,
            suppressInterestSignal: true,
          ),
          FeedSignal.generatedSummary,
          reason: 'kaynak beyanı kişiselleştirmeden bağımsız',
        );
      });

      test('başka gerekçe yoksa etiketsiz kalır', () {
        expect(
          feedSignalFor(
            _item(topics: const ['llm']),
            interests: const {'yapay-zeka'},
            now: _now,
            suppressInterestSignal: true,
          ),
          isNull,
        );
      });
    });

    /// Hiç ilgi alanı seçilmemişken "SANA" demek yalan olur.
    test('seçim yokken ilgi gerekçesi verilmez', () {
      expect(
        feedSignalFor(
          _item(topics: const ['llm']),
          interests: const {},
          now: _now,
        ),
        isNull,
      );
    });

    /// Eski bir sürümden kalan tanınmayan kimlik sessizce atlanır —
    /// `filterByInterests` ile aynı davranış.
    test('tanınmayan ilgi kimliği çökertmez', () {
      expect(
        feedSignalFor(
          _item(topics: const ['llm']),
          interests: const {'yok-boyle-alan'},
          now: _now,
        ),
        isNull,
      );
    });
  });
}
