/// Marka adının **eksiksiz** taşındığını ölçer.
///
/// `TecNow → tecOS` geçişi 2026-08-10'da yapıldı ve yarım kaldı: Android, iOS,
/// Dart kaynağı ve testler taşınmıştı ama masaüstü koşucuları taşınmamıştı.
/// Ölçüldü (2026-08-11):
///
/// | Dosya | Kalan |
/// |---|---|
/// | `linux/CMakeLists.txt` | `BINARY_NAME "tecnow"`, `com.tecnow.tecnow` |
/// | `macos/.../AppInfo.xcconfig` | `PRODUCT_NAME`, bundle kimliği, telif |
/// | `windows/runner/Runner.rc` | altı ayrı sürüm alanı |
/// | `README.md` | başlık ve ilk paragraf |
///
/// Hiçbiri Android yayınını etkilemiyordu — bu yüzden hiçbir kapı görmedi ve
/// bu yüzden kalıcı olacaktı. Masaüstü hedefleri bugün derlenmiyor; sorun
/// derlemenin bozulması değil, **ürünün iki adı olması**.
///
/// Kural: `tecnow` yalnız `"TecNow"` biçiminde, yani **eski adın anıldığı**
/// yerde geçebilir. Marka kararının kendisi (`DECISION_LOG` D-018, TÜRKPATENT
/// gerekçesi) o adı anmak zorunda; anmakla kullanmak farklı şeyler.
///
/// `tecnow.app` alan adı bu kapının **dışında**: `docs/` altında ve bilinçli
/// olarak duruyor — feed hâlâ oradan yayınlanıyor ve GitHub deposunun adı da
/// `tecnow`. Bu dosya `mobile/` ağacını ölçüyor, ürün kimliğinin yaşadığı yeri.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ölçülen ağaçlar. Üretilen ve indirilen her şey dışarıda: `.dart_tool`,
/// `build` ve `ephemeral` derleme çıktısıdır, kaynak değil.
const _roots = <String>[
  'lib',
  'test',
  'tool',
  'android',
  'ios',
  'linux',
  'macos',
  'windows',
  'web',
];

const _files = <String>['README.md', 'pubspec.yaml'];

/// Kaynak **olmayan** yollar. Üç ayrı sebep, tek desen:
///
/// **1 · Derleme çıktısı dizinleri.** `.dart_tool`, `build`, `ephemeral`,
/// `Pods` — hepsi üretilir, hiçbiri yazılmaz.
///
/// **2 · `flutter pub get`'in ürettiği yapılandırma dosyaları.** Bunlar
/// platform dizinlerinin *içinde* durduğu için yukarıdaki dizin kuralı onları
/// yakalamıyor. Kapı tam bu yüzden 2026-08-12'de CI'da kırıldı ve yerelde
/// kırılmadı — 895 test geçti, bu bir test kaldı:
///
/// ```
/// ios\Flutter\Generated.xcconfig:3:
///   FLUTTER_APPLICATION_PATH=D:\a\tecnow\tecnow\mobile
/// ios\Flutter\flutter_export_environment.sh:4:
///   export "FLUTTER_APPLICATION_PATH=D:\a\tecnow\tecnow\mobile"
/// ```
///
/// Koşucu depoyu `D:\a\tecnow\tecnow\` altına açıyor ve `pub get` o **mutlak
/// yolu** dosyaya yazıyor. Satırda geçen "tecnow" ürünün adı değil, **GitHub
/// deposunun dizin adı** — ve depo adı bilinçli olarak `tecnow` (bkz. bu
/// dosyanın başlığı: alan adı ve depo adı kapının dışında). Yerelde çalışma
/// dizini `stitch_techpulse_social (14)` olduğu için aynı satır hiç
/// oluşmuyordu; kusur koddaydı, ortamda değil.
///
/// Kural değişmiyor, **kapsamı düzeliyor**: üretilen dosya kaynak değildir.
///
/// **3 · Bu dosyanın kendisi.** Aradığı kelimeyi taşımak zorunda; kendini
/// işaretlemesi kapıyı susturmak için bahane değil, tanımının gereği.
final _ignored = RegExp(
  [
    r'[/\\](\.dart_tool|build|ephemeral|Pods)[/\\]',
    r'[/\\](Flutter-)?Generated\.xcconfig$',
    r'[/\\]flutter_export_environment\.sh$',
    r'[/\\]local\.properties$',
    r'[/\\][Gg]enerated[_]?[Pp]lugin[_]?[Rr]egistrant\.',
    r'brand_name_test\.dart$',
  ].join('|'),
);

