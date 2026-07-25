# Flutter Developer Handoff

Durum: Tasarım handoff hazır, Flutter uygulaması ortam nedeniyle bekliyor.

## Güvenilir kaynak sırası

1. Bu klasördeki `MASTER_DESIGN_SYSTEM.md`.
2. `APPROVED_SCREEN_INVENTORY.md` içindeki APPROVED satırlar.
3. `design_handoff/approved/<kategori>/<ekran>/screen.png` görsel referansı.
4. Aynı klasördeki `code.html`; yalnız ölçü/hiyerarşi analizi için.

`archive/` veya `original_reference/` altındaki dosyalar uygulama referansı değildir. Özellikle `g_nderi_yay_nlanamad_teknoak_fix_1` ve boş `i_lgi_alanlar_d_zenleme_teknoak_v3_1` kullanılmaz.

## Ortam açıldığında başlangıç

Proje kökünde Flutter stable ile `mobile/` oluşturulmalı; uygulama adı `teknoakis`, organization/package `com.teknoakis.app` olmalı. İlk olarak merkezi tokenlar ve theme, sonra ortak componentler, ardından dikey dilim uygulanmalı.

İstenen runtime paketleri: `flutter_riverpod`, `go_router`, `dio`, `freezed_annotation`, `json_annotation`, `shared_preferences`, `flutter_secure_storage`, `cached_network_image`. Dev paketleri: `build_runner`, `freezed`, `json_serializable`, `flutter_lints`, `mocktail`, `golden_toolkit`. Kullanılmayan paket eklenmemelidir.

## Faz 1 route önerisi

```text
/splash
/onboarding/:step
/interests
/home
/explore
/repository/:id
/ai-model/:id
/create-post
/notifications
/profile
/settings
```

Alt navigasyon: Ana Sayfa, Keşfet, Paylaş, Bildirimler, Profil. Paylaş yalnız yerel form route'una gider; gönderim yapmaz.

## Fixture sözleşmesi

`mobile/lib/fixtures/` altındaki her dosya şu üst uyarıyla başlamalı:

```text
DESIGN_FIXTURE_ONLY
NOT_LIVE_DATA
NOT_VERIFIED
```

Repository, model, duyuru, bildirim, profil ve ilgi alanı adları hayalî/örnek olmalı. Şirket, fiyat veya benchmark gerçeği iddia edilmemeli.

## Doğrulama kapısı

Sırayla pub get, format, analyze ve test çalıştırılmalı. Token, router, alt navigasyon, ilgi seçimi, feed, iki kart ve empty/error testleri zorunludur. Ana Sayfa, Repository Detayı ve AI Model Detayı golden'ları 390×844'te üretilmelidir. 360/390/430 genişlikleri ve büyük metin ayrıca test edilmelidir. Android doctor yeşilse debug APK oluşturulmalıdır.

Mevcut engel ve kurulum: `docs/FLUTTER_ENVIRONMENT_REPORT.md`.

