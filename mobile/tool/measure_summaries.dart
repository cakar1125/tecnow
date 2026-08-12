/// Özet sağlayıcısının **canlı yolunu** ölçer.
///
/// `summarize.dart` içindeki iki sağlayıcı da bugüne kadar hiç
/// çalıştırılmadı ve dosyanın kendisi bunu yazıyor: *"Bu sınıfın canlı yolu
/// ölçülmedi — geliştirme sırasında elde anahtar yoktu."* Test altında olan
/// şey anahtarsız yol, doğrulama kapısı ve reddedilen özetin orijinale
/// düşmesi; **gerçek API yanıtı değil**.
///
/// Bu araç o boşluğu kapatıyor. Üretimi çalıştırmıyor, hiçbir dosyayı
/// değiştirmiyor: paketlenmiş feed'den birkaç gerçek kayıt alıp modele
/// veriyor, kapıdan geçiriyor ve sonucu yan yana yazıyor. Ölçülen dört şey:
///
/// 1. Sağlayıcı gerçekten cevap veriyor mu (uç nokta, kimlik doğrulama, biçim)
/// 2. Yanıt ayrıştırılabiliyor mu (`parseOpenAiText` / `parseAnthropicText`)
/// 3. `summary_guard` kaç özeti reddediyor — ret oranı sağlayıcı
///    karşılaştırmasının ölçütü (D-015 ile aynı disiplin)
/// 4. Çıktı gerçekten hedef dilde mi — bunu hiçbir kapı ölçemez, göz ölçer
///
/// Kullanım:
/// ```
/// NVIDIA_API_KEY=... dart run tool/measure_summaries.dart [--count 5]
///                                                        [--language tr]
/// ```
///
/// Anahtar **ortamdan** okunur, hiçbir yere yazılmaz.
library;

import 'dart:convert';
import 'dart:io';

import 'package:tecos/data/feed/feed_schema.dart';

import 'feed/summarize.dart';
import 'feed/summary_guard.dart';

Future<int> main(List<String> args) async {
  var count = 5;
  var language = feedDefaultLanguage;
  var path = 'assets/feed/feed.json';

  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--count':
        count = int.tryParse(i + 1 < args.length ? args[++i] : '') ?? count;
      case '--language':
        language = i + 1 < args.length ? args[++i] : language;
      case '--feed':
        path = i + 1 < args.length ? args[++i] : path;
    }
  }

  final anthropicKey = Platform.environment['ANTHROPIC_API_KEY'];
  final nvidiaKey = Platform.environment['NVIDIA_API_KEY'];

  final Summarizer summarizer;
  final String provider;
  if (nvidiaKey != null && nvidiaKey.isNotEmpty) {
    final model =
        Platform.environment['NVIDIA_MODEL'] ?? 'meta/llama-3.3-70b-instruct';
    provider = 'NVIDIA · $model';
    summarizer = NvidiaSummarizer(apiKey: nvidiaKey, model: model);
  } else if (anthropicKey != null && anthropicKey.isNotEmpty) {
    provider = 'Anthropic';
    summarizer = AnthropicSummarizer(apiKey: anthropicKey);
  } else {
    stderr.writeln('Anahtar yok: NVIDIA_API_KEY ya da ANTHROPIC_API_KEY ver.');
    return 1;
  }

  final decoded = jsonDecode(File(path).readAsStringSync());
  final feed = Feed.fromJson((decoded as Map).cast<String, Object?>());

  // Yalnız henüz özetlenmemiş kayıtlar: zaten Türkçe olan bir kaydı yeniden
  // özetlemek, ölçmek istediğimiz şeyi ölçmez.
  final candidates = feed.items
      .where((item) => item.summaryOrigin == SummaryOrigin.original)
      .take(count)
      .toList(growable: false);

  stdout
    ..writeln('sağlayıcı : $provider')
    ..writeln(
      'hedef dil : $language (${summaryLanguageNames[language] ?? language})',
    )
    ..writeln('kayıt     : ${candidates.length} / ${feed.items.length}')
    ..writeln('');

  var accepted = 0;
  var failed = 0;
  final rejected = <SummaryRejection, int>{};
  final stopwatch = Stopwatch();

  for (final item in candidates) {
    final sourceText = sourceTextOf(item);
    stdout
      ..writeln('── ${item.title}')
      ..writeln('   kaynak : ${_clip(item.summary)}');

    String? generated;
    stopwatch
      ..reset()
      ..start();
    try {
      generated = await summarizer.summarize(
        title: item.title,
        sourceText: sourceText,
        language: language,
      );
    } catch (error) {
      stopwatch.stop();
      failed++;
      stdout
        ..writeln('   HATA   : $error')
        ..writeln('');
      continue;
    }
    stopwatch.stop();

    if (generated == null) {
      stdout
        ..writeln('   BOŞ    : sağlayıcı özet üretmedi')
        ..writeln('');
      continue;
    }

    final verdict = verifySummary(summary: generated, sourceText: sourceText);
    if (verdict.isAccepted) {
      accepted++;
      stdout.writeln('   ÖZET   : ${generated.trim()}');
    } else {
      rejected.update(verdict.rejection!, (n) => n + 1, ifAbsent: () => 1);
      stdout
        ..writeln('   RED    : ${verdict.rejection!.name}')
        ..writeln('   çıktı  : ${_clip(generated.trim())}');
    }
    stdout
      ..writeln('   süre   : ${stopwatch.elapsedMilliseconds} ms')
      ..writeln('');
  }

  stdout
    ..writeln('kabul     : $accepted / ${candidates.length}')
    ..writeln('hata      : $failed')
    ..writeln('ret       : ${rejected.isEmpty ? '-' : rejected}');
  return 0;
}

String _clip(String text) =>
    text.length <= 110 ? text : '${text.substring(0, 110)}…';
