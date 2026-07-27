/// Arayüzün içerik güncelliği hakkında bildiği her şey.
///
/// Dört durum ayrı ayrı taşınıyor çünkü kullanıcıya söylenecek cümle her
/// birinde farklı ve hiçbiri diğerinin yerine geçmiyor: "hiç güncellenmedi"
/// ile "güncellenemedi" aynı şey değildir, "ağ kapalı" ise bir sorun bile
/// değildir.
library;

final class FeedSyncState {
  const FeedSyncState({
    required this.remoteEnabled,
    this.lastSyncAt,
    this.refreshing = false,
    this.failure,
  });

  /// Uzak adres yapılandırılmış mı. `false` ise arayüz tazeleme kontrolünü
  /// **hiç göstermez**: çalışmayacağı bilinen bir düğme sahte bir işlev
  /// vaadidir.
  final bool remoteEnabled;

  /// Son başarılı senkronizasyon; hiç olmadıysa `null`.
  final DateTime? lastSyncAt;

  final bool refreshing;

  /// Son denemenin hata cümlesi. Başarıda temizlenir — eski bir hatayı
  /// ekranda bırakmak, düzelmiş bir durumu bozuk göstermek olurdu.
  final String? failure;

  FeedSyncState copyWith({
    DateTime? lastSyncAt,
    bool? refreshing,
    String? failure,
    bool clearFailure = false,
  }) => FeedSyncState(
    remoteEnabled: remoteEnabled,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    refreshing: refreshing ?? this.refreshing,
    failure: clearFailure ? null : (failure ?? this.failure),
  );
}
