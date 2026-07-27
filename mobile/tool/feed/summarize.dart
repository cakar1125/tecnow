/// Türkçe TeknoAkış özeti — **derleme zamanı**.
///
/// Uygulama AI'a hiç dokunmaz: anahtar burada, üreticinin ortam değişkeninde
/// durur ve mobil pakete girmez. Üretilen özet feed'e **metin olarak** iner.
///
/// Katman iki durumda da doğru çalışmak zorunda:
/// * **Anahtar yok** → hiç çağrı yapılmaz, her kayıt kaynağın kendi metniyle
///   ([SummaryOrigin.original]) yayımlanır. Anahtar bir kolaylıktır, koşul
///   değil; feed anahtarsız da eksiksiz üretilir.
/// * **Anahtar var** → özet üretilir, `summary_guard`'dan geçirilir ve ancak
///   geçerse kullanılır. Reddedilen özet atılır, kayıt orijinal açıklamasıyla
///   kalır. En kötü durumda içerik İngilizce kalır; asla uydurulmuş olmaz.
library;

import 'dart:convert';
import 'dart:io';

import 'package:teknoakis/data/feed/feed_schema.dart';

import 'summary_guard.dart';

/// Modelin gördüğü tek şey başlık ve kaynağın kendi açıklamasıdır.
///
/// Tarih, kimlik, yıldız sayısı gibi makine alanları **verilmez** — sebebi
/// `summary_guard.dart` içinde ölçülmüş hâliyle yazılı: tarih metne girerse
/// izin verilen sayı havuzu genişler ve uydurulmuş bir fiyat kapıdan geçer.
String sourceTextOf(FeedItem item) => '${item.title}\n${item.summary}';

abstract interface class Summarizer {
  /// Türkçe özet döndürür; üretemezse `null`.
  ///
  /// `null` bir hata değildir: "bu kayıt için özet yok" demektir ve kayıt
  /// orijinal metniyle yayımlanır.
  Future<String?> summarize({
    required String title,
    required String sourceText,
  });
}

/// Anahtar yokken kullanılan. Hiçbir çağrı yapmaz.
final class DisabledSummarizer implements Summarizer {
  const DisabledSummarizer();

  @override
  Future<String?> summarize({
    required String title,
    required String sourceText,
  }) async => null;
}

/// Bir koşuda yapılacak en fazla çağrı.
///
/// Maliyet kapısı: üretici düzenli aralıklarla çalışacak ve her koşuda her
/// kaydı yeniden özetlemek gereksiz masraftır. Sınır aşıldığında kalan
/// kayıtlar orijinal metinleriyle kalır — koşu **başarısız olmaz**.
const defaultSummaryBudget = 60;

final class SummaryPass {
  const SummaryPass({
    required this.items,
    this.summarized = 0,
    this.rejected = const {},
    this.failed = 0,
    this.budgetExhausted = false,
  });

  final List<FeedItem> items;

  /// Kapıdan geçip Türkçeye çevrilen kayıt sayısı.
  final int summarized;

  /// Reddedilen özetler, sebebiyle. "Neden İngilizce kaldı" sorusunun cevabı.
  final Map<SummaryRejection, int> rejected;

  /// Model çağrısı hata verdi. Kayıt orijinal metniyle kaldı.
  final int failed;

  final bool budgetExhausted;
}

