# Canlıya alma — adım adım

Bu belge tek oturumda takip edilmek için yazıldı. Her adımın sonunda
**"nasıl anlarım"** satırı var; orası tutmuyorsa sonraki adıma geçme.

`<KULLANICI>` = GitHub kullanıcı adın · `<ALANADI>` = aldığın alan adı
(örnek: `teknoakis.com`)

## Claude'un hazırladıkları (bitti)

- `master` dalı 43 commit'lik çalışmayı taşıyor (fast-forward birleştirme).
  **Bu şarttı:** GitHub zamanlanmış iş akışlarını yalnız varsayılan dalda
  çalıştırır ve `master` daha önce ne uygulamayı ne iş akışını içeriyordu.
- Kapılar `master` üzerinde geçiyor: `format` 0 · `analyze` 0 · 752/752.
- İş akışı, yedek adres desteği ve CNAME adımı yazılı ve testli.

Kalan adımların hepsi **senin hesabınla** yapılacak işler: `gh` kurulu değil,
ortamda GitHub jetonu yok ve kimlik yöneticisi tarayıcıdan soruyor.

---

## 1 · Alan adı al

Herhangi bir kayıt şirketi olur (~10–15 USD/yıl). **Cloudflare Registrar'dan
almanı öneririm** — DNS zaten orada olur ve 5. adımı tamamen atlarsın.

> Alan adın zaten varsa bu adımı atla.

**Nasıl anlarım:** alan adı hesabında görünüyor.

## 2 · GitHub deposunu aç

1. <https://github.com/new>
2. **Repository name:** `teknoakis`
3. **Public** seç — Pages ücretsiz hesapta yalnız public depolarda çalışır
4. "Add a README" / `.gitignore` / lisans **işaretleme** — içerik zaten var
5. **Create repository**

**Nasıl anlarım:** boş depo sayfası açılır ve sana `git remote add…` komutunu
gösterir.

## 3 · Kodu gönder

Git Bash'te (tek tek yapıştır):

```bash
cd "C:/Users/user/Desktop/stitch_techpulse_social (14)"
git remote add origin https://github.com/<KULLANICI>/teknoakis.git
git push -u origin master
```

İlk push'ta tarayıcıda GitHub girişi açılır — beklenen davranış, izin ver.

**Nasıl anlarım:** depo sayfasını yenile, `mobile/`, `docs/` ve `.github/`
klasörleri görünür.

## 4 · Pages'i aç

Depo → **Settings** → sol menüde **Pages** → *Build and deployment* →
**Source: GitHub Actions**

Klasik "Deploy from a branch" **seçme**; iş akışı `deploy-pages` kullanıyor.
Kaydet düğmesi yok, seçim anında geçerli olur.

**Nasıl anlarım:** kutuda "GitHub Actions" yazıyor.

## 5 · İlk koşuyu çalıştır

Depo → **Actions** sekmesi → sol listede **Feed yayımla** → sağda
**Run workflow** → dal `master` → yeşil **Run workflow**.

Koşu 3–5 dakika sürer (Flutter kurulumu + 16 kaynaktan derleme).

**Nasıl anlarım:** koşunun yanında yeşil tik. Sonra tarayıcıda aç:

```
https://<KULLANICI>.github.io/teknoakis/feed.json
```

JSON görünmeli. Görünmüyorsa Pages henüz yayına almamıştır, birkaç dakika
bekle.

> Buraya kadar her şey `github.io` üzerinde. Sonraki adımlar kendi alan adına
> geçiriyor. **Bu noktada APK derlemek yok** — `github.io` adresi APK'ya
> gömülürse kalıcı olur.

## 6 · Alan adını Cloudflare'e ekle

> Alan adını Cloudflare'den aldıysan bu adımı atla.

1. <https://dash.cloudflare.com> → **Add a site** → alan adını yaz
2. **Free** planı seç
3. Cloudflare sana iki nameserver verir
4. Kayıt şirketinin panelinde alan adının nameserver'larını bunlarla değiştir

Yayılması 5 dakika–24 saat sürebilir.

**Nasıl anlarım:** Cloudflare'de alan adının durumu **Active**.

## 7 · DNS kaydı — **gri bulut**

Cloudflare → **DNS** → **Records** → **Add record**

| Alan | Değer |
|---|---|
| Type | `CNAME` |
| Name | `feed` |
| Target | `<KULLANICI>.github.io` |
| Proxy status | **DNS only** (gri bulut) |

**Turuncu bulutu şimdi açma.** GitHub'ın sertifika verebilmesi için
doğrulamanın doğrudan GitHub'a ulaşması gerekir. Proxy baştan açık olursa
sertifika alınamaz ve uygulama `https` dışını reddettiği için feed hiç
okunamaz — üstelik sessizce, çünkü uygulama paketlenmiş içerikle çalışmaya
devam eder.

**Nasıl anlarım:** kayıt listede, bulut simgesi **gri**.

## 8 · GitHub'a alan adını tanıt

