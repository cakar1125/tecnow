import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teknoakis/data/feed/feed_repository.dart';
import 'package:teknoakis/data/feed/feed_schema.dart';
import 'package:teknoakis/design_system/components/app_components.dart';
import 'package:teknoakis/features/feed/feed_screen.dart';

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

Future<void> _selectTab(WidgetTester tester, HomeTab tab) async {
  await tester.tap(find.byKey(Key('feed-tab-${tab.name}-idle')));
  await tester.pumpAndSettle();
}

/// Sekme etiketleri kart rozetleriyle aynı metni taşıyabilir (örn. "GİTHUB"),
/// bu yüzden sekme beklentileri sekme şeridine daraltılır.
Finder _tab(String label) => find.descendant(
  of: find.byKey(const Key('feed-tab-scroll')),
  matching: find.text(label),
);

void main() {
  testWidgets('dört sekme de çizilir', (tester) async {
    await _pumpFeed(tester);

    expect(_tab('SANA ÖZEL'), findsOneWidget);
    expect(_tab('GÜNDEM'), findsOneWidget);
    expect(_tab('GİTHUB'), findsOneWidget);
    expect(_tab('AI MODELLERİ'), findsOneWidget);
  });

  group('paketlenmiş feed', () {
    testWidgets('kayıtlar akışta görünür', (tester) async {
      await _pumpFeed(tester);

      expect(find.text('ornek/depo'), findsOneWidget);
      expect(find.text('ornek/model'), findsOneWidget);
      expect(find.text('Bir duyuru'), findsOneWidget);
      expect(find.byType(FeedItemCard), findsNWidgets(3));
    });

    /// Gerçek içerik "ÖRNEK" diye işaretlenmez — o etiket orada yalan olur.
    testWidgets('gerçek içerik örnek diye işaretlenmez', (tester) async {
      await _pumpFeed(tester);
      expect(find.text('ÖRNEK'), findsNothing);
    });

    /// Politika: TeknoAkış özeti kaynağın kendi metninden görsel olarak
    /// ayrılır.
    testWidgets('TeknoAkış özeti ayrıca işaretlenir', (tester) async {
      await _pumpFeed(tester);
      expect(find.text('TEKNOAKIŞ ÖZETİ'), findsOneWidget);
    });

    /// Anahtarsız üretilen feed'de özetler kaynağın kendi dilinde kalıyor;
    /// kullanıcı bunu kartın üzerinde görmeli.
    testWidgets('Türkçe olmayan özet dil rozetiyle gösterilir', (tester) async {
      await _pumpFeed(tester);
      expect(find.text('EN'), findsNWidgets(2));
    });

    /// Kaynaklar "ne işe yarar" alanı vermiyor; boş bir başlık göstermek de
    /// bir şey vaat etmektir.
    testWidgets('olmayan açıklama bölümü hiç çizilmez', (tester) async {
      await _pumpFeed(tester);
      expect(find.text('NE İŞE YARAR?'), findsNothing);
    });
  });

  group('sekmeler', () {
    testWidgets('GÜNDEM yalnız duyuruları gösterir', (tester) async {
      await _pumpFeed(tester);
      await _selectTab(tester, HomeTab.gundem);

      expect(find.text('Bir duyuru'), findsOneWidget);
      expect(find.text('ornek/depo'), findsNothing);
    });

    testWidgets('AI MODELLERİ yalnız modelleri gösterir', (tester) async {
      await _pumpFeed(tester);
      await _selectTab(tester, HomeTab.aiModelleri);

      expect(find.text('ornek/model'), findsOneWidget);
      expect(find.byType(FeedItemCard), findsOneWidget);
    });

    testWidgets('GİTHUB kaynağa göre süzer, türe göre değil', (tester) async {
      await _pumpFeed(tester);
      await _selectTab(tester, HomeTab.github);

      expect(find.text('ornek/depo'), findsOneWidget);
      expect(
        find.text('ornek/model'),
        findsNothing,
        reason: 'Hugging Face kaydı GitHub sekmesine girmemeli',
      );
    });
  });

  group('SANA ÖZEL', () {
    /// Hiç ilgi alanı seçilmemişken boş bir sekme göstermek kullanıcıya bir
    /// şey anlatmaz, sadece bozuk görünür.
    testWidgets('ilgi alanı yoksa akışın tamamı gösterilir', (tester) async {
      await _pumpFeed(tester);
      expect(find.byType(FeedItemCard), findsNWidgets(3));
    });

    testWidgets('ilgi alanı varsa konu kesişimine süzülür', (tester) async {
      await _pumpFeed(tester, interests: const ['llm']);

      expect(find.text('ornek/model'), findsOneWidget);
      expect(find.byType(FeedItemCard), findsOneWidget);
    });

    testWidgets('kesişim boşsa yönlendirici bir boş durum çıkar', (
      tester,
    ) async {
      await _pumpFeed(tester, interests: const ['bulunmayan-konu']);

      expect(find.byType(FeedItemCard), findsNothing);
      expect(find.textContaining('ilgi alanlarını'), findsOneWidget);
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
        const MaterialApp(home: Scaffold(body: FeedScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('feed-error')), findsOneWidget);
    expect(find.text('İçerik okunamadı'), findsOneWidget);
    expect(find.byKey(const Key('feed-loading')), findsNothing);
  });

  testWidgets('kaydetme düğmesi yerel geri bildirim verir', (tester) async {
    await _pumpFeed(tester);

    await tester.tap(find.byKey(const Key('feed-bookmark-0000000000000001')));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
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

      expect(find.byType(FeedItemCard), findsNWidgets(3));
      expect(find.textContaining('Güncellenemedi'), findsOneWidget);
      expect(find.byKey(const Key('feed-error')), findsNothing);
    });
  });
}
