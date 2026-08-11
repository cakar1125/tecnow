import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecos/app/router.dart';
import 'package:tecos/data/feed/feed_repository.dart';
import 'package:tecos/data/feed/feed_schema.dart';
import 'package:tecos/data/providers.dart';
import 'package:tecos/design_system/components/feed_items.dart';
import 'package:tecos/design_system/theme/app_theme.dart';
import 'package:tecos/features/feed/feed_screen.dart';

import '../support/test_overrides.dart';

/// FeedScreen uygulamada `AppScaffold` içinde yaşar; SnackBar ve Material
/// etkileşimleri bir Scaffold atası gerektirir. Testler bu gerçeği yansıtır.
Future<void> _pumpFeed(
  WidgetTester tester, {
  List<FeedItem>? feed,
  List<String>? interests,
  FakeFeedRepository? repository,
}) async {
  await tester.pumpWidget(
    memoryDataHarness(
      const Scaffold(body: FeedScreen()),
      feed: feed,
      interests: interests,
      feedRepository: repository,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _selectTab(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(Key('feed-tab-$key-idle')));
  await tester.pumpAndSettle();
}

/// Şeritteki sekme etiketleri, soldan sağa.
List<String> _tabLabels(WidgetTester tester) => tester
    .widgetList<Text>(
      find.descendant(
        of: find.byKey(const Key('feed-tab-scroll')),
        matching: find.byType(Text),
      ),
    )
    .map((text) => text.data!)
    .toList(growable: false);

/// Sekme etiketleri kart rozetleriyle aynı metni taşıyabilir (örn. "GİTHUB"),
/// bu yüzden sekme beklentileri sekme şeridine daraltılır.
Finder _tab(String label) => find.descendant(
  of: find.byKey(const Key('feed-tab-scroll')),
  matching: find.text(label),
);

/// Akıştaki kayıt sayısı.
///
/// Akış iki anatomi kullanıyor: ilk kayıt [FeedHeroItem], sonrakiler
/// [FeedRowItem]. Testler "kaç kayıt görünüyor" diye soruyor, "hangi kutu
/// çizildi" diye değil — bu yüzden ikisinin toplamına bakılıyor ve anatomi
/// değişince testler değişmiyor.
final Finder _feedItems = find.byWidgetPredicate(
  (widget) => widget is FeedHeroItem || widget is FeedRowItem,
);

void main() {
  /// Şerit artık uygulamanın kendi şemasından (tür/kaynak) değil
  /// **kullanıcının seçtiği konulardan** kuruluyor. Gerekçesi ve `TÜMÜ`
  /// sekmesini zorunlu kılan ölçüm `lib/features/feed/home_tabs.dart`
  /// başlığında.
  group('sekme şeridi', () {
    testWidgets('seçim yokken iki sabit sekme kalır', (tester) async {
      await _pumpFeed(tester);

      expect(_tabLabels(tester), ['SANA ÖZEL', 'TÜMÜ']);
    });

    testWidgets('seçilen konular araya girer', (tester) async {
      await _pumpFeed(tester, interests: const ['bulut', 'yapay-zeka']);

      expect(_tabLabels(tester), ['SANA ÖZEL', 'BULUT', 'YAPAY ZEKÂ', 'TÜMÜ']);
    });

    /// Sıra kullanıcıya ait: depodaki sıra şeride birebir yansımalı.
    /// Yansımazsa Ayarlar'daki sürükle-bırak hiçbir şey yapmıyor demektir ve
    /// ekranda her şey doğru görünür.
    testWidgets('şeridin sırası kullanıcının sırasıdır', (tester) async {
      await _pumpFeed(tester, interests: const ['yapay-zeka', 'bulut']);

      expect(_tabLabels(tester), ['SANA ÖZEL', 'YAPAY ZEKÂ', 'BULUT', 'TÜMÜ']);
    });

    /// Türkçe büyütme: `toUpperCase()` "Mobil"i "MOBIL" yapıyor.
    testWidgets('etiketler Türkçe yazılır', (tester) async {
      await _pumpFeed(tester, interests: const ['mobil']);

      expect(_tab('MOBİL'), findsOneWidget);
      expect(_tab('MOBIL'), findsNothing);
    });
  });

  group('paketlenmiş feed', () {
    testWidgets('kayıtlar akışta görünür', (tester) async {
      await _pumpFeed(tester);

      expect(find.text('ornek/depo'), findsOneWidget);
      expect(find.text('ornek/model'), findsOneWidget);
      expect(find.text('Bir duyuru'), findsOneWidget);
      expect(_feedItems, findsNWidgets(3));
    });

    /// Gerçek içerik "ÖRNEK" diye işaretlenmez — o etiket orada yalan olur.
    testWidgets('gerçek içerik örnek diye işaretlenmez', (tester) async {
      await _pumpFeed(tester);
      expect(find.text('ÖRNEK'), findsNothing);
    });

    /// Politika: tecOS özeti kaynağın kendi metninden görsel olarak
    /// ayrılır.
    testWidgets('tecOS özeti ayrıca işaretlenir', (tester) async {
      await _pumpFeed(tester);
      // Yazım **kasıtlı**: marka kendi biçimini korur (`tecOS`), açıklama
      // büyük harf. Ad "TecNow"dan buraya taşındı — o ad, TÜRKPATENT'te
      // sınıf 09 ve 42'de tescilli TECNO markasını bütünüyle içeriyordu.
      // Bu beklenti yazımı kilitliyor — bkz. DECISION_LOG D-018.
      expect(find.text('tecOS ÖZETİ'), findsOneWidget);
    });

    /// Dil rozeti akıştan **kaldırıldı** (2026-08-11) — ölçümle.
    ///
    /// Rozet "özet kaynağın kendi dilinde" demek için konmuştu. Gerçek
    /// üretim ölçüldüğünde iki şey çıktı:
    ///
    /// 1. 200 kaydın **180'i** İngilizce. %90'a takılan bir etiket hiçbir
    ///    kaydı diğerinden ayırmaz; yalnız her satıra gürültü ekler.
    /// 2. Türkçe olan 20 kayıt, **tam olarak** tecOS'un özetlediği 20 kayıt
    ///    (kesişim 20, fark 0). Yani rozet, yanında duran `tecOS ÖZETİ`
    ///    gerekçesinin üstüne sıfır bilgi koyuyordu.
    ///
    /// Dil detay ekranında duruyor — orada tek kayda bakılıyor ve oranın
    /// gürültüsü yok. Bu test o kararı kilitliyor: rozet akışa geri
    /// gelirse kırılır.
    testWidgets('dil rozeti akışta gösterilmez', (tester) async {
      await _pumpFeed(tester);
      expect(find.text('EN'), findsNothing);
    });

    /// Kaynaklar "ne işe yarar" alanı vermiyor; boş bir başlık göstermek de
    /// bir şey vaat etmektir.
    testWidgets('olmayan açıklama bölümü hiç çizilmez', (tester) async {
      await _pumpFeed(tester);
      expect(find.text('NE İŞE YARAR?'), findsNothing);
    });
  });

  group('sekmeler', () {
    testWidgets('konu sekmesi yalnız o konuyu gösterir', (tester) async {
      // Test feed'inde `llm` konulu tek kayıt AI modeli.
      await _pumpFeed(tester, interests: const ['yapay-zeka', 'oyun']);
      await _selectTab(tester, 'yapay-zeka');

      expect(find.text('ornek/model'), findsOneWidget);
      expect(_feedItems, findsOneWidget);
    });

    /// Ölçüldü (2026-08-11, 200 kayıtlık üretim): kayıtların **67'si** sekiz
    /// ilgi alanının hiçbirine girmiyor. `TÜMÜ` olmasaydı akışın üçte biri
    /// Ana Sayfa'dan sessizce görünmez olurdu.
    testWidgets('TÜMÜ hiçbir kaydı elemez', (tester) async {
      await _pumpFeed(tester, interests: const ['yapay-zeka']);
      await _selectTab(tester, 'tumu');

      expect(_feedItems, findsNWidgets(3));
    });

    /// Kapatılan kaynak `TÜMÜ` sekmesinde de gelmez: susturma kullanıcının
    /// kararı ve hiçbir sekme onu geçersiz kılmaz.
    testWidgets('TÜMÜ kapatılmış kaynağı geri getirmez', (tester) async {
      await tester.pumpWidget(
        memoryDataHarness(
          const Scaffold(body: FeedScreen()),
          mutedSources: const {'GitHub'},
        ),
      );
      await tester.pumpAndSettle();
      await _selectTab(tester, 'tumu');

      expect(find.text('ornek/depo'), findsNothing);
      expect(_feedItems, findsNWidgets(2));
    });

    /// Boş bir sekme "içerik yok" demekle yetinmez: gerçek akışta "Oyun"
    /// konusu 200 kayıtta yalnız 2 kayıt buluyor, yani bu ekran istisna
    /// değil beklenen bir hâl.
    testWidgets('boş konu sekmesi konunun adını söyler', (tester) async {
      await _pumpFeed(tester, interests: const ['oyun']);
      await _selectTab(tester, 'oyun');

      expect(find.textContaining('"Oyun" konusunda'), findsOneWidget);
    });

    /// Bir sekme kaybolduğunda ekran boş kalmamalı: kullanıcı Keşfet'ten
    /// bulunduğu sekmenin konusunu kapatabilir.
    testWidgets('kaybolan sekmeden ilk sekmeye düşülür', (tester) async {
      final repository = InMemoryInterestsRepository(const ['oyun', 'bulut']);
      await tester.pumpWidget(
        memoryDataHarness(
          const Scaffold(body: FeedScreen()),
          interestsRepository: repository,
        ),
      );
      await tester.pumpAndSettle();
      await _selectTab(tester, 'oyun');
      expect(find.byKey(const Key('feed-tab-oyun-selected')), findsOneWidget);

      // Keşfet'ten "Oyun" kapatıldı.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(FeedScreen)),
      );
      container.read(interestsProvider.notifier).toggle('oyun');
      await tester.pumpAndSettle();

      expect(_tabLabels(tester), ['SANA ÖZEL', 'BULUT', 'TÜMÜ']);
      expect(
        find.byKey(const Key('feed-tab-sana-ozel-selected')),
        findsOneWidget,
      );
    });
  });

  group('SANA ÖZEL', () {
    /// Hiç ilgi alanı seçilmemişken boş bir sekme göstermek kullanıcıya bir
    /// şey anlatmaz, sadece bozuk görünür.
    testWidgets('ilgi alanı yoksa akışın tamamı gösterilir', (tester) async {
      await _pumpFeed(tester);
      expect(_feedItems, findsNWidgets(3));
    });

    /// **Kimlik** verilir, feed'in konu slug'ı değil.
    ///
    /// Bu testler eskiden `['llm']` gibi feed slug'ları geçiyordu — ürünün
    /// hiçbir yerinde üretilmeyen bir değer. İlgi alanı ekranı Türkçe
    /// etiket saklıyordu ve iki sözcük dağarcığı hiç kesişmiyordu; yani
    /// gerçek uygulamada bu sekme **kalıcı olarak boştu** ve test bunu
    /// göremiyordu. Cihazda bulundu (28 Temmuz 2026).
    testWidgets('ilgi alanı varsa eşleşen kayıtlara süzülür', (tester) async {
      // `yapay-zeka` anahtarları arasında `llm` var; test feed'inde yalnız
      // AI modeli kaydının konusu `llm`.
      await _pumpFeed(tester, interests: const ['yapay-zeka']);

      expect(find.text('ornek/model'), findsOneWidget);
      expect(_feedItems, findsOneWidget);
    });

    testWidgets('eşleşme yoksa yönlendirici bir boş durum çıkar', (
      tester,
    ) async {
      // Geçerli bir ilgi alanı, ama bu feed'de oyunla ilgili kayıt yok.
      await _pumpFeed(tester, interests: const ['oyun']);

      expect(_feedItems, findsNothing);
      // Yönlendirme **Keşfet'e**, Ayarlar'a değil: konu seçimi artık içerik
      // mağazasında ve alt gezinmeden tek dokunuş uzakta. Ayarlar → İlgi
      // Alanları hâlâ çalışıyor ama iki dokunuş.
      expect(find.textContaining('Keşfet\'ten'), findsOneWidget);
    });

    /// Tanınmayan kimlik yüzünden ekran boşalmaz: eski bir sürümden kalmış
    /// bir değer, kullanıcıyı boş bir açılış sekmesiyle karşılamamalı.
    testWidgets('tanınmayan kimlik akışı boşaltmaz', (tester) async {
      await _pumpFeed(tester, interests: const ['bilinmeyen-alan']);

      expect(_feedItems, findsNWidgets(3));
    });
  });

  /// "İçerik yok" ile "içerik okunamadı" farklı şeyler: boş feed bir boş
  /// durumdur, bozuk feed bir hatadır.
  testWidgets('boş feed hata değil, boş durum gösterir', (tester) async {
    await _pumpFeed(tester, feed: const []);

    expect(find.text('İçerik bulunamadı'), findsOneWidget);
    expect(find.byKey(const Key('feed-error')), findsNothing);
  });

  /// Bu ekran **hiç ölçülmemişti**: testler yalnız "hata görünmesin" diye
  /// bakıyordu. Riverpod 3 hatayı `AsyncLoading(error: …)` içinde taşıdığı
  /// için `AsyncError()` deseni hiç eşleşmiyordu ve bozuk bir feed sonsuza
  /// dek yükleme iskeleti gösteriyordu.
  testWidgets('bozuk feed hata durumu gösterir', (tester) async {
    await tester.pumpWidget(
      memoryDataScopeWithFailingFeed(
        MaterialApp(
          // Tema **verilmek zorunda**: ekranlar renkleri `AppPalette`
          // uzantısından okuyor ve uzantı yoksa `context.palette` atıyor.
          // Sessiz bir varsayılan, açık temada kırılan bir ekranı burada
          // görünmez kılardı.
          theme: AppTheme.dark,
          home: const Scaffold(body: FeedScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('feed-error')), findsOneWidget);
    expect(find.text('İçerik okunamadı'), findsOneWidget);
    expect(find.byKey(const Key('feed-loading')), findsNothing);
  });

  /// Regresyon kilidi.
  ///
  /// Bu test eskiden yalnız bir SnackBar arıyordu ve düğme gerçekten de
  /// yalnız SnackBar gösteriyordu: "Kaydetme yalnız yerel fixture
  /// etkileşimidir." Yani kullanıcı hiçbir şeyi kaydedemiyordu ve test bunu
  /// **doğruluyordu**. Artık depoya bakılıyor.
  testWidgets('kaydetme düğmesi kaydı gerçekten yazar', (tester) async {
    final saved = InMemorySavedItemsRepository(const []);
    await tester.pumpWidget(
      memoryDataHarness(
        const Scaffold(body: FeedScreen()),
        savedRepository: saved,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('feed-bookmark-0000000000000001')));
    await tester.pumpAndSettle();

    final stored = await saved.readAll();
    expect(stored.map((item) => item.id), ['0000000000000001']);
    expect(stored.single.kind, 'repository');
    expect(stored.single.sourceLabel, 'GitHub');
  });

  /// Regresyon kilidi: akıştaki **her** karta dokunulabilmeli.
  ///
  /// `_openItem` bir tür `switch`'iydi; `announcement` ve `tool` dallarında
  /// yalnız "detay ekranı henüz uygulanmadı" yazıyordu. Ölçüldü
  /// (2026-07-28): üretilen 200 kaydın **146'sı** duyuru, yani akışın dörtte
  /// üçü kapalı kapıydı — üstelik detay ekranı tür bağımsız çalışıyordu.
  testWidgets('duyuru kartına dokunmak detay ekranını açar', (tester) async {
    final router = createRouter(initialLocation: '/home');
    addTearDown(router.dispose);
    // Duyuru üçüncü kart; varsayılan test yüzeyinde katlamanın altında kalıyor.
    await tester.binding.setSurfaceSize(const Size(390, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      memoryDataScope(
        MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bir duyuru'));
    await tester.pumpAndSettle();

    // Yol değil, **ekran** ölçülüyor. `StatefulShellRoute` içinden yapılan
    // imperatif `push` sonrası GoRouter hem `routeInformationProvider`'ı hem
    // `currentConfiguration`'ı dalın konumunda (`/home`) bırakıyor; yola
    // bakan bir beklenti burada ürünü değil GoRouter'ı ölçerdi.
    expect(find.text('Duyuru Detayı'), findsOneWidget);
    expect(find.text('Bir duyuru'), findsWidgets);
    expect(
      find.text('Bu içerik türü için detay ekranı henüz uygulanmadı.'),
      findsNothing,
    );
  });

  testWidgets('ikinci dokunuş kaydı geri alır', (tester) async {
    final saved = InMemorySavedItemsRepository(const []);
    await tester.pumpWidget(
      memoryDataHarness(
        const Scaffold(body: FeedScreen()),
        savedRepository: saved,
      ),
    );
    await tester.pumpAndSettle();

    final bookmark = find.byKey(const Key('feed-bookmark-0000000000000001'));
    await tester.tap(bookmark);
    await tester.pumpAndSettle();
    await tester.tap(bookmark);
    await tester.pumpAndSettle();

    expect(await saved.readAll(), isEmpty);
  });

  group('içerik güncelliği', () {
    /// Çalışmayacağı bilinen bir kontrol sahte bir işlev vaadidir: uzak adres
    /// yapılandırılmamışken aşağı çekme jesti hiçbir şey yapmazdı.
    testWidgets('ağ kapalıyken tazeleme kontrolü hiç çizilmez', (tester) async {
      await _pumpFeed(tester);

      expect(find.byKey(const Key('feed-refresh')), findsNothing);
      expect(find.byType(RefreshIndicator), findsNothing);
    });

    testWidgets('ağ kapalıyken durum satırı tarih vaat etmez', (tester) async {
      await _pumpFeed(tester);

      expect(find.text('İçerik uygulamayla birlikte geliyor'), findsOneWidget);
    });

    testWidgets('ağ açıkken tazeleme kontrolü çizilir', (tester) async {
      await _pumpFeed(
        tester,
        repository: FakeFeedRepository(testFeedItems(), remoteEnabled: true),
      );

      expect(find.byKey(const Key('feed-refresh')), findsOneWidget);
      expect(find.text('Henüz güncellenmedi'), findsOneWidget);
    });

    testWidgets('senkronize edilmiş içerikte son güncelleme yazar', (
      tester,
    ) async {
      await _pumpFeed(
        tester,
        repository: FakeFeedRepository(
          testFeedItems(),
          remoteEnabled: true,
          // Gerçek saat kullanıldığı için tam metin değil, biçim ölçülüyor;
          // ifadenin kendisi `feed_sync_label_test.dart` içinde kilitli.
          lastSync: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      );

      expect(find.byKey(const Key('feed-sync-status')), findsOneWidget);
      expect(find.textContaining('Son güncelleme:'), findsOneWidget);
    });

    /// Açılışta ağ beklenmez: içerik önce gelir, tazeleme ilk kareden sonra
    /// ve yalnız içerik bayatsa denenir.
    testWidgets('taze içerikte açılışta ağa çıkılmaz', (tester) async {
      final repository = FakeFeedRepository(
        testFeedItems(),
        remoteEnabled: true,
        lastSync: DateTime.now(),
      );
      await _pumpFeed(tester, repository: repository);

      expect(repository.refreshCount, 0);
    });

    testWidgets('bayat içerikte açılışta bir kez tazelenir', (tester) async {
      final repository = FakeFeedRepository(
        testFeedItems(),
        remoteEnabled: true,
        stale: true,
        syncOutcome: FeedSyncOutcome(
          status: FeedSyncStatus.refreshed,
          feed: testFeed(testFeedItems()),
          syncedAt: DateTime.now(),
        ),
      );
      await _pumpFeed(tester, repository: repository);

      expect(repository.refreshCount, 1);
    });

    /// Kontrolün çizilmesi yetmez — jestin gerçekten tazelemeye bağlı olması
    /// gerekir. `onRefresh` yanlış bağlansaydı ekranda her şey doğru görünür,
    /// aşağı çekmek hiçbir şey yapmazdı.
    testWidgets('aşağı çekmek tazelemeyi tetikler', (tester) async {
      final repository = FakeFeedRepository(
        testFeedItems(),
        remoteEnabled: true,
        // Bayat değil: sayılan tek çağrı jestin kendisi olsun.
        lastSync: DateTime.now(),
        syncOutcome: FeedSyncOutcome(
          status: FeedSyncStatus.refreshed,
          feed: testFeed(testFeedItems()),
          syncedAt: DateTime.now(),
        ),
      );
      await _pumpFeed(tester, repository: repository);
      expect(repository.refreshCount, 0);

      await tester.fling(
        find.byKey(const Key('feed-scroll')),
        const Offset(0, 400),
        1000,
      );
      await tester.pumpAndSettle();

      expect(repository.refreshCount, 1);
    });

    /// Ağ hatası içeriği kaybettirmez: liste yerinde kalır, yalnız durum
    /// satırı değişir.
    testWidgets('başarısız tazeleme listeyi boşaltmaz', (tester) async {
      final repository = FakeFeedRepository(
        testFeedItems(),
        remoteEnabled: true,
        stale: true,
        syncOutcome: const FeedSyncOutcome.failed('Bağlantı kurulamadı'),
      );
      await _pumpFeed(tester, repository: repository);

      expect(_feedItems, findsNWidgets(3));
      expect(find.textContaining('Güncellenemedi'), findsOneWidget);
      expect(find.byKey(const Key('feed-error')), findsNothing);
    });
  });
}
