# Proje Durumu

> **Bu bir 3 Ağustos 2026 anlık görüntüsüdür ve güncel değildir.** Belge
> 12 Ağustos'ta olduğu gibi depoya alındı; içeriği **düzeltilmedi**, çünkü
> bir durum kaydını sonradan yeniden yazmak onu kayıt olmaktan çıkarır.
>
> O tarihten sonra değişenler ve nerede kayıtlı oldukları:
>
> | Ne | Nerede |
> |---|---|
> | Ürün adı `Tecnow/TecNow` → **`tecOS`**, `applicationId` → `com.tecos.app` | `DECISION_LOG.md` D-019 |
> | Ana Sayfa ve Keşfet yeniden kuruldu; konudan kurulan sıralanabilir sekmeler | `DECISION_LOG.md` D-020 |
> | Tazelik: saatlik üretim, 15 dk istemci aralığı, aralık `feed.json`'da | `DECISION_LOG.md` D-021 |
> | Barındırma **canlıya alındı**: `feed.tecnow.app` yayında | `CANLI_FEED_DOGRULAMA.md` |
> | Açık/koyu tema, `AppPalette` | D-020 |
> | Test sayısı 781 → **896** | D-020 |
>
> Aşağıdaki "AWAITING_HOSTING_DECISION" durum kodu bu yüzden artık geçerli
> değil: barındırma kararı verildi ve uygulandı.

Güncelleme: 3 Ağustos 2026 (özet taşıma + NVIDIA sağlayıcısı — D-015)

> **Flutter kaynağının yolu değişti:** `C:\YEDEKK\OLD_DESTOP\stitch_techpulse_social (14)`
> (eskiden Masaüstü). Dal `master`. Git, taşınma sonrası `safe.directory`
> kaydı gerektirdi — ayrıntı `START_HERE.md`.

## Durum kodu

`PHASE_02A_COMPLETE / PHASE_02B_COMPLETE / PHASE_03_APP_SIDE_COMPLETE /
AWAITING_HOSTING_DECISION`

Faz 3'ün uygulama tarafı bitti: içerik hattı kuruldu, uygulama gerçek içeriği
okuyor, ağ katmanı ve çevrimdışı önbellek hazır. **Kalan tek şey barındırma**
(TASK-0017) ve o bir insan kararı — uygulama bugün paketlenmiş içerikle eksiksiz
çalışıyor, uzak adres verildiği anda tazelenmeye başlar.

**Ürün adı karara bağlandı: Tecnow** (6 Ağustos, D-017). Yeniden adlandırma
aynı gün uygulandı — `applicationId = "com.tecnow.app"`, Dart paketi `tecnow`,
105 dosya. Rename penceresi mağaza yayınıyla kapanıyordu ve **kapanmadan önce**
kullanıldı. Ayrıntı ve uzantı gerekçesi:
[ALAN_ADI_KARARI.md](ALAN_ADI_KARARI.md).

**Barındırmayı bekleyen tek insan kararı kaldı:**

1. **Alan adı satın alma** (`tecnow.app`, Cloudflare Registrar) ve GitHub
   deposu — 15 adımlık rehberli oturum `docs/CANLIYA_ALMA_ADIMLARI.md`'de.
   Sepette **fiyat kontrol edilmeli**: kısa adlar kayıt defterinde premium
   olabiliyor.

**D-014 (1 Ağustos):** arayüz **12 ekranın tamamında** yeniden tasarlanacak —
navigasyon 5→4 sekme (Asistan kalır, Ayarlar sağ üst dişliye), vurgu **cyan
korunur**, tasarımın vaat ettiği içerik hattı (arXiv/`paper`, "Why it matters",
metrik rozetleri, günlük derleme) arayüzle birlikte gelir. Tahmin ~14-20
oturum. **Barındırmadan sonra** — içerik hattı, iş akışının gerçekten koştuğu
görülmeden test edilemez.

**D-012 (29 Temmuz, `46cc189`):** feed **kayıt seviyesinde ileri uyumlu**
yapıldı. Ölçüldü: 200 kayıttan tek birine bilinmeyen bir `kind` yazmak eski
kodda 200'ünü birden düşürüyordu — yani bir sonraki sürümde yeni içerik türü
eklemek, güncellemeyen her kullanıcıyı akıştan koparacaktı. Bu pencere ilk
sürümle kapandığı için barındırmadan önce kapatıldı. **D-013:** sıralama
içeriği `lmarena-ai/leaderboard-dataset` (CC-BY-4.0) kaynağından, ayrı bir
içerik türü olarak gelecek — Faz 2.

