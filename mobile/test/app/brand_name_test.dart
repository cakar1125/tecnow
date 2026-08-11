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

/// Derleme çıktısı kaynak değildir. Son desen **bu dosyanın kendisi**: aradığı
/// kelimeyi taşımak zorunda ve kendini işaretlemesi kapıyı susturmak için bir
/// bahane değil, tanımının gereği.
final _ignored = RegExp(
  r'[/\\](\.dart_tool|build|ephemeral|Pods)[/\\]|brand_name_test\.dart$',
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
}
