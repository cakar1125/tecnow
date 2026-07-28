# Faz 2A — Fiziksel Cihaz Kabulü

- Tarih: 2026-07-27
- Görev: PHASE-02A-99 (Faz 2A kapanışı)
- Yürüten: Claude Code
- Sonuç: **GEÇTİ** — üç kusur bulundu, üçü de düzeltildi ve cihazda yeniden doğrulandı

Bu, 25 Temmuz'daki kabulün tekrarı **değildir**. O kabul eski sosyal kabuğa aitti
(`../screenshots/` altında `create_post`, `notifications`, `profile` ekranları görünür).
Bu belge yeni ürün yönünün ilk fiziksel cihaz kabulüdür.

---

## 1. Cihaz

| Alan | Değer |
|---|---|
| Model | OnePlus 8 Pro (`IN2023`) |
| Seri | `c5226e6b` |
| Android | 13 (SDK 33) |
| ABI | `arm64-v8a` |
| Ekran | 1440 × 3168 fiziksel |
| Yoğunluk | 480 dpi fiziksel, **640 dpi geçersiz kılma** |
| **Mantıksal genişlik** | **360 dp** |

360 dp, `QUALITY_GATES.md` içindeki en dar kırılım noktasıdır — kabul, en zorlu
genişlikte yapılmış oldu.

## 2. Derleme ve kurulum

```
flutter build apk --debug        exit 0
APK      build/app/outputs/flutter-apk/app-debug.apk   182.12 MB
sha256   26BF39D3...A487027B     (commit 7eb49cc üzerinden derlendi)
```

Cihazda `com.teknoakis.app` sürüm 1.0.2 (25 Temmuz 22:57, eski sosyal kabuk) kuruluydu.
**Kaldırılıp temiz kuruldu** — `install -r` eski `shared_preferences` verisini taşır ve
25 Temmuz'un ilgi alanı seçimleri kabulü kirletirdi.

> OnePlus `pm clear`'ı kabuktan engelliyor
> (`SecurityException: … CLEAR_APP_USER_DATA`). Temiz veri için kaldır-yeniden kur
> yolu kullanıldı.

## 3. Taranan akış

Temiz kurulumdan sonra uçtan uca: açılış → onboarding 1/2/3 → ilgi alanları →
akış → beş sekmenin tamamı → Ayarlar alt bölümleri → Verileri Sil onayı →
Verileri Dışa Aktar → Kaydı Kaldır → uygulama yeniden başlatma → kalıcılık kontrolü.

| Ekran | Sonuç | Kanıt |
|---|---|---|
| Açılış + onboarding 1–3 | ✅ | `01`–`03` |
| İlgi Alanları (temiz) | ✅ `0/3 seçildi`, buton pasif | `04` |
| İlgi Alanları (seçili) | ✅ `3/3`, buton aktif | `05` |
| Ana Sayfa | ✅ | `06`, `07` |
| Keşfet | ✅ | `08` |
| Asistan | ✅ | `09` |
| Kaydedilenler | ✅ | `10` |
| Ayarlar (4 bölüm) | ✅ | `11`–`13` |
| Verileri Sil onayı | ✅ dürüst SnackBar | `14`, `15` |
| Verileri Dışa Aktar | ✅ "sonraki fazda uygulanacak" | `16` |
| Kaydı Kaldır | ✅ dürüst SnackBar | `17` |

### Doğrulanan dürüstlük davranışları

Sahte affordance bulunmadı. Üç kontrolün üçü de ne yaptığını doğru söylüyor:

- `Verileri Sil` → *"Silinecek yerel veri henüz yok. Yerel veri katmanı Faz 2B."*
- `Verileri Dışa Aktar` → *"Bu ekran sonraki fazda uygulanacak."*
- `Kaydı Kaldır` → *"Kaydı kaldırma yalnız yerel fixture etkileşimidir."*

Sürüm satırı `[DESIGN_FIXTURE_ONLY]` olarak görünüyor; gizlilik metni
*"TeknoAkış hesap veya sosyal profil oluşturmaz."* diyor.

## 4. Bulunan kusurlar

Üçü de **çalıştırarak** bulundu; 79 test yeşilken hiçbiri görünmüyordu.

### K-1 — Alt navigasyon etiketi kelime ortasından bölünüyor (düzeltildi)

`Kaydedilenler`, `Kaydedilenl` / `er` biçiminde iki satıra taşıyordu.

Ölçüm (gerçek Inter, 12sp w600, `RenderParagraph`):

| Genişlik | Bölme | "Kaydedilenler" gereken | Sonuç |
|---|---|---|---|
| 360 dp | 72.0 dp | 79.8 dp | 2 satır ❌ |
| 390 dp | 78.0 dp | 79.8 dp | 2 satır ❌ |
| 430 dp | 86.0 dp | 79.8 dp | 1 satır ✅ |

Kusur yalnız bu cihazda değil, **360 ve 390 dp'nin tamamında** vardı.

