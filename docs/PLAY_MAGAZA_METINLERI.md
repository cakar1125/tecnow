# Play Console — form cevapları ve mağaza metinleri

Bu dosya, Play Console'a **kopyala-yapıştır** girilecek metinleri ve form
cevaplarını tutar. Grafik gerektiren hiçbir madde burada değil; bunlar
ekran görüntüsü ve ikon olmadan da bugün doldurulabilir.

**Kaynak:** `com.tecos.app` · sürüm `1.0.2+3` · `docs/DECISION_LOG.md`

---

## 1 · Veri Güvenliği formu (Data safety)

Play'in sorduğu sırayla. **Her cevap ölçülmüş bir gerçeğe dayanıyor**;
dayanağı sağ sütunda.

| Play'in sorusu | Cevap | Dayanak |
|---|---|---|
| Uygulamanız kullanıcı verisi topluyor mu ya da paylaşıyor mu? | **Hayır** | Uygulamanın tek ağ isteği `feed.tecnow.app`'e **GET**; gövde göndermiyor (`feed_http_client.dart`) |
| Toplanan tüm kullanıcı verileri aktarım sırasında şifreleniyor mu? | **Evet** | `usesCleartextTraffic="false"`, istemci `https` dışını reddediyor |
| Kullanıcıların verilerinin silinmesini isteme yolu var mı? | **Evet** | Ayarlar → Verileri Sil; ayrıca kaldırma. Sunucuda veri yok |
| Uygulama Play Families politikasına tabi mi? | **Hayır** | Hedef kitle 13+ (bkz. §3) |
| Bağımsız güvenlik incelemesi | **Hayır** | Yapılmadı — "evet" demek beyan hatası olur |

### "Hayır" cevabının gerekçesi

Play'in tanımında **toplama**, verinin cihazdan çıkıp geliştiriciye
ulaşmasıdır. tecOS'ta:

- Hesap sistemi yok; ad, e-posta, telefon, konum istenmiyor
- Tercihler, kayıtlar, okuma geçmişi `shared_preferences` + `sqflite` ile
  **yalnız cihazda**
- Reklam kimliği (AAID) okunmuyor
- Reklam ağı, analitik, çökme raporlama SDK'sı **yok** — bağımlılıklar:
  `flutter_riverpod`, `go_router`, `sqflite`, `shared_preferences`,
  `url_launcher`, `path`, `cupertino_icons`

> **Cihazda işlenen veri toplama değildir**, ama form bunu "collected" saymaz
> yalnızca cihazdan çıkmadığı sürece. Bu koşul bugün sağlanıyor.

### Beyanı bozacak üç değişiklik

Aşağıdakilerden biri yayına girdiği **gün** bu form ve `gizlilik.html`
birlikte değişmeli. Beyanla gerçeğin ayrışması, Play'in uygulamayı kaldırma
sebebidir.

1. **Asistan** — kullanıcı mesajı bir yapay zekâ servisine gider →
   "Uygulama etkinliği / Diğer kullanıcı tarafından oluşturulan içerik",
   *toplanıyor*, *aktarılıyor*, geçici işleme
2. **Abonelik** — satın alma doğrulaması → "Satın alma geçmişi"
3. **Analitik / çökme raporu** — hangi araç olursa olsun beyan gerektirir

---

## 2 · Mağaza kaydı metinleri (Store listing)

### Uygulama adı — 30 karakter sınırı

```
tecOS
```

> **Neden sade:** `docs/ALAN_ADI_KARARI.md`'deki **TECNO** marka riski açık.
> Ada anahtar kelime eklemek ("tecOS - Teknoloji Haberleri") aynı sektörde
> çağrışımı güçlendirir. Anahtar kelimeler kısa açıklamada zaten var.

### Kısa açıklama — 80 karakter sınırı

```
Yeni AI modelleri, araçlar ve depolar — kaynağıyla birlikte. Hesap yok.
```

70 karakter. Play bunu arama sonucunda ve mağaza kartında gösterir; ilk
cümle hem **ne** hem **fark** vermeli.

### Tam açıklama — 4000 karakter sınırı