**D-010 (29 Temmuz):** cihazda saklananlar üç kaleme indirildi — kaydedilen
gönderiler · ilgi alanları · asistan **özeti**. Ölçüm, haber yığılmasının zaten
imkânsız olduğunu gösterdi (`feed_cache` tek satır, `CHECK (id = 1)`); tek kod
değişikliği okuma geçmişi tavanının 500→50 inmesi oldu. **D-011:** asistan
ücretli abonelik olacak (Faz 4); hesapsızlık Play Billing jetonuyla korunuyor.

## Tamamlananlar

- Stitch tasarım temizliği ve dokuz aktif ekranın onayı.
- Eski Flutter Faz 1 uygulaması ve 25 Temmuz'daki fiziksel kabul — **eski sosyal kabuk için**.
- **Faz 2A ekran çalışması bitti (TASK-0001 … TASK-0006):** kabuk + beş sekmenin tamamı
  onaylı tasarıma göre uygulandı.
- **Emülatörde uçtan uca doğrulandı** (`TeknoAkis_API35_Pixel7`).
  Kanıt: `docs/device_validation/EMULATOR_TEST_LOG.md`.
- **Faz 2A fiziksel cihazda kabul edildi (PHASE-02A-99).** OnePlus 8 Pro / Android 13 /
  **360 dp** — `QUALITY_GATES.md` içindeki en dar kırılım noktası. Temiz kurulum, uçtan uca
  gezinti, iki turlu logcat taraması. Kanıt:
  `<flutter-kök>/docs/device_validation/phase-02a/DEVICE_TEST_LOG.md` + 24 ekran görüntüsü.
- **Faz 2B başladı:** yerel veri katmanı temeli (TASK-0008) tamamlandı.

## Cihaz kabulünün bulduğu ve düzeltilen kusurlar

Üçü de kod incelemesiyle değil **çalıştırarak** bulundu; 79 test yeşilken görünmüyorlardı.

| # | Kusur | Düzeltme |
|---|---|---|
| K-1 | Alt navigasyonda `Kaydedilenler` kelime ortasından iki satıra bölünüyordu (360 **ve** 390 dp) | `AppTypography.navLabel` (11sp / `-0.3`) — etiket adı D-005 ile sabit olduğu için kısaltılamazdı |
| K-2 | SnackBar koyu temanın üstünde beyaz bant olarak çıkıyordu (üç ekranı birden etkiliyordu) | `AppTheme.dark` içine `snackBarTheme` |
| K-3 | Onboarding 3/3 metni pivot öncesi "sosyal kartları" ifadesini taşıyordu | "geliştirici araçlarını" |

K-1 ölçümü: `Kaydedilenler` 12sp Inter ile **79.8 dp** yer ister; beş bölmeli navigasyonda
360 dp ekranda bir bölme **72 dp**'dir. O günkü taşma kapısı bunu göremiyordu çünkü
metin sarmalaması bir taşma istisnası üretmez. Yeni `bottom_navigation_test.dart` etiket
yüksekliğini doğrudan ölçer ve **düzeltme geri alındığında düştüğü doğrulandı**.

> `shell_responsive_test.dart` 28 Temmuz'da kaldırıldı; yerine
> `responsive_overflow_test.dart` geldi (`4a46612`). Eskisi aynı anda üç
> yerden kördü: varsayılan yazı tipi, tek yazı ölçeği (1.0) ve yalnız kabuk
> sekmeleri. Yenisi gerçek yazı tipi yüklüyor, **her** rotayı geziyor ve üç
> genişliği dört yazı ölçeğiyle çarpıyor (180 durum). Kırmızı olabildiği
> doğrulandı: `_Fact` düzeltmesi geri alındığında bilinen koşulu (360 dp /
> 1.6) tek tek işaretledi ve ölçülmemiş bir koşulu daha buldu — **430 dp /
> 2.0**. Dar ekran her zaman en kötü durum değil: 360'ta metin sarıp sığıyor,
> 430'da tek satırda kalıp taşıyor.

