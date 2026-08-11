# Karar Günlüğü

## D-001 — Hesapsız ürün

Kayıt, giriş, kullanıcı adı ve şifre olmayacak.

## D-002 — Kullanıcı üretimli haber yok

Kullanıcı gönderisi, yorum, takipçi ve herkese açık sosyal etkileşim olmayacak. Haberleri yalnız Tecnow'ın kaynak hattı yayımlar.

## D-003 — Yerel kişisel veri

İlgi alanları, kayıtlar, okuma geçmişi ve asistan konuşmaları cihazda saklanır. İlk sürümde bulut senkronizasyonu yoktur.

> **D-010 ile daraltıldı (29 Temmuz 2026).** Saklananların kapsamı değişti; "cihazda kalır, buluta gitmez" ilkesi aynen geçerli.

## D-004 — Kaynak merkezli içerik

Tecnow kısa açıklama ve ön izleme sunar; orijinal GitHub/Hugging Face/resmî kaynak bağlantısı her içerikte görünür.

## D-005 — Yeni alt navigasyon

Ana Sayfa, Keşfet, Asistan, Kaydedilenler, Ayarlar.

> **D-014 ile güncellendi (1 Ağustos 2026).** Alt bar **dört** sekmeye iniyor:
> Ana Sayfa · Keşfet · Asistan · Kaydedilenler. Ayarlar sağ üst dişli ikonuna
> taşınıyor. Asistan sekmede **kalıyor** — D-011'de ürünün tek gelir kaynağı.

## D-006 — Eski sosyal ekranların kaldırılması

Paylaş/Gönderi Oluştur → Proje Asistanı  
Bildirimler → Kaydedilenler  
Profil → Ayarlar

## D-007 — Asistanın rolü

Proje fikrini anlamak için uyarlanabilir sorular sorar; uygun AI, skill, MCP ve teknoloji yol haritası üretir. Güncel iddialar kaynaklı olmalıdır.

## D-008 — Minimal merkezi altyapı

Kişisel hesap backend'i yok. Canlı içerik için statik feed hattı; asistan için geçmiş tutmayan minimal AI geçidi daha sonraki fazdadır.

## D-009 — Claude/Codex koordinasyonu

Claude proje lideri ve reviewer; Codex sınırlı görevlerin uygulama mühendisi. Ortak hafıza ve dosya tabanlı handoff zorunludur.

## D-010 — Cihazda saklananların daraltılması (D-003'ü günceller)

Cihazda **yalnız** şunlar saklanır: kaydedilen gönderiler, ilgi alanları ve asistan konuşmasının **asistan tarafından üretilmiş özeti**. Haberlerin/gönderilerin kendisi birikmez.

Gerekçe ve ölçüm (29 Temmuz 2026): şema ölçüldüğünde kural büyük ölçüde zaten sağlanıyordu — `feed_cache` tek satır (`CHECK (id = 1)`, veritabanı seviyesinde zorlanıyor) ve her tazelemede üzerine yazılıyor, yani bir yıl sonra da aynı boyutta. Okuma geçmişi içerik metni değil kimlik + tür + zaman tutuyor.

Uygulanan tek değişiklik: okuma geçmişi tavanı **500 → 50**. 500, feed'in 200 kayıtlık kayan penceresinin 2.5 katıydı; pencereden düşen kimlikler başlıksız satır olarak kalıyordu (`ReadHistoryEntry.resolved`). 50, pencerenin içinde kalır ve her satır çözülür. Ekranın vaadi "arşiv" değil "son okuduklarım".

Karar geçici olarak alındı: canlıya çıkıp test aşamasına gelindiğinde yeniden değerlendirilecek.

Sonuçları henüz uygulanmayanlar (Faz 4): `assistant_messages.content` tam mesaj metnini tutuyor, özete dönecek — tablo hiç yazılmadığı için değiştirmek şimdilik bedava. Ölü `favorites` tablosu kaldırılacak (v5 göçü).

## D-011 — Asistan ücretli, uygulama ücretsiz (Faz 4)

Uygulama ücretsiz kalır; asistan aylık abonelikle ücretlendirilir — başlangıç, orta ve ileri olmak üzere üç plan, her biri bir token kotasına karşılık gelir.

