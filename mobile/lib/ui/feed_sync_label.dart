/// İçerik güncelliğinin kullanıcıya söylenen hâli.
///
/// Saf fonksiyon: cümle kurma kuralı widget'ın içine gömülseydi, ancak ekran
/// pump edilerek ölçülebilirdi ve "hiç güncellenmedi" ile "güncellenemedi"nin
/// karışması gibi bir hata testten kaçardı.
library;

import '../data/feed/feed_sync_state.dart';

String feedSyncLabel(FeedSyncState state, DateTime now) {
  if (state.refreshing) return 'Güncelleniyor…';

  // Ağ kapalıyken tarih verilmez. Paketlenmiş içeriğin "ne kadar taze"
  // olduğu sorusunun dürüst cevabı "uygulamayla birlikte geldi"dir; bir
  // tarih göstermek, tutulmayacak bir güncellik sözü verirdi.
  if (!state.remoteEnabled) return 'İçerik uygulamayla birlikte geliyor';

  if (state.failure != null) {
    return state.lastSyncAt == null
        ? 'Güncellenemedi · paketlenmiş içerik gösteriliyor'
        : 'Güncellenemedi · ${_relative(state.lastSyncAt!, now)} '
              'alınan içerik gösteriliyor';
  }

  if (state.lastSyncAt == null) return 'Henüz güncellenmedi';
  return 'Son güncelleme: ${_relative(state.lastSyncAt!, now)}';
}

/// Geçmiş bir anı Türkçe göreli ifadeye çevirir.
///
/// Gelecekteki bir zaman damgası "az önce" sayılır: cihazın saati geri
/// alındığında negatif bir süre oluşur ve "-3 saat önce" yazmak, kullanıcının
/// düzeltemeyeceği bir tuhaflık gösterirdi.
String _relative(DateTime moment, DateTime now) {
  final elapsed = now.difference(moment);
  if (elapsed.inMinutes < 1) return 'az önce';
  if (elapsed.inHours < 1) return '${elapsed.inMinutes} dakika önce';
  if (elapsed.inDays < 1) return '${elapsed.inHours} saat önce';
  return '${elapsed.inDays} gün önce';
}
