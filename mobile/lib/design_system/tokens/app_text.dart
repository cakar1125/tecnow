import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'app_tokens.dart';

/// Temaya göre çözülmüş metin biçimleri — `context.text.body` gibi.
///
/// [AppTypography] metnin **biçimini** tutar: punto, ağırlık, satır yüksekliği,
/// yazı ailesi. Rengini tutmaz, tutamaz — renk temaya göre değişir. Bu sınıf
/// ikisini birleştiren tek yer.
///
/// Widget'lar `AppTypography.*` kullanmaz; kullanırlarsa koyu temanın rengini
/// açık temaya taşırlar ve metin zeminin içinde kaybolur. Kural bir yorumla
/// değil, kapıyla korunuyor: `test/design_system/typography_usage_test.dart`
/// `lib/features/` ve `lib/design_system/components/` altında doğrudan
/// `AppTypography.` geçişi bulursa kırılır.
final class AppTextStyles {
  const AppTextStyles(this._palette);

  final AppPalette _palette;

  TextStyle get display =>
      AppTypography.display.copyWith(color: _palette.textPrimary);

  TextStyle get headline =>
      AppTypography.headline.copyWith(color: _palette.textPrimary);

  TextStyle get title =>
      AppTypography.title.copyWith(color: _palette.textPrimary);

  TextStyle get body =>
      AppTypography.body.copyWith(color: _palette.textPrimary);

  /// Gövde puntosunda, ikincil renkte. Uygulamanın en çok kullanılan biçimi:
  /// kart özetleri, açıklama satırları, ikincil bilgi.
  TextStyle get bodyMuted =>
      AppTypography.body.copyWith(color: _palette.textSecondary);

  TextStyle get label =>
      AppTypography.label.copyWith(color: _palette.textSecondary);

  TextStyle get navLabel =>
      AppTypography.navLabel.copyWith(color: _palette.textSecondary);

  /// Tek aralıklı teknik metin: sürüm, karma, tarih damgası, kaynak adresi.
  TextStyle get technical =>
      AppTypography.technical.copyWith(color: _palette.textSecondary);

  /// Marka renginde etiket — bağlantı ve eylem metinleri.
  TextStyle get labelAccent =>
      AppTypography.label.copyWith(color: _palette.primary);
}

extension AppTextContext on BuildContext {
  AppTextStyles get text => AppTextStyles(palette);
}