## Aktif uygulama kabuğu (uygulandı)

| # | Sekme | Route | Ekran | Durum |
|---|---|---|---|---|
| 0 | Ana Sayfa | `/home` | `FeedScreen` | ✅ Onaylı tasarım — 4 filtreleyen sekme, `NE İŞE YARAR?` kutuları |
| 1 | Keşfet | `/explore` | `ExploreScreen` | ✅ Onaylı tasarım — gerçek arama, 5 filtre, `NEDEN EŞLEŞTİ?` kutuları |
| 2 | Asistan | `/assistant` | `AssistantScreen` | ✅ Giriş tasarımı — **AI bağlantısı yok**, açıkça belirtiliyor |
| 3 | Kaydedilenler | `/saved` | `SavedScreen` | ✅ Süzgeç çipleri modelden türetiliyor; eşleşemeyen çip çizilmiyor, `Duyurular` eklendi (`4a46612`) |
| 4 | Ayarlar | `/settings` | `SettingsScreen` | ✅ Dört bölüm; ölü satırlar kapatıldı, dördü gerçek ekrana bağlandı (`017884d`) |

Shell dışı: `/splash`, `/onboarding/:step`, `/interests`, `/icerik/:id`,
`/hakkinda`, `/kaynak-politikasi`, `/okuma-gecmisi`.

`/repository/:id` ve `/ai-model/:id` **kaldırıldı** (`3a544f4`): tür → rota
eşlemesi çağıran ekranda yaşıyordu ve eşlemede yeri olmayan türler hiçbir
yere gitmiyordu. Tek rota kaldı; başlık, vurgu ve geçmiş türü kaydın
kendisinden türüyor.

Son üç rota 28 Temmuz'da eklendi. `ACTIVE_SCREEN_MAP.md` 28 Temmuz'da
güncellendi: onaylı ekranlar ile **onayı olmayan dört ekran** (`/splash`,
`/okuma-gecmisi`, `/hakkinda`, `/kaynak-politikasi`) artık ayrı tablolarda
duruyor ve onay beklediği yazılı (bkz. `NEXT_ACTION.md`).

Aynı güncellemede haritanın **var olmayan iki rota** vaat ettiği bulundu:
`/repository/:id` ve `/ai-model/:id` `3a544f4` ile kaldırılmıştı ve harita
düzeltilmemişti.

`/create-post`, `/notifications`, `/profile` aktif route'lardan kaldırıldı; dosyalar
`lib/legacy/` altında `LEGACY_NOT_ACTIVE` olarak korunuyor.

## Ölçülen kalite (28 Temmuz, Claude tarafından çalıştırıldı)

```
dart format --output=none --set-exit-if-changed lib test tool   exit 0
flutter analyze                                                 exit 0   No issues found!
flutter test                                                    exit 0   752/752 (11 sn)
flutter build apk --debug                                       exit 0
flutter build apk --debug --dart-define=FEED_URL=https://…      exit 0
```

### Cihaz kabulü — 28 Temmuz (OnePlus 8 Pro, Android 13, **360 dp**)

Tam kayıt: [device_validation/phase-03/DEVICE_TEST_LOG_2026-07-28.md](device_validation/phase-03/DEVICE_TEST_LOG_2026-07-28.md)

İki oturumda cihazda **üç kusur bulundu ve düzeltildi**:

1. "Sana Özel" sekmesi, ilgi alanı seçen her kullanıcı için kalıcı olarak
   boştu (`9e6bcc4`).
2. Ayarlar'daki **on bir satırın dokuzu** hiçbir yere gitmiyordu: hepsinde
   `>` oku vardı, dokunulunca "sonraki fazda uygulanacak" diyorlardı
   (`017884d`).
3. Ayarlar'daki adetler açılışta bir kez kurulup bir daha güncellenmiyordu:
   iki içerik okunduktan sonra `read_history` iki satır tutarken ekran hâlâ
   **"0 kayıt"** diyordu (`017884d`).

