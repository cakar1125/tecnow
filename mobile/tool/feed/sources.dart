/// Üreticinin çektiği kaynaklar.
///
/// Liste **ölçümle** ayarlanır, tahminle değil: her kaynak eklemeden önce
/// gerçekten sonuç döndürdüğü doğrulanır ve boş kalan bir kaynak raporda
/// görünür. Bir kaynağı doldurmak için uydurma yapılmaz.
library;

import 'connectors/connector_support.dart';
import 'connectors/github.dart';
import 'connectors/hugging_face.dart';
import 'connectors/syndication.dart';
import 'source_allowlist.dart';

/// Bağlayıcıların ortak imzası.
typedef FeedParser =
    ConnectorResult Function(String body, {required DateTime checkedAt});

final class FeedSource {
  const FeedSource({
    required this.name,
    required this.url,
    required this.parse,
    this.maxItems = _perSource,
  });

  /// Raporda görünen ad. Bir kaynak boşaldığında hangisi olduğu yazsın diye.
  final String name;
  final Uri url;
  final FeedParser parse;

  /// Bu kaynaktan alınacak en fazla kayıt — **en yenilerden**.
  ///
  /// Sayfalama parametresi yetmez: RSS beslemeleri kaç kayıt döndüreceğini
  /// kendileri seçer. Ölçüldü (2026-07-27): `openai.com/blog/rss.xml` tek
  /// istekte **943 kayıt** döndürdü, yani bloğun tüm geçmişi. Tavan olmadan
  /// tek bir kaynak feed'in tamamını doldurur ve rehber bir şirketin arşivine
  /// dönüşür.
  final int maxItems;
}

/// Bir kaynaktan alınacak varsayılan tavan.
const _perSource = 30;

List<FeedSource> defaultSources() => [
  _githubSearch('GitHub — MCP sunucuları', 'topic:mcp-server stars:>50'),
  _githubSearch('GitHub — Claude skill\'leri', 'topic:claude-skills'),
  _githubReleases('modelcontextprotocol/servers'),

  FeedSource(
    name: 'Hugging Face — modeller',
    // `sort=lastModified` denendi ve **reddedildi**: yüklemesi süren, sıfır
    // indirmeli kayıtları öne çıkarıyor (ölçüldü 2026-07-27, ilk sonuç
    // `upload-in-progress` etiketliydi). İndirmeye göre sıralamak rehberin
    // işine yarayan kaliteli kümeyi verir; tarih sıralamasını feed'in kendisi
    // zaten yapıyor. `full=true` zorunlu — bkz. [huggingFaceModelsQuery].
    url: Uri.https('huggingface.co', '/api/models', {
      'sort': 'downloads',
      'direction': '-1',
      'limit': '$_perSource',
      ...huggingFaceModelsQuery,
    }),
    parse: parseHuggingFaceModels,
  ),

  for (final feed in officialFeeds)
    FeedSource(
      name: 'Blog — ${Uri.parse(feed).host}',
      url: Uri.parse(feed),
      parse: parseSyndicationFeed,
    ),
];

FeedSource _githubSearch(String name, String query) => FeedSource(
  name: name,
  url: Uri.https('api.github.com', '/search/repositories', {
    'q': query,
    'sort': 'updated',
    'order': 'desc',
    'per_page': '$_perSource',
  }),
  parse: parseGitHubRepositories,
);

FeedSource _githubReleases(String repository) => FeedSource(
  name: 'GitHub — $repository sürümleri',
  url: Uri.https('api.github.com', '/repos/$repository/releases', {
    'per_page': '10',
  }),
  parse: parseGitHubReleases,
);
