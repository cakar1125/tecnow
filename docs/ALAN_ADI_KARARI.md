# Alan adı kararı — uzantı ve ad adayları

Güncelleme: 6 Ağustos 2026 · Durum: **karara bağlandı → `tecnow.app`** (D-017)

Bu dosya var çünkü aday listesi ve müsaitlik ölçümü daha önce **yalnız sohbette**
duruyordu ve sohbet sıkıştırıldığında kayboldu. Kararı kilitleyen bir bilgi
diskte durmalı.

---

## 0 · Karar

**Ad: Tecnow · Alan adı: `tecnow.app`**

| Uzantı | Durum | Not |
|---|---|---|
| `tecnow.com` | **dolu** | 1999'dan beri kayıtlı (GoDaddy), transfer/güncelleme kilitli, 2030'a kadar ödenmiş, 114 baytlık park sayfası — düşmesi beklenmemeli |
| `tecnow.net` | boş | |
| **`tecnow.app`** | **boş → alınacak** | seçilen |
| `tecnow.dev` | boş | |

Yeniden adlandırma 6 Ağustos'ta uygulandı (105 dosya, `com.tecnow.app`);
gerekçe ve ölçümler [DECISION_LOG.md](DECISION_LOG.md) → D-017.

> **Kayda geçmiş risk — TECNO markası.** TECNO, Transsion Holdings'in akıllı
> telefon markası ve Türkiye dahil satışta. "Tecnow" ondan tek harf uzakta ve
> **aynı sektörde**. Google Play'in marka şikâyeti yolu var; kabul edilen bir
> şikâyet uygulamanın kaldırılmasıyla sonuçlanabiliyor. Bu bir hukuk görüşü
> değil. Alan adını almadan ve mağaza kaydını açmadan önce **TÜRKPATENT** ve
> **EUIPO/WIPO** marka aramasıyla teyit edilmesi öneriliyor.

Aşağıdaki bölümler kararın nasıl verildiğini saklıyor.

---

## 1 · Müsaitlik ölçümü

Yöntem: RDAP sorgusu — HTTP 404 = kayıtlı değil, 200 = kayıtlı.
Kayıt defterlerinin kendi uçları kullanıldı (`rdap.org` 302 döndürüyor):

- `.com` / `.net` → `rdap.verisign.com`
- `.app` → `www.registry.google`

Tümü **6 Ağustos 2026'da aynı anda** ölçüldü.

| Ad | `.com` | `.net` | `.app` |
|---|---|---|---|
| teknoakis | dolu | **boş** | **boş** |
| pusula | dolu | dolu | **boş** |
| nabiz | dolu | dolu | **boş** |
| odak | dolu | dolu | **boş** |
| menzil | dolu | dolu | **boş** |
| frekans | dolu | dolu | **boş** |
| devre | dolu | dolu | **boş** |
| ritim | dolu | dolu | **boş** |
| rota | dolu | dolu | **boş** |
| prizma | dolu | dolu | **boş** |
| mecra | dolu | dolu | **boş** |
| kunye | dolu | dolu | **boş** |
| kerte | dolu | **boş** | **boş** |
| anten | dolu | dolu | **boş** |

**Toplam: `.com` 0/14 boş · `.net` 2/14 boş · `.app` 14/14 boş.**

> **RDAP fiyatı göstermez.** "Boş", "standart fiyat" demek değildir. Kayıt
> defterleri kısa sözlük kelimelerini **premium** fiyatlayabiliyor (yıllık yüzlerce
> dolar). `odak`, `rota`, `ritim`, `anten` gibi tek kelimeler bu riski taşıyor;
> `teknoakis` gibi birleşik bir ad taşımıyor. Gerçek fiyat Cloudflare'in satın
> alma ekranında görünür — **sepette fiyatı gör, sonra onayla.**

---

## 2 · `.net` mi `.app` mi

Ölçüm soruyu büyük ölçüde kendisi cevaplıyor: 14 adayın **12'sinde `.net` diye
bir seçenek yok.** Karar yalnız `teknoakis` ve `kerte` için gerçek bir tercih.

