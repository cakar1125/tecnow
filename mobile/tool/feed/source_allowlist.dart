/// Kaynak allowlist'i.
///
/// `docs/CONTENT_TRUST_POLICY.md`: *"Birincil tercih: GitHub, Hugging Face,
/// resmi şirket blogları, resmi dokümantasyon ve araştırma makaleleri."*
///
/// Allowlist **kapalı bir listedir**: listede olmayan hiçbir host feed'e
/// giremez. Yeni bir kaynak eklemek bilinçli bir karardır ve bu dosyada
/// görünür — üreticinin bir yerinde sessizce genişleyemez.
library;

import 'package:tecnow/data/feed/feed_schema.dart';

/// Bir gelişmenin **sahibi** olan hostlar.
///
/// Buradan gelen kayıtlar `TrustSignals.officialSource` alır: duyuruyu
/// yapan kurumun kendi adresi, üçüncü taraf aktarımı değil.
const _officialHosts = <String>{
  // Yapay zekâ laboratuvarları ve model sağlayıcılar
  'openai.com',
  'anthropic.com',
  'blog.google',
  'googleblog.com', // developers. / android-developers. alt alanlarını kapsar
  'deepmind.google',
  'ai.meta.com',
  'mistral.ai',
  'huggingface.co',
  // Çatılar ve altyapı
  'pytorch.org',
  'developer.nvidia.com',
  'aws.amazon.com',
  // Geliştirici platformları
  'github.blog',
  'developer.chrome.com',
  'web.dev',
  'code.visualstudio.com',
  'docs.flutter.dev',
  'dart.dev',
};

/// İçerik barındıran ama sahibi olmayan platformlar.
///
/// GitHub bir depoyu "yayımlamaz", barındırır; bu yüzden buradan gelen
/// kayıtlar varsayılan olarak resmi sayılmaz. İstisna: deponun sahibi
/// [_officialGitHubOwners] içindeyse resmi kabul edilir.
const _platformHosts = <String>{'github.com', 'huggingface.co'};

/// Üreticinin **istek atabileceği**, ama feed'de **görünemeyecek** hostlar.
///
/// `api.github.com` bir içerik adresi değildir: kullanıcıya gösterilecek şey
/// `github.com/sahip/depo`dur. Veri buradan çekilir, ama bu host içerik
/// allowlist'ine konsaydı bir API yanıtı yayımlanabilir bir kaynak hâline
/// gelirdi. İki soru ayrı: *nereden çekiyoruz* ve *neyi gösteriyoruz*.
const _apiHosts = <String>{'api.github.com'};

/// Resmi dokümantasyon hostları. Blogdan ayrılırlar: dokümantasyon bir
/// duyuru değil, sürekli güncellenen başvuru metnidir.
const _documentationHosts = <String>{'docs.flutter.dev', 'dart.dev'};

/// Platform hostlarında **platformun kendisine** ait yollar.
///
/// `huggingface.co` iki şey birden: hem başkalarının modellerini barındıran
/// bir platform hem de kendi blogunun yayıncısı. `huggingface.co/blog/...`
/// Hugging Face'in kendi yazısıdır ve resmidir; `huggingface.co/biri/model`
/// barındırılan içeriktir ve sahibine bakılarak karar verilir.
///
/// Bu ayrım olmadan kurumun kendi blogu "üçüncü taraf" sayılıyordu — ilk
/// sahip segmenti `blog` olduğu ve sahip listesinde bulunmadığı için.
const _platformOwnedPaths = <String, Set<String>>{
  'huggingface.co': {'blog'},
};

/// GitHub/Hugging Face üzerinde kurumun kendi hesabı.
const _officialGitHubOwners = <String>{
  'openai',
  'anthropic-experimental',
  'anthropics',
  'google',
  'google-deepmind',
  'googleapis',
  'meta-llama',
  'facebookresearch',
  'mistralai',
  'huggingface',
  'pytorch',
  'nvidia',
  'flutter',
  'dart-lang',
  'modelcontextprotocol',
};

/// Küratörlü bir besleme.
///
/// Adres tek başına yetmez: bu listenin **denetlenebilir** olması gerekiyor.
/// Kim yayımlıyor ve en önemlisi **ne zaman doğrulandı** — ikisi de
/// kaydediliyor ki listeye bakan biri "bu adres hâlâ yaşıyor mu" sorusunu
/// tarihe bakarak sorabilsin.
final class CuratedFeed {
  const CuratedFeed({
    required this.url,
    required this.name,
    required this.publisher,
    required this.verifiedOn,
    required this.usableAtVerification,
  });

  final String url;

  /// Raporda ve kayıt üzerinde görünen ad.
  final String name;

  /// Yayımlayan kurum.
  final String publisher;

  /// Adresin canlı olarak denendiği tarih.
  final String verifiedOn;