Cihazda doğrulananlar: şema v1→v3 taşıması (ilgi alanları korundu) ·
kaydetmenin gerçekten yazması ve force-stop sonrası durması · duyuruların
detay ekranında açılması · "AI Araçları" çipinin dolu gelmesi · aksansız
Türkçe aramanın eşleşmesi · okuma geçmişinin tekilleşmesi · "Kaynağa git"
düğmesinin Chrome'u açması · **`Verileri Sil` uçtan uca** (bütün tablolar
boşaldı, onboarding bayrağı kalktı, şema 3'te kaldı, indeksler korundu,
yeniden açılışta kurulum soruldu) · dört yeni ekranın gerçek veriyle
çalışması · lisans sayfasının Türkçe ve tam ekran açılması. Logcat'te
`FATAL`/`ANR`/`RenderFlex` yok.

**Yazı ölçeği (A4)** kullanıcı tarafından elle doğrulandı: sistem yazı tipi
en büyüğe alındığında kartlar büyüyor, ekran dışına taşma yok.

Cihazda hâlâ **ölçülemeyen**: ağ yolu (TLS, gerçek DNS, uçak modu, CDN
önbelleği) — barındırma canlıya alınmadan ölçülemez — ve yatay yönlendirme
(aynı `settings put` engeli).

Faz 2A kapanışında ayrıca fiziksel cihazda: `adb install` Success, iki turlu
`logcat FATAL/ANR/E-flutter/RenderFlex` taraması 0 eşleşme (o gün 104/104).

TASK-0016'nın manifest değişikliği **birleştirilmiş manifest okunarak**
doğrulandı: `android.permission.INTERNET` ve `usesCleartextTraffic="false"`
derleme çıktısında var.

Test sayısı: 19 → 44 → 60 → 79 → 104 → 163 → 218 → 222 → 260 → 300 → 356 →
382 → 387 → 406 → 417 → 450 → 466 → 485 → 518 → 533 → 708 → 721 → 738 → **752**.
Hiçbir test silinmedi, susturulmadı veya gevşetilmedi.

İki test **kaldırılmadı ama tersine çevrildi** (`017884d`): biri sürüm
satırındaki `[DESIGN_FIXTURE_ONLY]` yer tutucusunu, diğeri "okuma geçmişi
liste ekranı yok" mesajını kilitliyordu. İkisi de kusurun **kendisini**
doğruluyordu; yerlerine yeni davranışı ölçen testler geldi.

Kilitler geri alınarak doğrulanıyor — bir düzeltmenin testi, düzeltme geçici
olarak kaldırıldığında **düşmüyorsa** kilit değil süstür. TASK-0016'da altı
kilit böyle sınandı: https zorunluluğu, yönlendirmede şema düşüşü, en yeni
kopya kuralı, etkin feed kuralı, sahte affordance kapısı, eşzamanlı tazeleme
kapısı. TASK-0020/0021'de üçü daha: kaydetmenin yazması (yazma devre dışı
bırakılınca iki test düştü), Türkçe arama katlaması (katlama kapatılınca
altı test düştü), detay tarih satırı (eski hâline döndürülünce 360 dp / 1.6
ölçekte gerçek yazı tipiyle düştü).

Ortam: Flutter 3.44.8 · Dart 3.12.2 · Android SDK 36 · Codex CLI 0.145.0.

## Git

Branch `phase-02a-shell-migration`. `master`'a dokunulmadı, push yapılmadı.

