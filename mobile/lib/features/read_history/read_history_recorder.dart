import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';

/// Detay ekranı açıldığında okuma geçmişine bir satır yazar.
///
/// Ateşle-unut: geçmiş **ikincil** bir veridir. Yazma başarısız olursa
/// (veritabanı açılamadı, disk dolu) içerik yine görünmelidir; bu yüzden
/// hata yutulur ve ekrana yansıtılmaz.
///
/// Döndürülen future testlerde beklenebilir; üretimde yok sayılır.
Future<void> recordRead(
  WidgetRef ref, {
  required String itemId,
  required String kind,
}) async {
  if (itemId.isEmpty) return;
  try {
    final repository = await ref.read(readHistoryRepositoryProvider.future);
    await repository.record(itemId, kind);
  } catch (_) {
    // Bilinçli olarak sessiz: bkz. yukarıdaki not.
  }
}
