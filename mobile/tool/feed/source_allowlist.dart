/// Kaynak allowlist'i.
///
/// `docs/CONTENT_TRUST_POLICY.md`: *"Birincil tercih: GitHub, Hugging Face,
/// resmi şirket blogları, resmi dokümantasyon ve araştırma makaleleri."*
///
/// Allowlist **kapalı bir listedir**: listede olmayan hiçbir host feed'e
/// giremez. Yeni bir kaynak eklemek bilinçli bir karardır ve bu dosyada
/// görünür — üreticinin bir yerinde sessizce genişleyemez.
library;

import 'package:teknoakis/data/feed/feed_schema.dart';

/// Bir gelişmenin **sahibi** olan hostlar.
///
/// Buradan gelen kayıtlar `TrustSignals.officialSource` alır: duyuruyu
/// yapan kurumun kendi adresi, üçüncü taraf aktarımı değil.
const _officialHosts = <String>{
  'openai.com',
  'anthropic.com',
  'blog.google',
  'ai.googleblog.com',
  'ai.meta.com',
  'mistral.ai',
  'deepmind.google',
  'huggingface.co',
  'pytorch.org',
  'developer.nvidia.com',
  'docs.flutter.dev',
  'dart.dev',
};

/// İçerik barındıran ama sahibi olmayan platformlar.
///
/// GitHub bir depoyu "yayımlamaz", barındırır; bu yüzden buradan gelen
/// kayıtlar varsayılan olarak resmi sayılmaz. İstisna: deponun sahibi
/// [_officialGitHubOwners] içindeyse resmi kabul edilir.
const _platformHosts = <String>{'github.com', 'huggingface.co'};

/// Resmi dokümantasyon hostları. Blogdan ayrılırlar: dokümantasyon bir
/// duyuru değil, sürekli güncellenen başvuru metnidir.
const _documentationHosts = <String>{'docs.flutter.dev', 'dart.dev'};

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

/// Resmi RSS/Atom kaynakları.
///
/// Her biri [_officialHosts] içindeki bir hosta ait olmalıdır; test bunu
/// doğrular, böylece allowlist'e girmeyen bir blog feed listesine sızamaz.
const officialFeeds = <String>[
  'https://openai.com/blog/rss.xml',
  'https://www.anthropic.com/news/rss.xml',
  'https://blog.google/technology/ai/rss/',
  'https://mistral.ai/feed.xml',
  'https://pytorch.org/feed.xml',
  'https://developer.nvidia.com/blog/feed/',
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
  /// değildir.
  static bool isOfficial(Uri url) {
    final host = _normalizeHost(url.host);
    if (_platformHosts.contains(host)) {
      final owner = _firstPathSegment(url);
      return owner != null && _officialGitHubOwners.contains(owner);
    }
    return _officialHosts.contains(host) ||
        _officialHosts.any((allowed) => host.endsWith('.$allowed'));
  }

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