| Commit | İçerik |
|---|---|
| `a4eab0f` | Kabuk ve router dönüşümü |
| `a0f7667` | Kaydedilenler |
| `4204289` | Ayarlar |
| `ff27b04` | Proje Asistanı |
| `0845039` | Ana Sayfa |
| `2aff8d8` | Keşfet |
| `1ba8d02` | Sekme etiketi monospace kural ihlali düzeltmesi |
| `27f627d` | Arama alanındaki sahte filtre ikonunun kaldırılması |
| `aee184e` | Faz 2B yerel veri temeli (sqflite, şema v1, depolar) |
| `7eb49cc` | `LoadingSkeleton` timer sızıntısı düzeltmesi |
| `2e36b67` | **Cihaz kabulü düzeltmeleri** — navigasyon etiketi, SnackBar teması, onboarding metni |
| `0265754` | **Kaydedilenler kalıcılığı (TASK-0009-R)** — açılışta tohumlama, `AsyncNotifier`, sqflite |
| `fa04267` | **İlgi alanları taşıması + onboarding bayrağı + okuma geçmişi (TASK-0010)** |
| `6696832` | **`Verileri Sil` gerçek + kayıt sayıları (TASK-0011)** — Faz 2B kapanışı |
| `3b323d6` `86efee4` | Feed sözleşmesi + AI özet doğrulama kapısı (TASK-0012) |
| `490ea96` | Kaynak allowlist'i + kopya birleştirme (TASK-0013a) |
| `7d21abb` | GitHub / Hugging Face / RSS-Atom bağlayıcıları (TASK-0013b) |
| `862f0b3` | **Gerçek API yanıtlarıyla doğrulama** — 3 kusur düzeltildi |
| `7790e2d` `645ceaf` `5798bfe` | Üretici CLI, kalite kapısı, Türkçe özet katmanı (TASK-0014) |
| `46306be` `f3d8f0f` | **Uygulama gerçek içeriği okuyor**, köken dürüst işaretleniyor (TASK-0015) |
| `4825111` | Faz 3 kapsam denetimi — 4 boşluk kapatıldı |
| `0da08e5` | **Ağ katmanı + offline cache + şema v2 + son senkronizasyon (TASK-0016a)** |
| `bd0395f` | **Güncellik satırı + aşağı çekerek tazeleme (TASK-0016b)** |
| `1ffea75` | TASK-0016 kapsam denetimi — 1 çökme yolu düzeltildi |
| `ee6c0e6` | **Depolama disiplini + küratörlü kaynaklar (TASK-0018)** — gzip önbellek, geçmiş budama, VACUUM, 10 doğrulanmış besleme, tür dengesi |
| `3a544f4` | **Detay ekranları gerçek kayda bağlandı (TASK-0019)** + ölü hata durumu düzeltmesi |
| `b7bdcff` | **Keşfet gerçek feed'de, kaydetme gerçek, tek detay rotası (TASK-0020/0021/0022)** — sahte yer imi düğmesi, fixture tohumlaması ve duyuruların kapalı kapısı kaldırıldı |
| `055d919` | **Barındırma hattı (TASK-0017)** — yayım koruması, GitHub Actions zamanlayıcısı, `tool` türü için gerçek kaynak |
| `9e6bcc4` | **"Sana Özel" boştu (TASK-0023)** — ilgi alanı sözlüğü, etiket→kimlik taşıması. **Cihazda bulundu** |
| `017884d` | **Ayarlar'ın dokuz ölü satırı (TASK-0024)** — 4 gerçek ekran (Okuma Geçmişi, Hakkında, Kaynak Politikası, Lisanslar), 5 satır dürüst "Yakında", bayat adetler türetildi, gerçek sürüm, Türkçe yerelleştirme. **Cihazda bulundu** |
| `507806e` | **Koşullu istek + çip kayması (TASK-0025)** — şema v4 (`ETag`/`Last-Modified`), 304 yolu, gerçek sunucularda ölçüldü; `AppFilterChip.stableWidth`. **Cihazda bulundu** |
| `576e3d7` | **Taşma kapısı kendi kendini koruyor (TASK-0027)** — rota listesi yönlendiriciden doğrulanıyor; ilk koşuda `/splash`in hiç ölçülmediğini buldu |
| `4a46612` | **Kör taşma kapısı + iki ölü kontrol (TASK-0026)** — `responsive_overflow_test.dart` (180 durum, gerçek font, tüm rotalar), Ayarlar→İlgi Alanları geri dönüşü, Kaydedilenler süzgeç modeli `lib/ui/saved_filter.dart` |
| `6c9a91c` | Test dosyası sahip olmadığı kapsamı iddia ediyordu — `android_platform_test.dart` / `legacy_screens_test.dart` ayrımı |
| `e688738` | **44 dp dokunma alanı kuralı yazılıydı, hiç ölçülmüyordu (TASK-0028)** — Ana Sayfa'nın dört sekmesi 39 dp'ydi; `touch_target_test.dart` her rotayı dokunuş sınamasıyla geziyor, çizilen tasarım değişmedi |

## Veri durumu