Etiket adları `DECISION_LOG.md` D-005 ve `CLAUDE.md` ile sabitlendiği için
kısaltma seçenek değildi. `AppTypography.navLabel` eklendi (11sp,
`letterSpacing -0.3` → 69.2 dp). Ölçülen aday stiller:

```
font=12.0  ls= 0.0  -> 79.8  SIGMAZ
font=11.0  ls= 0.0  -> 73.1  SIGMAZ
font=11.0  ls=-0.3  -> 69.2  SIGAR   <- secildi
font=10.5  ls=-0.2  -> 67.2  SIGAR
```

**Neden mevcut testler yakalamadı:** `shell_responsive_test.dart` yalnız
`takeException(), isNull` kontrol ediyor. Metin sarmalaması bir taşma
istisnası üretmez, sessizce ikinci satıra iner.

### K-2 — SnackBar koyu temada beyaz bant (düzeltildi)

`AppTheme.dark` içinde `snackBarTheme` tanımlı değildi; Material'in açık zeminli
varsayılanı devreye giriyordu. Uygulamanın tek bildirim biçimi olduğu için üç
ekranı birden etkiliyordu. `surfaceHigh` zemin + `body` metin token'ına bağlandı.

### K-3 — Onboarding metninde pivot öncesi ifade (düzeltildi)

3/3 sayfası *"Repository, yapay zekâ modeli ve **sosyal kartları** birlikte incele."*
diyordu. Ürün sosyal ağdan çıktı; `geliştirici araçlarını` ile değiştirildi.

## 5. Düzeltme sonrası doğrulama

```
flutter analyze              exit 0   No issues found!
flutter test                 exit 0   84/84   (79 -> 84)
flutter build apk --debug    exit 0
```

Yeni test `mobile/test/design_system/bottom_navigation_test.dart` etiket
yüksekliğini 360/390/430 dp'de doğrudan ölçer. **Düzeltme geçici olarak geri
alınıp testin düştüğü doğrulandı** (360 ve 390'da `yükseklik 32.0, tek satır 16.0`),
yani gerçek bir regresyon kilidi.

Cihazda yeniden derlenip kuruldu ve doğrulandı: `22` (tek satır navigasyon),
`23` (koyu SnackBar), `24` (düzeltilmiş metin), `25` (beş sekme son tur).

## 6. Logcat

| Tur | Dosya | Sonuç |
|---|---|---|
| Düzeltme öncesi | `logs/device_app.log` (9833 satır) | kritik bulgu yok |
| Düzeltme sonrası | `logs/device_app_fixed.log` (3200 satır) | kritik bulgu yok |

Aranan desenler: `FATAL EXCEPTION`, `ANR in`, `E/flutter`, `RenderFlex`,
`overflowed`, `Failed assertion`.

Uygulama sürecinden çıkan 18 E/W satırının tamamı satıcı gürültüsüdür
(`SchedAssist`, `ColorX_Check`, `OplusBracketLog`, `libc` property erişimi) veya
Flutter motorunun Android 13'te `android.window.BackEvent` gizli API'sine takılmasıdır
(`hiddenapi: … denied`). Hiçbiri uygulama kodundan kaynaklanmaz ve hiçbiri ölümcül değildir.

## 7. Doğrulanan bilinen borç

**Kaydedilenler kalıcı değil.** `Kaydı Kaldır` ile silinen kayıt, uygulama yeniden
başlatılınca geri geldi (`17` → `18`/`20`). Bu beklenen durumdur ve TASK-0009-R'nin
konusudur; yeni bir bulgu değildir.

**İlgi alanları kalıcı.** Yeniden başlatmadan sonra `3/3 seçildi` korundu (`19`) —
`shared_preferences` katmanının çalıştığının kanıtı.

## 8. Ölçülemeyenler (dürüst kayıt)

- **Yatay yönlendirme.** OnePlus, `settings put` (`WRITE_SETTINGS`) ve `wm size`
  (`WRITE_SECURE_SETTINGS`) komutlarını kabuktan engelliyor. Programatik çevirme
  yapılamadı; cihazda hiçbir ayar değiştirilmedi. Yatay, Faz 2A kapısı değildir;
  gerekirse emülatörde ölçülebilir.
- **Büyük sistem yazı tipi ölçeği.** `navLabel` düzeltmesi varsayılan ölçekte
  geçerlidir. Material `NavigationBar` metin ölçeğini 1.3'e kadar uygular; 1.3'te
  "Kaydedilenler" yeniden sarmalanır. Beş bölmeli eşit genişlikli bir navigasyon
  360 dp'de bu etiketi erişilebilir ölçeklerde barındıramaz — yapısal çözüm,
  onaylı tasarımdaki gibi **içeriğe göre genişleyen** bir alt bar olur.
  `KNOWN_LIMITATIONS.md` içine yazıldı.

## 9. Sonuç

Faz 2A ekran çalışması fiziksel cihazda kabul edildi. Beş sekme onaylı tasarıma
göre çalışıyor, çökme/ANR/taşma yok, sahte affordance yok, fixture içerik dürüst
işaretlenmiş.