**Hesapsızlık korunur.** Play Billing `purchaseToken` → geçit Google Play API'sine doğrulatır → kısa ömürlü **anonim** kota bileti üretir. E-posta, şifre veya kullanıcı adı yok; D-001 ihlal edilmez.

**D-008 daraltılıyor:** geçit "geçmiş tutmayan" değil, **"konuşma tutmayan"** olacak. Konuşma sıfır kalabilir ama abonelik başına kota sayacı zorunludur — kota istemci tarafında zorlanamaz.

Kullanıcıya iletilen ve kabul edilen dört gerçek:

1. **"Anlık" tahsilat yoktur.** Play %15 keser ve **aylık** öder (ay kapanışından ~15 gün sonra). API maliyeti anında doğar, tahsilat ~45 gün sonra gelir; aradaki fark işletme sermayesiyle finanse edilir. İadeler parayı geri alır, harcanan token geri gelmez.
2. Dijital abonelikte **mağaza ödemesi zorunludur**; uygulama içi doğrudan kart alınamaz.
3. Asıl risk kota değil **maliyet tavanıdır**: sunucu tarafı sert dönemsel kota, istek başına maksimum token, hız sınırı ve toplam harcama devre kesicisi olmadan tek kullanıcı aylık marjı yakabilir.
4. Play ödemeleri banka hesabı ve vergi kaydı gerektirir; Play ayrıca abonelik şartları ve iade politikası metni ister.

Fiyat modellemesi barındırma canlıya alındıktan sonra yapılacak: `plan fiyatı − %15 mağaza kesintisi − (kota × model token fiyatı) = marj`.

## D-012 — Feed ileri uyumluluğu kayıt seviyesinde çözülür (29 Temmuz 2026)

Yayın bu uygulama sürümünün tanımadığı bir kayıt taşıdığında feed **reddedilmez**; yalnız o kayıt atlanır ve geri kalanı okunur (`Feed.unsupportedItemCount` sayar).

Gerekçe ölçümdür: paketlenmiş 200 kayıttan **tek birine** bilinmeyen bir `kind` yazıldığında eski kod 200'ünü birden reddediyordu. Yayımlanmış bir uygulamada bu, güncellemeyen kullanıcının yeni türü değil **hiçbir şeyi** bir daha alamaması demekti — sessizce, çünkü önbellek korunuyor ve ekran "Güncellenemedi" deyip duruyor.

Ayrım iki istisna tipiyle kuruldu: `FeedFormatException` (yayın bozuk → reddet) ve `FeedItemUnsupportedException` (yayın ileri → kaydı atla).

Sınır **dar tutuldu**: zorunlu alanın eksik olması ve `schemaVersion`'ın yüksek olması hâlâ tüm feed'i reddettirir. Birincisi üretici kusurudur ve maskelenmemeli; ikincisi yapısal kırılma sinyalidir ve katkı niteliğindeki değişiklikler için **asla artırılmayacaktır** (bkz. Ders 73).

`summaryOrigin` bilinmeyen değerde kaydı **atlar**, nötr bir değere düşmez: Tecnow özetini kaynağın kendi metniymiş gibi sunmak dürüstlük kuralını çiğnerdi. Buna karşılık `sourceKind` `other`a düşer ve kayıt kalır — küratörlü `sourceName` zaten görünür.

Zamanlama zorunluydu: bu pencere ilk sürümle kapanıyor. Yayından sonra düzeltmek güncellemeyen kullanıcıyı kurtarmaz.

## D-013 — Sıralama içeriği: kaynak ve biçim (Faz 2, 29 Temmuz 2026)

Model sıralamaları yeni bir içerik türü olarak eklenecek (`FeedItemKind.leaderboard`), **barındırma canlıya alındıktan sonra**.

**Kaynak:** `lmarena-ai/leaderboard-dataset` (Hugging Face), **CC-BY-4.0**, Arena ekibinin kendi yayını. `datasets-server.huggingface.co` üzerinden auth'suz erişiliyor; ölçüldü: `agent/latest` = 44 satır, sitedeki 44 modelle birebir, `leaderboard_publish_date: 2026-07-28`.

`arena.ai` sitesinin kendisinden **kazıma yapılmayacak**: resmî API'si yok ve üçüncü tarafların izinsiz aynaları "her içerikte orijinal kaynak görünür" kuralıyla çakışıyor. Resmî dataset bu sorunu ortadan kaldırıyor.

