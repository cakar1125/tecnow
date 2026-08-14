# Canlı feed doğrulaması

Ölçüm tarihi: **11–12 Ağustos 2026**
Uç nokta: `https://feed.tecnow.app/feed.json`

Bu belge, feed'in **gerçek adres üzerinden** ölçülen davranışını kaydeder.
Bugüne kadar bütün cihaz testleri paketlenmiş içerikle yapılmıştı; uygulama
uzak adres verilmeden derlendiği için ağ yolunun hiçbir parçası hiç
çalıştırılmamıştı.

> **Güncelleme — 14 Ağustos 2026:** cihaz tarafı ölçüldü. Altı maddenin
> **beşi** gerçek telefonda doğrulandı; altıncısı (aynaya düşme) ayna deposu
> henüz yayın yapmadığı için hâlâ ölçülemedi. Ayrıntı: "Cihaz ölçümü".

---

## Ölçülen sürüm

| | |
|---|---|
| APK | `tecOS-1.0.3-canli.apk` |
| Boyut | 58.559.704 bayt |
| SHA-256 | `01B2ED16FFC1975749055389E0273862CD83C8F4CB3DE7841430BDE753FF8F96` |
| Derleme | `flutter build apk --release --dart-define=FEED_URL=https://feed.tecnow.app/feed.json` |
| `FEED_URL_FALLBACK` | **verilmedi** — o tarihte ayna deposu yoktu. 14 Ağustos ölçümünde verildi, bkz. "Cihaz ölçümü" |

Önceki APK'lar (`tecOS-1.0.2-bundle`, `tecOS-1.0.3-sekmeler`) `--dart-define`
almadan derlenmişti, yani **paketlenmiş içerikle** çalışıyorlardı. Uygulama
bunu gizlemiyordu: durum satırı "İçerik uygulamayla birlikte geliyor" yazıyor
ve tazeleme kontrolünü hiç çizmiyordu. Doğru davranış, ama ağ yolu ölçüsüz
kaldı.

---

## Uç nokta

### Yanıt başlıkları (koşulsuz `GET`)

```
HTTP/2 200
content-type                : application/json; charset=utf-8
content-length              : 193679
etag                        : W/"6a7b8f46-2f48f"
last-modified               : Tue, 11 Aug 2026 21:08:22 GMT
cache-control               : max-age=600
server                      : cloudflare
cf-cache-status             : DYNAMIC
access-control-allow-origin : *
```

### TLS

| | |
|---|---|
| Sertifika konusu | `CN=tecnow.app` |
| Veren | `CN=WE1, O=Google Trust Services, C=US` |
| Geçerlilik | 6 Ağustos 2026 – 4 Kasım 2026 |

Cloudflare Universal SSL, kendi kendini yeniliyor. Uygulama `https` dışını
zaten reddediyor (`openExternalUrl`, `FeedHttpClient`).

### Gecikme

Beş ölçümün ortancası:

| İstek | Süre | Gövde |
|---|---|---|
| Koşulsuz `GET` | **93 ms** | 193.679 bayt |
| Koşullu `GET` (`If-None-Match`) | **62 ms** | **0 bayt** |

İlk istek 3.354 ms — bağlantı kurulumu ve TLS el sıkışması. Sonraki istekler
bağlantıyı yeniden kullanıyor.

`syncing_feed_repository.dart` başlığındaki "~150 ms, 0 bayt gövde" tahmini
artık gerçek adres üzerinde ölçüldü ve **iyimser değil, kötümserdi**: 62 ms.
Saatlik tazeleme kararının dayandığı sayı bu.

### Koşullu istek

| Gönderilen | Yanıt |
|---|---|
| `If-None-Match: W/"6a7b8f46-2f48f"` | **304**, gövdesiz |
| `If-Modified-Since: Tue, 11 Aug 2026 21:08:22 GMT` | **304**, gövdesiz |

Uygulama `If-None-Match` gönderiyor ve `304`'ü gövdesiz işliyor
(`feed_http_client.dart:137`, `:163`). Yani değişmemiş içerik için tazeleme
maliyeti gerçekten sıfır gövde.

