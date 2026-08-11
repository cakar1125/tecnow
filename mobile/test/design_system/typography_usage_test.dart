import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Kaynak seviyesinde bir kapı: **widget'lar renkleri temadan alır.**
///
/// İki temalı bir uygulamada en sinsi kusur şudur: bir ekran `AppTypography`
/// ya da sabit bir `Color(0x…)` kullanır, koyu temada kusursuz görünür ve
/// açık temada beyaz zemine beyaz metin yazar. Hiçbir birim testi kırılmaz,
/// hiçbir golden kırılmaz — çünkü goldens koyu temada üretilir. Kusur ancak
/// biri temayı çevirip baktığında görülür.
///
/// Bu yüzden kural çalışma zamanında değil **kaynakta** ölçülüyor:
/// `lib/features/`, `lib/legacy/` ve `lib/design_system/components/` altında
/// tema-kör renk kullanımı aranıyor.
///
/// Doğru yol: `context.text.body` ve `context.palette.primary`.
void main() {
  final root = Directory('lib');

  /// Kuralın geçerli olmadığı yerler.
  ///
  /// Üçü de renk **tanımlayan** dosyalar, tüketen değil — ve üçünün de
  /// kendi ölçüm kapısı var. Kapısı olmayan bir muafiyet gevşetmedir:
  ///
  /// - `tokens/` — `AppPalette` ve `AppTypography`.
  ///   Kapı: `palette_contrast_test.dart`
  /// - `theme/` — `TextTheme`'i kurarken biçimleri renklendiriyor; orada
  ///   `context` yok, palet doğrudan elinde.
  ///   Kapı: `palette_contrast_test.dart`
  /// - `ui/source_brand.dart` — kaynakların marka renkleri. Bunlar temanın
  ///   rolü değil kaynağın verisi; her biri iki tonlu ve ölçülmüş.
  ///   Kapı: `test/ui/source_brand_test.dart`
  const exemptPaths = {
    'design_system/tokens',
    'design_system/theme',
    'ui/source_brand.dart',
  };

  List<File> sourceFiles() => root
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) {
        final normalized = file.path.replaceAll(r'\', '/');
        return !exemptPaths.any(normalized.contains);
      })
      .toList();

  test('hiçbir ekran AppTypography\'yi doğrudan kullanmaz', () {
    final offenders = <String>[];

    for (final file in sourceFiles()) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        // Yorumlar sayılmaz: bu dosyaların kültürü gerekçeyi yorumda
        // anlatmak ve `AppTypography` adı orada geçebilir.
        if (line.trimLeft().startsWith('//')) continue;
        if (line.contains('AppTypography.')) {
          offenders.add('${file.path}:${i + 1}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Bu satırlar metin rengini derleme zamanında sabitliyor ve açık '
          'temada okunmaz hale geliyor. `context.text.<biçim>` kullan.\n'
          '${offenders.join('\n')}',
    );
  });

  /// Ham `Color(0x…)`.
  ///
  /// Tek bir yerde meşru: paletin kendi tanımı — o da muaf dizinde.
  test('hiçbir ekran ham renk sabiti yazmaz', () {
    final offenders = <String>[];
    final rawColor = RegExp(r'\bColor\(0x[0-9A-Fa-f]{6,8}\)');

    for (final file in sourceFiles()) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;
        if (rawColor.hasMatch(line)) {
          offenders.add('${file.path}:${i + 1} → ${line.trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Ham renk sabiti temayla değişmez. Rolü palete ekle ve '
          '`context.palette.<rol>` kullan.\n${offenders.join('\n')}',
    );
  });

  /// Kapının kendisi çalışıyor mu? Tarama hiç dosya bulmuyorsa testler
  /// sessizce "geçer" ve koruma diye bir şey kalmaz.
  test('tarama gerçekten dosya buluyor', () {
    expect(sourceFiles().length, greaterThan(20));
  });
}