**Biçim:** ayrı bir sıralama kartı — mevcut AI model kayıtlarına rozet takmak **elendi**. Arena model adları (`Claude Fable 5 (High)`) ile feed'deki HF model kimlikleri bulanık eşleşiyor; yanlış rozet takmak doğrulanmamış veriyi doğrulanmış gibi göstermek olurdu.

Güven aralıkları **gösterilecek**: ±0.022 ile 1. ve 2. sıranın istatistiksel olarak ayrışmadığını gizlemek yanlış kesinlik üretir.

Yeni bir detay ekranı gerekiyor ve **tasarım onayı bekleyecek**; onaysız ekran uydurulmayacak.

## D-014 — Arayüzün yeniden tasarımı (Faz 5, barındırmadan sonra)

Kullanıcı yeni bir Figma tasarımı verdi (Home "Bundle" · Explore · Saved) ve arayüzün neredeyse sıfırdan yeniden düzenlenmesini istedi. Karar verildi, **uygulama barındırma canlıya alındıktan sonra** başlayacak.

**Kapsam: 12 ekranın tamamı.** Tasarım yalnız 3 ekranı gösteriyor; kalan 9'unun (Detay, Ayarlar, Onboarding, İlgi Alanları, Splash, Hakkında, Kaynak Politikası, Okuma Geçmişi, Asistan) tasarımı Claude tarafından türetilecek ve **kullanıcı onayına sunulacak**. Üç ekranı yenileyip dokuzunu eski dilde bırakmak, uygulamayı yarısı yeni yarısı eski gösterirdi.

**Navigasyon: 5 sekme → 4** (Home · Explore · **Asistan** · Saved); Ayarlar sağ üst dişli ikonuna taşınır. Mockup üç sekme gösteriyor ve Asistan'ı hiç içermiyor, ama Asistan D-007'nin çekirdeği ve D-011'de **ürünün tek gelir kaynağı** — görünmeyen bir özellik satılamaz. D-005 bu kararla güncellenir. Yan fayda: alt bar 5'ten 4'e inince, `KNOWN_LIMITATIONS`'ta yazılı "Kaydedilenler 1.3 yazı ölçeğinde sarmalanıyor" sorunu yapısal olarak hafifler.

**Vurgu rengi değişmiyor.** Mockup Home'da neon lime kullanıyor; değişmez kural ("koyu tema, `#0A0C10`, **cyan** ana vurgu, mor yalnız AI/Asistan bağlamı") **korunur**. Alınan şey mockup'ın yapısal fikirleri: Bundle yerleşimi, iki sütunlu masonry, kart-içinde-kart dili, kategori pilleri, "Revisit" affordance'ı.

**İçerik hattı arayüzle birlikte yapılacak.** Tasarımın vaat ettiği ama üreticinin bugün üretmediği veriler de bu kapsamda: arXiv bağlayıcısı ve `paper` türü ("Papers" çipi), "Agents" kategorisi, kart başına "Why it matters" editoryal satırı (yeni üretim + kalite kapısı), `MMLU` / `Arena` metrik rozetleri (D-013 verisi) ve "MORNING BRIEFING" günlük derlemesi (üretici bugün kayan pencere veriyor, günlük seçki değil).

Bu, tasarımın boş kutu ya da uydurma veri göstermemesi için şart: proje aynı tuzağa daha önce iki kez düştü ("Başlangıç İçin" boş bölümü, hiç sonuç vermeyen "AI Araçları" çipi) ve "kurgusal veri gerçek gibi sunulmaz" kuralı bunu yasaklıyor.

**Ölçülen yüzey ve tahmin.** Arayüz katmanı 5.075 satır kod + 3.624 satır test (12 ekran, 28 paylaşılan bileşen); veri/üretici katmanı (5.532 + 5.831 satır) bu işten **etkilenmiyor**. Tasarım sistemi merkezî — token dışında yalnız 2 ham renk, 142 `AppColors.` referansı — bu yüzden renk/köşe/boşluk ucuz, pahalı olan yapı.

Tahmin **~14-20 oturum** (satır sayıları ölçüldü, oturum sayısı tahmindir). İki kalem Claude'un hızına bağlı değil: 9 ekranın tasarım onayı ve "Why it matters" için editoryal ton kararı.

