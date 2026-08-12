# Yol haritası — nerede olduğumuz ve yayına ne kaldığı

Tarama tarihi: **12 Ağustos 2026, 22:00 UTC**
Bu belge tahmin değil, **ölçüm**. Her satırın dayanağı ya bir komut çıktısı ya
bir dosya. Ölçülmeyen bir şey "bilinmiyor" diye yazılı, "çalışıyor" diye değil.

---

## Ölçülen bugünkü durum

| | |
|---|---|
| Dal | `redesign/bundle-home-explore` @ `0727d3b` |
| `master` | `a081966` — **dalın gerisinde**, birleştirme bekliyor (fast-forward) |
| Test | **937**, hepsi yeşil · `flutter analyze` 0 · `dart format` temiz |
| Canlı feed | `feed.tecnow.app/feed.json` · 200 kayıt · son üretim 19:31 UTC |
| Feed dili | **180 `en` / 20 `tr`** — özetleyici anahtarsız, yani çalışmıyor |
| Alan adı | `tecnow.app` Cloudflare'de aktif; **kök adres çözülmüyor** |
| Ayna feed | **404** — `FEED_URL_FALLBACK` bilinçli olarak boş |
| Sürüm | `1.0.2+3` · `applicationId` `com.tecos.app` |
| İmzalama | `key.properties` **yok** → sürüm derlemesi debug anahtarıyla imzalanıyor |
| Asistan | `assistant_screen.dart` 331 satır, **ağ çıkışı yok** — kabuk |
| Abonelik / ödeme | Kod **yok** |
| Gizlilik politikası | **Yok** (metin de, adres de) |
| Play Console | Hesap **yok** |

---

## Yedi faz

### Faz A · İçerik hattı — **%90**

Feed üretiliyor, kendi alan adımızdan yayınlanıyor, uygulama okuyor.

Biten: 18 kaynak · kalite kapısı · kopya birleştirme · güven sinyalleri ·
`ETag`→`304` (0 bayt, 62 ms ölçüldü) · saatlik cron · yayım koruması ·
özet doğrulama kapısı · **çok dilli şema** (D-022).

Eksik:
- [ ] **Türkçe özetler üretilmiyor.** Anahtar (`NVIDIA_API_KEY`) bağlı değil.
      Sağlayıcının canlı yolu 12 Ağustos'ta ilk kez ölçüldü ve **kırıktı**
      (Latin-1 kodlama; beş çağrının beşi düştü). Düzeltildi ve doğrulandı:
      5/5 kabul. Düzeltme **master'da değil**.
