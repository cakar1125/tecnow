import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Küçük ayar bayrakları.
///
/// `LOCAL_DATA_ARCHITECTURE.md` dil, tema, görünüm tercihleri ve
/// "onboarding tamamlandı" bilgisini `shared_preferences`'a, listeleri ise
/// sqflite'a yazar. Bu sınıf o sözleşmenin anahtar tarafını tek yerde tutar.
final class AppPreferences {
  const AppPreferences(this._preferences);

  static const onboardingCompletedKey = 'onboarding_completed_v1';
  static const themeModeKey = 'theme_mode_v1';
  static const mutedSourcesKey = 'muted_sources_v1';

  final SharedPreferences _preferences;

  bool get onboardingCompleted =>
      _preferences.getBool(onboardingCompletedKey) ?? false;

  Future<void> markOnboardingCompleted() =>
      _preferences.setBool(onboardingCompletedKey, true);

  /// Tema tercihi. Kaydedilmemişse **sistem** — uygulamanın kendi zevkini
  /// dayatmasındansa cihazın kararına uyması doğru varsayılan.
  ///
  /// Diskte `ThemeMode.index` değil, ada göre saklanıyor. `index` sıralamaya
  /// bağlıdır ve Flutter enum'a bir değer eklerse eski kurulumlar sessizce
  /// başka bir temaya kayar; ad böyle bir bağ kurmaz. Tanınmayan bir değer
  /// okunursa varsayılana düşer, atmaz — bir tercih dosyası yüzünden uygulama
  /// açılmamazlık etmemeli.
  ThemeMode get themeMode => switch (_preferences.getString(themeModeKey)) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  Future<void> setThemeMode(ThemeMode mode) =>
      _preferences.setString(themeModeKey, mode.name);

  /// Akıştan **çıkarılmış** kaynaklar.
  ///
  /// Saklanan şey takip edilenler değil, susturulanlar. Fark önemli: yeni
  /// bir kaynak eklendiğinde takip listesi tutuluyor olsaydı o kaynak
  /// kimseye görünmezdi — kullanıcı varlığından haberdar olmadığı bir şeyi
  /// açamaz. Susturulanları tutmak, varsayılanı "hepsi açık" yapar.
  ///
  /// `shared_preferences`'ta, sqflite'ta değil: küme küçük ve sınırlı
  /// (ölçüldü: üretilen 200 kayıtta **14** benzersiz kaynak), bir liste
  /// değil bir tercih, ve yayın öncesi bir şema göçünden kaçınıyor —
  /// `app.db` sürümü tek yönlü bir kapı.
  Set<String> get mutedSources =>
      (_preferences.getStringList(mutedSourcesKey) ?? const <String>[]).toSet();

  Future<void> setMutedSources(Set<String> sources) =>
      _preferences.setStringList(mutedSourcesKey, sources.toList()..sort());

  Future<void> reset() async {
    await _preferences.remove(onboardingCompletedKey);
    await _preferences.remove(themeModeKey);
    await _preferences.remove(mutedSourcesKey);
  }
}
