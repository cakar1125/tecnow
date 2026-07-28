# Faz 0–1 Uygulama Raporu

Nihai durum: `PHASE_01_READY`

Doğrulama tarihi: 25 Temmuz 2026

## Teslim özeti

- Paket (14), zorunlu `fix_2`, 255 özgün dosyanın korunması, 53 onaylı çift ve 75 arşiv kaydı yeniden doğrulandı.
- Flutter 3.44.8 / Dart 3.12.2 ve Android SDK 36 ortamı hazırlandı; Android lisansları kabul edildi.
- Git deposu oluşturuldu. Tasarım handoff'u `f0c21ee` (`chore: preserve approved TeknoAkis design handoff`) commit'iyle koruma altına alındı.
- `mobile/` altında `com.teknoakis.app` kimlikli Flutter uygulaması üretildi.
- Faz 1 ekranları, gerçek shell navigasyonu, ortak tasarım sistemi, yerel ilgi alanı saklama ve açıkça işaretli fixture verisi tamamlandı.
- Backend, Firebase, kimlik doğrulama, canlı API veya üçüncü taraf veri çağrısı eklenmedi.

## Kalite kapıları

| Kapı | Gerçek sonuç |
|---|---|
| `flutter pub get` | exit 0 |
| `dart format .` | exit 0 — 29 dosya, değişiklik yok |
| `flutter analyze` | exit 0 — No issues found |
| `flutter test` | exit 0 — 14/14 geçti |
| Golden üretimi | exit 0 — 3/3 üretildi ve görsel incelendi |
| 360/390/430 px + 1.3× metin ölçeği | PASS — exception/overflow yok |
| `flutter build apk --debug` | exit 0 |
| Fixture işaretleri | PASS — üç zorunlu işaret mevcut |
| Canlı bağlantı taraması | PASS — ağ istemcisi/API çağrısı yok |
| API 35 emülatör smoke testi | PASS — onboarding, ilgi alanları ve ana akış çalıştı; crash logu yok |

İlk genel `dart format .` denemesi, üretilmiş `build/` altındaki geçici Android dönüşüm dizini kaybolduğu için tarama sırasında durdu. Standart `flutter clean` sonrasında istenen beş komut tam sırayla yeniden çalıştırıldı ve tamamı exit 0 verdi. Golden font yükleme içe aktarımı da geliştirme sırasında analizde yakalanıp düzeltildi; yukarıdaki tablo son, temiz çalıştırmaları gösterir.

## Görsel doğrulama

390×844 golden çıktıları Ana Sayfa, Repository Detayı ve AI Model Detayı için üretildi. Inter/JetBrains Mono fontları testte gerçekten yüklendi; metin okunabilirliği ve taşma görsel olarak kontrol edildi. Kayıtlar `docs/flutter_visual_validation/` altındadır.

Stitch AI detay export'undaki açık tema, master tasarım sistemine aykırı olduğu için Flutter uygulamasında ortak koyu tema ve yalnız AI yüzeylerinde mor vurgu kullanıldı. Gerçekliği doğrulanmamış Stitch adları ve sayıları hayalî Türkçe fixture'larla değiştirildi. Pixel-perfect iddiası yoktur.

## Android çalışma düzeltmesi

İlk APK gerçek cihazda ve API 35 emülatörde açılışta kapandı. Logcat kök nedeni `ClassNotFoundException: com.teknoakis.app.MainActivity` olarak gösterdi: application ID değiştirilmiş, Kotlin activity paketi eski `com.teknoakis.teknoakis` değerinde kalmıştı. `MainActivity` kaynak yolu ve package bildirimi `com.teknoakis.app` ile eşlendi. Aynı uyuşmazlığı tekrar yakalamak için Android namespace/application ID/manifest/activity bütünlüğü regresyon testi eklendi.

Düzeltilmiş APK emülatöre temiz biçimde yeniden kuruldu. Süreç çalışır (`PID` mevcut), odaklanan activity `com.teknoakis.app/.MainActivity` ve temiz başlangıçtan sonra AndroidRuntime/Flutter fatal logu yoktur.

## APK

| Alan | Değer |
|---|---|
| Dosya | `mobile/build/app/outputs/flutter-apk/app-debug.apk` |
| Boyut | 152.132.529 bayt (145,08 MB) |
| SHA-256 | `1187F7B8D3E5B2F60BE076C2551A5DE51D0C3A455FE216128512C86E23BFA526` |
| Paket | `com.teknoakis.app` |
| Sürüm | `1.0.2+3` |
| SDK | compile/target 36, min 24 |

APK debug/test teslimidir; mağaza yayını için imzalanmış release değildir.

Fiziksel OnePlus IN2023 kabulü ve final log sonucu `docs/PHASE_01_DEVICE_ACCEPTANCE.md` altında kayıtlıdır.
