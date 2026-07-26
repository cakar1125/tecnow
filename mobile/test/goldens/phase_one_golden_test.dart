import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:teknoakis/design_system/theme/app_theme.dart';
import 'package:teknoakis/features/ai_model_detail/ai_model_detail_screen.dart';
import 'package:teknoakis/features/feed/feed_screen.dart';
import 'package:teknoakis/features/repository_detail/repository_detail_screen.dart';

void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  testGoldens('GOLDEN Ana Sayfa 390x844', (tester) async {
    await tester.pumpWidgetBuilder(
      const FeedScreen(),
      wrapper: materialAppWrapper(theme: AppTheme.dark),
      surfaceSize: const Size(390, 844),
    );
    await screenMatchesGolden(tester, 'home_390x844');
  });

  testGoldens('GOLDEN Repository Detayı 390x844', (tester) async {
    await tester.pumpWidgetBuilder(
      const RepositoryDetailScreen(),
      wrapper: materialAppWrapper(theme: AppTheme.dark),
      surfaceSize: const Size(390, 844),
    );
    await screenMatchesGolden(tester, 'repository_detail_390x844');
  });

  testGoldens('GOLDEN AI Model Detayı 390x844', (tester) async {
    await tester.pumpWidgetBuilder(
      const AiModelDetailScreen(),
      wrapper: materialAppWrapper(theme: AppTheme.dark),
      surfaceSize: const Size(390, 844),
    );
    await screenMatchesGolden(tester, 'ai_model_detail_390x844');
  });
}