İçerik **artık gerçek**. `assets/feed/feed.json` (193.589 bayt ≈ **189 KB**,
**200 kayıt**, dosyada adı geçen **14 kaynak**; dosya okunarak sayıldı,
28 Temmuz)
derleme zamanında `tool/feed/generate.dart` ile üretiliyor; her kayıtta orijinal
adres, kaynak türü, yayın tarihi, son kontrol zamanı ve güven sinyalleri var.
Anahtarsız üretildiği için özetler kaynağın kendi dilinde ve kartta dil rozeti
gösteriliyor; Tecnow'ın kendi ürettiği özetler mor `TECNOW ÖZETİ`
rozetiyle ayrılıyor.

**Aktif ekranların hiçbiri artık fixture okumuyor** (28 Temmuz). Keşfet de
gerçek feed'e bağlandı: arama, "NEDEN EŞLEŞTİ?" gerekçesi ve "Popüler"
bölümü kayıtların kendisinden geliyor.

Kaydedilenler'in açılış tohumlaması **kaldırıldı**. Uygulama artık
kullanıcının kaydetmediği hiçbir şeyi listeye koymuyor, dolayısıyla `Örnek
kayıt` rozeti de kalmadı. Tohumlanmış cihazlarda o üç satır açılışta bir kez
siliniyor (`SavedItemsSampleCleanup`); kullanıcının kendi kaydettiğine
dokunulmuyor.

`lib/fixtures/fixtures.dart` yalnız ilgi alanı listesi ve tasarım referansı
olarak duruyor.

### Kaynaklar (TASK-0018 · TASK-0017, 28 Temmuz)

**13 küratörlü RSS/Atom beslemesi** (`officialFeeds`, sayıldı 28 Temmuz) +
GitHub arama / GitHub sürümleri / Hugging Face API bağlayıcıları. Hepsi listeye
alınırken canlı denendi ve **gerçekten kayıt verdiği** ölçüldü — durum kodu ya
da geçerli XML ölçüt sayılmıyor. Denenip elenenler ve sebepleri
`tool/feed/source_allowlist.dart` içinde tablo hâlinde duruyor.

**Listede olmak, yayımlanan dosyada olmak demek değil.** Üretilen feed 200
kayıtta sabit ve tarihe göre kesiliyor; yavaş yayın yapan bir kaynak
pencerenin dışında kalabiliyor. Ölçüldü (28 Temmuz): dosyada 13 küratörlü
kaynağın **12'si** görünüyor, `web.dev` hiç görünmüyor. Bağlayıcı kusuru
**değil** — `web.dev` beslemesi canlı ve 10 kayıt veriyor, ama en yeni yazısı
29 Mayıs ve dosyadaki duyuru penceresi 8 Haziran'da başlıyor. Kaynak listeden
çıkarılmadı: daha sık yayın yaptığında kendiliğinden girer.

Yapay zekâ: OpenAI · Google AI · Google DeepMind · Mistral AI
Çatı/altyapı: PyTorch · NVIDIA · AWS Makine Öğrenmesi
Platform: GitHub Blog · GitHub Değişiklikler · Android Geliştirici ·
Chrome Geliştirici · web.dev · Visual Studio Code
API: GitHub arama (MCP · skill · **AI araçları**) · GitHub sürümleri ·
Hugging Face modelleri

Feed 200 kayıtta sabit ve **tür başına taban** ayrılıyor: saf tarih
sıralaması "AI Modelleri" sekmesini 4 kayda düşürmüştü. 28 Temmuz canlı
koşusunda tür dağılımı: duyuru 121 · AI modeli 20 · MCP 20 · skill 20 ·
araç 19.

`tool` türü 28 Temmuz'a kadar **hiçbir bağlayıcıdan gelmiyordu** ve
Keşfet'in "AI Araçları" çipi her zaman boş sonuç veriyordu. `topic:ai-tools
stars:>200` araması ve depoların kendi beyan ettiği konulardan okunan bir
sınıflandırma eklendi.

### Cihazda ne kadar yer kaplıyor (ölçüldü 28 Temmuz)

| | Boyut |
|---|---|
| Paketlenmiş feed (APK içinde, silinemez) | 189,0 KB |
| İndirilen kopya (önbellek, gzip) | **30,5 KB** |
| Okuma geçmişi (500 kayıt tavanı) | ~30 KB |

Önbellek tek satır: yeni kopya eskisinin **yerine** geçer, birikmez.
`Verileri Sil` sonrası `VACUUM` çalışıyor, yani dosya gerçekten küçülüyor.

### Ağ ve çevrimdışı (TASK-0016)

- Uzak adres derleme zamanı yapılandırması: `--dart-define=FEED_URL=https://…`
  ve `--dart-define=FEED_URL_FALLBACK=https://…`. **Varsayılanı yok** —
  barındırma kararı verilmeden bir adres gömmek, olmayan bir sunucuya istek
  atan bir uygulama demek olurdu.