```
tecOS, teknoloji dünyasındaki gelişmeleri tek bir akışta toplayan
hesapsız bir rehberdir. Haber yazmaz, yorum katmaz: yeni çıkan yapay
zekâ modellerini, geliştirici araçlarını ve açık kaynak depolarını
derler, her birini kimin yayımladığıyla birlikte gösterir ve
orijinaline yönlendirir.

KAYIT OLMADAN
Uygulamayı açar açmaz kullanmaya başlarsınız. E-posta, telefon
numarası ya da şifre istenmez — okuduğunuz şeyin bir hesaba bağlanması
gerekmiyor.

VERİLERİNİZ TELEFONUNUZDA KALIR
Kaydettikleriniz, okuma geçmişiniz ve ilgi alanlarınız cihazınızda
saklanır ve oradan hiç çıkmaz. Uygulamada reklam ağı, analitik aracı
ya da izleme bileşeni bulunmaz. Reklam kimliğiniz okunmaz. İstenen tek
izin internet erişimidir.

KAYNAK HER ZAMAN GÖRÜNÜR
İçerik yalnızca önceden onaylanmış adreslerden gelir: GitHub, Hugging
Face ve kurumların kendi resmi blogları ile dokümantasyonu. Ölçüt tek
cümleyle şu: bir gelişmeyi aktaran değil, yapan yazar. Akışta kullanıcı
gönderisi, yorum ya da katkı bulunmaz.

İLGİ ALANINIZA GÖRE
Yapay zekâ, mobil geliştirme, web, altyapı, güvenlik ve donanım gibi
alanlardan ilgilendiklerinizi seçersiniz; ana sayfa sekmeleri buna göre
kurulur. Beğenmediğiniz bir kaynağı susturabilir, ilgilendiklerinizi
kaydedebilirsiniz.

İNTERNETSİZ DE OKUNUR
İndirilen içerik cihazda saklanır. Bağlantı kesildiğinde uygulama
elindekini göstermeye devam eder. İçerik saatte bir yenilenir ve
değişiklik yoksa veri harcanmaz.

TÜRKÇE ÖZETLER İŞARETLİ
Bazı kayıtların özeti tecOS tarafından Türkçeleştirilir. Bu özetler
arayüzde açıkça işaretlenir ve kaynağın kendi metniyle karıştırılmaz.
Kaynakta geçmeyen bir sayı ya da bağlantı içeren özet kullanılmaz;
şüphede kalındığında içerik özgün dilinde bırakılır.

Kaynak politikasının tamamı: https://tecnow.app/kaynaklar.html
Gizlilik politikası: https://tecnow.app/gizlilik.html
```

~1.750 karakter. Sınırı doldurmak amaç değil; anahtar kelime yığmak Play'in
spam politikasına takılır.

### Kategori ve etiketler

| Alan | Değer |
|---|---|
| Uygulama türü | Uygulama (oyun değil) |
| Kategori | **Haberler ve Dergiler** |
| Etiketler (en fazla 5) | Teknoloji haberleri · Yapay zekâ · Geliştirici araçları · Açık kaynak · Haber okuyucu |
| İletişim e-postası | `destek@tecnow.app` |
| Web sitesi | `https://tecnow.app` |
| Gizlilik politikası | `https://tecnow.app/gizlilik.html` |

> **Kategori seçimi:** "Araçlar" ve "Verimlilik" de aday. "Haberler ve
> Dergiler" seçildi çünkü uygulamanın işi güncel gelişmeleri aktarmak;
> kategori yanlışsa Play'in kendi öneri motoru uygulamayı yanlış kitleye
> gösterir ve bu, yükleme sayısından daha zor fark edilen bir kayıptır.

---

## 3 · İçerik derecelendirme anketi (Content rating)

IARC anketi. Cevaplar:

