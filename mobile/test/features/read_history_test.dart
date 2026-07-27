import 'package:flutter_test/flutter_test.dart';
import 'package:teknoakis/features/ai_model_detail/ai_model_detail_screen.dart';
import 'package:teknoakis/features/repository_detail/repository_detail_screen.dart';

import '../support/test_overrides.dart';

void main() {
  testWidgets('opening a repository detail records a read', (tester) async {
    final history = InMemoryReadHistoryRepository();

    await tester.pumpWidget(
      memoryDataHarness(
        const RepositoryDetailScreen(id: 'akis-motoru'),
        readHistory: history,
      ),
    );
    await tester.pumpAndSettle();

    expect(history.records, [(itemId: 'akis-motoru', kind: 'repository')]);
  });

  testWidgets('opening an AI model detail records a read', (tester) async {
    final history = InMemoryReadHistoryRepository();

    await tester.pumpWidget(
      memoryDataHarness(
        const AiModelDetailScreen(id: 'sentez-mini'),
        readHistory: history,
      ),
    );
    await tester.pumpAndSettle();

    expect(history.records, [(itemId: 'sentez-mini', kind: 'aiModel')]);
  });

  /// Router `:id` boş gelirse (bozuk derin bağlantı) geçmişe çöp satır
  /// yazılmamalı.
  testWidgets('an empty id records nothing', (tester) async {
    final history = InMemoryReadHistoryRepository();

    await tester.pumpWidget(
      memoryDataHarness(
        const RepositoryDetailScreen(id: ''),
        readHistory: history,
      ),
    );
    await tester.pumpAndSettle();

    expect(history.records, isEmpty);
  });
}
