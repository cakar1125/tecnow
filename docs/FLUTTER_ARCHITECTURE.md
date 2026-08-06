# Flutter Mimari Kararı

Durum: `IMPLEMENTED_LOCAL`

## Uygulama sınırı

- Uygulama adı: `tecnow`
- Android/iOS kimliği: `com.tecnow.app`
- Faz 1 yalnızca yerel fixture verisiyle çalışan, backend'siz bir mobil dikey dilimdir.
- Mimari feature-first tutuldu; bu ölçekte değer üretmeyen boş `data/domain` katmanları açılmadı.

## Kaynak yapısı

```text
mobile/lib/
  app/                 # bootstrap, MaterialApp ve go_router
  design_system/       # token, tema ve ortak bileşenler
  features/            # ekran bazlı özellikler
  fixtures/            # DESIGN_FIXTURE_ONLY / NOT_LIVE_DATA / NOT_VERIFIED
```

Uygulanan feature'lar: splash, üç adımlı onboarding, ilgi alanları, ana akış, keşfet, repository detayı, AI model detayı, gönderi oluşturma, bildirimler, profil ve ayarlar.

## Navigasyon

`go_router` içindeki `StatefulShellRoute.indexedStack`, Ana Sayfa, Keşfet, Paylaş, Bildirimler ve Profil sekmelerinin durumunu korur. Detay ekranları shell dışında açılır ve geri eylemi route stack'ini kullanır.

| Route | Ekran |
|---|---|
| `/splash` | Splash |
| `/onboarding/:step` | Onboarding 1–3 |
| `/interests` | İlgi alanı seçimi |
| `/home` | Ana akış |
| `/explore` | Keşfet |
| `/create-post` | Yerel gönderi formu |
| `/notifications` | Bildirimler |
| `/profile` | Profil |
| `/repository/:id` | Repository detayı |
| `/ai-model/:id` | AI model detayı |
| `/settings` | Ayarlar |

## Durum ve veri

- Riverpod, seçili ilgi alanlarının durumunu yönetir.
- `shared_preferences`, ilgi alanlarını cihazda yerel olarak saklar.
- Tüm ürün içeriği `lib/fixtures/fixtures.dart` içinde hayalî ve doğrulanmamış veri olarak işaretlidir.
- Gönderi oluşturma ekranı yalnızca yerel geri bildirim verir; yayınlama yapmaz.

## Tasarım sistemi

Merkezi token'lar renk, boşluk, radius, tipografi, gölge, animasyon süresi ve breakpoint'leri kapsar. Ortak bileşenler arasında scaffold/top bar, alt navigasyon, butonlar, alanlar, filtre/badge'ler, içerik kartları, sosyal aksiyonlar, boş-hata-yükleniyor durumları, bottom sheet ve onay diyaloğu bulunur.

Inter ve JetBrains Mono, resmî Google Fonts deposundaki OFL lisanslı dosyalarla uygulamaya gömülmüştür.

## Bağımlılık kararı

Kullanılan paketler: `flutter_riverpod`, `go_router`, `shared_preferences`; testte `golden_toolkit`.

Faz 1'de gerçek kullanım olmadığı için `dio`, `freezed_annotation`, `json_annotation`, `flutter_secure_storage`, `cached_network_image`, `build_runner`, `freezed`, `json_serializable` ve `mocktail` eklenmedi. Böylece canlı ağ, kimlik, serileştirme ve gereksiz kod üretimi katmanları oluşmadı.

