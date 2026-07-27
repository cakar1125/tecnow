/// RSS / Atom bağlayıcısı.
///
/// Ağ yok; besleme gövdesini `FeedItem`'a çevirir.
///
/// İki biçim de desteklenir çünkü resmi bloglar ikisini de kullanır: RSS 2.0
/// (`<rss><channel><item>`) ve Atom (`<feed><entry>`). Ad alanları (namespace)
/// kaynaktan kaynağa değiştiği için elemanlar **nitelikli adla değil, yerel
/// adla** aranır; `dc:date` ile `date` aynı muameleyi görür.
///
/// Beslemedeki her bağlantı allowlist'ten geçirilir: resmi bir blogun kendi
/// beslemesi üçüncü taraf bir siteye link verebilir ve bu, allowlist'i dolanan
/// bir arka kapı olurdu.
library;

import 'package:teknoakis/data/feed/feed_schema.dart';
import 'package:xml/xml.dart';

import '../source_allowlist.dart';
import 'connector_support.dart';

ConnectorResult parseSyndicationFeed(
  String body, {
  required DateTime checkedAt,
}) {
  final XmlDocument document;
  try {
    document = XmlDocument.parse(body);
  } on XmlException catch (error) {
    throw ConnectorException('Besleme XML olarak okunamadı: ${error.message}');
  }

  final root = document.rootElement;
  final isAtom = root.localName == 'feed';
  final channel = isAtom ? root : _descendant(root, 'channel') ?? root;

  final feedTitle = _childText(channel, 'title');
  final language = _language(channel, root);

  final entries = _descendants(root, isAtom ? 'entry' : 'item');
  final items = <FeedItem>[];
  final skipped = <SkippedRecord>[];

  for (final entry in entries) {
    final title = _childText(entry, 'title');
    final label = title ?? _link(entry, isAtom)?.toString() ?? '<başlıksız>';

    final url = _link(entry, isAtom);
    if (url == null) {
      skipped.add(SkippedRecord(label, SkipReason.missingUrl));
      continue;
    }
    if (!SourceAllowlist.isAllowed(url)) {
      skipped.add(SkippedRecord(label, SkipReason.notAllowed));
      continue;
    }
    if (title == null) {
      skipped.add(SkippedRecord(label, SkipReason.missingTitle));
      continue;
    }

    final rawSummary =
        _childText(entry, 'description') ??
        _childText(entry, 'summary') ??
        _childText(entry, 'encoded') ??
        _childText(entry, 'content');
    final summary = rawSummary == null ? null : stripHtml(rawSummary);
    if (summary == null || summary.isEmpty) {
      skipped.add(SkippedRecord(title, SkipReason.missingSummary));
      continue;
    }

    final publishedAt =
        parseFeedDate(_childText(entry, 'pubDate')) ??
        parseFeedDate(_childText(entry, 'published')) ??
        parseFeedDate(_childText(entry, 'date')) ??
        parseFeedDate(_childText(entry, 'updated'));
    if (publishedAt == null) {
      skipped.add(SkippedRecord(title, SkipReason.missingDate));
      continue;
    }

    items.add(
      FeedItem(
        id: feedItemId(url),
        kind: FeedItemKind.announcement,
        title: normalizeSpaces(title),
        summary: truncateSummary(summary),
        summaryOrigin: SummaryOrigin.original,
        sourceName: feedTitle == null ? url.host : normalizeSpaces(feedTitle),
        sourceKind: SourceAllowlist.sourceKindFor(url),
        url: url,
        publishedAt: publishedAt,
        checkedAt: checkedAt,
        language: language,
        trust: TrustSignals(
          officialSource: SourceAllowlist.isOfficial(url),
          // Bir blog yazısının lisansı yoktur; "yok" demek doğru cevaptır.
          hasLicense: false,
          recentlyUpdated: isWithin(publishedAt, checkedAt, recentWindow),
          // Yayın akışı sürüyorsa kaynak canlıdır. Yazının kendisi
          // güncellenmez; ölçülen şey kaynağın etkinliğidir.
          maintained: isWithin(publishedAt, checkedAt, maintainedWindow),
        ),
        topics: _categories(entry),
      ),
    );
  }

  return ConnectorResult(items: items, skipped: skipped);
}

/// RSS bağlantıyı eleman metninde, Atom `href` niteliğinde taşır. Atom'da
/// `rel="alternate"` (ya da rel'siz) olan insan tarafından okunacak sayfadır;
/// `rel="self"` beslemenin kendi adresidir ve içerik değildir.
Uri? _link(XmlElement entry, bool isAtom) {
  if (!isAtom) {
    final raw = _childText(entry, 'link');
    return raw == null ? null : _absolute(raw);
  }

  Uri? fallback;
  for (final link in _children(entry, 'link')) {
    final rel = link.getAttribute('rel');
    final href = link.getAttribute('href');
    if (href == null) continue;
    final url = _absolute(href);
    if (url == null) continue;
    if (rel == null || rel == 'alternate') return url;
    fallback ??= url;
  }
  return fallback;
}

Uri? _absolute(String raw) {
  final url = Uri.tryParse(raw.trim());
  return url != null && url.isAbsolute ? url : null;
}

/// RSS `<language>en-us</language>`, Atom `xml:lang="en"`. İkisi de yoksa
/// varsayılan `en`: resmi kaynakların neredeyse tamamı İngilizce yayımlıyor.
String _language(XmlElement channel, XmlElement root) {
  final declared =
      _childText(channel, 'language') ??
      root.getAttribute('xml:lang') ??
      root.getAttribute('lang');
  if (declared == null) return 'en';
  final code = declared.trim().toLowerCase();
  return code.length < 2 ? 'en' : code.substring(0, 2);
}

/// RSS kategoriyi eleman metninde, Atom `term` niteliğinde taşır.
List<String> _categories(XmlElement entry) => _children(entry, 'category')
    .map((node) => (node.getAttribute('term') ?? node.innerText).trim())
    .where((value) => value.isNotEmpty)
    .map((value) => value.toLowerCase())
    .toSet()
    .toList(growable: false);

Iterable<XmlElement> _children(XmlElement parent, String localName) =>
    parent.childElements.where((child) => child.localName == localName);

Iterable<XmlElement> _descendants(XmlElement root, String localName) =>
    root.descendantElements.where((node) => node.localName == localName);

XmlElement? _descendant(XmlElement root, String localName) =>
    _descendants(root, localName).firstOrNull;

String? _childText(XmlElement parent, String localName) {
  for (final child in _children(parent, localName)) {
    final text = child.innerText.trim();
    if (text.isNotEmpty) return text;
  }
  return null;
}
