# Flutter Mimari Kararı

Bu belge uygulanacak mimariyi tanımlar; ortam engeli nedeniyle henüz Flutter kaynak kodu üretilmemiştir.

## Hedef

- Uygulama: `teknoakis`
- Android/iOS kimliği: `com.teknoakis.app`
- Feature-first yapı; yalnızca ihtiyaç olan feature'larda `data`, `domain`, `presentation` katmanları.
- Riverpod ile durum/bağımlılık yönetimi, go_router ile route ve shell navigasyonu.
- Canlı servis olmadan `lib/fixtures/` altındaki açıkça işaretlenmiş fixture veriler.

## Klasörler

```text
lib/
  app/                 # bootstrap, uygulama, router
  core/                # constants, errors, network, storage, utils
  design_system/       # tokens, theme, components, states
  features/            # splash, onboarding, interests, feed, explore,
                       # search, repository_detail, ai_model_detail,
                       # create_post, notifications, profile, settings
  fixtures/            # DESIGN_FIXTURE_ONLY / NOT_LIVE_DATA / NOT_VERIFIED
```

## Navigasyon

`StatefulShellRoute` benzeri bir kabukla Ana Sayfa, Keşfet, Paylaş, Bildirimler ve Profil sekmeleri durumlarını korur. Detay route'ları shell üstünde açılır; geri eylemi route stack'ine döner. Paylaş bu fazda yalnızca yerel Gönderi Oluştur ekranını açar ve yayın yapmaz.

## Bağımlılık sınırı

İstenen paketler yalnızca gerçek kullanım başladığında eklenir. Dio/network ve storage katmanları Faz 1'de canlı bağlantı kurmaz. Backend, Firebase, gerçek kimlik doğrulama veya üçüncü taraf API yoktur.

