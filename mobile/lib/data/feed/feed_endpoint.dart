/// Uzak feed adresi — **derleme zamanı** yapılandırması.
///
/// ```
/// flutter build apk --dart-define=FEED_URL=https://ornek.test/feed.json
/// ```
///
/// Varsayılanı bilinçli olarak **yoktur**. Barındırma kararı (TASK-0017)
/// verilmeden buraya bir adres yazmak, var olmayan bir sunucuya her açılışta
/// istek atan bir uygulama demek olurdu. Tanımsızken ağ tazelemesi kapalıdır
/// ve uygulama paketlenmiş içerikle tam olarak çalışır — arayüz de bunu
/// olduğu gibi söyler, "güncelleniyor" numarası yapmaz.
library;

/// Derleme zamanında verilen ham değer. Verilmediyse boş dizedir.
const feedUrlFromEnvironment = String.fromEnvironment('FEED_URL');

/// Ham değeri kullanılabilir bir adrese çevirir; kullanılamıyorsa `null`.
///
/// **Yalnız `https`.** Düz metin bir feed, aradaki herhangi bir ağın içeriği
/// değiştirebilmesi demektir; bu uygulamanın bütün güven anlatısı içeriğin
/// denetlenmiş bir hattan gelmesine dayandığı için `http` kabul edilmez.
/// Yerel geliştirme için de gevşetilmez: bir kere açılan delik, derleme
/// bayrağı yanlış ayarlanmış her sürümde açık kalır.
///
/// Geçersiz bir değer sessizce yok sayılır ([null] döner) ve uygulama
/// paketlenmiş içerikle çalışmaya devam eder. Açılışta istisna fırlatmak,
/// yanlış yazılmış bir derleme bayrağı yüzünden **hiç açılmayan** bir
/// uygulama üretirdi.
Uri? parseFeedEndpoint(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final url = Uri.tryParse(trimmed);
  if (url == null) return null;
  if (url.scheme != 'https') return null;
  if (url.host.isEmpty) return null;
  return url;
}