  /// Doğrulama anında beslemeden **kullanılabilir** çıkan kayıt sayısı.
  ///
  /// `<item>` etiketlerini saymak değil: üretici gerçekten çalıştırılıp
  /// ayrıştırmadan sağ çıkan kayıtlar sayıldı. Fark önemli — Hugging Face
  /// blogu 831 `<item>` döndürüyor ama hiçbirinde açıklama yok, yani
  /// kullanılabilir sayısı **sıfır**. Ham etiket sayısına bakan bir doğrulama
  /// bu kaynağı listeye alırdı.
  final int usableAtVerification;

  Uri get uri => Uri.parse(url);
}

/// Resmi RSS/Atom kaynakları.
///
/// Her biri [_officialHosts] içindeki bir hosta ait olmalıdır; test bunu
/// doğrular, böylece allowlist'e girmeyen bir blog feed listesine sızamaz.
///
/// **Test üyeliği doğrular, varlığı değil.** Ağsız bir süit bir adresin
/// gerçekten yanıt verdiğini ölçemez. Aşağıdakilerin tamamı 2026-07-28'de
/// tek tek denendi, 200 döndürdü, RSS/Atom olarak ayrıştırıldı **ve üretici
/// koşusunda gerçekten kayıt verdi**. Yeni bir besleme eklenirken aynısı
/// yapılmalı.
///
/// Denenip **listeye alınmayanlar** — aynı hatayı ikinci kez yapmamak için:
///
/// | Aday | Sonuç |
/// |---|---|
/// | `anthropic.com` (9 farklı yol) | hepsi 404, keşfedilebilir beslemesi yok |
/// | `cohere.com/blog/rss.xml` | **200 ama HTML** — durum koduna bakmak yanıltır |
/// | `stability.ai/news?format=rss` | 200 ama HTML |
/// | `blog.langchain.dev/rss/` | 200 ama HTML |
/// | `deepmind.google/discover/blog/rss.xml` | 404 (doğrusu `/blog/rss.xml`) |
/// | `blog.cohere.com` | alan adı çözülmüyor |
/// | `ai.meta.com/blog/rss/` | bağlantı kapanıyor, iki denemede de |
/// | `openai.com/news/rss.xml` | çalışıyor ama `/blog/rss.xml` ile **birebir aynı** |
/// | `huggingface.co/blog/feed.xml` | 200, geçerli RSS, 831 kayıt — **hiçbirinde açıklama yok** |
/// | `developers.googleblog.com/feeds/posts/default` | 200, geçerli RSS, 20 kayıt — **hiçbirinde `pubDate` yok** |
///
/// Son iki satır bu listenin en pahalı dersi. İkisi de 200 döndü, ikisi de
/// düzgün RSS'ti, ikisi de ayrıştırıldı — ve ikisi de feed'e **sıfır** kayıt
/// verdi. Biri açıklama alanını hiç göndermiyor, diğeri tarih alanını.
/// Eksik alanı `checkedAt` ile doldurmak teknik olarak kolaydı ve
/// `CONTENT_TRUST_POLICY.md`'yi ihlal ederdi: yayın tarihi uydurmak, eski bir
/// yazıyı bugün çıkmış gibi göstermek demektir. Kaynaklar çıkarıldı.
///
/// Çıkan ders: durum kodu yetmez, geçerli XML yetmez — bir kaynağın
/// **kullanılabilir kayıt verdiği** ölçülmeden listeye alınmaz.
const officialFeeds = <CuratedFeed>[
  // --- Yapay zekâ laboratuvarları ------------------------------------------
  CuratedFeed(
    url: 'https://openai.com/blog/rss.xml',
    name: 'OpenAI',
    publisher: 'OpenAI',
    verifiedOn: '2026-07-28',
    usableAtVerification: 943,
  ),
  CuratedFeed(
    url: 'https://blog.google/technology/ai/rss/',
    name: 'Google AI',
    publisher: 'Google',
    verifiedOn: '2026-07-28',
    usableAtVerification: 20,
  ),
  CuratedFeed(
    url: 'https://deepmind.google/blog/rss.xml',
    name: 'Google DeepMind',
    publisher: 'Google DeepMind',
    verifiedOn: '2026-07-28',
    usableAtVerification: 83,
  ),
  CuratedFeed(
    url: 'https://mistral.ai/rss.xml',
    name: 'Mistral AI',
    publisher: 'Mistral AI',
    verifiedOn: '2026-07-28',
    usableAtVerification: 19,
  ),

  // --- Çatılar ve altyapı ---------------------------------------------------
  CuratedFeed(
    url: 'https://pytorch.org/blog/feed.xml',
    name: 'PyTorch',
    publisher: 'PyTorch Foundation',
    verifiedOn: '2026-07-28',
    usableAtVerification: 10,
  ),
  CuratedFeed(
    url: 'https://developer.nvidia.com/blog/feed/',
    name: 'NVIDIA Geliştirici',
    publisher: 'NVIDIA',
    verifiedOn: '2026-07-28',
    usableAtVerification: 100,
  ),
  CuratedFeed(
    url: 'https://aws.amazon.com/blogs/machine-learning/feed/',
    name: 'AWS Makine Öğrenmesi',
    publisher: 'Amazon Web Services',
    verifiedOn: '2026-07-28',
    usableAtVerification: 20,
  ),

  // --- Geliştirici platformları ---------------------------------------------
  CuratedFeed(
    url: 'https://github.blog/feed/',
    name: 'GitHub Blog',
    publisher: 'GitHub',
    verifiedOn: '2026-07-28',
    usableAtVerification: 10,
  ),
  CuratedFeed(
    url: 'https://github.blog/changelog/feed/',
    name: 'GitHub Değişiklikler',
    publisher: 'GitHub',
    verifiedOn: '2026-07-28',
    usableAtVerification: 10,
  ),
  CuratedFeed(
    url: 'https://android-developers.googleblog.com/feeds/posts/default',
    name: 'Android Geliştirici',
    publisher: 'Google',
    verifiedOn: '2026-07-28',
    usableAtVerification: 25,
  ),
  CuratedFeed(
    url: 'https://developer.chrome.com/static/blog/feed.xml',
    name: 'Chrome Geliştirici',
    publisher: 'Google',
    verifiedOn: '2026-07-28',
    usableAtVerification: 10,
  ),
  CuratedFeed(
    url: 'https://web.dev/static/blog/feed.xml',
    name: 'web.dev',
    publisher: 'Google',
    verifiedOn: '2026-07-28',
    usableAtVerification: 10,
  ),
  CuratedFeed(
    url: 'https://code.visualstudio.com/feed.xml',
    name: 'Visual Studio Code',
    publisher: 'Microsoft',
    verifiedOn: '2026-07-28',
    usableAtVerification: 48,
  ),
];

