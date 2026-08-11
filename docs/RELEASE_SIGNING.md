# Sürüm imzası — kurulum

Bu belge, mağazaya yüklenebilir bir paket üretmek için gereken imza anahtarını
anlatır. **Parolalar bu depoya, bir sohbete veya bir ekran görüntüsüne asla
girmez.**

## Neden gerekli

`flutter build appbundle --release` şu an debug anahtarıyla imzalanmış bir
çıktı üretiyor. Play Console bunu **reddeder**. Kendi anahtarınız olmadan
uygulama yayınlanamaz.

## Tek yönlü kapı uyarısı

Play'de bir uygulamanın imza anahtarı **değiştirilemez**. Anahtarı kaybederseniz
o uygulamaya bir daha güncelleme yayımlayamazsınız — kullanıcılar eski sürümde
kalır ve tek çözüm yeni bir uygulama açmaktır (yükleme sayısı, yorumlar ve puan
taşınmaz).

**Play App Signing'i açın.** Google yayın anahtarını kendi tutar, siz yalnızca
bir *yükleme anahtarı* taşırsınız. Yükleme anahtarını kaybederseniz Google
sıfırlayabilir; yayın anahtarını kaybetmek geri dönüşü olmayan bir hatadır.
Bu, Play Console'da uygulamayı ilk oluştururken bir kez sorulur.

## 1 · Anahtarı üret

Bilgisayarınızda, **depo dizininin dışında** bir yere üretin. Örnek: `C:\anahtarlar\`.

```powershell
keytool -genkey -v -keystore C:\anahtarlar\tecos-upload.jks ^
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

`keytool` bulunamazsa JDK'nın `bin` klasöründedir (Android Studio ile gelir):
`C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe`

Komut sırayla soracak:

| Soru | Ne yazılır |
|---|---|
| Keystore password | Kendi belirlediğiniz parola — **not edin** |
| First and last name | Ad soyad ya da `tecOS` |
| Organizational unit / Organization | Boş bırakılabilir |
| City / State / Country code | Şehir, il, `TR` |
| Is CN=... correct? | `yes` |

`-validity 10000` ≈ 27 yıl. Play, anahtarın **2033'ten sonrasına kadar** geçerli
olmasını ister; 10000 bunu fazlasıyla karşılar.

## 2 · `key.properties` dosyasını yaz

`mobile/android/key.properties` oluşturun (`.gitignore`'da, depoya girmez):

```properties
storePassword=BURAYA_KEYSTORE_PAROLASI
keyPassword=BURAYA_ANAHTAR_PAROLASI
keyAlias=upload
storeFile=C:/anahtarlar/tecos-upload.jks
```

Notlar:
- Yol **eğik çizgiyle** (`/`) yazılır, ters eğik çizgiyle değil.
- Genelde iki parola aynıdır; `keytool` ikincisini sormadıysa aynısını yazın.
- Şablon: `mobile/android/key.properties.example`

## 3 · Doğrula

```powershell
cd mobile
flutter build appbundle --release
```

Çıktı: `build/app/outputs/bundle/release/app-release.aab`

Derleme günlüğünde **"UYARI: android/key.properties yok"** satırı görünüyorsa
dosya okunamamıştır — yol ya da dosya adı yanlıştır.

İmzayı gerçekten doğrulamak için:

```powershell
keytool -printcert -jarfile build\app\outputs\bundle\release\app-release.aab
```

Sahip (`Owner`) satırında debug değil, kendi bilgileriniz görünmeli.

## 4 · Yedekle

Kaybı geri alınamaz olan iki şey:

1. `tecos-upload.jks` dosyası
2. Parolaları

İkisini de **iki ayrı yerde** saklayın (ör. şifreli bir disk + bir parola
yöneticisi). Bulut senkronizasyonu olan bir klasöre koyacaksanız dosyayı
şifreleyin.

## Yapılmayacaklar

- Anahtarı ya da parolaları depoya eklemek
- Parolayı bir sohbete, e-postaya ya da ekran görüntüsüne yazmak
- Anahtarı GitHub Actions secret'ı yapmak — CI'da sürüm derlemesi kurulana
  kadar buna gerek yok, ve o gün geldiğinde base64 olarak **ayrı** bir
  yükleme anahtarıyla yapılır
