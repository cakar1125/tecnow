# MASTER_DESIGN_SYSTEM.md

## 1. Tasarım İlkeleri
- **Fütüristik Teknik Estetik:** Modern, temiz ve veriye dayalı bir arayüz.
- **Karanlık Öncelikli:** OLED dostu, yüksek kontrastlı karanlık mod odaklı tasarım.
- **Hiyerarşik Netlik:** Teknik verilerin ve sosyal etkileşimlerin dengeli sunumu.

## 2. Renk Token'ları (Unified Dark)
| Token | Değer | Kullanım Alanı |
|---|---|---|
| `surface` | #0A0C10 | Ana arka plan (Derin Siyah/Lacivert) |
| `surface-container` | #15181F | Kartlar ve konteynerler |
| `primary` | #00F0FF | **Electric Cyan:** Ana navigasyon, aktif durumlar, vurgular |
| `secondary` | #A855F7 | **Cyber Purple:** AI içerikleri, model karşılaştırmaları, akıllı analiz |
| `on-surface` | #FFFFFF | Ana metinler |
| `on-surface-variant` | #94A3B8 | Yardımcı metinler, açıklamalar |
| `success` | #10B981 | Olumlu benchmarklar, sistem durumları |
| `error` | #EF4444 | Hatalar, kritik uyarılar |

## 3. Tipografi
- **Ana Font:** Geist / Inter (Sans-serif)
- **Teknik/Veri Fontu:** JetBrains Mono (Monospace)
- **Hiyerarşi:**
  - Display: 32px (Bold)
  - Headline: 24px (Semi-bold)
  - Title: 18px (Medium)
  - Body: 14px (Regular)
  - Label: 12px (Medium, Caps for metadata)

## 4. Spacing & Radius
- **Base Unit:** 8px
- **Radius:**
  - `sm`: 8px (Input, Chip)
  - `md`: 12px (Standard Card)
  - `lg`: 16px (Large Card, Modal)
  - `full`: 999px (Avatar, Icon Button)

## 5. Navigasyon (Standard 5-Tab)
1. **Ana Sayfa** (home)
2. **Keşfet** (explore)
3. **Paylaş** (add_circle) - Vurgulu
4. **Bildirimler** (notifications)
5. **Profil** (person)

## 6. Flutter Token Map (Taslak)
- `AppColors.surface` -> `Color(0xFF0A0C10)`
- `AppColors.primary` -> `Color(0xFF00F0FF)`
- `AppRadius.card` -> `BorderRadius.circular(12)`
- `AppTextStyles.headline` -> `TextStyle(fontFamily: 'Geist', fontSize: 24, fontWeight: FontWeight.w600)`
