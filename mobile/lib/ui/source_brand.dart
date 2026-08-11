import 'package:flutter/material.dart';

import '../design_system/tokens/app_palette.dart';

/// Bir kaynağın görsel kimliği: rengi ve harfleri.
///
/// ## Neden logo dosyası değil
///
/// Akışta **hiçbir kaydın görseli yok** — ölçüldü (2026-08-11): üretilen
/// 200 kaydın 200'ünde de görsel alanı yok, çünkü şemada böyle bir alan
/// hiç tanımlanmadı. Görsel odaklı bir liste düzeni (büyük kart + küçük
/// önizleme) o yüzden doğrudan uygulanamıyor.
///
/// Çözüm kaynağın kendisini görsel çıpa yapmak. Gerçek logo dosyası yerine
/// **marka rengi + harf** kullanılıyor:
///
/// - çevrimdışı çalışır, uygulama boyutuna bir bayt eklemez,
/// - üçüncü tarafın sunucusundan yükleme yapmaz (feed istemcisi zaten
///   "gövde göndermez, tek çıkış" sözleşmesine bağlı),
/// - kimsenin logosunu kopyalamaz.
///
/// Gerçek logolar istenirse [SourceBrand] bir varlık yolu daha taşır ve
/// çağıran taraf değişmez.
///
/// ## Neden iki renk
///
/// Tek bir marka rengi iki temada birden okunamıyor. Ölçüldü: beyaz zeminde
/// AA (4.5:1) için parlaklık ≤ 0.183 gerekiyor, koyu yüzeyde ≥ 0.216 —
/// **kesişmiyorlar.** Bu yüzden her marka, aynı tondan türetilmiş iki renk
/// taşıyor; ikisi de en zorlu zeminde (her temanın `surfaceHigh`'ı) ölçüldü
/// ve kilidi `test/ui/source_brand_test.dart` tutuyor.
@immutable
final class SourceBrand {
  const SourceBrand({
    required this.initials,
    required this.onDark,
    required this.onLight,
  });

  /// Bir ya da iki harf. Kaynağın tanınan kısaltması.
  final String initials;

  /// Koyu temada kullanılan ton.
  final Color onDark;

  /// Açık temada kullanılan ton.
  final Color onLight;

  Color resolve(AppPalette palette) => palette.isDark ? onDark : onLight;

  /// Kaynak adından markayı bulur.
  ///
  /// Eşleşme **önek** üzerinden: feed'de aynı yayıncının birden çok akışı
  /// var (`GitHub`, `GitHub Blog`, `GitHub Değişiklikler`) ve üçü de aynı
  /// markayı taşımalı. Tanınmayan bir kaynak sessizce kaybolmaz, adının ilk
  /// harfleriyle nötr bir marka alır.
  static SourceBrand of(String sourceName) {
    for (final entry in _brands.entries) {
      if (sourceName.toLowerCase().startsWith(entry.key)) return entry.value;
    }
    return SourceBrand(
      initials: _initialsFrom(sourceName),
      onDark: _fallback.onDark,
      onLight: _fallback.onLight,
    );
  }

  /// Bilinen kaynaklar. Anahtarlar küçük harf **önek**tir; sıra önemli:
  /// daha uzun önek daha kısa olandan önce gelmeli.
  static const _brands = <String, SourceBrand>{
    'github': SourceBrand(
      initials: 'GH',
      onDark: Color(0xFF7D8590),
      onLight: Color(0xFF626973),
    ),
    'hugging face': SourceBrand(
      initials: 'HF',
      onDark: Color(0xFFFF9D00),
      onLight: Color(0xFF945B00),
    ),
    'openai': SourceBrand(
      initials: 'AI',
      onDark: Color(0xFF10A37F),
      onLight: Color(0xFF0C795E),
    ),
    'google deepmind': SourceBrand(
      initials: 'DM',
      onDark: Color(0xFF3684EB),
      onLight: Color(0xFF1565CF),
    ),
    'google': SourceBrand(
      initials: 'G',
      onDark: Color(0xFF4285F4),
      onLight: Color(0xFF0D5FE6),
    ),
    'nvidia': SourceBrand(
      initials: 'NV',
      onDark: Color(0xFF76B900),
      onLight: Color(0xFF487200),
    ),
    'android': SourceBrand(
      initials: 'AN',
      onDark: Color(0xFF3DDC84),
      onLight: Color(0xFF167942),
    ),
    'aws': SourceBrand(
      initials: 'AW',
      onDark: Color(0xFFFF9900),
      onLight: Color(0xFF995C00),
    ),
    'visual studio code': SourceBrand(
      initials: 'VS',
      onDark: Color(0xFF0089E6),
      onLight: Color(0xFF006EB8),
    ),
    'pytorch': SourceBrand(
      initials: 'PT',
      onDark: Color(0xFFEE4C2C),
      onLight: Color(0xFFC82E10),
    ),
    'chrome': SourceBrand(
      initials: 'CR',
      onDark: Color(0xFFDF584D),
      onLight: Color(0xFFC63024),
    ),
    'mistral': SourceBrand(
      initials: 'MI',
      onDark: Color(0xFFFF7000),
      onLight: Color(0xFFAD4C00),
    ),
  };

  static const _fallback = SourceBrand(
    initials: '?',
    onDark: Color(0xFF956AF7),
    onLight: Color(0xFF763FF4),
  );

  /// Tanınmayan kaynak için harf üretir: ilk iki kelimenin baş harfleri,
  /// tek kelimeyse ilk iki harf.
  static String _initialsFrom(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      final word = words.first;
      return (word.length == 1 ? word : word.substring(0, 2)).toUpperCase();
    }
    return words.take(2).map((w) => w[0]).join().toUpperCase();
  }

  /// Testlerin gezebilmesi için bilinen markaların tamamı.
  @visibleForTesting
  static Iterable<SourceBrand> get all => [..._brands.values, _fallback];
}
