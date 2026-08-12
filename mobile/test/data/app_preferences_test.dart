import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tecos/data/app_preferences.dart';

Future<AppPreferences> _preferences([
  Map<String, Object> seed = const {},
]) async {
  SharedPreferences.setMockInitialValues(seed);
  return AppPreferences(await SharedPreferences.getInstance());
}

void main() {
  group('tema tercihi', () {
    test('kaydedilmemişse sistem', () async {
      final preferences = await _preferences();

      expect(preferences.themeMode, ThemeMode.system);
    });

    test('yazılan değer geri okunur', () async {
      final preferences = await _preferences();

      for (final mode in ThemeMode.values) {
        await preferences.setThemeMode(mode);
        expect(preferences.themeMode, mode);
      }
    });

    /// Diskte **ad** saklanıyor, `index` değil.
    ///
    /// `index` sıralamaya bağlıdır: Flutter `ThemeMode`'a bir değer eklerse
    /// eski kurulumlar sessizce başka bir temaya kayardı. Bu test o kararı
    /// kilitliyor — biçim `index`'e dönerse kırılır.
    test('diske ad yazılır, sayı değil', () async {
      SharedPreferences.setMockInitialValues({});
      final raw = await SharedPreferences.getInstance();
      await AppPreferences(raw).setThemeMode(ThemeMode.light);

      expect(raw.getString(AppPreferences.themeModeKey), 'light');
    });

    /// Tanınmayan bir değer uygulamayı açılmaz hale getirmemeli: eski bir
    /// sürümden kalan ya da elle bozulmuş bir tercih dosyası, varsayılana
    /// düşmeli — atmamalı.
    test('tanınmayan değer varsayılana düşer', () async {
      final preferences = await _preferences({
        AppPreferences.themeModeKey: 'sepya',
      });

      expect(preferences.themeMode, ThemeMode.system);
    });

    /// `Verileri Sil` tema tercihini de temizler: "bu cihazda hiçbir izim
    /// kalmasın" diyen kullanıcı için yarım bir silme, silme değildir.
    test('reset tema tercihini de siler', () async {
      final preferences = await _preferences();
      await preferences.setThemeMode(ThemeMode.dark);

      await preferences.reset();

      expect(preferences.themeMode, ThemeMode.system);
    });
  });

  group('içerik dili', () {
    /// `null` ile `'tr'` **aynı şey değil**: cihazını Almanca kullanan biri,
    /// yayına Almanca eklendiği gün onu kendiliğinden almalı. Varsayılan sabit
    /// bir dile bağlansaydı o gün hiçbir şey olmazdı.
    test('kaydedilmemişse cihaza uyulur (null)', () async {
      expect((await _preferences()).feedLanguage, isNull);
    });

    test('seçim saklanır ve geri okunur', () async {
      final preferences = await _preferences();
      await preferences.setFeedLanguage('en');

      expect(preferences.feedLanguage, 'en');
    });

    /// "Cihaza uy"a dönmek bir seçim; anahtarı silerek yapılıyor.
    test('null yazmak tercihi siler', () async {
      final preferences = await _preferences();
      await preferences.setFeedLanguage('en');

      await preferences.setFeedLanguage(null);

      expect(preferences.feedLanguage, isNull);
    });

    /// Boş dize diskte kalmış bozuk bir değer olabilir; onu bir dil kodu
    /// sanmak, çözülemeyen bir adres denemesi demek olurdu.
    test('boş değer cihaza uymak sayılır', () async {
      final preferences = await _preferences({
        AppPreferences.feedLanguageKey: '',
      });

      expect(preferences.feedLanguage, isNull);
    });

    test('reset dil tercihini de siler', () async {
      final preferences = await _preferences();
      await preferences.setFeedLanguage('en');

      await preferences.reset();

      expect(preferences.feedLanguage, isNull);
    });
  });
}
