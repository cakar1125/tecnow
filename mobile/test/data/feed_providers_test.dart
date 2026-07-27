import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:teknoakis/data/feed/feed_schema.dart';
import 'package:teknoakis/data/feed/syncing_feed_repository.dart';
import 'package:teknoakis/data/providers.dart';

import '../support/test_overrides.dart';

/// Sağlayıcıları okumak için tek kullanımlık bir tüketici.
Future<WidgetRef> _ref(WidgetTester tester, {List<FeedItem>? feed}) async {
  late WidgetRef captured;
  await tester.pumpWidget(
    memoryDataScope(
      Consumer(
        builder: (context, ref, _) {
          captured = ref;
          // İzlemek şart: yalnız `read` edilen bir sağlayıcı hiç başlamaz ve
          // test sonsuza dek `AsyncLoading` görür.
          ref.watch(feedProvider);
          return const SizedBox.shrink();
        },
      ),
      feed: feed,
    ),
  );
  await tester.pumpAndSettle();
  return captured;
}

void main() {
  testWidgets('feedProvider görünür kayıtları verir', (tester) async {
    final ref = await _ref(tester);
    final items = ref.read(feedProvider).value!;

    expect(items, hasLength(3));
    expect(items.map((item) => item.id), [
      '0000000000000001',
      '0000000000000002',
      '0000000000000003',
    ]);
  });

  /// Politika düzeltmeyi kayıtla yönetiyor: geri çekilen içerik dosyada
  /// kalır ama kullanıcıya **gösterilmez**.
  testWidgets('geri çekilmiş kayıt akışa girmez', (tester) async {
    final ref = await _ref(
      tester,
      feed: [
        testFeedItem(
          id: '0000000000000008',
          kind: FeedItemKind.repository,
          title: 'duran kayıt',
        ),
        testFeedItem(
          id: '0000000000000009',
          kind: FeedItemKind.repository,
          title: 'geri çekilen',
          retractedAt: DateTime.utc(2026, 7, 26),
        ),
      ],
    );

    final items = ref.read(feedProvider).value!;
    expect(items.map((item) => item.title), ['duran kayıt']);
  });

  group('feedItemProvider', () {
    testWidgets('kimliğe göre kayıt bulur', (tester) async {
      final ref = await _ref(tester);
      final item = ref.read(feedItemProvider('0000000000000002'));

      expect(item, isNotNull);
      expect(item!.title, 'ornek/model');
    });

    /// Detay ekranı bilinmeyen bir kimlikle açılabilir (eski bir kayıt,
    /// elle girilen bir adres). Çökmek yerine `null` döner.
    testWidgets('bilinmeyen kimlik null döner', (tester) async {
      final ref = await _ref(tester);
      expect(ref.read(feedItemProvider('yok-boyle-bir-sey')), isNull);
    });

    testWidgets('feed okunamamışsa null döner', (tester) async {
      late WidgetRef captured;
      await tester.pumpWidget(
        memoryDataScopeWithFailingFeed(
          Consumer(
            builder: (context, ref, _) {
              captured = ref;
              ref.watch(feedProvider);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(captured.read(feedProvider).hasError, isTrue);
      expect(captured.read(feedItemProvider('0000000000000001')), isNull);
    });
  });

  /// Ekran testlerinin hepsi `feedRepositoryProvider`'ı sahte bir depoyla
  /// değiştiriyor; gerçek bağlantının kendisi hiçbir yerde ölçülmüyordu.
  /// Yanlış bağlanmış bir sağlayıcı ancak cihazda görünürdü.
  group('varsayılan bağlantı', () {
    ProviderContainer container() {
      final scope = ProviderContainer(
        overrides: [
          // Gerçek sqflite açılışı testte yapılmaz; önbellek veritabanını
          // yalnız okuma anında beklediği için hiç tamamlanmaması yeterli.
          databaseProvider.overrideWith((ref) => Completer<Database>().future),
        ],
      );
      addTearDown(scope.dispose);
      return scope;
    }

    test('depo paketlenmiş dosya + önbellek + ağ bileşimidir', () {
      expect(
        container().read(feedRepositoryProvider),
        isA<SyncingFeedRepository>(),
      );
    });

    /// `--dart-define=FEED_URL` verilmediği için varsayılan derlemede ağ
    /// tazelemesi **kapalı** olmalı.
    test('adres verilmediğinde tazeleme kapalıdır', () {
      final scope = container();

      expect(scope.read(feedEndpointProvider), isNull);
      expect(scope.read(feedRepositoryProvider).remoteEnabled, isFalse);
    });
  });

  testWidgets('reload aynı veriyi yeniden okur', (tester) async {
    final ref = await _ref(tester);
    await ref.read(feedProvider.notifier).reload();
    await tester.pumpAndSettle();

    expect(ref.read(feedProvider).value, hasLength(3));
  });
}
