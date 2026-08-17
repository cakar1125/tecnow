import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tecos/data/feed/feed_schema.dart';

import '../../tool/feed/documents.dart';
import '../../tool/feed/fetch.dart';

final _now = DateTime.utc(2026, 8, 17);

FeedItem _item({
  String id = 'a',
  required Uri url,
  FeedSourceKind sourceKind = FeedSourceKind.github,
}) => FeedItem(
  id: id,
  kind: FeedItemKind.repository,
  title: 'owner/repo',
  summary: 'Bir araç.',
  summaryOrigin: SummaryOrigin.original,
  sourceName: 'GitHub',
  sourceKind: sourceKind,
  url: url,
  publishedAt: _now,
  checkedAt: _now,
  language: 'en',
  trust: const TrustSignals(
    officialSource: false,
    hasLicense: true,
    recentlyUpdated: true,
    maintained: true,
  ),
);

/// Adrese göre cevap veren sahte getirici. Ağa çıkılmaz.
final class FakeFetcher implements FeedFetcher {
  FakeFetcher(this.responses);

  final Map<String, FetchResponse> responses;
  final requested = <Uri>[];

  @override
  Future<FetchResponse> fetch(Uri url) async {
    requested.add(url);
    return responses[url.toString()] ??
        const FetchResponse(statusCode: 404, body: '');
  }
}

/// Her istekte fırlatan getirici.
final class ExplodingFetcher implements FeedFetcher {
  var calls = 0;

  @override
  Future<FetchResponse> fetch(Uri url) async {
    calls++;
    throw const SocketExceptionStub();
  }
}

final class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}

String _gitHubReadme(String markdown) => jsonEncode({
  'encoding': 'base64',
  'content': base64.encode(utf8.encode(markdown)),
});

void main() {
  group('belge adresi', () {
    test('GitHub deposu için API yoluna çevrilir', () {
      final url = documentUrlFor(
        _item(url: Uri.parse('https://github.com/owner/repo')),
      );
      // Token yalnız `api.github.com`'a gönderiliyor; ham dosya yolu
      // seçilseydi saatlik sınır 60'ta kalırdı.
      expect(url.toString(), 'https://api.github.com/repos/owner/repo/readme');
    });

    test('Hugging Face modeli için kart yoluna çevrilir', () {
      final url = documentUrlFor(
        _item(
          url: Uri.parse('https://huggingface.co/meta-llama/Llama-3'),
          sourceKind: FeedSourceKind.huggingFace,
        ),
      );
      expect(
        url.toString(),
        'https://huggingface.co/meta-llama/Llama-3/raw/main/README.md',
      );
    });

    test('depo kökü olmayan GitHub adresi elenir', () {
      // Sürüm adresinin README'si yok ve sürüm notu zaten düzyazı.
      final url = documentUrlFor(
        _item(url: Uri.parse('https://github.com/owner/repo/releases/tag/v1')),
      );
      expect(url, isNull);
    });

    test('blog ve dokümantasyon için belge çekilmez', () {
      for (final kind in [
        FeedSourceKind.officialBlog,
        FeedSourceKind.documentation,
        FeedSourceKind.other,
      ]) {
        final url = documentUrlFor(
          _item(
            url: Uri.parse('https://openai.com/index/bir-yazi'),
            sourceKind: kind,
          ),
        );
        expect(url, isNull, reason: '$kind için istek yapılmamalı');
      }
    });
  });

  group('markdown temizleme', () {
    test('YAML ön bilgisi atılır', () {
      const raw = '---\nlicense: mit\ntags:\n- llm\n---\nGerçek metin burada.';
      expect(cleanDocument(raw), 'Gerçek metin burada.');
    });

    test('kod blokları atılır', () {
      const raw = 'Kurulum aşağıda.\n```bash\nnpm install foo\n```\nBitti.';
      final text = cleanDocument(raw);
      expect(text, isNot(contains('npm install')));
      expect(text, contains('Kurulum aşağıda.'));
      expect(text, contains('Bitti.'));
    });

    test('rozet ve görseller atılır, bağlantı metni kalır', () {
      const raw =
          '[![build](https://img.shields.io/x.svg)](https://ci.example.com)\n'
          'Ayrıntı için [belgelere](https://example.com/docs) bakın.';
      final text = cleanDocument(raw);
      // Adres kalsaydı kapı ([verifySummary]) onu "kaynakta var" sayar ve
      // model özete bağlantı yazabilirdi.
      expect(text, isNot(contains('http')));
      expect(text, contains('belgelere'));
    });

    test('başlık işaretleri ve HTML temizlenir', () {
      const raw = '# Başlık\n<p align="center">Orta</p>\n- madde';
      final text = cleanDocument(raw);
      expect(text, isNot(contains('#')));
      expect(text, isNot(contains('<p')));
      expect(text, contains('Başlık'));
      expect(text, contains('madde'));
    });

    test('sınır aşılırsa kırpılır', () {
      final raw = 'kelime ' * 500;
      final text = cleanDocument(raw, charLimit: 100);
      expect(text.length, lessThanOrEqualTo(101));
      expect(text, endsWith('…'));
    });
  });

  group('belge çekme', () {
    test('GitHub yanıtı base64 çözülür', () async {
      final fetcher = FakeFetcher({
        'https://api.github.com/repos/owner/repo/readme': FetchResponse(
          statusCode: 200,
          body: _gitHubReadme('# Araç\nDizin ağaçlarını karşılaştırır.'),
        ),
      });

      final documents = await fetchDocuments([
        _item(url: Uri.parse('https://github.com/owner/repo')),
      ], fetcher: fetcher);

      expect(documents['a'], contains('Dizin ağaçlarını karşılaştırır.'));
    });

    test('404 kaydı düşürmez, yalnız belgesiz bırakır', () async {
      final fetcher = FakeFetcher(const {});
      final documents = await fetchDocuments([
        _item(url: Uri.parse('https://github.com/owner/repo')),
      ], fetcher: fetcher);

      // README'si olmayan depo var; bu bir hata değil.
      expect(documents, isEmpty);
    });

    test('ağ hatası yukarı taşınmaz', () async {
      final fetcher = ExplodingFetcher();
      final documents = await fetchDocuments([
        _item(url: Uri.parse('https://github.com/owner/repo')),
      ], fetcher: fetcher);

      // Belge bir iyileştirmedir; yokluğu feed'i düşürmemeli.
      expect(documents, isEmpty);
      expect(fetcher.calls, 1);
    });

    test('sınır aşılınca istek yapılmaz', () async {
      final fetcher = FakeFetcher(const {});
      final items = [
        for (var i = 0; i < 10; i++)
          _item(id: 'i$i', url: Uri.parse('https://github.com/owner/repo$i')),
      ];

      await fetchDocuments(items, fetcher: fetcher, limit: 3);

      expect(fetcher.requested, hasLength(3));
    });

    test('belgesi olamayacak kayıt sınırdan düşmez', () async {
      final fetcher = FakeFetcher(const {});
      final items = [
        _item(
          id: 'blog',
          url: Uri.parse('https://openai.com/index/yazi'),
          sourceKind: FeedSourceKind.officialBlog,
        ),
        _item(id: 'repo', url: Uri.parse('https://github.com/owner/repo')),
      ];

      await fetchDocuments(items, fetcher: fetcher, limit: 1);

      // Blog kaydı istek üretmediği için bütçeyi harcamamalı; aksi hâlde
      // listenin başındaki bloglar depoların hepsini bloke ederdi.
      expect(fetcher.requested, hasLength(1));
      expect(fetcher.requested.single.host, 'api.github.com');
    });
  });
}