/// Özet katmanını uygular.
///
/// Yalnız [SummaryOrigin.original] taşıyan kayıtlar adaydır: TeknoAkış'ın
/// kendi kurduğu cümleler (Hugging Face yapısal özeti) zaten Türkçedir ve
/// yeniden özetlenmez.
Future<SummaryPass> applySummaries(
  List<FeedItem> items, {
  required Summarizer summarizer,
  int budget = defaultSummaryBudget,
}) async {
  final result = <FeedItem>[];
  final rejected = <SummaryRejection, int>{};
  var summarized = 0;
  var failed = 0;
  var calls = 0;

  for (final item in items) {
    if (item.summaryOrigin != SummaryOrigin.original || calls >= budget) {
      result.add(item);
      continue;
    }

    final sourceText = sourceTextOf(item);
    String? generated;
    try {
      calls++;
      generated = await summarizer.summarize(
        title: item.title,
        sourceText: sourceText,
      );
    } catch (_) {
      // Model çağrısı bir kaydı düşürebilir, koşuyu değil.
      failed++;
      result.add(item);
      continue;
    }

    if (generated == null) {
      result.add(item);
      continue;
    }

    final verdict = verifySummary(summary: generated, sourceText: sourceText);
    if (!verdict.isAccepted) {
      rejected.update(
        verdict.rejection!,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      result.add(item);
      continue;
    }

    summarized++;
    result.add(
      item.withSummary(
        summary: generated.trim(),
        summaryOrigin: SummaryOrigin.teknoakis,
        language: 'tr',
      ),
    );
  }

  return SummaryPass(
    items: result,
    summarized: summarized,
    rejected: rejected,
    failed: failed,
    budgetExhausted: calls >= budget,
  );
}

/// Anthropic Messages API ile özetler.
///
/// **Bu sınıfın canlı yolu ölçülmedi**: geliştirme sırasında elde anahtar
/// yoktu. Anahtarsız yol, doğrulama kapısı ve reddedilen özetin orijinale
/// düşmesi test altındadır; gerçek API yanıtı değildir. İlk anahtarlı koşuda
/// çıktı gözle doğrulanmalı.
final class AnthropicSummarizer implements Summarizer {
  AnthropicSummarizer({
    required this.apiKey,
    this.model = 'claude-haiku-4-5-20251001',
    this.timeout = const Duration(seconds: 30),
  });

  /// Ortam değişkeninden gelir. Depoya yazılmaz, uygulamaya gömülmez.
  final String apiKey;

  /// Kısa metinlerin toplu özeti için en ucuz uygun model.
  final String model;

  final Duration timeout;

  static final _endpoint = Uri.https('api.anthropic.com', '/v1/messages');

  /// Yönerge kısıtlayıcıdır: kapı zaten uydurma sayıyı reddediyor, ama
  /// reddedilen her özet boşa harcanmış bir çağrıdır.
  static const _instruction =
      'Aşağıdaki teknoloji duyurusunu Türkçe olarak en fazla iki cümlede '
      'özetle. Kaynakta geçmeyen hiçbir sayı, oran, fiyat, ölçüt ya da '
      'bağlantı ekleme. Yorum katma, tanıtım dili kullanma. Yalnızca özeti '
      'yaz, başka hiçbir şey yazma.';

  @override
  Future<String?> summarize({
    required String title,
    required String sourceText,
  }) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.postUrl(_endpoint);
      request.headers
        ..set('x-api-key', apiKey)
        ..set('anthropic-version', '2023-06-01')
        ..set(HttpHeaders.contentTypeHeader, 'application/json');
      request.write(
        jsonEncode({
          'model': model,
          'max_tokens': 300,
          'messages': [
            {'role': 'user', 'content': '$_instruction\n\n$sourceText'},
          ],
        }),
      );

      final response = await request.close().timeout(timeout);
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) {
        throw HttpException('Anthropic API ${response.statusCode}: $body');
      }
      return _textOf(body);
    } finally {
      client.close(force: true);
    }
  }

  /// Yanıttan metni çıkarır. Beklenmeyen bir biçimde `null` döner: kayıt
  /// orijinal metniyle kalır, tahmin edilmez.
  static String? _textOf(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map) return null;
    final content = decoded['content'];
    if (content is! List) return null;
    final buffer = StringBuffer();
    for (final block in content) {
      if (block is Map && block['type'] == 'text' && block['text'] is String) {
        buffer.write(block['text']);
      }
    }
    final text = buffer.toString().trim();
    return text.isEmpty ? null : text;
  }
}
