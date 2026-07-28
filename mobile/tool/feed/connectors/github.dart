/// GitHub bağlayıcısı.
///
/// Ağ yok: bu dosya yalnız **ham yanıt gövdesini** `FeedItem`'a çevirir.
/// İndirme işi üreticinindir; ayrıştırma böylece fixture'larla test edilir.
///
/// İki uç nokta desteklenir:
/// * `/search/repositories` (ya da düz depo listesi) → [parseGitHubRepositories]
/// * `/repos/{owner}/{repo}/releases` → [parseGitHubReleases]
library;

import 'package:teknoakis/data/feed/feed_schema.dart';

import '../source_allowlist.dart';
import 'connector_support.dart';

/// MCP sunucusu olduğunu **deponun kendisi** beyan eden konular.
///
/// Skill ve MCP için olgun bir dizin API'si yok. Bu yüzden tür, deponun kendi
/// konu etiketlerinden çıkarılır; ad ya da açıklama üzerinden tahmin
/// yürütülmez. Liste bilinçli olarak dardır: eşleşme yoksa kayıt
/// `repository` kalır. Yanlış etiketlemektense etiketlememek doğrudur.
const _mcpTopics = <String>{
  'mcp',
  'mcp-server',
  'mcp-servers',
  'model-context-protocol',
};

/// Claude/agent skill'i olduğunu beyan eden konular.
const _skillTopics = <String>{'agent-skills', 'claude-skill', 'claude-skills'};

/// Geliştiriciye doğrudan araç sunduğunu beyan eden konular.
///
/// Keşfet'in "AI Araçları" çipi `tool` türüne bakıyor ve bu tür 28 Temmuz
/// 2026'ya kadar **hiçbir bağlayıcı tarafından üretilmiyordu**: çip her
/// zaman boş sonuç veriyordu. Sınıflandırma, `mcp` ve `skill` ile aynı
/// desende — deponun kendi beyan ettiği konulardan okunuyor, tahmin
/// edilmiyor.
const _toolTopics = <String>{
  'ai-tools',
  'llm-tools',
  'developer-tools',
  'devtools',
  'cli-tool',
};

/// Depo listesini ayrıştırır.
///
/// `search/repositories` yanıtı `{"items": [...]}` biçimindedir; düz bir depo
/// dizisi de kabul edilir.
ConnectorResult parseGitHubRepositories(
  String body, {
  required DateTime checkedAt,
}) {
  final entries = _entries(body, 'items');
  final items = <FeedItem>[];
  final skipped = <SkippedRecord>[];

  for (final entry in entries) {
    if (entry == null) {
      skipped.add(const SkippedRecord('<kayıt>', SkipReason.malformed));
      continue;
    }

    final name = jsonString(entry, 'full_name') ?? jsonString(entry, 'name');
    final label = name ?? jsonString(entry, 'html_url') ?? '<isimsiz>';

    final url = jsonUrl(entry, 'html_url');
    if (url == null) {
      skipped.add(SkippedRecord(label, SkipReason.missingUrl));
      continue;
    }
    if (!SourceAllowlist.isAllowed(url)) {
      skipped.add(SkippedRecord(label, SkipReason.notAllowed));
      continue;
    }
    if (name == null) {
      skipped.add(SkippedRecord(label, SkipReason.missingTitle));
      continue;
    }
    if (entry['private'] == true) {
      skipped.add(SkippedRecord(name, SkipReason.private));
      continue;
    }

    final description = jsonString(entry, 'description');
    if (description == null) {
      skipped.add(SkippedRecord(name, SkipReason.missingSummary));
      continue;
    }

    final createdAt = parseFeedDate(jsonString(entry, 'created_at'));
    if (createdAt == null) {
      skipped.add(SkippedRecord(name, SkipReason.missingDate));
      continue;
    }

    // Depo "ne zaman ortaya çıktı" sorusunun cevabı `created_at`; `pushed_at`
    // ise canlılık ölçüsüdür. İkisi farklı sorulara cevap verir.
    final pushedAt = parseFeedDate(jsonString(entry, 'pushed_at')) ?? createdAt;
    final topics = jsonStringList(entry, 'topics');
    final abandoned = entry['archived'] == true || entry['disabled'] == true;

    items.add(
      FeedItem(
        id: feedItemId(url),
        kind: _kindFromTopics(topics),
        title: name,
        summary: truncateSummary(normalizeSpaces(description)),
        summaryOrigin: SummaryOrigin.original,
        sourceName: 'GitHub',
        sourceKind: FeedSourceKind.github,
        url: url,
        publishedAt: createdAt,
        checkedAt: checkedAt,
        language: 'en',
        trust: TrustSignals(
          officialSource: SourceAllowlist.isOfficial(url),
          hasLicense: entry['license'] != null,
          recentlyUpdated: isWithin(pushedAt, checkedAt, recentWindow),
          maintained:
              !abandoned && isWithin(pushedAt, checkedAt, maintainedWindow),
          popularity: jsonInt(entry, 'stargazers_count'),
        ),
        topics: topics,
      ),
    );
  }

  return ConnectorResult(items: items, skipped: skipped);
}