Depo → Settings → Pages → **Custom domain** → `feed.<ALANADI>` → **Save**

GitHub bir DNS kontrolü yapar (birkaç dakika). Ardından **Enforce HTTPS**
kutusu tıklanabilir hâle gelir — **işaretle**. Sertifika sağlanması
dakikalar, bazen 1 saat sürer.

**Nasıl anlarım:**

```bash
curl -I https://feed.<ALANADI>/feed.json
```

`HTTP/2 200` dönmeli. `SSL certificate problem` diyorsa sertifika henüz
hazır değil, bekle.

## 9 · Cloudflare proxy'sini aç

1. Cloudflare → DNS → `feed` kaydı → **Edit** → Proxy status:
   **Proxied** (turuncu bulut) → Save
2. Cloudflare → **SSL/TLS** → Overview → **Full (strict)**

**Nasıl anlarım:**

```bash
curl -I https://feed.<ALANADI>/feed.json
```

Yine `200`, ve başlıklarda `server: cloudflare` görünür.

## 10 · Depo değişkenlerini yaz

Depo → Settings → **Secrets and variables** → **Actions** → **Variables**
sekmesi → **New repository variable** (iki kez):

| Ad | Değer |
|---|---|
| `FEED_DOMAIN` | `feed.<ALANADI>` |
| `FEED_URL` | `https://feed.<ALANADI>/feed.json` |

`FEED_URL` olmadan yayım koruması her koşuda "ilk yayım" sanar ve çöken bir
feed'i durduramaz.

Sonra Actions → Feed yayımla → **Run workflow** (tekrar).

**Nasıl anlarım:** koşu çıktısında `CNAME yazıldı: feed.<ALANADI>` notu var.

## 11 · Ayna deposunu kur

Yedek adres, alan adının kaybına karşı. Ayna **ayrı bir depo** olmalı ve
**özel alan adı verilmemeli.**

1. <https://github.com/new> → `teknoakis-ayna` → **Public** → Create
2. Git Bash:

```bash
cd "C:/Users/user/Desktop/stitch_techpulse_social (14)"
git remote add ayna https://github.com/<KULLANICI>/teknoakis-ayna.git
git push ayna master
```

3. Ayna depo → Settings → Pages → Source: **GitHub Actions**
4. Ayna depo → Settings → Variables → `FEED_URL` =
   `https://<KULLANICI>.github.io/teknoakis-ayna/feed.json`
   **`FEED_DOMAIN` ekleme** — aynada CNAME yazılmamalı
5. Ayna depo → Actions → **Run workflow**

**Nasıl anlarım:**

```
https://<KULLANICI>.github.io/teknoakis-ayna/feed.json
```

JSON dönüyor.

## 12 · Yedeğin gerçekten bağımsız olduğunu ölç

```bash
curl -I https://<KULLANICI>.github.io/teknoakis/feed.json
```

**`301` bekleniyor** — birincil deponun `github.io` adresi özel alan adına
yönleniyor demektir, yani yedek olarak kullanılamaz. Ayna deposunun ayrı
olmasının sebebi tam olarak bu.

`200` dönerse bana söyle: varsayımım yanlış çıkmış olur ve yedek
yapılandırmasını gözden geçiririm.

---

## 13 · Bana haber ver

Bu noktadan sonrası bende. Yapacaklarım:

- Sürüm APK'sını **iki adresle** derlemek
- Bugüne kadar hiç ölçülemeyen beş şeyi ölçmek: TLS, gerçek DNS, uçak modu
  geçişi, CDN önbellek gecikmesi ve koşullu isteğin (`ETag` → `304`) kendi
  hattımızda çalışması
- Failover'ı cihazda denemek: birincil adresi engelleyip uygulamanın aynaya
  düştüğünü görmek
- Kanıtları `docs/device_validation/` altına yazmak

Bana şunları ver: `<KULLANICI>`, `<ALANADI>` ve 12. adımın çıktısı.

---

## Bir şey ters giderse

| Belirti | Sebep | Ne yapmalı |
|---|---|---|
| Actions'ta hiç koşu yok | Varsayılan dal yanlış | Settings → Branches → Default branch = `master` |
| `curl` SSL hatası veriyor | Sertifika hazır değil ya da proxy erken açıldı | Cloudflare'de gri buluta dön, sertifikayı bekle, sonra aç |
| Koşu kırmızı, "kayıt sayısı çöktü" | Yayım koruması durdurdu | Doğru davranış — yayımdaki dosya korundu, kaynaklara bak |
| `feed.json` 404 | Pages henüz dağıtmadı | Birkaç dakika bekle, Actions'ta deploy adımına bak |
| Ayna koşusu CNAME yazıyor | Aynada `FEED_DOMAIN` tanımlı | Ayna deposundan o değişkeni sil |

İşletme notları (zamanlayıcının 60 günde kapanması, çıkış kodları, maliyet):
[FEED_HOSTING_RUNBOOK.md](FEED_HOSTING_RUNBOOK.md).
