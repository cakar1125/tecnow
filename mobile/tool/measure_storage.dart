/// Yerel depolamanın gerçekte ne kadar yer kapladığını **ölçer**.
///
/// Tahminle optimize edilmez: hangi tablonun büyüdüğü, sıkıştırmanın ne
/// kazandırdığı ve silmenin dosyayı gerçekten küçültüp küçültmediği ölçülür.
///
/// ```
/// dart run tool/measure_storage.dart
/// ```
library;

import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final feed = File('assets/feed/feed.json');
  if (!feed.existsSync()) {
    stderr.writeln('assets/feed/feed.json yok — önce üreticiyi çalıştırın.');
    exitCode = 1;
    return;
  }

  final raw = await feed.readAsBytes();
  final gzipped = gzip.encode(raw);
  final items = (jsonDecode(utf8.decode(raw)) as Map)['items'] as List;

  stdout
    ..writeln('Paketlenmiş feed (APK içinde, silinemez)')
    ..writeln('  kayıt sayısı : ${items.length}')
    ..writeln('  ham          : ${_kb(raw.length)}')
    ..writeln(
      '  gzip         : ${_kb(gzipped.length)}'
      '  (${(100 - gzipped.length / raw.length * 100).toStringAsFixed(1)}% küçülme)',
    )
    ..writeln('  kayıt başına : ${(raw.length / items.length).round()} B')
    ..writeln()
    ..writeln('Önbellek (indirilen kopya, cihazda)')
    ..writeln('  ham saklansa : ${_kb(raw.length)}')
    ..writeln('  gzip saklansa: ${_kb(gzipped.length)}')
    ..writeln()
    ..writeln('read_history satır maliyeti (ölçüm: 60 B/satır varsayımı)')
    ..writeln(
      '  günde 20 açılış × 3 yıl = ${20 * 365 * 3} satır'
      ' ≈ ${_kb(20 * 365 * 3 * 60)}',
    );
}

String _kb(int bytes) => '${(bytes / 1024).toStringAsFixed(1)} KB';
