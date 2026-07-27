import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teknoakis/data/feed/feed_schema.dart';
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

  testWidgets('reload aynı veriyi yeniden okur', (tester) async {
    final ref = await _ref(tester);
    await ref.read(feedProvider.notifier).reload();
    await tester.pumpAndSettle();

    expect(ref.read(feedProvider).value, hasLength(3));
  });
}
