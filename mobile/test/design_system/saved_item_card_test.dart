import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecos/design_system/tokens/app_palette.dart';
import 'package:tecos/data/feed/feed_schema.dart';
import 'package:tecos/design_system/components/app_components.dart';
import 'package:tecos/ui/content_card_model.dart';

import '../test_harness.dart';

ContentCardModel _card({
  FeedItemKind kind = FeedItemKind.repository,
  bool isSample = true,
}) => isSample
    ? ContentCardModel.sample(
        id: 'a',
        kind: kind,
        title: 'Bir kayıt',
        sourceLabel: 'GitHub',
        summary: 'Bir açıklama.',
      )
    : ContentCardModel(
        id: 'a',
        kind: kind,
        title: 'Bir kayıt',
        sourceLabel: 'GitHub',
        summary: 'Bir açıklama.',
      );

void main() {
  testWidgets('renders the correct label and color for every content kind', (
    tester,
  ) async {
    // `const` değil: renkler artık paletten okunuyor ve bir sabit ifadede
    // nesne alanına erişilemiyor. Bedeli yok — harita test içinde bir kez
    // kuruluyor.
    final expectations = {
      FeedItemKind.repository: (
        'DEPO',
        AppPalette.dark.primary,
        Icons.code_rounded,
      ),
      FeedItemKind.aiModel: (
        'AI MODEL',
        AppPalette.dark.aiAccent,
        Icons.psychology_outlined,
      ),
      FeedItemKind.tool: (
        'ARAÇ',
        AppPalette.dark.warning,
        Icons.build_outlined,
      ),
      FeedItemKind.skill: (
        'SKILL',
        AppPalette.dark.success,
        Icons.school_outlined,
      ),
      FeedItemKind.mcp: ('MCP', AppPalette.dark.primary, Icons.hub_outlined),
      FeedItemKind.announcement: (
        'DUYURU',
        AppPalette.dark.success,
        Icons.campaign_outlined,
      ),
    };

    // Her tür kapsanmalı: yeni bir tür eklenip rozeti unutulursa burada
    // görünsün.
    expect(expectations.keys.toSet(), FeedItemKind.values.toSet());

    for (final entry in expectations.entries) {
      final (label, color, icon) = entry.value;

      await tester.pumpWidget(
        testHarness(
          SavedItemCard(
            item: _card(kind: entry.key),
            onRemove: () {},
            onOpenDetails: () {},
          ),
        ),
      );

      expect(find.text(label), findsOneWidget);
      final categoryIcon = tester.widget<Icon>(find.byIcon(icon));
      expect(categoryIcon.color, color);
    }
  });

  group('örnek işareti', () {
    /// `CLAUDE.md`: kurgusal veri gerçek gibi sunulmaz.
    testWidgets('fixture kaydı görünür biçimde işaretlenir', (tester) async {
      await tester.pumpWidget(
        testHarness(
          SavedItemCard(item: _card(), onRemove: () {}, onOpenDetails: () {}),
        ),
      );
      expect(find.text('Örnek kayıt'), findsOneWidget);
    });

    /// Ters yön de yanlış: kullanıcının gerçekten kaydettiği bir içeriğe
    /// "örnek" demek onu değersizleştirir ve yanlış bilgi verir.
    testWidgets('gerçek kayıt örnek diye işaretlenmez', (tester) async {
      await tester.pumpWidget(
        testHarness(
          SavedItemCard(
            item: _card(isSample: false),
            onRemove: () {},
            onOpenDetails: () {},
          ),
        ),
      );
      expect(find.text('Örnek kayıt'), findsNothing);
    });
  });

  testWidgets('renders both actions and invokes their callbacks', (
    tester,
  ) async {
    var removeCalls = 0;
    var detailCalls = 0;

    await tester.pumpWidget(
      testHarness(
        SavedItemCard(
          item: _card(),
          onRemove: () => removeCalls++,
          onOpenDetails: () => detailCalls++,
        ),
      ),
    );

    expect(find.text('Kaydı Kaldır'), findsOneWidget);
    expect(find.text('Detaya Git'), findsOneWidget);

    await tester.tap(find.text('Kaydı Kaldır'));
    await tester.tap(find.text('Detaya Git'));
    await tester.pump();

    expect(removeCalls, 1);
    expect(detailCalls, 1);
  });
}