---

## Adres topolojisi

| Adres | Sonuç | Yorum |
|---|---|---|
| `feed.tecnow.app/feed.json` | **200** | birincil, canlı |
| `cakar1125.github.io/tecnow/feed.json` | **301** → `feed.tecnow.app/feed.json` | **varsayım doğrulandı** |
| `cakar1125.github.io/tecnow-ayna/feed.json` | **404** | ayna **yok** |
| `tecnow.app` (kök) | DNS çözülmüyor | site yok |

**301 neden önemli:** `CANLIYA_ALMA_ADIMLARI.md` A12 adımı bunu bekliyordu ve
tuttu. Birincil deponun `github.io` adresi özel alan adına yönleniyor, yani
**yedek olarak kullanılamaz**. Ayna deposunun ayrı bir depo olması gerektiğinin
kanıtı bu — tahmin değil, ölçüm.

**Ayna 404:** yedek adres yok. `FEED_URL_FALLBACK` bu yüzden **bilinçli olarak
boş bırakıldı**; 404 dönen bir adresi yedek diye gömmek, failover'ı çalışıyor
sanmaktan beter olurdu.

**`tecnow.app` kökü çözülmüyor:** Play'in zorunlu tuttuğu gizlilik politikası
URL'si için bir yer yok. Kritik yolda ve bekliyor.

---

## Bulgu: Cloudflare JSON'u kenar sunucuda önbelleklemiyor

Bütün ölçümlerde `cf-cache-status: DYNAMIC`. Cloudflare varsayılan önbellek
kuralları statik uzantıları kapsıyor ve `.json` o listede değil; yani proxy
açık (TLS, DDoS koruması çalışıyor) ama her istek GitHub Pages'e kadar gidiyor.

Bugün zararsız: isteklerin çoğu `304` ve gövdesiz. Ama kullanıcı sayısı
artarsa GitHub Pages'in yumuşak bant genişliği sınırına yüklenen taraf bu olur.
Çözümü ücretsiz ve panelden: Cloudflare → Caching → Cache Rules → `/feed.json`
için kısa TTL'li bir kural.

Bu bir **eylem değil gözlem**: değiştirmedim, çünkü Cloudflare hesabı
kullanıcının ve kural yazmak yayın davranışını değiştirir.

---

## Cihaz ölçümü — 14 Ağustos 2026

| | |
|---|---|
| Cihaz | OnePlus 8 Pro (IN2023) · Android 13 · SDK 33 |
| Ağ | Wi-Fi 5 GHz, doğrulanmış |
| APK | `app-release.apk`, 56,1 MB, **debug anahtarıyla** imzalı (yayın anahtarı yok) |
| Derleme | `--dart-define=FEED_URL=https://feed.tecnow.app/feed.json`<br>`--dart-define=FEED_URL_FALLBACK=https://cakar1125.github.io/tecnow-ayna/feed.json` |
| Kurulum | Önceki sürüm **kaldırıldı**, temiz kuruldu — eski şema kalıntısı ölçümü kirletmesin |

### Ölçüm yöntemi

Ekran görüntüsü tek başına yetmez: "tazelendi" yazan bir arayüz, ağa hiç
çıkmadan da aynı şeyi yazabilir. Bu yüzden her adımda uygulamanın **kendi
UID'sine ait bayt sayacı** okundu (`dumpsys netstats`, `BPF map content`,
`uid=10477`). Arayüz ne derse desin, sayaç yalan söylemiyor.

Referans değer: açılıştaki tam indirme **41.572 bayt**.

### Sonuçlar

| # | Ölçüm | Sonuç | Kanıt |
|---|---|---|---|
| 1 | Gerçekten ağdan indiriyor | ✅ | Ekrandaki ilk kayıt canlı feed'de var, paketlenmişte yok |
| 2 | Aşağı çekme gerçek istek yapıyor | ✅ | +4.406 bayt indi, +1.077 bayt gitti |
| 3 | İkinci tazeleme `304` alıyor | ✅ | Tam indirmenin **onda biri** — gövde inmedi |
| 4 | Uçak modu: önbellek + dürüst hata | ✅ | Sayaç **hiç artmadı**; durum satırı hatayı yazdı |
| 5 | Dönüşte kendiliğinden toparlanma | ✅ | Uygulama yeniden başlatılmadan `304` deseni geri geldi |
| 6 | Ayna adresine düşme | ✅ | Birincil `NXDOMAIN` iken **43.366 bayt** indi; içerik aynada var, pakette yok |

