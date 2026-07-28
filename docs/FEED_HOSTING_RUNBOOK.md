# Feed barındırma — kurulum ve işletme

Karar: **GitHub Pages + Actions cron** (28 Temmuz 2026).

Bu belge iki şeyi ayırır: **hazır olan** (kod, iş akışı, koruma) ve
**yapılması gereken** (depo açmak, Pages'i açmak, adresi uygulamaya vermek).
İkincisi bir GitHub hesabı gerektirdiği için burada yazılı adımlarla
bırakıldı; hiçbiri tahmin değil, hepsi tek tek yapılabilir.

---

## Şu an ne hazır

| Parça | Durum |
|---|---|
| Üretici (`tool/feed/generate.dart`) | ✅ çalışıyor, 13 küratörlü kaynak |
| Yayım koruması (`tool/feed/publish_guard.dart`) | ✅ **15** testle kilitli |
| Zamanlayıcı (`.github/workflows/publish-feed.yml`) | ✅ yazıldı, **hiç çalıştırılmadı** |
| Yayım sayfası (`docs/feed_site_index.html`) | ✅ |
| Uygulamanın ağ katmanı | ✅ (TASK-0016) |

**Ölçülmemiş:** iş akışı hiçbir zaman GitHub'da çalışmadı ve uygulama
gerçek bir uzak sunucuya hiç bağlanmadı. Bunların ikisi de ancak depo
açıldıktan sonra ölçülebilir.

---

## Yapılacaklar (sırayla)

### 1. Depoyu GitHub'a bağla

Şu an yerel depoda **hiç uzak adres yok** (`git remote -v` boş) ve bu
makinede `gh` komutu kurulu değil. Depoyu tarayıcıdan açıp bağlamak
gerekiyor.

```bash
cd "C:/Users/user/Desktop/stitch_techpulse_social (14)"
git remote add origin https://github.com/<kullanıcı>/<depo>.git
git push -u origin phase-02a-shell-migration
```

#### Çalışma dalı **varsayılan dal olmalı** — yoksa zamanlayıcı hiç çalışmaz

GitHub, `schedule` ile tetiklenen iş akışlarını **yalnız varsayılan dalda**
çalıştırır. Ölçüldü (29 Temmuz): `master` dalında ne `.github/` var ne de
`mobile/` — bugüne kadarki 39 commit'in tamamı `phase-02a-shell-migration`
üzerinde. `master` varsayılan kalırsa cron hiçbir zaman ateşlenmez ve bu
sessizce olur: hata yok, koşu yok.

İki yoldan biri, push'tan **önce** ya da hemen sonra:

```bash
# A) dalı master'a birleştir (tercih edilen — dal adı kapsamı yansıtmıyor)
git checkout master && git merge phase-02a-shell-migration && git push -u origin master

# B) ya da GitHub'da: Settings → Branches → Default branch → phase-02a-shell-migration
```

`workflow_dispatch` (elle **Run workflow**) bu kısıttan etkilenmez; ilk koşuyu
her hâlükârda elle tetikliyoruz. Sorun yalnız otomatik tempoda ortaya çıkar.

**Depo public olmalı.** GitHub Pages, ücretsiz hesaplarda yalnız public
depolarda çalışır.

Kaynak kodunu public yapmak istemiyorsanız ikinci yol var ve aynı ölçüde
çalışır: **yalnız üretilmiş `feed.json`'ı barındıran ayrı bir public depo**
açılır, uygulama kaynağı private kalır. O durumda iş akışı dosyası bu
depoda durur ve `deploy-pages` yerine çıktıyı diğer depoya push eden bir
adım kullanılır. Feed'in içeriğinde gizli hiçbir şey yok — herkese açık
kaynaklardan derleniyor ve anahtar hiçbir zaman içine girmiyor.

### 2. Pages'i aç

Depo → **Settings → Pages → Build and deployment → Source: GitHub Actions**.

Klasik "Deploy from a branch" seçilmemeli; iş akışı `deploy-pages` eylemini
kullanıyor.

### 3. İlk koşuyu elle çalıştır

**Actions → Feed yayımla → Run workflow.**

İlk koşuda `FEED_URL` değişkeni tanımlı olmadığı için karşılaştırma
yapılmaz ve koruma "ilk yayım" der. Koşu bittiğinde adres:

```
https://<kullanıcı>.github.io/<depo>/feed.json
```

Tarayıcıda açıp gerçekten JSON döndüğünü görün. Dönmüyorsa Pages henüz
yayına almamış olabilir; birkaç dakika sürer.

### 4. Adresi depo değişkeni olarak kaydet

Depo → **Settings → Secrets and variables → Actions → Variables → New
repository variable**:

- Ad: `FEED_URL`
- Değer: yukarıdaki tam adres

Bu değişken olmadan koruma her koşuda "ilk yayım" sanar ve **çöken bir
feed'i durduramaz** — koruma karşılaştıracak bir şey bulamaz.

### 5. Uygulamayı adrese bağla

```bash
cd mobile
flutter build apk --release --dart-define=FEED_URL=https://<kullanıcı>.github.io/<depo>/feed.json
```

Uygulama kodunda değişiklik yok. Adres verilmediğinde uygulama paketlenmiş
içerikle çalışır ve arayüz bunu olduğu gibi söyler ("İçerik uygulamayla
birlikte geliyor"); "güncelleniyor" numarası yapmaz.

### 6. Cihazda ölç (ilk kez gerçek ağ)

Bunlar bugüne kadar **hiç** ölçülmedi, çünkü ölçülecek bir adres yoktu:

- [ ] TLS el sıkışması ve gerçek DNS
- [ ] İlk açılışta tazeleme (`refreshIfStale`) gerçekten tetikleniyor mu
- [ ] Aşağı çekerek tazeleme ve "Son güncelleme: …" satırının doğruluğu
- [ ] Uçak modu → açık moda geçiş; çevrimdışıyken önbellekten okuma
- [ ] Yavaş bağlantı (Android geliştirici seçeneklerinden kısıtlama)
- [ ] CDN önbelleği: yayımdan sonra yeni içeriğin cihaza ne kadar sürede
      geldiği (Pages varsayılanı ~10 dakika `max-age`)

---

## İşletme notları

### Zamanlayıcı 60 günde kapanır

GitHub, **60 gün hiç hareket görmeyen** depolarda zamanlanmış iş
akışlarını otomatik olarak devre dışı bırakır ve e-posta gönderir. Bu iş
akışı feed'i yayımlarken depoya commit atmıyor, yani depo kendiliğinden
"hareketli" görünmez. İki seçenek: e-posta gelince Actions sekmesinden
yeniden etkinleştirmek, ya da ayda bir elle `Run workflow` demek.

### Çıkış kodları ve ne anlama geldikleri

| Durum | Koşu | Ne yapmalı |
|---|---|---|
| Yayımlandı | yeşil | — |
| Kayıtlar değişmemiş | yeşil + notice | — (normal) |
| Bazı kaynaklar okunamadı | yeşil + warning | Kaynak ölmüş olabilir; çıktıdaki listeye bakın |
| Kayıt sayısı çöktü | **kırmızı** | Yayımdaki dosya korundu. Kaynaklara bakın |
| Yeni feed boş | **kırmızı** | Aynı |
| Yeni dosya eski damgalı | **kırmızı** | Saat/sıralama sorunu |

Koruma kırmızı verdiğinde **yayımdaki dosya olduğu gibi kalır**.
Kullanıcılar eski ama sağlam içeriği görmeye devam eder — bu, "güncellendi"
deyip akışın yedide birini göstermekten iyidir.

### Flutter sürümünü yükseltmek

İş akışında sürüm sabitlenmiş (`flutter-version: 3.44.8`). Yükseltirken:
önce yerelde yükseltin, `flutter analyze` + `flutter test` + üreticiyi
`--dry-run` ile çalıştırın, sonra iş akışındaki sürümü değiştirin. Sırayı
tersine çevirmek, kırılmayı ilk kez üretimde görmek olur.

### Maliyet

Public depoda GitHub Actions ve Pages ücretsiz. Günde 4 koşu × ~3 dakika
≈ ayda 6 saat; ücretsiz kotanın çok altında. `ANTHROPIC_API_KEY` sırrı
eklenirse özet katmanı devreye girer ve **o** ücretlidir; eklenmezse
özetler kaynağın kendi metniyle kalır.

---

## Neden Pages, neden diğerleri değil

| Seçenek | Neden seçilmedi |
|---|---|
| Cloudflare Pages / R2 | Ayrı hesap ve ayrı CDN önbellek ayarı gerekiyordu; kazancı yoktu |
| Kendi VPS | Aylık ücret ve sunucu bakımı; bu iş için fazlası |
| Barındırma yok | İçerik APK ile donardı: akışı tazelemek için mağazaya sürüm çıkmak gerekirdi |

Pages'in bilinen zayıflıkları kabul edildi ve yukarıda yazılı: depo public
olmalı, cron yoğunlukta gecikebilir, 60 gün hareketsizlikte zamanlayıcı
kapanır.
