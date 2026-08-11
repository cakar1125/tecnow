import 'package:flutter_test/flutter_test.dart';
import 'package:tecos/features/detail/feed_detail_screen.dart';

import '../support/test_overrides.dart';

/// Okuma geçmişi.
///
/// Tür artık **rotadan** değil kaydın kendisinden okunuyor. Önceden
/// `/repository/:id` ile açılan her şey geçmişe `repository` yazıyordu; bir
/// skill ya da MCP kaydı açıldığında geçmişte yanlış tür duruyordu.
void main() {
  testWidgets('açılan kaydın türü geçmişe kaydın kendisinden yazılır', (
    tester,
  ) async {
    final history = InMemoryReadHistoryRepository();

    await tester.pumpWidget(
      memoryDataHarness(
        const FeedDetailScreen(id: '0000000000000001'),
        readHistory: history,
      ),
    );
    await tester.pumpAndSettle();

    expect(history.records, [(itemId: '0000000000000001', kind: 'repository')]);
  });

  testWidgets('AI modeli aiModel olarak kaydedilir', (tester) async {
    final history = InMemoryReadHistoryRepository();

    await tester.pumpWidget(
      memoryDataHarness(
        const FeedDetailScreen(id: '0000000000000002'),
        readHistory: history,
      ),
    );
    await tester.pumpAndSettle();

    expect(history.records, [(itemId: '0000000000000002', kind: 'aiModel')]);
  });

  /// Router `:id` boş gelirse (bozuk derin bağlantı) geçmişe çöp satır
  /// yazılmamalı.
  testWidgets('boş kimlik hiçbir şey kaydetmez', (tester) async {
    final history = InMemoryReadHistoryRepository();

    await tester.pumpWidget(
      memoryDataHarness(const FeedDetailScreen(id: ''), readHistory: history),
    );
    await tester.pumpAndSettle();

    expect(history.records, isEmpty);
  });

  /// Akışta olmayan bir kimlik de yazılmaz: geçmişte var olmayan bir
  /// içeriğin satırı hiçbir işe yaramaz ve listeyi kirletir.
  testWidgets('bulunamayan kayıt geçmişe yazılmaz', (tester) async {
    final history = InMemoryReadHistoryRepository();

    await tester.pumpWidget(
      memoryDataHarness(
        const FeedDetailScreen(id: 'yok-boyle-kayit'),
        readHistory: history,
      ),
    );
    await tester.pumpAndSettle();

    expect(history.records, isEmpty);
  });

  /// Ekran feed tazelenirken yeniden çizilir; her çizimde bir satır yazmak
  /// geçmişi şişirirdi.
  testWidgets('yeniden çizim ikinci satır yazmaz', (tester) async {
    final history = InMemoryReadHistoryRepository();

    await tester.pumpWidget(
      memoryDataHarness(
        const FeedDetailScreen(id: '0000000000000001'),
        readHistory: history,
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(history.records, hasLength(1));
  });
}