/// Eski adın **anıldığı** biçim. Tırnak zorunlu: `"TecNow"` bir alıntıdır,
/// `tecnow` bir kimliktir.
const _quotedMention = '"TecNow"';

void main() {
  test('ürünün tek adı var', () {
    final offenders = <String>[];

    void scan(File file) {
      if (_ignored.hasMatch(file.path)) return;
      final String content;
      try {
        content = file.readAsStringSync();
      } on FileSystemException {
        return; // ikili dosya
      }
      final lines = content.split('\n');
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        if (!line.toLowerCase().contains('tecnow')) continue;
        if (line.contains(_quotedMention)) continue;
        offenders.add('${file.path}:${index + 1}: ${line.trim()}');
      }
    }

    for (final root in _roots) {
      final directory = Directory(root);
      if (!directory.existsSync()) continue;
      for (final entity in directory.listSync(recursive: true)) {
        if (entity is File) scan(entity);
      }
    }
    for (final path in _files) {
      final file = File(path);
      if (file.existsSync()) scan(file);
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Eski marka adı hâlâ kimlik olarak kullanılıyor:\n'
          '  ${offenders.join("\n  ")}\n'
          'Eski adı yalnız $_quotedMention biçiminde, geçmişe atıf olarak '
          'anabilirsiniz.',
    );
  });

  /// Kapının gerçekten baktığını gösterir: kural yalnız alıntıyı geçirmeli.
  test('kapı alıntı ile kimliği ayırır', () {
    expect('// Ad "TecNow"dan taşındı'.contains(_quotedMention), isTrue);
    expect('set(BINARY_NAME "tecnow")'.contains(_quotedMention), isFalse);
  });

  /// Kapının **kapsamı** da ölçülmeli. Bu yolların ilk ikisi CI'da gerçekten
  /// kapıyı kırdı (2026-08-12): koşucunun çalışma dizini `…\tecnow\tecnow\`
  /// olduğu için `pub get` depo adını üretilen dosyalara yazdı.
  test('üretilen yapılandırma dosyaları taranmaz', () {
    for (final path in [
      r'ios\Flutter\Generated.xcconfig',
      r'ios\Flutter\flutter_export_environment.sh',
      r'macos\Flutter\Flutter-Generated.xcconfig',
      r'android\local.properties',
      r'windows\flutter\generated_plugin_registrant.cc',
      r'ios\Runner\GeneratedPluginRegistrant.m',
      r'ios\Flutter\ephemeral\Packages\.packages\FlutterFramework',
    ]) {
      expect(_ignored.hasMatch(path), isTrue, reason: '$path taranmamalı');
    }
  });

  /// Kapsam daralmasının sessizce fazla daralmadığını ölçer. Bu dört dosya
  /// elle yazılıyor ve kapıyı kuran bulgu **tam olarak** onlardı: taranmaya
  /// devam etmezlerse kapı adını korur, işini kaybeder.
  test('elle yazılan platform dosyaları taranmaya devam eder', () {
    for (final path in [
      r'linux\CMakeLists.txt',
      r'macos\Runner\Configs\AppInfo.xcconfig',
      r'windows\runner\Runner.rc',
      r'android\app\build.gradle.kts',
    ]) {
      expect(_ignored.hasMatch(path), isFalse, reason: '$path taranmalı');
    }
  });
}
