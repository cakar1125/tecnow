import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecnow/design_system/components/app_components.dart';
import 'package:tecnow/legacy/notifications_screen.dart';

import '../test_harness.dart';

/// `lib/legacy/` altındaki ekranların testleri.
///
/// **Bu ekranlar yönlendiricide yok.** Sosyal ağ dönemi kalıntısı olarak
/// bilinçli korunuyorlar (`LEGACY_NOT_ACTIVE`), yani buradaki testler
/// kullanıcının ulaşamayacağı kodu ölçüyor. Ayrı bir dosyada duruyorlar ki
/// süite bakan biri bunları ürünün kapsaması sansın diye yanılmasın.
///
/// Öncesinde `physical_device_regression_test.dart` içindeydiler; o dosyanın
/// adı cihaz regresyonu vaat ediyordu ve dört testinin ikisi buydu.
///
/// Ölçüldü (2026-07-28): `NotificationsScreen`, `ProfileScreen` ve
/// `CreatePostScreen` hiçbir rotadan açılmıyor; `RepositoryCard` yalnız
/// `ProfileScreen` içinde, `SocialActionBar` yalnız `RepositoryCard` içinde
/// kullanılıyor. Zincirin tamamı ölü.
///
/// `lib/legacy/` silinirse bu dosya da silinmeli.
void main() {
  testWidgets('notification actions provide local feedback', (tester) async {
    await tester.pumpWidget(
      testHarness(const Scaffold(body: NotificationsScreen())),
    );
    await tester.tap(find.byType(InkWell).first);
    await tester.pump();
    expect(
      find.text('Bu bildirim yalnız fixture önizlemesidir.'),
      findsOneWidget,
    );
  });

  testWidgets('social actions provide local feedback', (tester) async {
    await tester.pumpWidget(
      testHarness(const Scaffold(body: SocialActionBar())),
    );
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pump();
    expect(
      find.text('Beğen yalnız yerel fixture etkileşimidir.'),
      findsOneWidget,
    );
  });
}