**1 · Ağdan indirme.** Paketlenmiş feed 28 Temmuz tarihli. Ekrandaki ilk
kayıt (`Grok 4.6 is now available in GitHub Copilot`) canlı `feed.json`'da
iki kez geçiyor, paketlenmiş dosyada **hiç** geçmiyor. Aynı ölçüm TLS'i ve
gerçek DNS çözümünü de kanıtlıyor: istemci `https` dışını reddediyor,
dolayısıyla içerik ekrana geldiyse sertifika doğrulanmış demektir.

**3 · Koşullu istek.** 4,4 KB'lik hareket TLS el sıkışması ve başlıklardan
ibaret. Gövde inseydi sayaç ~41 KB artardı.

**4 · Uçak modu.** İki ayrı durum ölçüldü ve ikisi de doğru çıktı:

- *Soğuk açılış:* içerik 15 dakikadan taze olduğu için uygulama ağa **hiç
  çıkmadı** ve hata da göstermedi. Gösterse yanlış olurdu — başarısız olan
  bir şey yok.
- *Elle tazeleme:* sayaç hiç artmadı (45.978 → 45.978) ve durum satırı
  şunu yazdı:

  > Güncellenemedi · 1 dakika önce alınan içerik gösteriliyor

  Hata gizlenmedi, içerik de kaybolmadı.

**6 · Aynaya düşme.** Telefonda tek bir alan adını engellemek root ister,
bu yüzden ağ değil **kod yolu** ölçüldü: birincili çözülmeyen bir adrese
(`feed-yok-test.tecnow.app`, doğrulandı `NXDOMAIN`), yedeği gerçek aynaya
bağlayan ayrı bir APK derlendi. Bu, yedeğin var olma sebebi olan senaryonun
birebir aynısı — alan adının kaybı.

Ölçüm:

| | |
|---|---|
| Birincil | `feed-yok-test.tecnow.app` → `NXDOMAIN` |
| İndirilen | **43.366 bayt** — tam feed, yani önbellek değil |
| İçerik | `Grok 4.6…` kaydı aynada **var**, paketlenmiş feed'de **yok** |

Uygulama birincili denedi, çözemedi, yedeğe düştü ve içeriği oradan aldı.
Ölçümden sonra doğru adresleri taşıyan APK yeniden derlenip kuruldu.

### Ayna kurulumunda çıkan iki tuzak

İkisi de belgelerde yoktu ve ikisi de **sessizce** başarısız oluyordu:

1. **GitHub yeni depoda iş akışını indekslemiyor.** `tecnow-ayna`'ya kod
   gitti, dosya doğru yerdeydi (`raw` `200`), varsayılan dal `master`'dı —
   ama `Feed yayımla` API'de `Not Found` döndü ve Actions listesinde
   görünmedi. Başka dosyaları değiştiren iki push ve bir `schedule`
   tetiklemesi işe yaramadı. **Çözüm:** iş akışı dosyasının kendisini
   değiştiren bir push. Dosyaya bir yorum eklemek anında kaydettirdi.

2. **`github-pages` ortamı yanlış dala kilitli açılıyor.** Pages "GitHub
   Actions" moduna alındığında GitHub ortamı hesabın varsayılan dal adıyla
   (`main`) oluşturdu, oysa deponun dalı `master`. Sonuç:
   `Branch "master" is not allowed to deploy to github-pages`.
   **Çözüm:** Settings → Environments → `github-pages` → Deployment
   branches → `main` yerine `master`.

Kurulum doğrulaması, bu yüzden, "ayarları yaptım"la bitmez:

```bash
curl -s .../actions/workflows/publish-feed.yml | grep '"state"'          # active
curl -s .../environments/github-pages/deployment-branch-policies         # master
```
