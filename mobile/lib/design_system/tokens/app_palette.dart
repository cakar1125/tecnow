import 'package:flutter/material.dart';

/// Temaya göre çözülen renk rolleri.
///
/// Uygulama bugüne kadar renkleri `AppColors` içinde **statik sabit** olarak
/// tutuyordu. Bu, tek temalı bir uygulamada çalışır; iki temalı bir uygulamada
/// çalışmaz, çünkü `AppColors.textPrimary` derleme zamanında tek bir değere
/// bağlıdır ve açık temada beyaz metni beyaz zemine yazar. Renkler artık
/// ağaçtan, yani `context`'ten çözülüyor.
///
/// **Neden `ColorScheme` değil de `ThemeExtension`?** Material'in şemasında
/// bu uygulamanın dört rolünün karşılığı yok: `surfaceHigh` (kart içi ikinci
/// kademe), `aiAccent` (yapay zekâ kaynaklı içeriğin işareti), `outlineStrong`
/// ve `technical`. Bunları `tertiary`, `surfaceContainerHighest` gibi
/// yuvalara sıkıştırmak isimlerin anlamını kaybettirirdi. `ColorScheme` yine
/// kuruluyor (Material bileşenleri ondan besleniyor) ama **bu paletten
/// türetiliyor** — tek gerçek kaynak burası.
///
/// ## Ölçülen kontrast (WCAG 2.1, 2026-08-11)
///
/// Her çift ölçüldü, tahmin edilmedi. Metin çiftlerinin tamamı ≥ 4.5:1 (AA),
/// çoğu ≥ 7:1 (AAA):
///
/// | Çift | Koyu | Açık |
/// |---|---|---|
/// | `textPrimary` / `background` | 18.67:1 | 16.18:1 |
/// | `textSecondary` / `surface` | 7.14:1 | 6.18:1 |
/// | `primary` / `surface` | 13.00:1 | 5.36:1 |
/// | `aiAccent` / `surface` | 4.63:1 | 7.10:1 |
/// | `warning` / `surface` | 8.53:1 | 5.02:1 |
/// | `critical` / `surface` | 4.87:1 | 5.74:1 |
/// | `outlineStrong` / `surface` | 3.83:1 | 3.43:1 |
///
/// Kilidi `test/design_system/palette_contrast_test.dart` tutuyor: oran
/// eşiğin altına düşerse test kırılır. Renk değiştirmek serbest, sessizce
/// okunmaz hale getirmek değil.
@immutable
final class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.outline,
    required this.outlineStrong,
    required this.primary,
    required this.onPrimary,
    required this.aiAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.success,
    required this.warning,
    required this.critical,
    required this.shadow,
  });

  /// Koyu tema — bugüne kadarki tek tema.
  ///
  /// Değerler `AppColors`'tan taşındı ve **ikisi hariç** aynı kaldı. Bu dosya
  /// bir yeniden düzenleme, bir yeniden tasarım değil; renk kararları ayrı
  /// bir adımda, kendi diff'iyle gelir.
  ///
  /// İki istisna, kontrast kapısı yazılınca ortaya çıkan **mevcut** kusurlar:
  ///
  /// - `aiAccent` #A855F7, `surfaceHigh` üstünde **4.28:1** ölçüldü — AA
  ///   eşiğinin (4.5) altında. "tecOS ÖZETİ" rozeti ve etiket kutuları o
  ///   zemini kullanıyor. #B37AF8 ile 5.68:1.
  /// - `critical` #EF4444 aynı zeminde **4.50:1**'in kılpayı altında.
  ///   #F15A5A ile 5.12:1.
  ///
  /// İkisi de bugün ekranda duran, hiç ölçülmemiş kusurlardı. Kapıyı
  /// gevşetmek yerine renkler düzeltildi.
  static const dark = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF0A0C10),
    surface: Color(0xFF11151B),
    surfaceHigh: Color(0xFF181D25),
    outline: Color(0xFF2B3440),
    outlineStrong: Color(0xFF677482),
    primary: Color(0xFF00F0FF),
    onPrimary: Color(0xFF0A0C10),
    aiAccent: Color(0xFFB37AF8),
    textPrimary: Color(0xFFF7FAFC),
    textSecondary: Color(0xFF94A3B8),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    critical: Color(0xFFF15A5A),
    shadow: Color(0x3D000000),
  );

  /// Açık tema.
  ///
  /// Koyu paletin renkleri **doğrudan taşınamadı**, ölçüm izin vermedi:
  ///
  /// - `primary` #00F0FF beyaz zeminde **1.32:1** — camgöbeği açık zeminde
  ///   okunmuyor. Aynı renk ailesinde koyulaştırıldı: #0E7490, 5.36:1.
  ///   Marka izi (uygulama simgesindeki camgöbeği terminal işareti) koyu
  ///   temada aynen duruyor.
  /// - `warning` #F59E0B beyaz zeminde **2.15:1** — kehribar açık zeminde
  ///   başarısız. #92400E ile 7.09:1.
  /// - Zemin saf beyaz değil (#F1F4F8): kabul edilen yön "yumuşak" idi ve
  ///   kart (#FFFFFF) ile sayfa arasında bir kademe farkı bırakmak gerekiyor.
  ///
  /// Değerler en zorlu zemine (`surfaceHigh` #E7ECF2) göre seçildi; beyaz
  /// yüzeyde hepsi daha rahat geçiyor. Kılpayı geçen bir renk, sonraki
  /// küçük bir ayarda kapıyı kırar.
  static const light = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFF1F4F8),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFE7ECF2),
    outline: Color(0xFFD7DEE6),
    outlineStrong: Color(0xFF7F8C9A),
    primary: Color(0xFF0C6A83),
    onPrimary: Color(0xFFFFFFFF),
    aiAccent: Color(0xFF6D28D9),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF526375),
    success: Color(0xFF047857),
    warning: Color(0xFF92400E),
    critical: Color(0xFFC81E1E),
    shadow: Color(0x1F0F172A),
  );

  final Brightness brightness;

  /// Sayfa zemini — `Scaffold` arkası.
  final Color background;

  /// Kart ve panel yüzeyi.
  final Color surface;

  /// Yüzeyin içindeki ikinci kademe (kart içi kutu, seçili satır).
  final Color surfaceHigh;

  /// **Dekoratif** ince çizgi. Kontrastı düşüktür ve öyle olması istenir.
  ///
  /// Bir sınırın tek ayırıcı olduğu yerde bunu kullanma — WCAG 1.4.11 orada
  /// 3:1 istiyor ve bu renk onu sağlamıyor (koyu temada yüzey üstünde
  /// **1.45:1** ölçüldü). Orası [outlineStrong]'un işi.
  final Color outline;

  /// Sınırın taşıdığı bilgi başka hiçbir şeyle anlatılmadığında kullanılan
  /// çizgi: metin alanı çerçevesi, odak halkası, seçili durum.
  ///
  /// İki temada da yüzey üstünde ≥ 3:1 ölçüldü (koyu 3.83:1, açık 3.43:1).
  final Color outlineStrong;

  /// Marka rengi ve birincil eylem.
  final Color primary;

  /// [primary] dolgusunun üstündeki metin/simge rengi.
  final Color onPrimary;

  /// Yapay zekâ kaynaklı içeriğin işareti (`SummaryOrigin`).
  final Color aiAccent;

  final Color textPrimary;
  final Color textSecondary;
  final Color success;
  final Color warning;
  final Color critical;

  /// Kart gölgesi. Koyu temada siyah, açık temada metin renginin şeffafı —
  /// açık zeminde saf siyah gölge kirli bir gri halka bırakıyor.
  final Color shadow;

  bool get isDark => brightness == Brightness.dark;

  @override
  AppPalette copyWith({
    Brightness? brightness,
    Color? background,
    Color? surface,
    Color? surfaceHigh,
    Color? outline,
    Color? outlineStrong,
    Color? primary,
    Color? onPrimary,
    Color? aiAccent,
    Color? textPrimary,
    Color? textSecondary,
    Color? success,
    Color? warning,
    Color? critical,
    Color? shadow,
  }) => AppPalette(
    brightness: brightness ?? this.brightness,
    background: background ?? this.background,
    surface: surface ?? this.surface,
    surfaceHigh: surfaceHigh ?? this.surfaceHigh,
    outline: outline ?? this.outline,
    outlineStrong: outlineStrong ?? this.outlineStrong,
    primary: primary ?? this.primary,
    onPrimary: onPrimary ?? this.onPrimary,
    aiAccent: aiAccent ?? this.aiAccent,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    critical: critical ?? this.critical,
    shadow: shadow ?? this.shadow,
  );

  /// Tema değişiminde renkler arasında geçiş.
  ///
  /// [brightness] **karıştırılmaz**, `t >= 0.5`'te ayrık olarak atlar: yarı
  /// koyu bir parlaklık diye bir şey yok ve gölge yoğunluğu gibi ona bakan
  /// kararlar iki değerden birini görmeli.
  @override
  AppPalette lerp(covariant ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      outlineStrong: Color.lerp(outlineStrong, other.outlineStrong, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      aiAccent: Color.lerp(aiAccent, other.aiAccent, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      critical: Color.lerp(critical, other.critical, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }

  /// Değer eşitliği.
  ///
  /// `ThemeExtension` bunu vermiyor ve varsayılan kimlik karşılaştırması
  /// burada **sessizce yanlış** çalışırdı: Flutter bir temanın değişip
  /// değişmediğine `==` ile karar veriyor, dolayısıyla kimlik
  /// karşılaştırması aynı renkleri taşıyan iki palet için gereksiz yeniden
  /// çizim üretir. `lerp` testi de tam olarak bu eksiği yakaladı.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppPalette &&
          other.brightness == brightness &&
          other.background == background &&
          other.surface == surface &&
          other.surfaceHigh == surfaceHigh &&
          other.outline == outline &&
          other.outlineStrong == outlineStrong &&
          other.primary == primary &&
          other.onPrimary == onPrimary &&
          other.aiAccent == aiAccent &&
          other.textPrimary == textPrimary &&
          other.textSecondary == textSecondary &&
          other.success == success &&
          other.warning == warning &&
          other.critical == critical &&
          other.shadow == shadow;

  @override
  int get hashCode => Object.hash(
    brightness,
    background,
    surface,
    surfaceHigh,
    outline,
    outlineStrong,
    primary,
    onPrimary,
    aiAccent,
    textPrimary,
    textSecondary,
    success,
    warning,
    critical,
    shadow,
  );
}

/// `context.palette` — ekranlarda ve bileşenlerde renklere tek erişim yolu.
extension AppPaletteContext on BuildContext {
  /// Ağaçtaki paleti verir.
  ///
  /// Palet yoksa **sessizce koyu temaya düşmez, atar.** Sessiz bir varsayılan
  /// tam olarak aranan hatayı gizlerdi: temasız kurulan bir ekran koyu
  /// renkleri alır, açık temada yanlış çıkar ve hiçbir test kırılmaz. Hata
  /// mesajı ne yapılacağını söylüyor.
  AppPalette get palette {
    final palette = Theme.of(this).extension<AppPalette>();
    if (palette == null) {
      throw FlutterError(
        'AppPalette temada kayıtlı değil.\n'
        'Bu widget `AppTheme.dark` / `AppTheme.light` dışında bir tema '
        'altında kuruldu. Testlerde `testApp()` / `testHarness()` kullan; '
        'uygulamada tema `TecOsApp` tarafından verilir.',
      );
    }
    return palette;
  }
}
