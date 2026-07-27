import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:teknoakis/design_system/theme/app_theme.dart';
import 'package:teknoakis/features/detail/feed_detail_screen.dart';
import 'package:teknoakis/features/feed/feed_screen.dart';

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

  /// Detay ekranları da artık gerçek kaydı gösteriyor; golden sabit test
  /// verisiyle çekiliyor. Önceki hâlleri `id`'yi hiç okumadan bir fixture
  /// çiziyordu, bu yüzden hangi kimlikle pump edildikleri önemsizdi.
  testGoldens('GOLDEN Repository Detayı 390x844', (tester) async {
    await tester.pumpWidgetBuilder(
      memoryDataScope(const RepositoryDetailScreen(id: '0000000000000001')),
      wrapper: materialAppWrapper(theme: AppTheme.dark),
      surfaceSize: const Size(390, 844),
    );
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'repository_detail_390x844');
  });

  testGoldens('GOLDEN AI Model Detayı 390x844', (tester) async {
    await tester.pumpWidgetBuilder(
      memoryDataScope(const AiModelDetailScreen(id: '0000000000000002')),
      wrapper: materialAppWrapper(theme: AppTheme.dark),
      surfaceSize: const Size(390, 844),
    );
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'ai_model_detail_390x844');
  });
}
