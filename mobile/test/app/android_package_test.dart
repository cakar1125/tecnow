import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android entry activity matches the application namespace', () {
    const packageName = 'com.tecos.app';
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final activity = File(
      'android/app/src/main/kotlin/com/tecos/app/MainActivity.kt',
    );

    expect(gradle, contains('namespace = "$packageName"'));
    expect(gradle, contains('applicationId = "$packageName"'));
    expect(manifest, contains('android:name=".MainActivity"'));
    expect(activity.existsSync(), isTrue);
    expect(activity.readAsStringSync(), contains('package $packageName'));
  });

  /// Bu izin yalnız `src/debug/AndroidManifest.xml` içinde duruyordu — orayı
  /// Flutter aracı hot reload için kendisi ekliyor. Sonuç: ağ geliştirmede
  /// çalışır, **yayın derlemesinde sessizce çalışmazdı** ve bu ancak
  /// mağazadaki sürümde görünürdü.
  test('yayın manifesti internet iznini bildirir', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, contains('android.permission.INTERNET'));
  });

  /// Feed yalnız `https` üzerinden çekilir (`parseFeedEndpoint`). Platform
  /// tarafında da açıkça kapatılır: varsayılana güvenmek, `targetSdk` bir gün
  /// düştüğünde sessizce düz metne izin vermek olurdu.
  test('düz metin trafiği kapalıdır', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, contains('android:usesCleartextTraffic="false"'));
  });
}
