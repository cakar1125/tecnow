# Faz 1.5 Fiziksel Cihaz Kabulü

Doğrulama tarihi: 25 Temmuz 2026

## Kabul özeti

| Alan | Sonuç |
|---|---|
| Fiziksel cihaz | OnePlus 8 Pro, model `IN2023` |
| ADB seri numarası | `c5226e6b` |
| Android | 13, API 33 |
| Fiziksel ekran | 1440×3168; 480 dpi, cihaz override 640 dpi |
| Paket | `com.teknoakis.app` |
| Sürüm | `1.0.2+3`, debug/test |
| APK | `mobile/build/app/outputs/flutter-apk/app-debug.apk` |
| APK boyutu | 152.132.529 bayt |
| SHA-256 | `1187F7B8D3E5B2F60BE076C2551A5DE51D0C3A455FE216128512C86E23BFA526` |
| Kurulum | PASS — `adb -s c5226e6b install -r`, kullanıcı verisi silinmedi |
| Otomatik kapılar | PASS — format temiz, analyze temiz, 19/19 test, debug APK build |
| İzole son log | PASS — crash, ANR, Flutter exception, overflow, asset/font/route hatası yok |

## Zorunlu akışlar

| Akış | Sonuç | Fiziksel cihaz gözlemi |
|---|---|---|
| Android ve Flutter splash | PASS | Varsayılan Flutter simgesi kaldırıldı; terminal işareti ve TEKNOAKIŞ ekranı göründü |
| Onboarding | PASS | Sayfalar sırayla açıldı; fiziksel geri tuşu önceki sayfaya döndü |
| İlgi alanları | PASS | 0/3 devre dışı, seçili durumlar belirgin, 3/3 etkin |
| İlgi alanı kalıcılığı | PASS | `install -r` ve uygulama yeniden başlatma sonrası üç seçim geri yüklendi |
| Alt navigasyon | PASS | Beş sekme açıldı ve aktif sekme durumu korundu |
| Ana akış ve kaydırma | PASS | Repository, AI ve teknoloji kartları taşma olmadan kaydırıldı |
| Sosyal aksiyonlar | PASS | Beğen, yorum, kaydet ve paylaş 44×44 erişilebilir hedefler; yerel fixture geri bildirimi |
| Keşfet ve klavye | PASS | Arama, filtre çipleri ve açık klavye durumunda taşma yok |
| Repository detayı | PASS | Açılış ve Android geri dönüşü doğru |
| AI model detayı | PASS | Koyu tema ve yalnız AI alanında mor vurgu doğru |
| Gönderi oluşturma | PASS | Klavye açık/kapalı düzeni kullanılabilir; yayınlama yerine fixture snackbar |
| Bildirimler | PASS | Kartlar dokunulabilir ve yalnız fixture önizleme geri bildirimi veriyor |
| Profil ve Ayarlar | PASS | Ayarlar hatasız açıldı; iki anahtar çalıştı; geri tuşu profile döndü |
| Arka plan ve sürdürme | PASS | HOME sonrası uygulama aynı Profil durumuyla öne geldi |
| Döndürme smoke testi | PASS | Geçici yatay dönüşte crash/exception yok; ürün portre öncelikli |

## Fiziksel testte düzeltilen sorunlar

- Ayarlar ekranındaki `Null check operator used on a null value` hatası giderildi. Android `ListTile` taban çizgisi tema eksikliği tamamlandı ve ayarlar anahtarları güvenli yerel satırlara dönüştürüldü.
- Onboarding ileri geçişleri geçmiş yığınına alındı; Android geri tuşu artık uygulamadan çıkmak yerine önceki onboarding sayfasına dönüyor.
- Bildirim kartları ile sosyal aksiyonlar gerçek dokunma hedefleri ve açık fixture geri bildirimi kazandı.
- İlgi alanlarının yazılıp yeniden okunmaması giderildi; yerel tercihler uygulama açılışında geri yükleniyor.
- Android 13 geri çağrı bildirimi etkinleştirildi.
- Android açılış simgesi ve Flutter splash, TEKNOAKIŞ terminal kimliğiyle eşlendi.

## Sınırlamalar

- APK debug/test yapısıdır; release imzası ve mağaza dağıtımı kapsamında değildir.
- Uygulama yalnız yerel/hayalî fixture verisi kullanır; backend, canlı API, kimlik doğrulama, push ve gerçek yayınlama yoktur.
- Portre düzeni kabul hedefidir. Yatay görünüm crash üretmedi ve kaydırılabilir kaldı; ayrı bir yatay tasarım cilası yapılmadı.
- Soğuk debug açılışı release performansını temsil etmez; ANR gözlenmedi ve kesin FPS iddiası yapılmadı.

## Faz 2 kararı

Fiziksel cihaz, görsel kabul, akış, log ve yeniden derleme kapıları tamamlandı. Faz 2’ye geçiş için Faz 1 cihaz engeli kalmadı.

PHASE_01_DEVICE_ACCEPTED