/// Bir host'un allowlist'te olup olmadığını ve resmi sayılıp sayılmadığını
/// söyler.
abstract final class SourceAllowlist {
  /// Feed'e girebilecek hostlar: resmi kaynaklar + barındırma platformları.
  static bool isAllowed(Uri url) {
    if (url.scheme != 'https') return false;
    final host = _normalizeHost(url.host);
    return _officialHosts.contains(host) ||
        _platformHosts.contains(host) ||
        _officialHosts.any((allowed) => host.endsWith('.$allowed'));
  }

  /// Kurumun kendi adresi mi?
  ///
  /// Platform hostlarında (GitHub, Hugging Face) karar **sahibe** bakılarak
  /// verilir: `github.com/anthropics/...` resmidir, `github.com/biri/...`
  /// değildir. Platformun kendi bölümü ([_platformOwnedPaths]) ayrıdır.
  static bool isOfficial(Uri url) {
    final host = _normalizeHost(url.host);
    if (_platformHosts.contains(host)) {
      final owner = _firstPathSegment(url);
      if (owner == null) return false;
      // Platformun kendi bölümü mü, yoksa barındırdığı bir içerik mi?
      if (_platformOwnedPaths[host]?.contains(owner) ?? false) return true;
      return _officialGitHubOwners.contains(owner);
    }
    return _officialHosts.contains(host) ||
        _officialHosts.any((allowed) => host.endsWith('.$allowed'));
  }

  /// Üretici bu adrese istek atabilir mi?
  ///
  /// İçerik allowlist'i **artı** API uçları. [isAllowed] ile karıştırılmamalı:
  /// istek atılabilen her adres, gösterilebilir değildir.
  static bool isFetchable(Uri url) =>
      isAllowed(url) ||
      (url.scheme == 'https' && _apiHosts.contains(_normalizeHost(url.host)));

  /// Adresin hangi kaynak türüne ait olduğunu söyler.
  ///
  /// Host bilgisi tek bir yerde dursun diye burada: bağlayıcılar kendi
  /// içlerinde ayrı host listeleri tutsaydı, biri güncellenip diğeri
  /// unutulurdu.
  static FeedSourceKind sourceKindFor(Uri url) {
    final host = _normalizeHost(url.host);
    if (host == 'github.com') return FeedSourceKind.github;
    if (host == 'huggingface.co') return FeedSourceKind.huggingFace;
    if (_documentationHosts.contains(host)) return FeedSourceKind.documentation;
    return FeedSourceKind.officialBlog;
  }

  /// Allowlist dışı kayıtları eler. Üretici, ayıklanan kayıtları günlüğe
  /// yazar — sessizce kaybolmazlar.
  static Iterable<Uri> rejected(Iterable<Uri> urls) =>
      urls.where((url) => !isAllowed(url));

  static String _normalizeHost(String host) =>
      host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');

  static String? _firstPathSegment(Uri url) {
    for (final segment in url.pathSegments) {
      if (segment.isNotEmpty) return segment.toLowerCase();
    }
    return null;
  }
}
