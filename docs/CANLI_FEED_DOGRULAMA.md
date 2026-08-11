# Canlı feed doğrulaması

Ölçüm tarihi: **11–12 Ağustos 2026**
Uç nokta: `https://feed.tecnow.app/feed.json`

Bu belge, feed'in **gerçek adres üzerinden** ölçülen davranışını kaydeder.
Bugüne kadar bütün cihaz testleri paketlenmiş içerikle yapılmıştı; uygulama
uzak adres verilmeden derlendiği için ağ yolunun hiçbir parçası hiç
çalıştırılmamıştı.

> **Bu belge yarım.** Uç nokta tarafı ölçüldü; **cihaz tarafı ölçülmedi** —
> telefon ölçüm sırasında bağlantıdan düştü. Eksik kalanlar aşağıda
> "Ölçülmeyenler" başlığında tek tek yazılı ve hiçbiri "çalışıyor" diye
> kaydedilmedi.

---

## Ölçülen sürüm

| | |
|---|---|
| APK | `tecOS-1.0.3-canli.apk` |
| Boyut | 58.559.704 bayt |
| SHA-256 | `01B2ED16FFC1975749055389E0273862CD83C8F4CB3DE7841430BDE753FF8F96` |
| Derleme | `flutter build apk --release --dart-define=FEED_URL=https://feed.tecnow.app/feed.json` |
| `FEED_URL_FALLBACK` | **verilmedi** — ayna deposu henüz yok (aşağıya bakın) |

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

## Ölçülmeyenler

Telefon ölçüm sırasında bağlantıdan düştü. Bunların **hiçbiri** doğrulanmış
sayılmaz:

- [ ] Uygulamanın gerçekten ağdan indirmesi (durum satırının "Son güncelleme"ye
      dönmesi)
- [ ] Aşağı çekme jestinin gerçek bir tazeleme yapması
- [ ] İkinci tazelemenin `304` alması (cihaz tarafında)
- [ ] Uçak modu: içeriğin önbellekten gelmesi, durum satırının hatayı söylemesi
- [ ] Uçak modundan dönüşte kendiliğinden toparlanma
- [ ] Ayna adresine düşme (ayna yokken zaten ölçülemez)

Yapılacak: telefon bağlandığında `tecOS-1.0.3-canli.apk` kurulur, `pm clear`
ile temiz başlangıç yapılır ve yukarıdaki altı madde tek tek ölçülür.