- **Yedek adres (29 Temmuz, `4461790`).** Adresler sırayla denenir; birincil
  ağ hatası, `2xx` dışı yanıt ya da bozuk gövde verdiğinde yedeğe geçilir.
  Gerekçe: kendi alan adımız barındırıcı değişimini çözüyor ama alan adının
  **kaybını** çözmüyor — o durumda yayın yapılacak yer kalmadığı için yeni
  adres duyurulamaz. Yedek bu yüzden bağımsız bir kökende olmalı; özel alan
  adı tanımlıyken birincil deponun `github.io` adresi o alan adına
  yönlendirildiği için yedek olamaz.
  - Önbellek failover'da **atılmaz**: ölçüt "tanınan adreslerden biri", yoksa
    elde sağlam kopya varken paketlenmiş eski dosyaya düşülürdü.
  - Doğrulayıcılar (`ETag`/`Last-Modified`) yalnız **kendilerini üreten**
    adrese gider; aynaya gönderilen bir `ETag` gövdesiz bir `304` üretip
    başka bir yayının kopyasını geçerli saydırabilirdi.
- Adres yokken: uygulama paketlenmiş içerikle eksiksiz çalışır, aşağı çekerek
  tazeleme kontrolü **hiç çizilmez**, durum satırı "İçerik uygulamayla birlikte
  geliyor" der. Tarih vaat edilmez.
- Adres varken: açılışta yalnız içerik bayatsa (12 saat) bir kez denenir,
  kullanıcı ayrıca aşağı çekerek tazeleyebilir. Başarılı çekim `feed_cache`
  tablosuna yazılır; ağ hatası gösterilen içeriği **değiştirmez**.
- Hangi kopyanın gösterileceği tek kural: **üretim tarihi en yeni olan**.
  Uygulama güncellendiğinde paketlenmiş dosya eski önbellekten yeni olabilir.
- Yalnız `https`; yönlendirmeler elle çözülüyor ve şema düşüşü reddediliyor.
- Yerel veritabanı şeması **v4** (`lib/data/local/schema.dart` okundu,
  28 Temmuz). v2 rakamı TASK-0016 döneminden kalmıştı; v3 okuma geçmişi, v4
  ise `ETag`/`Last-Modified` sütunlarını ekledi. Kurulum migration'ları
  oynatarak ilerliyor, sıfırdan kurulan ve yükseltilen şemanın aynı olduğu
  testle doğrulanıyor.

Fiziksel cihazda doğrulanan kalıcılık davranışı:

- **Kaydedilenler kalıcı** (TASK-0009-R) — silinen kayıt yeniden açılışta geri gelmiyor;
  kullanıcı hepsini silerse fixture'lar geri getirilmiyor.
- **İlgi alanları sqflite'ta** (TASK-0010) — `shared_preferences`'tan taşındı, eski
  anahtar taşıma sonrası siliniyor.
- **Onboarding bir kez** (TASK-0010) — tamamlandı bayrağı yazılıyor, splash okuyor;
  yeniden açılış doğrudan akışa gidiyor.
- **Okuma geçmişi yazılıyor** (TASK-0010) — detay ekranı açılınca `read_history`'ye
  satır düşüyor. Ayarlar adedi gösteriyor. **Liste ekranı 28 Temmuz'da
  eklendi** (`/okuma-gecmisi`, `017884d`): "onaysız ekran uydurmama" gerekçesi
  geçerliliğini yitirmişti, çünkü sonucu sayıyı gösterip hiçbir yere gitmeyen
  **çalışmayan bir satır** olmuştu. Ekran onay bekliyor.
- **`Verileri Sil` gerçek** (TASK-0011) — bütün tabloları birden boşaltıyor, onboarding
  bayrağını sıfırlıyor, adetleri yeniliyor. Tohumlama bayrağı bilinçli olarak
  korunuyor: fixture'lar geri gelmiyor, kullanıcının silme kararı geçerli kalıyor.
  TASK-0016'dan sonra feed önbelleği de siliniyor — içerik kişisel veri değil ama
  satır **ne zaman senkronize edildiğini** taşıyor.

