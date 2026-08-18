/// İçerik güncelliğinin kullanıcıya söylenen hâli.
///
/// Saf fonksiyon: cümle kurma kuralı widget'ın içine gömülseydi, ancak ekran
/// pump edilerek ölçülebilirdi ve "hiç güncellenmedi" ile "güncellenemedi"nin
/// karışması gibi bir hata testten kaçardı.
///
/// Çeviriler **parametre olarak** alınıyor, `BuildContext`'ten okunmuyor —
/// aynı sebeple. `L10n` bir bağlam değil, veri.
library;

import '../data/feed/feed_sync_state.dart';
import '../l10n/app_localizations.dart';

String feedSyncLabel(FeedSyncState state, DateTime now, L10n l10n) {
  if (state.refreshing) return l10n.feedSyncRefreshing;

  // Ağ kapalıyken tarih verilmez. Paketlenmiş içeriğin "ne kadar taze"
  // olduğu sorusunun dürüst cevabı "uygulamayla birlikte geldi"dir; bir
  // tarih göstermek, tutulmayacak bir güncellik sözü verirdi.
  if (!state.remoteEnabled) return l10n.feedSyncBundled;

  if (state.failure != null) {
    return state.lastSyncAt == null
        ? l10n.feedSyncFailedBundled
        : l10n.feedSyncFailedCached(_relative(state.lastSyncAt!, now, l10n));
  }

  if (state.lastSyncAt == null) return l10n.feedSyncNever;
  return l10n.feedSyncLast(_relative(state.lastSyncAt!, now, l10n));
}

/// Geçmiş bir anı göreli ifadeye çevirir.
///
/// Gelecekteki bir zaman damgası "az önce" sayılır: cihazın saati geri
/// alındığında negatif bir süre oluşur ve "-3 saat önce" yazmak, kullanıcının
/// düzeltemeyeceği bir tuhaflık gösterirdi.
String _relative(DateTime moment, DateTime now, L10n l10n) {
  final elapsed = now.difference(moment);
  if (elapsed.inMinutes < 1) return l10n.relativeJustNow;
  if (elapsed.inHours < 1) return l10n.relativeMinutes(elapsed.inMinutes);
  if (elapsed.inDays < 1) return l10n.relativeHours(elapsed.inHours);
  return l10n.relativeDays(elapsed.inDays);
}
