/// Uzak feed adresleri — **derleme zamanı** yapılandırması.
///
/// ```
/// flutter build apk \
///   --dart-define=FEED_URL=https://feed.ornek.test/feed.json \
///   --dart-define=FEED_URL_FALLBACK=https://ornek.github.io/ayna/feed.json
/// ```
///
/// Varsayılanı bilinçli olarak **yoktur**. Barındırma kararı (TASK-0017)
/// verilmeden buraya bir adres yazmak, var olmayan bir sunucuya her açılışta
/// istek atan bir uygulama demek olurdu. Tanımsızken ağ tazelemesi kapalıdır
/// ve uygulama paketlenmiş içerikle tam olarak çalışır — arayüz de bunu
/// olduğu gibi söyler, "güncelleniyor" numarası yapmaz.
///
/// ## Neden iki adres
///
/// Adres APK'ya derleme zamanında gömülüyor ve çalışma zamanında
/// değiştirilemiyor. Kendi alan adımızı kullanmak barındırıcı değişimini
/// çözer (DNS çevrilir, kurulu uygulamalar etkilenmez) ama **alan adının
/// kendisinin kaybını** çözmez: süresi dolarsa ya da DNS kesilirse yayın
/// yapılacak bir yer kalmadığı için yeni adresi duyurmanın da yolu yoktur.
///
/// Yedek adres tam olarak bu deliği kapatır ve bu yüzden birincilden
/// **bağımsız bir kökende** olmalıdır. Özel alan adı tanımlandığında GitHub,
/// `<kullanıcı>.github.io/<depo>` adresini o alan adına yönlendirir; yani
/// birincil deponun kendi `github.io` adresi yedek olamaz — alan adı ölürse
/// yönlendirme de ölü adrese gider. Yedek, özel alan adı olmayan ayrı bir
/// yayın olmalıdır.
library;

/// Derleme zamanında verilen ham değerler. Verilmediyse boş dizedir.
const feedUrlFromEnvironment = String.fromEnvironment('FEED_URL');
const feedFallbackUrlFromEnvironment = String.fromEnvironment(
  'FEED_URL_FALLBACK',
);

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

/// Denenecek adresler, **sırayla**: önce birincil, sonra yedek.
///
/// Geçersiz olan atlanır. Birincil bozuk yazılmışsa yedek tek başına
/// kullanılır: yanlış yazılmış bir derleme bayrağının cezası, çalışabilecek
/// bir yedeği de kapatmak olmamalı.
///
/// Aynı adres iki kez verilmişse bir kez denenir — aksi hâlde çöken bir
/// sunucuya arka arkaya iki istek atılırdı.
List<Uri> parseFeedEndpoints(String primary, String fallback) {
  final endpoints = <Uri>[];
  for (final raw in [primary, fallback]) {
    final url = parseFeedEndpoint(raw);
    if (url == null) continue;
    if (endpoints.contains(url)) continue;
    endpoints.add(url);
  }
  return List.unmodifiable(endpoints);
}
