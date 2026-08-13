# `tecnow.app` sitesi

Üç sayfa, bir CSS dosyası, **sıfır bağımlılık**. Derleme adımı yok; dosyalar
olduğu gibi yayınlanır.

| Dosya | İş |
|---|---|
| `index.html` | Tanıtım. Uygulamanın ne olduğu, ne olmadığı. |
| `gizlilik.html` | **Google Play'in zorunlu tuttuğu gizlilik politikası.** |
| `kaynaklar.html` | Kaynak politikası — güven yüzeyi ve SEO. |
| `style.css` | Renkler uygulamanın paletinden birebir alındı. |

Yazı tipi indirilmiyor ve hiçbir üçüncü taraf betiği yok. "Bu site sizi
izlemiyor" diyen bir sayfanın bir CDN'e istek atması kendi cümlesini
çürütürdü.

---

## Bu metin hukuki görüş değil

`gizlilik.html` içindeki her cümle **ölçülmüş teknik gerçeklere** dayanıyor:
hesapsız tasarım, yerel depolama, tek yönlü tek ağ çıkışı, `INTERNET` dışında
izin olmaması, hiçbir reklam/analitik SDK'sının bulunmaması. Yani metin
doğrudur.

Ama **hukuki yeterliliği ayrı bir sorudur.** KVKK ve GDPR açısından sunucu
loglarına düşen IP adresi kişisel veridir; metin bunu dürüstçe yazıyor ancak
sizin sorumluluk ve yükümlülüklerinizi bir hukukçunun değerlendirmesi
gerekir. Yayınlamadan önce okuyun; gerekirse bir hukukçuya okutun.

---

## Yayınlama

### Neden Cloudflare Pages

`tecnow.app` alan adı zaten Cloudflare'de ve **apex alan adı** (kök adres)
orada yerel olarak destekleniyor. GitHub Pages depo başına yalnız **tek**
site veriyor; `tecnow` deposunun Pages sitesi `feed.tecnow.app` olarak
kullanımda, dolayısıyla site için ikinci bir depo ve apex için GitHub IP
adreslerine A kaydı gerekirdi. Cloudflare Pages ikisini de gereksiz kılıyor.

Ücretsiz plan yeterli.

### Adımlar

1. **Cloudflare** → hesabınız → sol menü **Workers & Pages** → **Create** →
   **Pages** → **Upload assets**
2. Proje adı: `tecnow-site`
3. Bu klasördeki **dört dosyayı** (`index.html`, `gizlilik.html`,
   `kaynaklar.html`, `style.css`) sürükleyip bırakın → **Deploy**
4. Dağıtım bitince **Custom domains** → **Set up a custom domain** →
   `tecnow.app` → onaylayın
   *(Cloudflare gerekli DNS kaydını kendisi ekler.)*
5. İsterseniz `www.tecnow.app` için de aynısını yapın

**Nasıl anlarım:** tarayıcıda `https://tecnow.app/gizlilik.html` açılıyor ve
kilit simgesi görünüyor.

> `feed.tecnow.app` kaydına **dokunmayın**. O ayrı bir hizmet ve uygulamanın
> içerik adresi; APK'ya gömülü olduğu için değişmesi geri alınamaz.

### Play Console'a yazılacak adres

```
https://tecnow.app/gizlilik.html
```

---

## `destek@tecnow.app` adresini açın

Her iki sayfa da bu adresi gösteriyor ve **şu an böyle bir kutu yok**.
Çalışmayan bir iletişim adresi, gizlilik politikasının en zayıf yeri olur.

Cloudflare bunu ücretsiz çözüyor:

1. Cloudflare → `tecnow.app` → **Email** → **Email Routing** → etkinleştir
2. **Create address** → `destek@tecnow.app` → hedef: kendi e-posta adresiniz
3. Hedef adrese gelen doğrulama bağlantısını onaylayın

Başka bir adres kullanmak isterseniz iki HTML dosyasında da geçen
`destek@tecnow.app` metnini değiştirmeniz yeterli.

---

## Güncelleme

Dosyaları düzenleyip 3. adımı tekrarlayın (yeni bir dağıtım oluşur).
`gizlilik.html` her değiştiğinde alttaki **"Son güncelleme"** tarihini de
güncelleyin — politikanın ne zaman değiştiği, politikanın kendisi kadar
önemli.

**Politika şu üç durumda mutlaka güncellenmeli:**

1. Asistan yayına girdiğinde (kullanıcı mesajları bir yapay zekâ servisine
   iletilecek)
2. Abonelik eklendiğinde (satın alma doğrulaması)
3. Herhangi bir analitik ya da çökme raporlama aracı eklendiğinde

Üçünde de Play Console'daki **Veri Güvenliği** formu aynı gün değişmeli.
Beyanla gerçeğin ayrışması, Play'in uygulamayı kaldırma sebebidir.
