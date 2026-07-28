# Fiziksel Cihaz Test Logu

Doğrulama tarihi: 25 Temmuz 2026

## Cihaz seçimi ve kurulum

`adb devices -l` içinde iki hedef görüldü; bütün fiziksel test komutlarında seri açıkça seçildi:

```text
c5226e6b      device product:OnePlus8Pro model:IN2023 device:OnePlus8Pro
emulator-5554 device product:sdk_gphone64_x86_64 model:sdk_gphone64_x86_64
```

- Üretici/model: OnePlus / IN2023
- Android: 13, API 33
- Paket: `com.teknoakis.app`
- Sürüm: `1.0.2+3`
- Kurulum: `adb -s c5226e6b install -r ...` → `Success`
- Uygulama verisi temizlenmedi; seçim kalıcılığı bu nedenle gerçek güncelleme koşulunda sınandı.

## APK bütünlüğü

- Dosya: `mobile/build/app/outputs/flutter-apk/app-debug.apk`
- Boyut: 152.132.529 bayt
- SHA-256: `1187F7B8D3E5B2F60BE076C2551A5DE51D0C3A455FE216128512C86E23BFA526`
- Cihazdaki sürüm: `versionName=1.0.2`, `versionCode=3`

## Otomatik kalite kapıları

| Komut | Sonuç |
|---|---|
| `flutter clean` | PASS |
| `flutter pub get` | PASS; kilitli bağımlılıklar çözüldü |
| `dart format .` | PASS; 31 dosya, değişiklik yok |
| `flutter analyze` | PASS; issue yok |
| `flutter test` | PASS; 19/19 |
| `flutter build apk --debug` | PASS |

## Fiziksel etkileşim kaydı

- Soğuk başlatma, Android splash, Flutter splash ve onboarding izlendi.
- Onboarding ileri ve fiziksel geri tuşu UI hierarchy ile doğrulandı.
- Üç ilgi alanı seçildi, kaydedildi; final APK `install -r` ile kuruldu; yeniden başlatma sonrası 3/3 seçim geri yüklendi.
- Alt navigasyonun beş sekmesi, kart detayları, akış kaydırma, Keşfet araması, açık klavye, gönderi fixture bildirimi, bildirim kartı, Profil ve Ayarlar çalıştırıldı.
- Sosyal aksiyonlar ile bildirim kartı dokunma geri bildirimleri ekran görüntüsüyle doğrulandı.
- Ayarlar anahtarı `checked=true` durumuna geçti; fiziksel geri tuşu Profile döndü.
- HOME sonrası uygulama yeniden öne alındığında Profil durumu korundu.
- Cihaz geçici olarak yataya kilitlendi; crash/exception gözlenmedi; ardından portreye döndürülüp otomatik döndürme serbest bırakıldı.
- Sistem yazı ölçeği `1.0` olarak okundu ve değiştirilmedi.

## Log izolasyonu ve hata taraması

- Başlangıçta `logcat -c` çalıştırıldı.
- Son log yalnız `com.teknoakis.app` PID `14370` için alındı: `logs/final_app.log`.
- Tarama sonucu: `FATAL EXCEPTION`, `AndroidRuntime`, ANR, `FlutterError`, null-check hatası, RenderFlex overflow, asset/font/route hatası veya uncaught exception yok.
- OnePlus `Quality` satırlarında `Skipped: false` kayıtları vardır; bunlar hata değildir.
- Pre-fix fiziksel kanıt `logs/pre_fix_app.log` ve `screenshots/12_settings_pre_fix_error.png` altında korunmuştur.

## Sonuç

Kurulum, zorunlu akışlar, kalıcılık, fiziksel geri, klavye, arka plan/sürdürme, döndürme smoke testi, ekran görüntüleri ve izole log kapıları PASS durumundadır.