Cihaz veritabanı çekilip okunarak doğrulandı — silmeden önce
`interests` 3 · `read_history` 1 · `saved_items` 5; silmeden sonra **her tablo 0**.

### Barındırma (TASK-0017, 28 Temmuz)

Karar verildi: **GitHub Pages + Actions cron**.

Yazılan ve testli olan: yayım koruması (`tool/feed/publish_guard.dart`,
15 test), zamanlayıcı (`.github/workflows/publish-feed.yml`), yayım sayfası,
işletme belgesi (`docs/FEED_HOSTING_RUNBOOK.md`).

**Çalıştırılmayan:** iş akışı GitHub'da hiç koşmadı. Yerel depoda uzak adres
yok (`git remote -v` boş) ve bu makinede `gh` kurulu değil; depo açma, Pages
açma ve `FEED_URL` değişkenini tanımlama adımları runbook'ta yazılı olarak
bırakıldı.

Koruma neyi engelliyor: üretici tek kaynak okunabildiği sürece dosya yazar
(doğru karar), ama 13 kaynağın 12'si düştüğünde çıkan 15 kayıtlık dosya
yayımdaki 200 kayıtlık dosyanın üzerine yazmamalı. Boş feed, eski damga ve
%40'tan fazla kayıp reddediliyor; koşu kırmızıya dönüyor ve **yayımdaki
dosya olduğu gibi kalıyor**.

## Sonraki adımlar

Uygulama tarafında kapatılmamış bir kusur kalmadı. Sırada iki şey var ve
ikisi de insan eylemi gerektiriyor:

1. **Cihaz testi** — `docs/DEVICE_TEST_PLAN_2026-07-28.md`. Bu oturumda
   yazılan hiçbir şey fiziksel cihazda denenmedi.
2. **Barındırmayı canlıya alma** — `docs/FEED_HOSTING_RUNBOOK.md` adımları.

Faz 4 (asistan) ayrı bir karar: para ve barındırma ister, anahtar uygulamaya
asla gömülmez. Ayrıntı ve açık maddeler: `docs/NEXT_ACTION.md`.

## Bilinen boşluklar

- Alt navigasyon etiketi büyük sistem yazı ölçeğinde (1.3) yine sarmalanıyor; yapısal çözüm
  içeriğe göre genişleyen bir alt bar. Ölçüm ve kilit `bottom_navigation_test.dart` içinde.
- Yatay yönlendirme fiziksel cihazda **ölçülemedi**: OnePlus `settings put` ve `wm size`
  komutlarını adb kabuğundan engelliyor.
- Sekme ekranlarında iki düzen deseni bir arada (`CustomScrollView`+`SliverAppBar` ve
  `Column`+`AppTopBar`) — işlevsel sorun yok, birleştirme ertelendi.
- `lib/legacy/` altındaki üç ekran hiçbir rotadan açılmıyor ama testleri
  duruyor (`test/legacy/legacy_screens_test.dart`, başlığında bunu söylüyor).
  Klasörün tamamen silinip silinmeyeceği açık bir kullanıcı kararı.
- `golden_toolkit 0.15.0` discontinued — yeni `bottom_navigation_test.dart` de gerçek font
  yüklemek için bu pakete bağlı.
- ~~Tam `dart format .` exit 0 vermiyor, `flutter clean` onay bekliyor.~~
  **Kapandı** (28 Temmuz): sebep bozuk önbellek değil, kapının yanlış
  yazılmasıymış. `dart format .` Gradle'ın `build/` altındaki geçici
  dizinlerini tarıyor ve onlar listeleme sırasında kayboluyor
  (`PathNotFoundException`) — `flutter clean` bunu kalıcı çözmez, dizinler ilk
  derlemede geri gelir. Derleme çıktısını biçimlendirmenin zaten anlamı yok.
  Kapı `dart format lib test tool` olarak düzeltildi; `flutter clean` onayına
  **gerek kalmadı**.
- Kod ve doküman kökleri ayrı (kullanıcı kararı: olduğu gibi bırak).
