# TeknoAkış Master Design System

Sürüm: Faz 0 handoff  
Kaynaklar: paket içindeki beş `DESIGN.md`, onaylı Stitch HTML/PNG çiftleri ve ürün kuralları.

## Marka ve temel ilkeler

- Marka adı her yerde **TeknoAkış**; eski DevPulse/TECH_SYNC adları kullanılamaz.
- Koyu tema ana deneyimdir. Temel yüzey `#0A0C10`.
- Electric Cyan ana eylem/aktif durum rengidir. Mor yalnızca AI özellikleri ve model bağlamında kullanılır.
- Teknik estetik okunabilirliğin önüne geçmez. Normal butonlar ve uzun metinler monospace değildir.
- Stitch HTML/Tailwind yalnızca görsel referanstır; Flutter üretim koduna kopyalanmaz.

## Flutter token eşlemesi

### AppColors

| Token | Değer | Kullanım |
|---|---|---|
| `background` | `#0A0C10` | Ana arka plan |
| `surface` | `#11151B` | Kart ve yükseltilmiş yüzey |
| `surfaceHigh` | `#181D25` | Modal/bottom sheet |
| `outline` | `#2B3440` | Sınır ve ayırıcı |
| `primary` | `#00F0FF` | Electric Cyan, ana eylem |
| `aiAccent` | `#A855F7` | Yalnızca AI bağlamı |
| `textPrimary` | `#F7FAFC` | Ana metin |
| `textSecondary` | `#94A3B8` | Yardımcı metin |
| `success` | `#10B981` | Başarı + ikon/metin |
| `warning` | `#F59E0B` | Uyarı + ikon/metin |
| `critical` | `#EF4444` | Kritik/hata + ikon/metin |

Durumlar yalnız renkle anlatılmaz; ikon, etiket veya açıklama eşlik eder. Metin ve yüzey kombinasyonları WCAG kontrast kontrolünden geçirilir.

### AppSpacing

`xs=4`, `sm=8`, `md=12`, `lg=16`, `xl=24`, `xxl=32`, `xxxl=48` mantıksal piksel.

### AppRadius

`small=8`, `card=12`, `large=16`, `featured=24`, `pill=999`.

### AppTypography

- UI ailesi: Geist bulunursa Geist, aksi halde paketlenmiş Inter.
- Teknik metadata: JetBrains Mono.
- Display 32/38, headline 24/30, title 18/24, body 14/21, label 12/16.
- Dinamik metin ölçeği engellenmez; kritik yerleşimler en az 1.3× ölçekle test edilir.

### AppShadows

- `none`: düz yüzey.
- `card`: siyah %24, blur 16, y 6.
- `cyanGlow`: primary %18, blur 20; yalnız odak/öne çıkan alanlarda.
- Gölgeler sınır ve kontrastın yerine geçmez.

### AppDurations

`instant=0ms`, `fast=120ms`, `normal=200ms`, `slow=320ms`. Reduce-motion tercihinde dekoratif animasyonlar kapatılır veya `instant` kullanılır.

### AppBreakpoints

- `compactMin=360`, `reference=390`, `comfortable=430`.
- Ana referans viewport 390×844; zorunlu doğrulamalar 360×800, 390×844, 430×932.
- İçerik yatay taşmaz; safe area ve en az 44×44 dokunma alanı zorunludur.

## Theme ve component kuralları

`AppTheme.dark` Material 3 temeli kullanır fakat color scheme, typography, input, chip, navigation ve dialog stilleri bu tokenlardan türetilir. Ekran dosyalarında literal renk, spacing veya radius dağıtılmaz.

İlk ortak component kataloğu: `AppScaffold`, `AppTopBar`, `AppBackTopBar`, `AppBottomNavigation`, üç buton varyantı, `AppTextField`, `AppSearchField`, `AppFilterChip`, badge/avatar/action bileşenleri, `TechnologyCard`, `RepositoryCard`, `AIModelCard`, empty/error/loading state'leri, bottom sheet ve confirmation dialog.

## Erişilebilirlik

- Türkçe semantics label ve tooltip kullanılır.
- Geri, kapat, kaydet, paylaş ve navigasyon ikonları erişilebilir ad taşır.
- 44×44 altındaki görsel ikonlara geniş hit target verilir.
- Hata ve başarı mesajları screen reader canlı bölgesinde duyurulur.
- Metin kesilmez; gerektiğinde wrap veya kaydırma kullanılır.

