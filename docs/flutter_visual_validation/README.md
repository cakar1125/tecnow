# Flutter Görsel Doğrulama

Durum: `PASS`

Doğrulama viewport'u: 390×844. Golden testleri uygulamaya gömülü Inter ve JetBrains Mono fontlarını yükler.

| Ekran | Stitch referansı | Flutter golden | Bilinen/gerekçeli fark | Kalan düzeltme |
|---|---|---|---|---|
| Ana Sayfa | `design_handoff/approved/feed/ana_ak_teknoak_unified/screen.png` | `flutter_home_390x844.png` | Hayalî Türkçe fixture; viewport kırpımı | Yok |
| Repository Detayı | `design_handoff/approved/repository/github_repo_detay_teknoak_unified/screen.png` | `flutter_repository_detail_390x844.png` | Doğrulanmamış repo/sayılar fixture ile değiştirildi | Yok |
| AI Model Detayı | `design_handoff/approved/ai_models/ai_model_detay_gemini_1.5_pro_unified/screen.png` | `flutter_ai_model_detail_390x844.png` | Master koyu tema; AI için mor vurgu; hayalî model | Yok |

Kontroller:

- Metinler gerçek fontlarla okunabilir.
- 390×844 golden'larda render exception/overflow yok.
- Ayrı responsive test 360×800, 390×844 ve 430×932 boyutlarında 1.3× metin ölçeğiyle geçti.
- Koyu yüzey, cyan ana vurgu, mor AI vurgusu, kart radius/outline ve bilgi hiyerarşisi master tasarım sistemiyle tutarlı.

Görseller:

- `flutter_home_390x844.png`
- `flutter_repository_detail_390x844.png`
- `flutter_ai_model_detail_390x844.png`

“Pixel-perfect” iddiasında bulunulmamıştır.