**Sıra bilinçli:** barındırma önce. İçerik hattı işi (arXiv, yeni türler, günlük derleme) üreticinin gerçekten koştuğu görülmeden test edilemez — zamanlayıcı iş akışı bugüne kadar GitHub'da **hiç çalışmadı**.

## D-015 — Özet katmanı: taşıma + ikinci sağlayıcı (3 Ağustos 2026)

Kullanıcı NVIDIA'nın ücretsiz API'li modellerini önerdi. Araştırma bir fırsat **ve bir kusur** ortaya çıkardı.

**Kusur:** yayımlanan 200 kaydın **180'i İngilizceydi**. Sebebi bütçe sayısı değil, yapısal israftı: üretici feed'i her koşuda kaynaklardan yeniden kurduğu için geçen koşunun Türkçe özetleri kayboluyor ve 60'lık bütçe aynı işi tekrar satın almaya gidiyordu. Kuyruktaki 140 kayıt hiç sıra alamıyordu.

**Taşıma.** Yayımdaki kopya artık üreticiye veriliyor (`--previous`); iş akışı onu zaten **üretimden önce** indiriyordu, yani ek maliyet yok. Kimlik eşleşiyor **ve kaynak metin aynıysa** özet taşınır. "Kaynak metin aynı mı" sorusu cevaplanamıyordu — yayımlanmış kayıtta kaynak metin yok, yerinde Türkçe özet var. Çözüm `summarySourceHash`: katkı niteliğinde opsiyonel alan, `schemaVersion` **artırılmadı** (D-012 sayesinde kurulu uygulamalar tanımadıkları anahtarı yok sayıyor).

Taşınan özet kapıdan **yeniden** geçirilir: kapının kuralları sıkılaşmış olabilir ve taşımak yeni kuralı sessizce atlamak anlamına gelmemeli.

**İkinci sağlayıcı.** `NvidiaSummarizer` (OpenAI uyumlu uç) eklendi; ücretsiz katmanın 40 istek/dakika sınırı için çağrılar arasında 1,5 sn beklenir. `FallbackSummarizer` sıralı dener ve **yalnız fırlatılan istisna** zinciri ilerletir — `null` "bu kayıt için özet yok" demektir. Hangi sağlayıcının birincil olacağı **ölçümle** seçilecek (`summary_guard` ret oranı), varsayımla değil.

**Asistan (D-011) bu katmana bağlanmayacak.** NVIDIA "production"ı *"gerçek son kullanıcılara hizmet"* diye tanımlayıp NVIDIA AI Enterprise şart koşuyor; ayrıca 40 RPM tüm kullanıcıların toplamı olurdu.

Bütçe 60 → 120: artık maliyet kapısı değil, kaçak durum tavanı.

**Ölçüm** (gerçek 200 kayıtlık dosya): 1. koşu 120 çağrı / 0 taşıma · 2. koşu 60 çağrı / **120 taşıma** → **200/200 Türkçe**. Kararlı durumda yalnız yeni kayıtlar çağrı üretir.

## D-016 — Tasarım otoritesi Flutter deposunda değil (1 Ağustos 2026)

Kullanıcı "neden hep (14) üzerinde çalışıyorsun" diye sorunca üç kök olduğu ve ikisinin çakıştığı ölçüldü.