- [ ] **Yayım iş akışı kararsız**: son sekiz koşunun ikisi (#96, #99) "Feed
      üret" adımında 255 ile düştü. Kök sebep **bilinmiyor**; yerelde yeniden
      üretilemedi. Hata artık tip + yığın + annotation olarak görünür kılındı.
- [ ] **Ayna yayın yok** (404). Alan adı kaybına karşı yedek adres eksik.

### Faz B · Uygulama (Android) — **%85**

Dokuz rota, 937 test, ölçülmüş tasarım sistemi.

Biten: onboarding · ilgi alanları (sürüklenebilir sekme sırası) · ana akış ·
keşfet · kaydedilenler · okuma geçmişi · detay ekranları · ayarlar · tema ·
yerel veri silme · offline önbellek · **içerik dili tercihi**.

Eksik:
- [ ] **Cihaz doğrulaması — 6 madde ölçülmedi** (`CANLI_FEED_DOGRULAMA.md`):
      ağdan indirme, aşağı çekme, ikinci tazelemede `304`, uçak modu,
      dönüşte toparlanma, aynaya düşme. Telefon ölçüm sırasında bağlantıdan
      düşmüştü.
- [ ] **Arayüz dizeleri gömülü** (40 dosyada ~250 dize). Bilinçli ertelendi:
      tek yönlü kapı değil ve İngilizce feed olmadan İngilizce menünün
      müşterisi yok.

### Faz C · Mağaza hazırlığı — **%0** ← **kritik yol burada**

Hiçbiri başlamadı ve **hepsi yayının önkoşulu**.

- [ ] **Play Console hesabı** — $25 tek seferlik, kimlik doğrulaması günler
      sürebilir
- [ ] **Yayın anahtarı (`.jks`)** — henüz üretilmedi. **Tek yönlü kapı**:
      kaybedilirse uygulama bir daha güncellenemez, yeni bir uygulama olarak
      yayınlanmak zorunda kalır
- [ ] **Gizlilik politikası + yayınlanacak adres** — Play'in zorunlu şartı.
      `tecnow.app` kökü çözülmüyor, yani politikanın konacağı yer de yok
- [ ] **Veri Güvenliği formu** — cevaplar hazır (uygulama veri toplamıyor),
      form doldurulmadı
- [ ] **Mağaza görselleri** — 512 ikon, 1024×500 öne çıkan görsel, ekran
      görüntüleri, açıklama metni
- [ ] **Marka kontrolü** — TÜRKPATENT/TMview'da `TECNO` araması hiç
      yapılmadı. `ALAN_ADI_KARARI.md`'de kayıtlı risk; `applicationId`
      yayından sonra **değiştirilemez**

### Faz D · Kapalı test — **%0**

- [ ] Test kullanıcısı listesi (Play Console'un ekranında yazan sayı geçerli;
      2023 sonrası kişisel hesaplar için 12 kişi / 14 gün kesintisiz)
- [ ] 14 günlük kesintisiz test — sayaç düşerse baştan başlar
- [ ] Geri bildirimlerin işlenmesi

### Faz E · Üretim yayını — **%0**

- [ ] Üretim sürümüne yükseltme başvurusu
- [ ] Google incelemesi

### Faz F · Gelir (asistan) — **%5**

Yalnız arayüz kabuğu var. Ekonomi ve mimari kararlaştırıldı, kod yazılmadı.

- [ ] Cloudflare Worker geçidi (`gateway/`)
- [ ] Kota sayacı (Durable Objects)
- [ ] Play abonelik doğrulaması (servis hesabı + Play Developer API)
- [ ] Asistan ekranının gerçek hâli
- [ ] Model yeterliliği ölçümü (Haiku vs Sonnet)

### Faz G · Web ve çok dillilik — **%15**

Şema tarafı bitti (D-022), yüzey yok.

- [ ] `tecnow.app` statik sitesi (SEO + gizlilik politikası yüzeyi)
- [ ] İngilizce feed (`feed.en.json`) — üretici hazır, koşu yapılmadı
- [ ] Arayüz dizeleri → ARB

---

## Kritik yol

Yayına giden en kısa zincir, **paralel yürüyemeyen** halkalar:

```
Play hesabı (günler)  ─┐
Gizlilik politikası    ├─→ Kapalı test (14 gün) → İnceleme → YAYIN
   ← site gerekiyor    │
Keystore + AAB        ─┘
```

**En uzun bekleme kapalı test: 14 gün.** Ondan önceki her şey birkaç güne
sığar ama **sırayla** olmak zorunda: hesap onaylanmadan uygulama
oluşturulamaz, uygulama olmadan kapalı test açılamaz.

**En riskli halka gizlilik politikası**, çünkü bir siteye bağlı ve site yok.
Bugün başlanırsa kritik yolu uzatmaz; unutulursa kapalı testin sonunda
yayını durdurur.

**En pahalı hata marka.** Kontrol edilmeden yayınlanır ve şikâyet kabul
edilirse, `applicationId` değiştirilemediği için uygulama yükleme sayısı ve
yorumlarıyla birlikte kaybedilir. Kontrol ücretsiz ve bir saatlik iş.

---

## Şu an neredeyiz

**Faz A ve B'nin sonundayız. Faz C hiç başlamadı.**

Teknik taraf yayına hazır olmaya yakın; **mağaza tarafı sıfırda**. Bu, işin
zor kısmının bittiği anlamına gelmiyor — kalan işlerin çoğu kod değil, hesap
açma, belge yazma ve bekleme.

Bugünden yayına en iyimser tahmin: **3–5 hafta**, ve bu tahminin tamamı
Faz C ve D'nin süresidir. Kod tarafı bu sürenin içinde zaten biter.

---

## Kimde ne var

**Sende (kod yazılarak çözülemez):**
1. NVIDIA anahtarını yenile ve Secrets'a yaz — *sohbete yapıştırılan anahtar
   yakıldı, iptal edilmeli*
2. Play Console hesabı aç ($25) ve kimlik doğrula
3. TÜRKPATENT/TMview marka kontrolü
4. Keystore üret ve **repo dışında yedekle** (parolalar sohbete girmez)
5. 12–15 test kullanıcısının Google e-postasını topla
6. Ayna deposunu aç (`tecnow-ayna`)

**Bende:**
1. Master'ı ileri al *(CI yeşile döner dönmez)*
2. Yayım kararsızlığının kök sebebi — bir dahaki kırılmada okunabilir
3. Gizlilik politikası ve abonelik şartları taslakları
4. `tecnow.app` statik sitesi
5. Cihaz doğrulaması (telefon bağlanınca)
6. Mağaza görselleri hariç her şey
