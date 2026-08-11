import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:tecos/design_system/theme/app_theme.dart';
import 'package:tecos/features/detail/feed_detail_screen.dart';
import 'package:tecos/features/feed/feed_screen.dart';

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
      memoryDataScope(const FeedDetailScreen(id: '0000000000000001')),
      wrapper: materialAppWrapper(theme: AppTheme.dark),
      surfaceSize: const Size(390, 844),
    );
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'repository_detail_390x844');
  });

  testGoldens('GOLDEN AI Model Detayı 390x844', (tester) async {
    await tester.pumpWidgetBuilder(
      memoryDataScope(const FeedDetailScreen(id: '0000000000000002')),
      wrapper: materialAppWrapper(theme: AppTheme.dark),
      surfaceSize: const Size(390, 844),
    );
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'ai_model_detail_390x844');
  });

  /// Açık temanın **kendi** görsel kilidi.
  ///
  /// Buradaki golden'ların hepsi koyu temada çekiliyordu; açık tema 2026-08-11'de
  /// eklendiğinde tek bir görsel kapı bile onu görmüyordu. Bu tehlikeli: bir
  /// ekran koyu temada kusursuz görünüp açık temada beyaz zemine beyaz metin
  /// yazabilir ve hiçbir test kırılmaz.
  ///
  /// Kontrast kapısı (`palette_contrast_test.dart`) renklerin **birbirine
  /// göre** doğru olduğunu ölçüyor; bu golden'lar renklerin **doğru yerde**
  /// kullanıldığını ölçüyor. İkisi farklı sorular: palet kusursuz olabilir
  /// ama bir widget yine de sabit bir renk taşıyor olabilir.
  group('açık tema', () {
    testGoldens('GOLDEN Ana Sayfa açık 390x844', (tester) async {
      await tester.pumpWidgetBuilder(
        memoryDataScope(const FeedScreen()),
        wrapper: materialAppWrapper(theme: AppTheme.light),
        surfaceSize: const Size(390, 844),
      );
      await tester.pumpAndSettle();
      await screenMatchesGolden(tester, 'home_light_390x844');
    });

    testGoldens('GOLDEN AI Model Detayı açık 390x844', (tester) async {
      await tester.pumpWidgetBuilder(
        memoryDataScope(const FeedDetailScreen(id: '0000000000000002')),
        wrapper: materialAppWrapper(theme: AppTheme.light),
        surfaceSize: const Size(390, 844),
      );
      await tester.pumpAndSettle();
      await screenMatchesGolden(tester, 'ai_model_detail_light_390x844');
    });
  });

  /// Dar ekran **ve** büyük yazı, birlikte.
  ///
  /// Bu dosya gerçek yazı tipini yüklüyor; suitin geri kalanındaki taşma
  /// testleri varsayılan test yazı tipiyle ölçüyor ve o tipin glif
  /// genişlikleri cihazdakine benzemiyor. Ölçüldü (2026-07-28): detay
  /// ekranının tarih satırı 360 dp + 1.6 ölçekte gerçek yazı tipiyle
  /// taşıyordu; 1.0 ve 1.3'te taşmıyordu. Yani ne golden (yalnız 1.0) ne de
  /// widget testleri (yalnız 800 piksel) bu birleşimi deniyordu.
  for (final scale in [1.0, 1.3, 1.6]) {
    testWidgets('detay 360 dp / $scale ölçekte taşmaz', (tester) async {
      await tester.pumpWidgetBuilder(
        memoryDataScope(const FeedDetailScreen(id: '0000000000000001')),
        wrapper: materialAppWrapper(theme: AppTheme.dark),
        surfaceSize: const Size(360, 1600),
      );
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: '360 dp @ $scale');
    });
  }
}
