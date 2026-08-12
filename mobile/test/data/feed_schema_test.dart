import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tecos/data/feed/feed_schema.dart';

FeedItem sampleItem({
  String url = 'https://github.com/ornek/depo',
  SummaryOrigin origin = SummaryOrigin.original,
  DateTime? retractedAt,
}) => FeedItem(
  id: feedItemId(Uri.parse(url)),
  kind: FeedItemKind.repository,
  title: 'ornek/depo',
  summary: 'Örnek bir depo açıklaması.',
  summaryOrigin: origin,
  sourceName: 'GitHub',
  sourceKind: FeedSourceKind.github,
  url: Uri.parse(url),
  publishedAt: DateTime.utc(2026, 7, 20),
  checkedAt: DateTime.utc(2026, 7, 27),
  language: 'en',
  trust: const TrustSignals(
    officialSource: false,
    hasLicense: true,
    recentlyUpdated: true,
    maintained: true,
    popularity: 120,
  ),
  topics: const ['dart', 'mobil'],
  retractedAt: retractedAt,
);

void main() {
  group('gidiş-dönüş', () {
    test('bir feed JSON üzerinden aynen geri okunur', () {
      final feed = Feed(
        schemaVersion: feedSchemaVersion,
        generatedAt: DateTime.utc(2026, 7, 27, 9),
        items: [sampleItem()],
      );

      final decoded = Feed.fromJson(
        jsonDecode(jsonEncode(feed.toJson())) as Map<String, Object?>,
      );

      expect(decoded.schemaVersion, feedSchemaVersion);
      expect(decoded.generatedAt, feed.generatedAt);
      final item = decoded.items.single;
      expect(item.id, feed.items.single.id);
      expect(item.title, 'ornek/depo');
      expect(item.url, Uri.parse('https://github.com/ornek/depo'));
      expect(item.publishedAt, DateTime.utc(2026, 7, 20));
      expect(item.checkedAt, DateTime.utc(2026, 7, 27));
      expect(item.topics, ['dart', 'mobil']);
      expect(item.trust.popularity, 120);
    });
  });

  group('tazeleme aralığı', () {
    Feed decode(Object? refreshAfterMinutes) => Feed.fromJson({
      'schemaVersion': feedSchemaVersion,
      'generatedAt': '2026-08-06T09:00:00Z',
      'refreshAfterMinutes': ?refreshAfterMinutes,
      'items': <Object?>[],
    });

    test('sunucunun bildirdiği aralık okunur', () {
      expect(decode(30).refreshAfter, const Duration(minutes: 30));
    });

    test('gidiş-dönüşte korunur', () {
      final feed = Feed(
        schemaVersion: feedSchemaVersion,
        generatedAt: DateTime.utc(2026, 8, 6),
        items: const [],
        refreshAfter: const Duration(minutes: 45),
      );

      final decoded = Feed.fromJson(
        jsonDecode(jsonEncode(feed.toJson())) as Map<String, Object?>,
      );

      expect(decoded.refreshAfter, const Duration(minutes: 45));
    });

    /// Alan **isteğe bağlı** olmak zorunda: yayına eklendiğinde kurulu her
    /// uygulama onu tanımıyor olacak ve tanımayan sürüm feed'i okumaya devam
    /// etmeli.
    test('alan yoksa varsayılana düşer', () {
      expect(decode(null).refreshAfter, feedDefaultRefreshAfter);
    });

    /// Bozuk bir **ayar** yüzünden 200 kayıt gösterilmemesi orantısız olurdu.
    test('bozuk değer feed’i düşürmez, varsayılana düşer', () {
      for (final bad in <Object>['30', 0, -5, 12.5, true]) {
        expect(
          decode(bad).refreshAfter,
          feedDefaultRefreshAfter,
          reason: '$bad için varsayılan bekleniyor',
        );
      }
    });

    /// Sunucudan gelen değer bizi kendimize karşı korumalı: yanlışlıkla
    /// yazılmış küçük bir sayı kurulu her uygulamayı ağa boğardı.
    test('alt sınırın altındaki değer kırpılır', () {
      expect(decode(1).refreshAfter, feedMinRefreshAfter);
    });

    test('üst sınırın üstündeki değer kırpılır', () {
      expect(decode(60 * 24 * 7).refreshAfter, feedMaxRefreshAfter);
    });

    /// Alanın eklenmesi sürüm yükseltmesi **değildir**. Yükseltilseydi eski
    /// sürümler feed'i topluca reddederdi.
    test('alan şema sürümünü yükseltmedi', () {
      expect(feedSchemaVersion, 1);
      final json = Feed(
        schemaVersion: feedSchemaVersion,
        generatedAt: DateTime.utc(2026, 8, 6),
        items: const [],
        refreshAfter: const Duration(minutes: 20),
      ).toJson();
      expect(json['schemaVersion'], 1);
      expect(json['refreshAfterMinutes'], 20);
    });
  });

  group('şema sürümü', () {
    test('gelecekteki bir sürüm reddedilir', () {
      expect(
        () => Feed.fromJson({
          'schemaVersion': feedSchemaVersion + 1,
          'generatedAt': '2026-07-27T09:00:00Z',
          'items': <Object?>[],
        }),
        throwsA(isA<FeedFormatException>()),
        reason: 'bilinmeyen şema sessizce yanlış ayrıştırılmamalı',
      );
    });

    test('sürüm alanı yoksa reddedilir', () {
      expect(
        () => Feed.fromJson({
          'generatedAt': '2026-07-27T09:00:00Z',
          'items': <Object?>[],
        }),
        throwsA(isA<FeedFormatException>()),
      );
    });
  });

  group('zorunlu alanlar — CONTENT_TRUST_POLICY', () {
    /// "Her içerikte orijinal URL, kaynak türü, yayın tarihi ve son kontrol
    /// zamanı tutulur."
    for (final field in ['url', 'sourceKind', 'publishedAt', 'checkedAt']) {
      test('$field olmadan kayıt okunamaz', () {
        final json = sampleItem().toJson()..remove(field);
        expect(
          () => FeedItem.fromJson(json),
          throwsA(isA<FeedFormatException>()),
        );
      });
    }

    test('göreli URL reddedilir', () {
      final json = sampleItem().toJson()..['url'] = '/ornek/depo';
      expect(
        () => FeedItem.fromJson(json),
        throwsA(isA<FeedFormatException>()),
      );
    });

    /// Politika alanın **varlığını** şart koşuyor, değerinin bu sürümce
    /// biliniyor olmasını değil. Bilinmeyen bir kaynak türü kaydı düşürmez;
    /// `other`a düşer ve içerik görünür kalır.
    ///
    /// Davranış 29 Temmuz 2026'da değişti. Eskiden reddediliyordu ve bu bir
    /// **güven kapısı sanılıyordu**; ölçüldüğünde değildi:
    /// - Allowlist yalnız üreticide zorlanıyor (`tool/feed/source_allowlist.dart`);
    ///   `lib/` içinde tek bir referansı yok.
    /// - Feed'i değiştirebilen biri `sourceKind: "github"` de yazabilirdi,
    ///   yani katılık düşmanca bir yayına karşı hiçbir şey kazandırmıyordu.
    /// - Üretici bilinmeyen bir değer üretemiyor: bağlayıcılar ya sabit enum
    ///   yazıyor ya da `SourceAllowlist.sourceKindFor` çağırıyor.
    ///
    /// Geriye tek gerçek etki kalıyordu: **gelecekteki** bir kaynak türü
    /// yüzünden kurulu uygulamanın tüm feed'i düşürmesi.
    test('bilinmeyen kaynak türü kaydı düşürmez, other olur', () {
      final json = sampleItem().toJson()..['sourceKind'] = 'twitter';
      expect(FeedItem.fromJson(json).sourceKind, FeedSourceKind.other);
    });

    /// Gevşeme **dar**: gevşeyen şey değerin tanınırlığı, varlığı değil.
    /// Boş bir alan gelecekteki bir değer değil, bozuk bir alandır — üretici
    /// kusuru olarak ölümcül kalır.
    test('kaynak türü boş metinse hâlâ reddedilir', () {
      final json = sampleItem().toJson()..['sourceKind'] = '';
      expect(
        () => FeedItem.fromJson(json),
        throwsA(isA<FeedFormatException>()),
      );
    });
  });

  /// İleri uyumluluk: yayın bu sürümden yeni olduğunda uygulama **bildiklerini
  /// göstermeye devam eder**.
  ///
  /// Ölçülen kusur (2026-07-29): paketlenmiş 200 kayıttan tek birine bilinmeyen
  /// bir `kind` yazıldığında 200'ü birden reddediliyordu. Yayımlanmış bir
  /// uygulamada bu, güncellemeyen kullanıcının **hiçbir** taze içerik
  /// alamaması demekti — sessizce, çünkü önbellek korunuyor ve ekran
  /// "Güncellenemedi" deyip duruyor.
  group('ileri uyumluluk', () {
    Map<String, Object?> feedWith(List<Map<String, Object?>> items) => {
      'schemaVersion': feedSchemaVersion,
      'generatedAt': DateTime.utc(2026, 7, 29).toIso8601String(),
      'items': items,
    };

    test('bilinmeyen tür atlanır, diğer kayıtlar okunur', () {
      final feed = Feed.fromJson(
        feedWith([
          sampleItem(url: 'https://github.com/ornek/bir').toJson(),
          sampleItem().toJson()..['kind'] = 'leaderboard',
          sampleItem(url: 'https://github.com/ornek/iki').toJson(),
        ]),
      );

      expect(feed.items.map((item) => item.url.path), [
        '/ornek/bir',
        '/ornek/iki',
      ]);
      expect(feed.unsupportedItemCount, 1);
    });

    /// Dürüstlük kuralı ödün vermiyor: özetin kaynağı bilinmiyorsa kayıt
    /// gösterilmez. `original`a düşürmek, tecOS özetini kaynağın kendi
    /// metniymiş gibi sunmak olurdu.
    test('bilinmeyen özet kökeni atlanır', () {
      final feed = Feed.fromJson(
        feedWith([
          sampleItem(url: 'https://github.com/ornek/kalan').toJson(),
          sampleItem().toJson()..['summaryOrigin'] = 'community',
        ]),
      );

      expect(feed.items.single.url.path, '/ornek/kalan');
      expect(feed.unsupportedItemCount, 1);
    });

    /// Bilinmeyen **değer** atlanır ama bozuk **yapı** hâlâ ölümcül: üretici
    /// kusurunu maskelemek, sessizce eksik içerik yayımlamak olurdu.
    test('zorunlu alan eksikse feed hâlâ reddedilir', () {
      expect(
        () => Feed.fromJson(feedWith([sampleItem().toJson()..remove('title')])),
        throwsA(isA<FeedFormatException>()),
      );
    });

    /// Bugün doğru ama hiçbir yerde kilitli değildi: yeni bir opsiyonel alan
    /// eklemek kurulu uygulamayı bozmamalı. Aşama 2'nin sıralama kartı buna
    /// dayanacak.
    test('tanınmayan opsiyonel alan yok sayılır', () {
      final json = sampleItem().toJson()
        ..['leaderboardRank'] = 3
        ..['gelecektekiAlan'] = {'ic': 'ice'};

      expect(FeedItem.fromJson(json).title, sampleItem().title);
    });

    /// Özet taşıma, damganın **yayımlanan dosyada** hayatta kalmasına bağlı:
    /// bir sonraki koşu onu yayındaki feed'den okuyup "kaynak metin hâlâ aynı
    /// mı" sorusunu cevaplıyor. Gidiş-dönüşte düşerse taşıma sessizce kapanır
    /// ve her koşu özetleri yeniden satın alır.
    test('özet damgası JSON gidiş-dönüşünde korunur', () {
      final hash = fnv1aHex('Nexus-7B\nAçık ağırlıklı model.');
      final json = sampleItem().toJson()..['summarySourceHash'] = hash;

      expect(FeedItem.fromJson(json).summarySourceHash, hash);
    });

    /// Damga yalnız tecOS özetlerinde bulunur; olmayan kayıtta `null`
    /// kalmalı ve `toJson` anahtarı hiç yazmamalı.
    test('damgasız kayıt anahtarı hiç yazmaz', () {
      expect(sampleItem().toJson().containsKey('summarySourceHash'), isFalse);
      expect(sampleItem().summarySourceHash, isNull);
    });

    test('her şey tanınıyorsa atlanan kayıt sayısı sıfırdır', () {
      final feed = Feed.fromJson(
        feedWith([
          sampleItem(url: 'https://github.com/ornek/a').toJson(),
          sampleItem(url: 'https://github.com/ornek/b').toJson(),
        ]),
      );

      expect(feed.items, hasLength(2));
      expect(feed.unsupportedItemCount, 0);
    });
  });

  group('geri çekme', () {
    /// "Yanlış içerik düzeltme/geri çekme kaydıyla yönetilir." Kayıt silinmez,
    /// görünmez olur.
    test('geri çekilen kayıt feed\'de kalır ama görünür kümede olmaz', () {
      final feed = Feed(
        schemaVersion: feedSchemaVersion,
        generatedAt: DateTime.utc(2026, 7, 27),
        items: [
          sampleItem(),
          sampleItem(
            url: 'https://github.com/ornek/yanlis',
            retractedAt: DateTime.utc(2026, 7, 26),
          ),
        ],
      );

      expect(feed.items, hasLength(2));
      expect(feed.visibleItems, hasLength(1));
      expect(feed.visibleItems.single.url.path, '/ornek/depo');
    });
  });

  group('kimlik ve kanonikleştirme', () {
    test('kimlik aynı URL için her üretimde aynıdır', () {
      final first = feedItemId(Uri.parse('https://github.com/ornek/depo'));
      final second = feedItemId(Uri.parse('https://github.com/ornek/depo'));
      expect(first, second);
      expect(first, hasLength(16));
    });

    /// Kopya birleştirme buna bağlı: aynı gelişmenin farklı adresleri aynı
    /// kimliğe düşmeli.
    test(
      'izleme parametreleri, www ve sondaki eğik çizgi kimliği değiştirmez',
      () {
        final canonical = feedItemId(
          Uri.parse('https://github.com/ornek/depo'),
        );
        for (final variant in [
          'https://www.github.com/ornek/depo',
          'https://github.com/ornek/depo/',
          'https://github.com/ornek/depo?utm_source=twitter',
          'http://github.com/ornek/depo',
          'https://GitHub.com/ornek/depo',
        ]) {
          expect(
            feedItemId(Uri.parse(variant)),
            canonical,
            reason: '$variant kanonik biçime indirgenmeli',
          );
        }
      },
    );

    test('anlamlı sorgu parametresi korunur', () {
      expect(
        canonicalizeUrl(
          Uri.parse(
            'https://huggingface.co/models?search=llama&utm_medium=rss',
          ),
        ).toString(),
        'https://huggingface.co/models?search=llama',
      );
    });

    test('farklı içerikler farklı kimlik alır', () {
      expect(
        feedItemId(Uri.parse('https://github.com/ornek/depo')),
        isNot(feedItemId(Uri.parse('https://github.com/ornek/baska'))),
      );
    });

    /// Dart tam sayıları 64-bit **işaretlidir**: FNV-1a karışımı negatif bir
    /// değere düşebilir ve `toRadixString(16)` başa `-` koyar. Sözleşme
    /// incelemesinde `https://ornek.test/blog/yanlis-duyuru` tam olarak bunu
    /// üretti (`-4e43c92b700b9ce0`). Kimlik biçimi burada kilitlenir.
    test('kimlik her zaman 16 haneli küçük harf onaltılıktır', () {
      final pattern = RegExp(r'^[0-9a-f]{16}$');
      for (final url in [
        'https://ornek.test/blog/yanlis-duyuru',
        'https://github.com/ornek/depo',
        'https://huggingface.co/nexus/Nexus-7B',
        'https://ornek.test/a',
        'https://ornek.test/',
        'https://ornek.test/cok/uzun/bir/yol/parcasi/ile/deneme',
      ]) {
        final id = feedItemId(Uri.parse(url));
        expect(
          pattern.hasMatch(id),
          isTrue,
          reason: '$url -> "$id" biçime uymuyor',
        );
      }
    });
  });

  group('güven puanı', () {
    /// "Güvenilirlik yalnız popülerlik değildir." Popülerlik tek başına
    /// bakımlı, lisanslı, resmi bir kaynağı geçememeli.
    test('popülerlik tek başına düşük puan verir', () {
      const popularOnly = TrustSignals(
        officialSource: false,
        hasLicense: false,
        recentlyUpdated: false,
        maintained: false,
        popularity: 90000,
      );
      const officialMaintained = TrustSignals(
        officialSource: true,
        hasLicense: true,
        recentlyUpdated: true,
        maintained: true,
      );

      expect(popularOnly.score, 10);
      expect(officialMaintained.score, 90);
      expect(popularOnly.score, lessThan(officialMaintained.score));
    });

    test('hiçbir sinyal yoksa puan sıfırdır', () {
      const none = TrustSignals(
        officialSource: false,
        hasLicense: false,
        recentlyUpdated: false,
        maintained: false,
      );
      expect(none.score, 0);
    });
  });

  group('özet kaynağı', () {
    /// "tecOS özeti, orijinal kaynaktan görsel olarak ayrılır." Arayüzün
    /// ayırabilmesi için alan gidiş-dönüşte korunmalı.
    test('özet kaynağı gidiş-dönüşte korunur', () {
      for (final origin in SummaryOrigin.values) {
        final decoded = FeedItem.fromJson(sampleItem(origin: origin).toJson());
        expect(decoded.summaryOrigin, origin);
      }
    });
  });

  group('dil', () {
    Map<String, Object?> feedJson({
      String? language,
      Object? availableLanguages,
    }) => {
      'schemaVersion': feedSchemaVersion,
      'generatedAt': DateTime.utc(2026, 8, 12).toIso8601String(),
      'language': ?language,
      'availableLanguages': ?availableLanguages,
      'items': [sampleItem().toJson()],
    };

    test('dil ve dil listesi gidiş-dönüşte korunur', () {
      final feed = Feed(
        schemaVersion: feedSchemaVersion,
        generatedAt: DateTime.utc(2026, 8, 12),
        items: [sampleItem()],
        language: 'tr',
        availableLanguages: const [
          FeedLanguage(code: 'tr', url: 'feed.json'),
          FeedLanguage(code: 'en', url: 'feed.en.json'),
        ],
      );

      final decoded = Feed.fromJson(
        jsonDecode(jsonEncode(feed.toJson())) as Map<String, Object?>,
      );

      expect(decoded.language, 'tr');
      expect(decoded.availableLanguages.map((entry) => entry.code), [
        'tr',
        'en',
      ]);
      expect(decoded.availableLanguages.last.url, 'feed.en.json');
    });

    /// Alan **eklendiğinde** yayınlanmış eski dosyalar onu taşımıyor olacak.
    /// Bunlar Türkçe hedefli üretildi; varsayılan da o.
    test('alanı taşımayan eski yayın varsayılana düşer', () {
      final decoded = Feed.fromJson(feedJson());
      expect(decoded.language, feedDefaultLanguage);
      expect(decoded.availableLanguages, isEmpty);
      expect(decoded.items, hasLength(1), reason: 'içerik okunmaya devam eder');
    });

    /// Şema sürümü **artırılmadı**: artırılsaydı kurulu her uygulama feed'i
    /// topluca reddederdi. Eklenen alanı tanımayan sürüm onu yok sayar.
    test('yeni alanlar şema sürümünü artırmaz', () {
      final feed = Feed(
        schemaVersion: feedSchemaVersion,
        generatedAt: DateTime.utc(2026, 8, 12),
        items: [sampleItem()],
        language: 'en',
      );
      expect(feed.toJson()['schemaVersion'], 1);
    });

    test('bozuk giriş yalnız kendini düşürür', () {
      final decoded = Feed.fromJson(
        feedJson(
          language: 'tr',
          availableLanguages: [
            {'code': 'tr', 'url': 'feed.json'},
            {'code': 'de'}, // adres yok
            'yanlış tür',
            {'code': 'en', 'url': 'feed.en.json'},
          ],
        ),
      );
      expect(decoded.availableLanguages.map((entry) => entry.code), [
        'tr',
        'en',
      ]);
    });

    test('tekrar eden dil kodu bir kez sayılır', () {
      final decoded = Feed.fromJson(
        feedJson(
          language: 'tr',
          availableLanguages: [
            {'code': 'tr', 'url': 'feed.json'},
            {'code': 'tr', 'url': 'baska.json'},
          ],
        ),
      );
      expect(decoded.availableLanguages, hasLength(1));
      expect(decoded.availableLanguages.single.url, 'feed.json');
    });

    /// Kendi kendisiyle çelişen liste arayüz süremez: kullanıcı okumakta
    /// olduğu dile geri dönemezdi.
    test('okunan dil listede yoksa liste tümden reddedilir', () {
      final decoded = Feed.fromJson(
        feedJson(
          language: 'tr',
          availableLanguages: [
            {'code': 'en', 'url': 'feed.en.json'},
          ],
        ),
      );
      expect(decoded.availableLanguages, isEmpty);
      expect(decoded.items, hasLength(1));
    });

    group('adres çözümü', () {
      final base = Uri.parse('https://feed.example.test/feed.json');

      test('göreli adres feed adresine göre çözülür', () {
        const entry = FeedLanguage(code: 'en', url: 'feed.en.json');
        expect(
          entry.resolve(base),
          Uri.parse('https://feed.example.test/feed.en.json'),
        );
      });

      /// Uygulamanın ağ çıkışı bilinçli olarak dar. Dil listesi akışa açılan
      /// yeni bir adres alanı olduğu için o darlığın burada da tutması şart.
      test('başka konağa çözülen adres reddedilir', () {
        const entry = FeedLanguage(
          code: 'en',
          url: 'https://baska-sunucu.example/feed.json',
        );
        expect(entry.resolve(base), isNull);
      });

      test('https dışı adres reddedilir', () {
        const entry = FeedLanguage(
          code: 'en',
          url: 'http://feed.example.test/feed.en.json',
        );
        expect(entry.resolve(base), isNull);
      });
    });
  });
}
