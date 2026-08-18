import 'package:flutter_test/flutter_test.dart';
import 'package:tecos/data/feed/feed_sync_state.dart';
import 'package:tecos/l10n/app_localizations_en.dart';
import 'package:tecos/l10n/app_localizations_tr.dart';
import 'package:tecos/ui/feed_sync_label.dart';

final _now = DateTime.utc(2026, 7, 27, 12);
final _tr = L10nTr();
final _en = L10nEn();

String _label(FeedSyncState state) => feedSyncLabel(state, _now, _tr);

void main() {
  /// Paketlenmiş içeriğin "ne kadar taze" olduğu sorusunun dürüst cevabı
  /// "uygulamayla birlikte geldi"dir. Bir tarih göstermek, tutulmayacak bir
  /// güncellik sözü verirdi.
  test('ağ kapalıyken tarih vaat edilmez', () {
    final label = _label(const FeedSyncState(remoteEnabled: false));

    expect(label, 'İçerik uygulamayla birlikte geliyor');
    expect(label, isNot(contains('güncelleme')));
  });

  /// Ağ kapalıyken "henüz güncellenmedi" demek, bir gün güncelleneceğini
  /// ima ederdi — o derlemede güncellenmeyecek.
  test('ağ kapalıysa hata ve zaman durumu bunu değiştirmez', () {
    expect(
      _label(
        FeedSyncState(
          remoteEnabled: false,
          lastSyncAt: _now.subtract(const Duration(hours: 2)),
          failure: 'Bağlantı kurulamadı',
        ),
      ),
      'İçerik uygulamayla birlikte geliyor',
    );
  });

  test('hiç senkronize edilmemişse öyle söylenir', () {
    expect(
      _label(const FeedSyncState(remoteEnabled: true)),
      'Henüz güncellenmedi',
    );
  });

  test('tazeleme sırasında durum bildirilir', () {
    expect(
      _label(const FeedSyncState(remoteEnabled: true, refreshing: true)),
      'Güncelleniyor…',
    );
  });

  group('son güncelleme zamanı', () {
    String labelFor(Duration elapsed) => _label(
      FeedSyncState(remoteEnabled: true, lastSyncAt: _now.subtract(elapsed)),
    );

    test('bir dakikadan yeniyse "az önce"', () {
      expect(labelFor(const Duration(seconds: 30)), 'Son güncelleme: az önce');
    });

    test('dakika, saat ve gün eşikleri', () {
      expect(
        labelFor(const Duration(minutes: 1)),
        'Son güncelleme: 1 dakika önce',
      );
      expect(
        labelFor(const Duration(minutes: 59)),
        'Son güncelleme: 59 dakika önce',
      );
      expect(labelFor(const Duration(hours: 1)), 'Son güncelleme: 1 saat önce');
      expect(
        labelFor(const Duration(hours: 23)),
        'Son güncelleme: 23 saat önce',
      );
      expect(labelFor(const Duration(days: 1)), 'Son güncelleme: 1 gün önce');
      expect(labelFor(const Duration(days: 12)), 'Son güncelleme: 12 gün önce');
    });

    /// Cihazın saati geri alındığında geçen süre negatif olur. "-3 saat önce"
    /// yazmak, kullanıcının düzeltemeyeceği bir tuhaflık gösterirdi.
    test('gelecekteki zaman damgası "az önce" sayılır', () {
      expect(labelFor(const Duration(hours: -5)), 'Son güncelleme: az önce');
    });
  });

  group('başarısız deneme', () {
    /// "Hiç güncellenmedi" ile "güncellenemedi" aynı şey değil: ikincisinde
    /// gösterilen içerik gerçekten bir kez ağdan alınmış olabilir.
    test('daha önce alınan içerik varsa yaşı söylenir', () {
      final label = _label(
        FeedSyncState(
          remoteEnabled: true,
          lastSyncAt: _now.subtract(const Duration(hours: 3)),
          failure: 'Bağlantı kurulamadı',
        ),
      );

      expect(label, startsWith('Güncellenemedi'));
      expect(label, contains('3 saat önce'));
    });

    test('hiç alınmamışsa paketlenmiş içerik denir', () {
      expect(
        _label(
          const FeedSyncState(
            remoteEnabled: true,
            failure: 'Bağlantı kurulamadı',
          ),
        ),
        'Güncellenemedi · paketlenmiş içerik gösteriliyor',
      );
    });

    /// Tazeleme sürerken eski hata cümlesi ekranda kalmamalı.
    test('yeniden denenirken hata gösterilmez', () {
      expect(
        _label(
          const FeedSyncState(
            remoteEnabled: true,
            refreshing: true,
            failure: 'Bağlantı kurulamadı',
          ),
        ),
        'Güncelleniyor…',
      );
    });
  });

  /// Aynı kural İngilizcede de geçerli olmalı. Çeviri, davranışı sessizce
  /// değiştirebilecek tek yer: bir dilde tarih vaat etmeyen cümle, öbür dilde
  /// vaat edebilir ve bunu hiçbir Türkçe test yakalamaz.
  group('İngilizce', () {
    String label(FeedSyncState state) => feedSyncLabel(state, _now, _en);

    test('ağ kapalıyken tarih vaat edilmez', () {
      expect(
        label(const FeedSyncState(remoteEnabled: false)),
        'Content ships with the app',
      );
    });

    test('çoğul biçimleri ayrışır', () {
      String forElapsed(Duration elapsed) => label(
        FeedSyncState(remoteEnabled: true, lastSyncAt: _now.subtract(elapsed)),
      );

      // Türkçede tekil/çoğul ayrımı yok, İngilizcede var: ICU çoğul biçimi
      // gerçekten kuruluyor mu, ancak burada ölçülebilir.
      expect(forElapsed(const Duration(minutes: 1)), contains('1 minute ago'));
      expect(forElapsed(const Duration(minutes: 5)), contains('5 minutes ago'));
      expect(forElapsed(const Duration(hours: 1)), contains('1 hour ago'));
      expect(forElapsed(const Duration(days: 3)), contains('3 days ago'));
    });

    test('hata durumu içeriği gizlemez', () {
      final text = label(
        FeedSyncState(
          remoteEnabled: true,
          lastSyncAt: _now.subtract(const Duration(hours: 3)),
          failure: 'Bağlantı kurulamadı',
        ),
      );

      expect(text, startsWith("Couldn't update"));
      expect(text, contains('3 hours ago'));
    });
  });

  /// Teknik ayrıntı kullanıcıya gösterilmez; hata cümlesi durumu anlatır,
  /// yığın izini değil.
  test('etiket ham hata metnini ekrana taşımaz', () {
    expect(
      _label(
        const FeedSyncState(
          remoteEnabled: true,
          failure: 'SocketException: Failed host lookup',
        ),
      ),
      isNot(contains('SocketException')),
    );
  });
}
