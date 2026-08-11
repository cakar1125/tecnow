import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tecos/app/router.dart';
import 'package:tecos/data/feed/feed_schema.dart';
import 'package:tecos/data/repositories/read_history_repository.dart';
import 'package:tecos/design_system/theme/app_theme.dart';
import 'package:tecos/features/read_history/read_history_screen.dart';

import '../support/test_overrides.dart';

Future<void> pumpHistoryScreen(
  WidgetTester tester, {
  required ReadHistoryRepository history,
  List<FeedItem>? feed,
}) async {
  final router = createRouter(initialLocation: readHistoryRoute);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    memoryDataScope(
      MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
      readHistory: history,
      feed: feed,
    ),
  );
  await tester.pumpAndSettle();
}

/// Geçmiş satırı yazan bir depo kurar.
InMemoryReadHistoryRepository historyWith(
  List<({String itemId, String? kind})> records,
) {
  final repository = InMemoryReadHistoryRepository();
  repository.records.addAll(records);
  return repository;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('empty history explains what will appear here', (tester) async {
    await pumpHistoryScreen(tester, history: InMemoryReadHistoryRepository());

    expect(find.byKey(const Key('read-history-empty')), findsOneWidget);
    expect(find.text('Henüz içerik okumadın'), findsOneWidget);
  });

  testWidgets('read records are listed with their real titles', (tester) async {
    await pumpHistoryScreen(
      tester,
      history: historyWith([
        (itemId: '0000000000000001', kind: 'repository'),
        (itemId: '0000000000000003', kind: 'announcement'),
      ]),
    );

    expect(find.text('ornek/depo'), findsOneWidget);
    expect(find.text('Bir duyuru'), findsOneWidget);
    // Başlık kaydın türünden geliyor, rotadan değil.
    expect(find.text('Repository Detayı'), findsOneWidget);
    expect(find.text('Duyuru Detayı'), findsOneWidget);
  });

  /// Akıştan kalkmış bir kayıt **gizlenmez**.
  ///
  /// Gizlemek görsel olarak daha temiz olurdu ve yeni bir yalan üretirdi:
  /// Ayarlar "2 kayıt" derken liste tek satır gösterir, iki ekran birbiriyle
  /// çelişirdi. Test hem satırın durduğunu hem de gidilecek bir yer varmış
  /// gibi görünmediğini ölçer.
  testWidgets('a record that left the feed still occupies a row', (
    tester,
  ) async {
    await pumpHistoryScreen(
      tester,
      history: historyWith([
        (itemId: '0000000000000001', kind: 'repository'),
        (itemId: 'artik-akista-olmayan', kind: 'skill'),
      ]),
    );

    expect(find.text('Akıştan kaldırılmış içerik'), findsOneWidget);
    expect(find.text('Bu kayıt artık akışta yok.'), findsOneWidget);

    // Yalnız çözülen satırın oku var.
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
  });

  testWidgets('tapping a resolved row opens that record', (tester) async {
    await pumpHistoryScreen(
      tester,
      history: historyWith([
        (itemId: '0000000000000003', kind: 'announcement'),
      ]),
    );

    await tester.tap(find.text('Bir duyuru'));
    await tester.pumpAndSettle();

    // Rota yolu yerine **ekran** ölçülüyor: bir kabuk dalından yapılan
    // `push` sonrasında GoRouter'ın bildirdiği yol dalın konumunda kalıyor,
    // yani yol iddiası ürünü değil yönlendiriciyi ölçerdi.
    expect(find.text('Duyuru Detayı'), findsOneWidget);
    expect(find.byKey(const Key('detail-missing')), findsNothing);
  });

  /// Silme **depoya** ulaşmalı. Yalnız listeyi boşaltmak, uygulama yeniden
  /// açıldığında geçmişin geri gelmesi demekti — sahte kaydet düğmesinin
  /// aynısı.
  testWidgets('clearing history really empties the repository', (tester) async {
    final history = historyWith([
      (itemId: '0000000000000001', kind: 'repository'),
    ]);
    await pumpHistoryScreen(tester, history: history);

    await tester.tap(find.byTooltip('Geçmişi temizle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Onayla'));
    await tester.pumpAndSettle();

    expect(await history.readRecent(), isEmpty);
    expect(find.byKey(const Key('read-history-empty')), findsOneWidget);
  });

  testWidgets('cancelling the clear dialog keeps the history', (tester) async {
    final history = historyWith([
      (itemId: '0000000000000001', kind: 'repository'),
    ]);
    await pumpHistoryScreen(tester, history: history);

    await tester.tap(find.byTooltip('Geçmişi temizle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();

    expect(await history.readRecent(), hasLength(1));
    expect(find.text('ornek/depo'), findsOneWidget);
  });

  /// Boş geçmişte silinecek bir şey yok; düğme de olmamalı.
  testWidgets('the clear button is absent when there is nothing to clear', (
    tester,
  ) async {
    await pumpHistoryScreen(tester, history: InMemoryReadHistoryRepository());

    expect(find.byTooltip('Geçmişi temizle'), findsNothing);
  });

  group('buildReadHistoryRows', () {
    test('preserves order and marks unresolved entries', () {
      final rows = buildReadHistoryRows([
        ReadHistoryEntry(
          id: 1,
          itemId: '0000000000000001',
          kind: 'repository',
          readAt: DateTime(2026, 7, 28),
        ),
        ReadHistoryEntry(
          id: 2,
          itemId: 'yok',
          kind: 'skill',
          readAt: DateTime(2026, 7, 27),
        ),
      ], testFeedItems());

      expect(rows, hasLength(2));
      expect(rows.first.resolved, isTrue);
      expect(rows.first.item!.title, 'ornek/depo');
      expect(rows.last.resolved, isFalse);
      // Tür, kayıt akıştan kalksa bile geçmişte saklandığı için biliniyor.
      expect(rows.last.kind, FeedItemKind.skill);
    });

    test('every entry produces exactly one row', () {
      final entries = [
        for (var index = 0; index < 5; index++)
          ReadHistoryEntry(
            id: index,
            itemId: 'bilinmeyen-$index',
            kind: null,
            readAt: DateTime(2026, 7, 28),
          ),
      ];

      // Ayarlar'daki adet liste uzunluğuyla aynı kalmalı.
      expect(buildReadHistoryRows(entries, testFeedItems()), hasLength(5));
    });
  });
}
