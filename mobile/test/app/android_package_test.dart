import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android entry activity matches the application namespace', () {
    const packageName = 'com.teknoakis.app';
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final activity = File(
      'android/app/src/main/kotlin/com/teknoakis/app/MainActivity.kt',
    );

    expect(gradle, contains('namespace = "$packageName"'));
    expect(gradle, contains('applicationId = "$packageName"'));
    expect(manifest, contains('android:name=".MainActivity"'));
    expect(activity.existsSync(), isTrue);
    expect(activity.readAsStringSync(), contains('package $packageName'));
  });
}