/// Sürüm listesini ayrıştırır. Her sürüm bir duyurudur.
///
/// **`prerelease` bayrağına güvenilmez.** Gerçek yanıtta ölçüldü
/// (2026-07-27): `flutter/flutter` beta sürümleri — `3.19.0-0.1.pre` — bu
/// alanı `false` olarak işaretliyor. Beta ayıklaması bu bayrakla yapılamaz;
/// yapılırsa çalıştığı sanılır ve çalışmaz. Yalnız `draft` güvenilirdir.
ConnectorResult parseGitHubReleases(
  String body, {
  required DateTime checkedAt,
}) {
  final entries = _entries(body, null);
  final items = <FeedItem>[];
  final skipped = <SkippedRecord>[];

  for (final entry in entries) {
    if (entry == null) {
      skipped.add(const SkippedRecord('<kayıt>', SkipReason.malformed));
      continue;
    }

    final version = jsonString(entry, 'tag_name') ?? jsonString(entry, 'name');
    final label = version ?? jsonString(entry, 'html_url') ?? '<isimsiz>';

    final url = jsonUrl(entry, 'html_url');
    if (url == null) {
      skipped.add(SkippedRecord(label, SkipReason.missingUrl));
      continue;
    }
    if (!SourceAllowlist.isAllowed(url)) {
      skipped.add(SkippedRecord(label, SkipReason.notAllowed));
      continue;
    }
    // Taslak sürüm yayımlanmamıştır; adresi de herkese açık değildir.
    if (entry['draft'] == true) {
      skipped.add(SkippedRecord(label, SkipReason.draft));
      continue;
    }

    final repository = _repositoryOf(url);
    if (version == null || repository == null) {
      skipped.add(SkippedRecord(label, SkipReason.missingTitle));
      continue;
    }

    final notes = jsonString(entry, 'body');
    if (notes == null) {
      skipped.add(
        SkippedRecord('$repository $version', SkipReason.missingSummary),
      );
      continue;
    }

    final publishedAt =
        parseFeedDate(jsonString(entry, 'published_at')) ??
        parseFeedDate(jsonString(entry, 'created_at'));
    if (publishedAt == null) {
      skipped.add(
        SkippedRecord('$repository $version', SkipReason.missingDate),
      );
      continue;
    }

    items.add(
      FeedItem(
        id: feedItemId(url),
        kind: FeedItemKind.announcement,
        title: '$repository $version',
        summary: truncateSummary(flattenReleaseNotes(notes)),
        summaryOrigin: SummaryOrigin.original,
        sourceName: 'GitHub',
        sourceKind: FeedSourceKind.github,
        url: url,
        publishedAt: publishedAt,
        checkedAt: checkedAt,
        language: 'en',
        trust: TrustSignals(
          officialSource: SourceAllowlist.isOfficial(url),
          // Sürüm yanıtı lisans bilgisi taşımaz; bilinmeyeni "var" saymak
          // güven puanını şişirirdi.
          hasLicense: false,
          recentlyUpdated: isWithin(publishedAt, checkedAt, recentWindow),
          maintained: isWithin(publishedAt, checkedAt, maintainedWindow),
        ),
      ),
    );
  }

  return ConnectorResult(items: items, skipped: skipped);
}

FeedItemKind _kindFromTopics(List<String> topics) {
  final set = topics.map((topic) => topic.toLowerCase()).toSet();
  if (set.intersection(_mcpTopics).isNotEmpty) return FeedItemKind.mcp;
  if (set.intersection(_skillTopics).isNotEmpty) return FeedItemKind.skill;
  if (set.intersection(_toolTopics).isNotEmpty) return FeedItemKind.tool;
  return FeedItemKind.repository;
}

/// `https://github.com/owner/repo/releases/tag/v1` → `owner/repo`.
String? _repositoryOf(Uri url) {
  final segments = url.pathSegments.where((s) => s.isNotEmpty).toList();
  return segments.length < 2 ? null : '${segments[0]}/${segments[1]}';
}

List<Map<String, Object?>?> _entries(String body, String? key) =>
    jsonEntries(body, key, sourceLabel: 'GitHub');