| Konum | Rolü |
|---|---|
| `claude3\stitch_techpulse_social (16)` | Ham Stitch export (153 ekran, 0 Dart) — salt okunur |
| `TeknoAkis_ClaudeCode_Handoff\design_handoff\` | **Yürürlükteki tasarım otoritesi** — 9 onaylı ekran + `ACTIVE_SCREEN_MAP.md` |
| `OLD_DESTOP\stitch_techpulse_social (14)` | **Kod deposu** (tek git deposu) |

Flutter deposunda `design_handoff/` adında **pivot öncesi** bir kopya duruyordu: `approved/` altında `authentication`, `social`, `notifications`, `profile` — D-001/D-002/D-006 ile kaldırılan ekranlar "onaylı" etiketiyle. Ölçüldü: yürürlükteki 9 onaylı ekranın **6'sı** o kopyada hiç yoktu.

`design_handoff_pre_pivot/` olarak adlandırıldı (silinmedi — pivotta neyin değiştiğini görmek için tek kaynak) ve içine gerekçeyi yazan bir `README.md` konuldu. `START_HERE.md`'nin "İki kök" tablosu **üç köke** çıkarıldı.

## D-017 — Ürün adı: Tecnow (6 Ağustos 2026)

Kullanıcı adı **Tecnow** olarak belirledi. Yeniden adlandırma aynı gün uygulandı; pencere mağaza yayınıyla kapanıyordu.

**Uzantı: `.app`.** Ölçüm (RDAP, aynı anda): `tecnow.com` **dolu** — 1999'dan beri kayıtlı, GoDaddy'de, transfer/güncelleme kilitli ve 2030'a kadar ödenmiş; 114 baytlık park sayfası döndürüyor, yani düşmesi beklenmemeli. `tecnow.net`, `tecnow.app`, `tecnow.dev` **boş**. Gerekçe [ALAN_ADI_KARARI.md](ALAN_ADI_KARARI.md)'de: uzantının insana görünen tek işi mağaza kaydı ve gizlilik politikası bağlantısıdır.

**Güvenlik gerekçesi kullanılmadı, çünkü ölçüm onu desteklemiyor.** `.app` uzantısının tamamı tarayıcıda HSTS ön yüklemelidir, ama o liste **tarayıcıların** listesidir ve Dart'ın HTTP istemcisi ona bakmaz. Uygulama tarafında HTTPS zaten kodda zorunlu: `feed_endpoint.dart` `https` olmayan adresi kabul etmiyor, `feed_http_client.dart` yönlendirmede şema düşüşünü reddediyor. `.app`'in kazancı gerçek ama yalnız tarayıcı yüzeyini kapsıyor.

**Aynı turda iki tek yönlü kapı markadan arındırıldı.** Ad değişince ikisinin de yayından sonra dokunulamaz olduğu görüldü:

| Yer | Eski | Yeni | Yayından sonra değiştirilseydi |
|---|---|---|---|
| `SummaryOrigin` değeri | `teknoakis` | `generated` | Kurulu uygulamalarda o kayıtlar **sessizce düşerdi** (D-012: bilinmeyen `summaryOrigin` → kayıt atlanır) |
| `LocalSchema.databaseName` | `teknoakis.db` | `app.db` | sqflite **boş** bir veritabanı açardı: kaydedilenler, ilgi alanları ve okuma geçmişi bir güncellemede yok olurdu — göç yolu yok, hata yok |

Kural olarak kayda geçiyor: **ürün adı kalıcı tanımlayıcılara yazılmaz.** Ad değişebilir, tel biçimi ve veri dosyası adı değişmemeli.

**Ölçülen kapsam:** 105 git-izlenen dosya. Dart paketi `teknoakis` → `tecnow` (151 import), `applicationId`/`namespace`/iOS-macOS bundle kimlikleri `com.teknoakis.app` → `com.tecnow.app`, Android paket dizini ve `MainActivity`, splash drawable, Linux/Windows/web başlık ve kimlikleri, arayüz metinleri (`TEKNOAKIŞ ÖZETİ` → `TECNOW ÖZETİ`), fixture feed'deki 20 `summaryOrigin` değeri.

İki golden testi kırıldı; **gevşetilmedi, yeniden üretildi**. Önce `isolatedDiff` görüntüleri okundu ve değişen tek şeyin kelime markası ile özet rozeti olduğu doğrulandı — başka hiçbir piksel oynamamıştı. Kapılar: format 0 · analyze 0 · **772/772**.

**Kayda geçen risk: TECNO markası.** TECNO, Transsion Holdings'in akıllı telefon markası ve Türkiye dahil satışta. "Tecnow" ondan tek harf uzakta ve **aynı sektörde** (tüketici teknolojisi). Google Play'in marka şikâyeti yolu var ve kabul edilen şikâyet uygulamanın **kaldırılmasıyla** sonuçlanabiliyor. Bu bir hukuk görüşü değil, kayda geçmiş bir risk; alan adı ve mağaza kaydı öncesi TÜRKPATENT ve EUIPO/WIPO aramasıyla teyit edilmesi öneriliyor. Karar kullanıcının.

---

## D-018 — Marka yazımı: TecNow, ve TECNO araması (6 Ağustos 2026)

D-017'de "kayda geçen risk" olarak bırakılan TECNO sorusu **ölçüldü**. TÜRKPATENT marka araştırması (6 Ağustos 2026, 23:33) sonucu:

**"tecnow" araması → 2 kayıt, ikisi de bizi ilgilendirmiyor:** `tw tecnoworld` (YAPI ELEKTRONİK) ve `tecnowind` (BS SERVICE GROUP SRL), **ikisi de Nice sınıf 11** (ısıtma/soğutma/tesisat). Tam eşleşme yok — "Tecnow" Türkiye'de kimsenin değil.

**"tecno" araması → 392 kayıt.** Bunların içinde TECNO TELECOM (HK) LIMITED (7366273):

| Marka | Sınıf | Tescil |
|---|---|---|
| **tecno** (düz kelime) | **38 / 42** | 2025 027616 |
| tecno aı | **09** | 2025 067972 |
| tecno aı | 09 | (başvuru) |

**Sınıf 42 yazılım hizmetleri, sınıf 9 yazılım/mobil uygulama — ikisi de bizim sınıflarımız.** Başvuru tarihi Şubat–Mayıs 2025: Transsion korumasını telefondan yazılıma doğru **aktif olarak genişletiyor**. "TECNO AI" ayrıca ürünümüzün konusuyla örtüşüyor.

**Lehte olan argüman ve neden tek başına yetmiyor:** 392 sonuçta "tecno" öneki birçok farklı sahibe tescilli (tecnord, tecnoplas, tecnokar, tecnovies, tecnofx…), yani ön ek zayıf/tanımlayıcı sayılıyor. Ama bunların hepsi **TECNO + anlamlı bir kelime**; "Tecnow" ise **TECNO + tek harf**, yani 392 marka içinde çıplak TECNO'ya en yakın olan.

### Karar

Kullanıcı adın **"Tec Now" (teknoloji + şimdi)** olarak kurulduğunu belirtti. Kavramsal farklılık marka benzerliği değerlendirmesinde sayılan bir ölçüt — ama **gösterilmesi** gerekiyor. Ölçüm, niyetin hiçbir yerde görünmediğini gösterdi: uygulama `Tecnow`, rozet `TECNOW ÖZETİ`, kelime markası `TECNOW` (ana sayfa ve splash, tümü büyük harf).

**Marka her yerde `TecNow` yazılacak.** Tümü büyük harf yazım okumayı "TECNO + W"ye düşürüyor; deve sırtı yazım "Tec Now" ayrımını görünür kılıyor ve telaffuzu ayırıyor.

Değişen yerler: `android:label`, iOS `Info.plist`, `MaterialApp.title`, `AppTopBar` varsayılanı ve üç ekrandaki elle yazılmış hâli, ana sayfa ve splash kelime markaları, üç ayrı yerdeki özet rozeti, `about_screen`, `applicationName`, HTTP `userAgent`.

**Değişmeyen:** `applicationId` (`com.tecnow.app`), alan adı (`tecnow.app`), Dart paket adı (`tecnow`). Bunlar küçük harf ve tek yönlü kapı; deve sırtı zaten taşıyamazlar.

**Ne aldığımız ve almadığımız, açıkça.** Alınan: görsel ve işitsel ayrım artıyor, ve bir şikâyet gelirse **yayından önce kurulmuş**, tutarlı bir marka hikâyesi belgeli oluyor — sonradan uydurulmuş bir mazeret değil. **Alınmayan:** TECNO'nun sınıf 42 tescili yerinde duruyor, Play'in şikâyet süreci nüansı fazla tartmıyor, ve `com.tecnow.app` küçük harf olduğu için orada ayrım hiç görünmeyecek. Risk **azaldı, sıfırlanmadı**. Bu bir hukuk görüşü değildir; kesin cevap ancak marka vekilinden gelir.

**Ölçüm:** dart format 0 · flutter analyze 0 · **781/781 test yeşil**. Üç test beklentisi güncellendi (`userAgent`, iki rozet metni) ve yazımı kilitleyen yorumlar eklendi. İki golden kırıldı; **gevşetilmedi, yeniden üretildi** — önce `isolatedDiff` görüntüleri okundu, değişen tek şeyin kelime markası ve rozet olduğu doğrulandı.

---

> **Buradan aşağısı 12 Ağustos 2026'da eklendi.** Günlük 6 Ağustos'ta D-018'de
> duruyordu ve o tarihten sonra verilen üç karar yalnız **kodun yorumlarında**
> kayıtlıydı. Bir karar günlüğünün kodun gerisinde kalması, kararı verilmemiş
> saymaktan farksız: D-018 hâlâ "marka TecNow yazılacak" diyordu, oysa
> uygulama çoktan tecOS'a taşınmıştı. Aşağıdaki üç kayıt o boşluğu kapatıyor
> ve **yeni karar üretmiyor** — dayanakları koddaki ölçümler ve yorumlar.

## D-019 — Ürün adı: tecOS (10 Ağustos 2026)

D-018 "TecNow" yazımını seçmiş ve riski açıkça **"azaldı, sıfırlanmadı"**
diye bırakmıştı. Karar o cümlenin arkasında durmadı: ad değişti.

**Dayanak (TÜRKPATENT sicili, `app_components.dart` içinde kayıtlı):** TECNO,
Transsion'ın markası olarak **sınıf 09'da üç** tescil (2018 104811 ·
2023 040621 · 2024 051932) ve **sınıf 42'de bir** tescil (2025 027616)
taşıyor. İkisi de bizim sınıflarımız.

Belirleyici olan şu: **"TecNow" o markayı bütünüyle içeriyordu** —
`TECNO` + `W`. "tecOS" ise yalnız `TEC` önekini paylaşıyor ve sicilde
**11.421 marka** o öneki taşıyor, yani önek tek başına ayırt edici değil.

**Değişen:** görünen her ad, `applicationId` (`com.tecnow.app` →
`com.tecos.app`), Dart paket adı, iOS bundle kimliği, rozet metinleri.
`applicationId` mağaza yayınından sonra değiştirilemez; kapı **açıkken**
kapatıldı.

**Değişmeyen:** alan adı `tecnow.app` ve GitHub deposunun adı `tecnow`.
İkisi de dışarıya marka olarak görünmüyor (feed bir veri adresi), taşınmaları
para ve kesinti demek, ve `tecos.app` alınmadı. Bkz. `ALAN_ADI_KARARI.md`.

**Marka kendi yazımını korur:** `tecOS`, `TECOS` değil. Rozeti tümüyle
büyütmek adın biçimini yok eder; bu kural testle kilitli
(`feed_screen_test.dart`).

Bu bir hukuk görüşü değildir; kesin cevap ancak marka vekilinden gelir.

## D-020 — Ana Sayfa ve Keşfet'in yeniden kurulması (11 Ağustos 2026)

D-014 arayüz yenilemesini "barındırmadan sonra" diye ertelemişti. Kullanıcı
şikâyeti bunu öne aldı: *"arayüz çok karışık, her şey birbiri ile aynı."*

**Şikâyet ölçüldü ve kelimesi kelimesine doğru çıktı:** kart yüzeyi / sayfa
zemini kontrastı **1.07:1**, kart kenarlığı / yüzey **1.45:1**. Kartların
sınırı zaten görünmüyordu. Çerçeveler kaldırıldı; hiyerarşiyi punto, ağırlık
ve boşluk taşıyor.

**Referans:** kullanıcının kendi telefonundaki Bundle uygulaması, açık isteği
üzerine incelendi. Alınan mekanikler: çerçevesiz satır + ayraç, iki anatomi
(hero / kompakt satır), `Kaynak · GEREKÇE` meta satırı, konudan kurulan ve
sürüklenerek sıralanan sekme şeridi, Keşfet'in bir arama ekranından **içerik
mağazasına** dönüşmesi.

**Kopyalanamayan:** Bundle'ın ritmi fotoğrafa dayanıyor, bizde 200/200 kayıtta
görsel yok (şemada böyle bir alan yok). Boş bir 16:9 kutu denendi ve
reddedildi; ağırlık tipografiye taşındı, kaynak marka işaretiyle görsel
çapa oldu.

### Ölçümle **geri alınan** üç karar

1. **Popülerlik gerekçe olarak kullanılamaz.** `TrustSignals.popularity` iki
   uyumsuz birim taşıyor: GitHub yıldızı (n=54, ortanca 209) ve Hugging Face
   indirmesi (n=20, ortanca 16.619.070). Aralıklar hiç örtüşmüyor, yani ortak
   bir eşik sayıyı değil **kaynağı** ölçer. Şema birimi de taşıyana kadar
   kullanılmıyor.
2. **Dil rozeti kaldırıldı.** 200 kaydın 180'i `en`; Türkçe olan 20 kayıt
   **tam olarak** tecOS'un özetlediği 20 kayıt (kesişim 20, fark 0). Yanındaki
   `tecOS ÖZETİ` etiketinin üstüne sıfır bilgi koyuyordu.
3. **Gerekçe sıralaması ters çevrildi.** Tazelik, ilgi eşleşmesinin üstüne
   alındı: kullanıcı üç konu seçtiğinde `SANA` 102/200'e (%51) çıkıp `YENİ`yi
   13/200'den **4/200'e** düşürüyordu. Nadirlik ilkesinin tersi.

### `TÜMÜ` sekmesi neden var

Sekmeleri **yalnız** ilgi alanlarından kurmak denendi ve ölçüm reddetti:
200 kaydın **67'si** sekiz konunun hiçbirine girmiyor (31'inin konusu yok,
36'sınınki sözlükte karşılıksız). Akışın üçte biri Ana Sayfa'dan **sessizce**
görünmez olurdu.

### Türkçe yazım

`String.toUpperCase()` Unicode varsayılanını uygular ve `i → I` yapar.
Sekme etiketleri için Türkçe büyütme yazıldı (`Mobil → MOBİL`).

**Kaynak adı ise hiç büyütülmüyor.** 14 kaynağın onu iki dilli
(`NVIDIA Geliştirici`, `Visual Studio Code`): varsayılan kural bizim Türkçe
kelimemizi (`GELIŞTIRICI`), Türkçe kural başkasının markasını (`VİSUAL
STUDİO`) bozuyor. İki dilli bir dizgide doğru olan tek biçim adın kendi
yazımı.

**Ölçüm:** dart format 0 · flutter analyze 0 · **896 test** (781 → 896).
Cihazda doğrulandı (OnePlus 8 Pro): soğuk açılış 302–360 ms; sürükle-bırak ile
kurulan sekme sırası uygulama öldürülüp yeniden açıldığında korunuyor.

## D-021 — Tazelik: saatlik üretim, 15 dakikalık istemci aralığı (6 Ağustos 2026)

Kullanıcı sordu: *"12 saat içinde bir gelişme olursa kullanıcı bunu 12 saat
sonra mı görecek?"*

**Ölçülen durum:** aşağı çekme her zaman ağa çıkıyordu; kırık olan **pasif**
yoldu — açılışta tazeleme yalnız içerik 12 saatten eskiyse deneniyordu ve
sunucu 6 saatte bir üretiyordu, yani en kötü ihtimalle **~18 saat** eski
içerik.

12 saatin gerekçesi ("daha sık denemek pil ve veri harcar") kendi
barındırmamız ölçülmeden önce yazılmıştı. **Ölçüm o gerekçeyi geçersiz kıldı**
(gerçek uç nokta, 12 Ağustos): koşullu istek `304` dönüyor, **0 bayt gövde**,
ortanca **62 ms** — koşulsuz istek 193.679 bayt ve 93 ms.

**Değişenler:** cron `17 2,8,14,20 * * *` → `17 * * * *`; `feedStaleAfter`
12 saat → 15 dakika; ve tazeleme aralığı **`feed.json`'a taşındı**
(`refreshAfterMinutes`). Üçüncüsü kritikti: derleme zamanı sabiti olarak
kalsaydı, mağaza yayınından sonra tempo değiştirmek yeni bir APK gerektirir ve
güncellemeyen kullanıcı eski temposunda **kalıcı olarak** kalırdı. `app.db`
sürümü ve `SummaryOrigin` ile aynı sınıf bir tek yönlü kapı; açıkken kapatıldı.

**Sonuç:** en kötü tazelik ~18 saat → **~1 saat**.

**Dürüst tavan:** push bildirimi yok (cihaz jetonu kalıcı cihaz kimliği demek,
D-001 hesapsızlığıyla çelişiyor), kaynakların kendi yayın hızı bir tavan, ve
GitHub zamanlanmış işleri garantili değil (5–20 dk gecikebilir).