| Soru | Cevap |
|---|---|
| Uygulama kategorisi | Referans, haber veya eğitim |
| Şiddet, cinsellik, küfür, uyuşturucu, kumar | **Hayır** (tümü) |
| Kullanıcılar arası etkileşim / mesajlaşma | **Hayır** — akışta kullanıcı içeriği yok |
| Kullanıcı konumu paylaşımı | **Hayır** |
| Kişisel bilgi paylaşımı | **Hayır** |
| Dijital satın alma | **Hayır** *(abonelik geldiğinde **Evet** olacak)* |
| Denetlenmeyen kullanıcı içeriği barındırıyor mu | **Hayır** — kaynak listesi kapalı |

Beklenen sonuç: **3+ / Herkes**.

> Uygulama harici bağlantılar açıyor (`url_launcher`). IARC bunu ayrı bir
> soru olarak sormaz ama tam açıklama ve gizlilik politikası dış sitelere
> yönlendirmeyi açıkça yazıyor.

### Hedef kitle ve içerik (Target audience)

| Alan | Değer |
|---|---|
| Hedef yaş aralığı | **13-15, 16-17, 18+** |
| Çocuklara mı yönelik | **Hayır** |
| Play Families programı | Hayır |

13 alt sınırı bilinçli: uygulama çocuklara yönelik değil, "18+" demek de
gereksiz kısıtlama olurdu.

---

## 4 · Sürüm notları (Release notes)

Dil başına **500 karakter** sınırı.

### İlk yayın — `1.0.2 (3)`

```
İlk sürüm.

• Yapay zekâ modelleri, geliştirici araçları ve açık kaynak depoları tek
  akışta, kaynağıyla birlikte
• Kayıt yok, hesap yok, reklam yok
• İlgi alanlarınıza göre sekmeler; kaynak susturma ve kaydetme
• İnternetsiz okuma
• Türkçe özetler açıkça işaretli
```

### Şablon — sonraki sürümler

Sürüm notu **kullanıcının gördüğü değişikliği** yazar, iç işleri değil.
"Performans iyileştirmeleri ve hata düzeltmeleri" bir sürüm notu değil,
notun yokluğudur.

```
• <kullanıcının fark edeceği değişiklik>
• <düzeltilen ve kullanıcıyı etkileyen hata>
```

---

## 5 · Kapalı test (kişisel hesap şartı)

`docs/YOL_HARITASI.md` B yolundan: 2023 sonrası açılan **kişisel**
hesaplarda üretime çıkmadan önce **12 test kullanıcısıyla 14 gün kesintisiz**
kapalı test isteniyor. **Sayı ve süre için Play Console'un kendi ekranında
yazan değeri esas alın** — Google bu politikayı değiştiriyor.

### Test grubuna gönderilecek metin

```
tecOS'un kapalı testine katıldığın için teşekkürler.

Ne yapıyor: teknoloji dünyasındaki gelişmeleri (yeni AI modelleri,
geliştirici araçları, açık kaynak depolar) kaynağıyla birlikte
gösteriyor. Hesap açman gerekmiyor.

Senden istediğim: uygulamayı 14 gün boyunca telefonunda tutman ve ara
ara açman. Kaldırırsan sayaç sıfırlanıyor, bu yüzden kullanmasan bile
yüklü kalsın.

Bir şey bozulursa ya da tuhaf gelirse: destek@tecnow.app

Katılım bağlantısı: <Play Console'un verdiği opt-in URL>
```

> **15 kişi toplayın, 12 değil.** Katılmayan çıkarsa sayaç düşer ve 14 gün
> baştan başlar; bu, kritik yoldaki tek geri sarılabilir gecikmedir.

---

## 6 · Bu dosyanın kapsamadıkları

Kasıtlı olarak yok:

- **Ekran görüntüleri, uygulama ikonu, öne çıkan grafik** — grafik işi,
  metin işi değil
- **Abonelik şartları ve iade politikası** — ortada abonelik ürünü yok:
  fiyat, kota ve iptal davranışı tanımlanmadan yazılacak metin *taslak*
  değil *uydurma* olur. Faz F'te ürünle birlikte yazılır
- **Diğer dillerdeki mağaza metinleri** — uygulama arayüzü henüz
  yerelleştirilmedi (Faz 4). Türkçe olmayan bir mağaza kaydı, Türkçe
  arayüze indiren kullanıcı üretir
