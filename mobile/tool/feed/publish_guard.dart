/// Yayım koruması.
///
/// Üretici tek bir kaynak okunabildiği sürece dosya yazar — bu doğru karar,
/// çünkü bir kaynağın düşmesi koşuyu bitirmemeli. Ama **yayımlamak** ayrı
/// bir karar: 13 kaynağın 12'si düştüğünde üretilen 15 kayıtlık dosya,
/// yayımdaki 200 kayıtlık dosyanın üzerine yazılmamalı. Kullanıcı o gün
/// "içerik güncellendi" görüp akışın yedide birini bulurdu.
///
/// Bu yüzden zamanlayıcı, üreticinin çıktısını doğrudan yayımlamaz; önce
/// buradan geçirir.
///
/// Kullanım:
/// ```
/// dart run tool/feed/publish_guard.dart --next build/feed.json \
///     [--previous yayindaki.json]
/// ```
/// Çıkış kodları: 0 yayımla · 3 değişiklik yok (yayımlama, hata da değil) ·
/// 1 reddedildi (koşu kırmızı olmalı — kaynaklarda bir şey bozuk).
library;

import 'dart:convert';
import 'dart:io';

import 'package:tecnow/data/feed/feed_schema.dart';

enum PublishDecision {
  publish,

  /// Kayıtlar birebir aynı; yalnız üretim damgası değişmiş.
  unchanged,

  /// Yeni dosyada hiç kayıt yok.
  empty,

  /// Kayıt sayısı kabul edilemez ölçüde düşmüş.
  collapsed,

  /// Yeni dosya, yayımdakinden eski.
  notNewer,
}

final class PublishVerdict {
  const PublishVerdict(this.decision, this.message);

  final PublishDecision decision;
  final String message;

  bool get shouldPublish => decision == PublishDecision.publish;

  /// Reddediliş bir **hatadır**: sessizce geçilirse kaynakların bozulduğu
  /// hiç fark edilmez. "Değişiklik yok" hata değildir.
  bool get isFailure =>
      decision != PublishDecision.publish &&
      decision != PublishDecision.unchanged;

  int get exitCode => switch (decision) {
    PublishDecision.publish => 0,
    PublishDecision.unchanged => 3,
    _ => 1,
  };
}

/// Kayıt sayısının düşebileceği en düşük oran.
///
/// 0.6: kaynakların bir kısmı geçici olarak okunamayabilir ve bu normaldir;
/// akışın %40'tan fazlasını kaybetmek normal değildir.
const minRetainedRatio = 0.6;

PublishVerdict evaluatePublish({
  required Feed next,
  Feed? previous,
  double retainedRatio = minRetainedRatio,
}) {
  if (next.items.isEmpty) {
    return const PublishVerdict(
      PublishDecision.empty,
      'Yeni feed boş; yayımdaki dosya korunuyor.',
    );
  }

  if (previous == null) {
    return PublishVerdict(
      PublishDecision.publish,
      'İlk yayım: ${next.items.length} kayıt.',
    );
  }

  if (!next.generatedAt.isAfter(previous.generatedAt)) {
    return PublishVerdict(
      PublishDecision.notNewer,
      'Yeni dosya daha eski ya da aynı damgada '
      '(${next.generatedAt.toIso8601String()} ≤ '
      '${previous.generatedAt.toIso8601String()}).',
    );
  }

  final floor = (previous.items.length * retainedRatio).floor();
  if (next.items.length < floor) {
    return PublishVerdict(
      PublishDecision.collapsed,
      'Kayıt sayısı ${previous.items.length} → ${next.items.length} '
      '(taban $floor). Kaynaklarda bir şey bozuk; yayımdaki dosya korunuyor.',
    );
  }

  if (_sameContent(previous, next)) {
    return const PublishVerdict(
      PublishDecision.unchanged,
      'Kayıtlar aynı; yayımlanacak yeni bir şey yok.',
    );
  }

  return PublishVerdict(
    PublishDecision.publish,
    'Yayımlanıyor: ${next.items.length} kayıt '
    '(önceki ${previous.items.length}).',
  );
}

/// Üretim damgası dışında her şey aynı mı?
///
/// Damga her koşuda değişir; ona bakarak "değişti" demek, hiç değişmeyen bir
/// feed'i her altı saatte bir yeniden yayımlamak olurdu.
bool _sameContent(Feed a, Feed b) =>
    jsonEncode(a.toJson()['items']) == jsonEncode(b.toJson()['items']);

Feed? _readFeed(String path, {required bool required}) {
  final file = File(path);
  if (!file.existsSync()) {
    if (required) throw FileSystemException('Dosya yok', path);
    return null;
  }
  final raw = file.readAsStringSync().trim();
  // Yayımdaki dosya indirilemediğinde boş kalabilir; bu "önceki yok"
  // demektir, "önceki bozuk" değil.
  if (raw.isEmpty) {
    if (required) throw const FormatException('Dosya boş');
    return null;
  }
  return Feed.fromJson(jsonDecode(raw) as Map<String, Object?>);
}

int run(List<String> args) {
  String? nextPath;
  String? previousPath;

  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--next':
        nextPath = i + 1 < args.length ? args[++i] : null;
      case '--previous':
        previousPath = i + 1 < args.length ? args[++i] : null;
      case '--help':
        stdout.writeln(
          'Kullanım: dart run tool/feed/publish_guard.dart '
          '--next <yol> [--previous <yol>]',
        );
        return 0;
    }
  }

  if (nextPath == null) {
    stderr.writeln('--next zorunlu.');
    return 1;
  }

  final next = _readFeed(nextPath, required: true)!;

  // Önceki dosyanın **okunamaması** yayımı engellemez: ilk koşuda yok,
  // sonraki koşularda indirme başarısız olabilir. Karşılaştırma yapılamaz,
  // ama elde geçerli ve dolu bir feed varsa onu yayımlamamak için sebep yok.
  Feed? previous;
  if (previousPath != null) {
    try {
      previous = _readFeed(previousPath, required: false);
    } on Object catch (error) {
      stdout.writeln('  Önceki feed okunamadı ($error); karşılaştırma yok.');
    }
  }

  final verdict = evaluatePublish(next: next, previous: previous);
  final sink = verdict.isFailure ? stderr : stdout;
  sink.writeln('  ${verdict.message}');
  return verdict.exitCode;
}

void main(List<String> args) => exitCode = run(args);
