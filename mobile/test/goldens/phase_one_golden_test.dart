import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:teknoakis/design_system/theme/app_theme.dart';
import 'package:teknoakis/features/ai_model_detail/ai_model_detail_screen.dart';
import 'package:teknoakis/features/feed/feed_screen.dart';
import 'package:teknoakis/features/repository_detail/repository_detail_screen.dart';

import '../support/test_overrides.dart';

void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  /// Ana Sayfa artık paketlenmiş feed'i okuyor. Golden **sabit** veriyle
  /// çekilir: gerçek `assets/feed/feed.json` her üretici koşusunda değişir ve
  /// golden her koşuda kırılırdı — o da onu bir kilit olmaktan çıkarırdı.
  testGoldens('GOLDEN Ana Sayfa 390x844', (tester) async {
    await tester.pumpWidgetBuilder(
      memoryDataScope(const FeedScreen()),
      wrapper: materialAppWrapper(theme: AppTheme.dark),
      surfaceSize: const Size(390, 844),
    );
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'home_390x844');
  });

  testGoldens('GOLDEN Repository Detayı 390x844', (tester) async {
    await tester.pumpWidgetBuilder(
      // Detay ekranları artık okuma geçmişi yazdığı için `ProviderScope`
      // gerekiyor. Görsel çıktı değişmez; kayıt başarısız olursa sessiz kalır.
      const ProviderScope(child: RepositoryDetailScreen(id: 'golden')),
      wrapper: materialAppWrapper(theme: AppTheme.dark),
      surfaceSize: const Size(390, 844),
    );
    await screenMatchesGolden(tester, 'repository_detail_390x844');
  });

  testGoldens('GOLDEN AI Model Detayı 390x844', (tester) async {
    await tester.pumpWidgetBuilder(
      const ProviderScope(child: AiModelDetailScreen(id: 'golden')),
      wrapper: materialAppWrapper(theme: AppTheme.dark),
      surfaceSize: const Size(390, 844),
    );
    await screenMatchesGolden(tester, 'ai_model_detail_390x844');
  });
}