### `.app` lehine

**Play Store zaten bir web adresi istiyor.** Gizlilik politikası bağlantısı
yayın için **zorunlu**; mağaza kaydındaki "Web sitesi" alanı da aynı adrese
bakar. Uzantının insana görünen tek işi bu ve `.app` "bu bir mobil uygulama"
sinyalini doğrudan veriyor.

**Tüm `.app` uzantısı tarayıcı tarafında HSTS ön yüklemeli.** Google Registry
şart koştuğu için tarayıcılar `.app` altındaki her adresi HTTPS-zorunlu kabul
ediyor; düz metin bir sayfa yayınlamak *mümkün değil*. Yanlışlıkla kapatılabilen
bir ayar değil, uzantının kuralı.

### Ama bu bizim uygulamamız için ekstra bir şey getirmiyor — ölçüldü

Kolay yapılacak abartı bu, o yüzden açıkça yazıyorum: **HSTS ön yükleme listesi
tarayıcıların listesidir; Dart'ın HTTP istemcisi ona bakmaz.** Flutter
uygulamasının feed isteğini `.app` uzantısı korumuyor. Onu bizim kodumuz zaten
koruyor, iki katmanda:

| Yer | Kural |
|---|---|
| `feed_endpoint.dart:55` | `if (url.scheme != 'https') return null;` — `https` olmayan adres **hiç kabul edilmiyor** |
| `feed_http_client.dart:92` | yönlendirme `https` → `http`'ye düşerse istek **reddediliyor** (yükselme serbest) |

Yani `.app`'in güvenlik kazancı **gerçek ama dar**: tarayıcı yüzeyini (açılış
sayfası, gizlilik politikası, adresi tarayıcıya yapıştıran biri) kapsıyor,
uygulamanın kendi trafiğini değil. Uygulama tarafı uzantıdan bağımsız olarak
zaten kapalı.

### `.net` lehine

Türkiye'de daha tanıdık; yıllık birkaç dolar daha ucuz (ikisi de Cloudflare'de
maliyetine satılıyor). Bazı eski bağlantı ayrıştırıcıları `.app`'i otomatik
bağlantıya çevirmiyor — küçük ama gerçek bir sürtünme.

Zayıf yanı: `.net` "`.com` doluydu" diye okunuyor. Bu bizim durumumuzda **kelimesi
kelimesine doğru** ama zayıf bir sinyal.

---

## 3 · Tavsiye

**`.app`.**

Gerekçe sırayla: (1) 14 adayın 12'sinde `.net` seçenek bile değil, yani `.net`'i
seçmek adayları ikiye düşürüyor — uzantı, adı seçmemeli; (2) uzantının insana
görünen tek işi mağaza kaydı ve gizlilik politikası bağlantısı, orada `.app`
kasıtlı görünüyor; (3) tarayıcı yüzeyinde HTTPS'i uzantı garanti ediyor.

Güvenlik "`.app` daha güvenli" diye bir gerekçe **değil** — yukarıda ölçüldüğü
gibi uygulama tarafında fark yok.

---

## 4 · Karar verildiğinde ne olacak — durum

Ad seçimi **mağaza yayınıyla birlikte kapanan bir kapı**: `applicationId`
yayından sonra değiştirilemiyor — değiştirmek Play'de **yeni bir uygulama**
demek, yükleme sayısı ve yorumlar taşınmıyor. Kapı henüz açıktı ve kullanıldı.

| # | İş | Durum |
|---|---|---|
| 1 | Alan adı alınır (sepette fiyat kontrol edilir — premium olabilir) | ⬜ **senin hesabınla** |
| 2 | `applicationId` ve paket adı yeni ada göre güncellenir | ✅ 6 Ağustos, 105 dosya |
| 3 | `FEED_DOMAIN` / `FEED_URL` değişkenleri buna göre kurulur | ⬜ barındırma adım 7 |
| 4 | Karar ve tarih kaydedilir (`DECISION_LOG.md` → D-017) | ✅ |
