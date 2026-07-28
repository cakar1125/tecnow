import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';

/// Detay ekranı açıldığında okuma geçmişine bir satır yazar.
///
/// Ateşle-unut: geçmiş **ikincil** bir veridir. Yazma başarısız olursa
/// (veritabanı açılamadı, disk dolu) içerik yine görünmelidir; bu yüzden
/// hata yutulur ve ekrana yansıtılmaz.
///
/// Yazma **sağlayıcı üzerinden** yapılır, doğrudan depoya değil. Depoya yazmak
/// çalışıyordu ama kimseye haber vermiyordu: ölçüldü (2026-07-28, cihazda) iki
/// içerik açıldıktan sonra veritabanında iki satır varken Ayarlar "0 kayıt"
/// yazıyordu. Sağlayıcı, hem geçmiş listesini hem ondan türeyen adedi
/// güncelliyor.
///
/// Döndürülen future testlerde beklenebilir; üretimde yok sayılır.
Future<void> recordRead(
  WidgetRef ref, {
  required String itemId,
  required String kind,
}) async {
  if (itemId.isEmpty) return;
  try {
    await ref.read(readHistoryProvider.notifier).record(itemId, kind);
  } catch (_) {
    // Bilinçli olarak sessiz: bkz. yukarıdaki not.
  }
}
