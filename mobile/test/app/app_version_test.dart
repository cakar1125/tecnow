import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:teknoakis/app/app_version.dart';
import 'package:yaml/yaml.dart' show loadYaml;

/// `lib/app/app_version.dart` sabitleri `pubspec.yaml` ile aynı kalmalı.
///
/// Sabit elle yazılıyor, çünkü çalışma zamanında `pubspec.yaml` okunamıyor ve
/// tek satır metin uğruna `package_info_plus` eklentisi taşımak istemedik.
/// Elle yazılan her sabitin riski sapmadır: biri sürümü yükseltip burayı
/// unutursa kullanıcıya yanlış sürüm gösterilir ve **bunu kimse fark etmez**,
/// çünkü yanlış sürüm de tıpkı doğrusu gibi görünür.
///
/// Bu test o sessiz hatayı gürültülü hâle getirir.
void main() {
  test('app version constants match pubspec.yaml', () {
    final pubspec =
        loadYaml(File('pubspec.yaml').readAsStringSync())
            as Map<Object?, Object?>;
    final declared = pubspec['version'] as String;

    expect(
      declared,
      '$appVersion+$appBuildNumber',
      reason:
          'pubspec.yaml sürümü değişmiş ama lib/app/app_version.dart '
          'güncellenmemiş — kullanıcıya yanlış sürüm gösterilir',
    );
  });

  test('the version label is what the settings footer shows', () {
    expect(appVersionLabel, '$appVersion+$appBuildNumber');
  });

  /// Yer tutucu geri gelmesin. Fixture döneminde ekranda
  /// `Uygulama Sürümü: [DESIGN_FIXTURE_ONLY]` yazıyordu.
  test('the version carries no placeholder text', () {
    expect(appVersionLabel, isNot(contains('FIXTURE')));
    expect(appVersionLabel, matches(RegExp(r'^\d+\.\d+\.\d+\+\d+$')));
  });
}
