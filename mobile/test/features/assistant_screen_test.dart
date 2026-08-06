import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecnow/features/assistant/assistant_screen.dart';

import '../test_harness.dart';

const _suggestions = <String>[
  'Bir uygulama fikrim var',
  'Hangi AI\'ı kullanmalıyım?',
  'Bir skill veya MCP arıyorum',
  'İki aracı karşılaştır',
  'Mevcut projemi analiz et',
  'Öğrenme yol haritası oluştur',
];

Widget assistantScreenHarness() =>
    testHarness(const Scaffold(body: SafeArea(child: AssistantScreen())));

FilledButton startButton(WidgetTester tester) => tester.widget<FilledButton>(
  find.widgetWithText(FilledButton, 'Başlayalım'),
);

void main() {
  testWidgets('renders all six assistant starter suggestions', (tester) async {
    await tester.pumpWidget(assistantScreenHarness());

    for (final suggestion in _suggestions) {
      expect(find.text(suggestion), findsOneWidget);
    }
  });

  testWidgets('tapping a starter suggestion fills the prompt', (tester) async {
    await tester.pumpWidget(assistantScreenHarness());

    await tester.tap(find.text(_suggestions.first));
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      _suggestions.first,
    );
  });

  testWidgets('start button is disabled while the prompt is empty', (
    tester,
  ) async {
    await tester.pumpWidget(assistantScreenHarness());

    expect(startButton(tester).onPressed, null);
  });

  testWidgets('start action only shows the phase notice and preserves input', (
    tester,
  ) async {
    await tester.pumpWidget(assistantScreenHarness());
    const prompt = 'Yerel çalışan bir not uygulaması yapmak istiyorum.';

    await tester.enterText(find.byType(TextField), prompt);
    await tester.pump();
    expect(startButton(tester).onPressed == null, false);

    await tester.ensureVisible(find.text('Başlayalım'));
    await tester.pumpAndSettle();
    final textCountBeforeAction = find.byType(Text).evaluate().length;
    await tester.tap(find.text('Başlayalım'));
    await tester.pump();

    expect(
      find.text(
        'Proje Asistanı Faz 4\'te uygulanacak. '
        'Şu an hiçbir AI servisine bağlanılmıyor.',
      ),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.byType(Text).evaluate().length, textCountBeforeAction + 1);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      prompt,
    );
  });

  testWidgets('shows the explicit assistant phase warning', (tester) async {
    await tester.pumpWidget(assistantScreenHarness());

    expect(
      find.text(
        'Asistan henüz uygulanmadı. Bu ekran yalnız giriş tasarımıdır.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('does not expose attachment or microphone controls', (
    tester,
  ) async {
    await tester.pumpWidget(assistantScreenHarness());

    expect(find.byIcon(Icons.attach_file), findsNothing);
    expect(find.byIcon(Icons.mic), findsNothing);
    expect(find.byIcon(Icons.mic_none), findsNothing);
  });
}
