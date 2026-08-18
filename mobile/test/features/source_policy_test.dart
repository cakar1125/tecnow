import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test_harness.dart';
import 'package:tecos/app/router.dart';
import 'package:tecos/data/feed/feed_schema.dart';
import 'package:tecos/features/settings/source_policy_screen.dart';

import '../support/test_overrides.dart';

Future<void> pumpPolicyScreen(
  WidgetTester tester, {
  List<FeedItem>? feed,
  bool failing = false,
}) async {
  final router = createRouter(initialLocation: sourcePolicyRoute);
  addTearDown(router.dispose);

  final app = testRouterApp(router);
  await tester.pumpWidget(
    failing
        ? memoryDataScopeWithFailingFeed(app)
        : memoryDataScope(app, feed: feed),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the policy rules are stated', (tester) async {
    await pumpPolicyScreen(tester);

    expect(find.text('Kapalı liste'), findsOneWidget);
    expect(find.text('Önce birincil kaynak'), findsOneWidget);
    expect(find.text('Tarih uydurulmaz'), findsOneWidget);
    expect(find.text('Kullanıcı içeriği yok'), findsOneWidget);
  });

  /// Listenin **feed'den** geldiğini ölçer.
  ///
  /// Kaynak adları ekrana elle yazılsaydı bu test, gerçek kaynaklar değişse
  /// bile geçmeye devam ederdi. Burada besleme değiştiriliyor ve ekranın
  /// onu takip etmesi bekleniyor.
  testWidgets('the source list comes from the loaded feed', (tester) async {
    await pumpPolicyScreen(
      tester,
      feed: [
        testFeedItem(
          id: '0000000000000001',
          kind: FeedItemKind.announcement,
          title: 'a',
          sourceName: 'Uydurulmuş Gazete',
          sourceKind: FeedSourceKind.officialBlog,
        ),
      ],
    );

    expect(find.text('Uydurulmuş Gazete'), findsOneWidget);
    expect(find.text('1 içerik'), findsOneWidget);
    // Varsayılan test feed'inin kaynakları görünmemeli.
    expect(find.text('Hugging Face'), findsNothing);
  });

  testWidgets('sources are counted, not just listed', (tester) async {
    await pumpPolicyScreen(
      tester,
      feed: [
        testFeedItem(
          id: '0000000000000001',
          kind: FeedItemKind.repository,
          title: 'a',
        ),
        testFeedItem(
          id: '0000000000000002',
          kind: FeedItemKind.repository,
          title: 'b',
        ),
      ],
    );

    expect(find.text('2 içerik'), findsOneWidget);
  });

  testWidgets('a broken feed says so instead of claiming zero sources', (
    tester,
  ) async {
    await pumpPolicyScreen(tester, failing: true);

    expect(find.byKey(const Key('source-policy-error')), findsOneWidget);
    expect(find.byKey(const Key('source-policy-list')), findsNothing);
  });

  group('sourcesInFeed', () {
    test('groups by source name and counts records', () {
      final usages = sourcesInFeed([
        testFeedItem(
          id: '1',
          kind: FeedItemKind.repository,
          title: 'a',
          sourceName: 'GitHub',
        ),
        testFeedItem(
          id: '2',
          kind: FeedItemKind.repository,
          title: 'b',
          sourceName: 'GitHub',
        ),
        testFeedItem(
          id: '3',
          kind: FeedItemKind.aiModel,
          title: 'c',
          sourceName: 'Hugging Face',
          sourceKind: FeedSourceKind.huggingFace,
        ),
      ]);

      expect(usages.map((u) => u.name), ['GitHub', 'Hugging Face']);
      expect(usages.first.itemCount, 2);
      expect(usages.last.kind, FeedSourceKind.huggingFace);
    });

    /// Eşit sayıda kayıt veren iki kaynak her çağrıda aynı sırada gelmeli;
    /// yoksa liste ekran her yeniden çizildiğinde yerinden oynardı.
    test('ties break by name so the order is stable', () {
      final feed = [
        testFeedItem(
          id: '1',
          kind: FeedItemKind.announcement,
          title: 'a',
          sourceName: 'Zeta',
        ),
        testFeedItem(
          id: '2',
          kind: FeedItemKind.announcement,
          title: 'b',
          sourceName: 'Alfa',
        ),
      ];

      expect(sourcesInFeed(feed).map((u) => u.name), ['Alfa', 'Zeta']);
      expect(sourcesInFeed(feed.reversed.toList()).map((u) => u.name), [
        'Alfa',
        'Zeta',
      ]);
    });

    test('an empty feed yields no sources', () {
      expect(sourcesInFeed(const []), isEmpty);
    });
  });

  /// Cihazda görüldü: platform kaynaklarında ad ile tür etiketi aynı olduğu
  /// için satır "Hugging Face" başlığının altına yine "Hugging Face" yazıyordu.
  group('sourceKindSubtitle', () {
    test('is dropped when it only repeats the source name', () {
      expect(
        sourceKindSubtitle(
          const SourceUsage(
            name: 'Hugging Face',
            kind: FeedSourceKind.huggingFace,
            itemCount: 20,
          ),
        ),
        isNull,
      );
    });

    test('is kept when it adds something the name does not say', () {
      expect(
        sourceKindSubtitle(
          const SourceUsage(
            name: 'NVIDIA Geliştirici',
            kind: FeedSourceKind.officialBlog,
            itemCount: 12,
          ),
        ),
        'Resmi bloglar',
      );
    });
  });

  testWidgets('a platform source is not labelled with its own name twice', (
    tester,
  ) async {
    await pumpPolicyScreen(
      tester,
      feed: [
        testFeedItem(
          id: '0000000000000001',
          kind: FeedItemKind.aiModel,
          title: 'a',
          sourceName: 'Hugging Face',
          sourceKind: FeedSourceKind.huggingFace,
        ),
      ],
    );

    expect(find.text('Hugging Face'), findsOneWidget);
  });
}
