import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecnow/data/feed/feed_repository.dart';
import 'package:tecnow/data/feed/feed_schema.dart';
import 'package:tecnow/data/feed/feed_sync_state.dart';
import 'package:tecnow/data/providers.dart';

import '../support/test_overrides.dart';

final _syncedAt = DateTime.utc(2026, 7, 27, 12);

Future<WidgetRef> _ref(WidgetTester tester, FeedRepository repository) async {
  late WidgetRef captured;
  await tester.pumpWidget(
    memoryDataScope(
      Consumer(
        builder: (context, ref, _) {
          captured = ref;
          // İzlemek şart: yalnız `read` edilen bir sağlayıcı hiç başlamaz.
          ref.watch(feedProvider);
          ref.watch(feedSyncProvider);
          return const SizedBox.shrink();
        },
      ),
      feedRepository: repository,
    ),
  );
  await tester.pumpAndSettle();
  return captured;
}

FeedSyncState _state(WidgetRef ref) => ref.read(feedSyncProvider).value!;

FeedSyncOutcome _success(List<FeedItem> items) => FeedSyncOutcome(
  status: FeedSyncStatus.refreshed,
  feed: testFeed(items),
  syncedAt: _syncedAt,
);

void main() {
  testWidgets('başlangıç durumu depodan okunur', (tester) async {
    final ref = await _ref(
      tester,
      FakeFeedRepository(
        testFeedItems(),
        remoteEnabled: true,
        lastSync: _syncedAt,
      ),
    );

    expect(_state(ref).remoteEnabled, isTrue);
    expect(_state(ref).lastSyncAt, _syncedAt);
    expect(_state(ref).refreshing, isFalse);
  });

  testWidgets('başarılı tazeleme listeyi ve zamanı günceller', (tester) async {
    final repository = FakeFeedRepository(
      testFeedItems(),
      remoteEnabled: true,
      syncOutcome: _success([
        testFeedItem(
          id: '00000000000000cc',
          kind: FeedItemKind.repository,
          title: 'Yeni kayıt',
        ),
      ]),
    );
    final ref = await _ref(tester, repository);

    await ref.read(feedSyncProvider.notifier).refresh();
    await tester.pumpAndSettle();

    expect(_state(ref).lastSyncAt, _syncedAt);
    expect(_state(ref).failure, isNull);
    expect(ref.read(feedProvider).value!.single.title, 'Yeni kayıt');
  });

  /// Ağ hatası içeriği kaybettirmez: gösterilen liste aynen kalır, yalnız
  /// durum satırı değişir.
  testWidgets('başarısız tazeleme listeyi bozmaz', (tester) async {
    final repository = FakeFeedRepository(
      testFeedItems(),
      remoteEnabled: true,
      lastSync: _syncedAt,
      syncOutcome: const FeedSyncOutcome.failed('Bağlantı kurulamadı'),
    );
    final ref = await _ref(tester, repository);

    await ref.read(feedSyncProvider.notifier).refresh();
    await tester.pumpAndSettle();

    expect(_state(ref).failure, 'Bağlantı kurulamadı');
    expect(_state(ref).lastSyncAt, _syncedAt, reason: 'eski zaman korunmalı');
    expect(ref.read(feedProvider).value, hasLength(3));
  });

  /// Başarıdan sonra eski hata cümlesi ekranda kalmamalı: düzelmiş bir durumu
  /// bozuk göstermek olurdu.
  testWidgets('başarı önceki hatayı temizler', (tester) async {
    final repository = FakeFeedRepository(
      testFeedItems(),
      remoteEnabled: true,
      syncOutcome: const FeedSyncOutcome.failed('Bağlantı kurulamadı'),
    );
    final ref = await _ref(tester, repository);
    final notifier = ref.read(feedSyncProvider.notifier);

    await notifier.refresh();
    await tester.pumpAndSettle();
    expect(_state(ref).failure, 'Bağlantı kurulamadı');

    repository.syncOutcome = _success(testFeedItems());
    await notifier.refresh();
    await tester.pumpAndSettle();

    expect(_state(ref).failure, isNull);
    expect(_state(ref).lastSyncAt, _syncedAt);
  });

  group('refreshIfStale', () {
    testWidgets('içerik tazeyse ağa çıkılmaz', (tester) async {
      final repository = FakeFeedRepository(
        testFeedItems(),
        remoteEnabled: true,
        lastSync: _syncedAt,
      );
      final ref = await _ref(tester, repository);

      await ref.read(feedSyncProvider.notifier).refreshIfStale();
      await tester.pumpAndSettle();

      expect(repository.refreshCount, 0);
    });

    testWidgets('içerik bayatsa bir kez denenir', (tester) async {
      final repository = FakeFeedRepository(
        testFeedItems(),
        remoteEnabled: true,
        stale: true,
        syncOutcome: _success(testFeedItems()),
      );
      final ref = await _ref(tester, repository);

      await ref.read(feedSyncProvider.notifier).refreshIfStale();
      await tester.pumpAndSettle();

      expect(repository.refreshCount, 1);
    });

    /// Kullanıcı aşağı çekerken açılış denemesi de tetiklenebilir; aynı dosya
    /// iki kez indirilmemeli.
    testWidgets('eşzamanlı iki istek tek çağrı yapar', (tester) async {
      final repository = FakeFeedRepository(
        testFeedItems(),
        remoteEnabled: true,
        stale: true,
        syncOutcome: _success(testFeedItems()),
      );
      final ref = await _ref(tester, repository);
      final notifier = ref.read(feedSyncProvider.notifier);

      await Future.wait([notifier.refresh(), notifier.refresh()]);
      await tester.pumpAndSettle();

      expect(repository.refreshCount, 1);
    });
  });

  /// Ağ kapalıyken tazeleme hiç denenmez.
  testWidgets('uzak adres yokken tazeleme ağa çıkmaz', (tester) async {
    final repository = FakeFeedRepository(testFeedItems());
    final ref = await _ref(tester, repository);

    await ref.read(feedSyncProvider.notifier).refreshIfStale();
    await tester.pumpAndSettle();

    expect(repository.refreshCount, 0);
    expect(_state(ref).remoteEnabled, isFalse);
  });
}
