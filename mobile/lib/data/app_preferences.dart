import 'package:shared_preferences/shared_preferences.dart';

/// Küçük ayar bayrakları.
///
/// `LOCAL_DATA_ARCHITECTURE.md` dil, tema, görünüm tercihleri ve
/// "onboarding tamamlandı" bilgisini `shared_preferences`'a, listeleri ise
/// sqflite'a yazar. Bu sınıf o sözleşmenin anahtar tarafını tek yerde tutar.
final class AppPreferences {
  const AppPreferences(this._preferences);

  static const onboardingCompletedKey = 'onboarding_completed_v1';

  final SharedPreferences _preferences;

  bool get onboardingCompleted =>
      _preferences.getBool(onboardingCompletedKey) ?? false;

  Future<void> markOnboardingCompleted() =>
      _preferences.setBool(onboardingCompletedKey, true);

  Future<void> reset() => _preferences.remove(onboardingCompletedKey);
}
