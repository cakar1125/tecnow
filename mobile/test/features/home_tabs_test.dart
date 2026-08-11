import 'package:flutter_test/flutter_test.dart';
import 'package:tecos/data/interests/interest_taxonomy.dart';
import 'package:tecos/features/feed/home_tabs.dart';

import '../support/test_overrides.dart';

Interest _interest(String id) => interestById(id)!;

void main() {
  group('şerit kurulumu', () {
    test('seçim yokken yalnız iki sabit sekme kalır', () {
      final tabs = homeTabsFor(const []);

      expect(tabs.map((tab) => tab.key), ['sana-ozel', 'tumu']);
    });

    test('konular ikisinin arasına verilen sırayla girer', () {
      final tabs = homeTabsFor([_interest('bulut'), _interest('oyun')]);

      expect(tabs.map((tab) => tab.key), [
        'sana-ozel',
        'bulut',
        'oyun',
        'tumu',
      ]);
    });

    /// `SANA ÖZEL` başta, `TÜMÜ` sonda — sıralama ikisinin arasında yapılır.
    test('sabit sekmeler uçlarda kalır', () {
      final tabs = homeTabsFor([
        for (final interest in interestTaxonomy) interest,
      ]);

      expect(tabs.first.key, HomeTab.forYou.key);
      expect(tabs.last.key, HomeTab.all.key);
      expect(tabs, hasLength(interestTaxonomy.length + 2));
    });

    /// `toUpperCase()` "Mobil"i "MOBIL", "Veri Bilimi"ni "VERI BILIMI"
    /// yapıyor — Türkçede `i`'nin büyüğü `İ`. Sekme etiketi kullanıcının
    /// gördüğü ilk metin; orada yanlış yazım kabul edilebilir değil.
    test('etiketler Türkçe büyütülür', () {
      final labels = {
        for (final tab in homeTabsFor(interestTaxonomy.toList()))
          if (tab.interest case final interest?) interest.id: tab.label,
      };

      expect(labels['mobil'], 'MOBİL');
      expect(labels['veri-bilimi'], 'VERİ BİLİMİ');
      expect(labels['siber-guvenlik'], 'SİBER GÜVENLİK');
      // Doğru çalışan harfler de kilitli: düzeltme yalnız `i`'yi
      // değiştirmeli, `ı → I` zaten doğru.
      expect(labels['donanim'], 'DONANIM');
      expect(labels['acik-kaynak'], 'AÇIK KAYNAK');
    });
  });

  group('sekme süzgeci', () {
    final items = testFeedItems();

    test('TÜMÜ hiçbir kaydı elemez', () {
      expect(
        itemsForTab(HomeTab.all, items, const {'yapay-zeka'}),
        hasLength(items.length),
      );
    });

    test('konu sekmesi yalnız o konuyu gösterir', () {
      // Test feed'inde `llm` konulu tek kayıt AI modeli.
      final matched = itemsForTab(
        HomeTab.ofInterest(_interest('yapay-zeka')),
        items,
        const {'yapay-zeka'},
      );

      expect(matched.map((item) => item.title), ['ornek/model']);
    });

    test('SANA ÖZEL seçimlerin birleşimini gösterir', () {
      expect(
        itemsForTab(HomeTab.forYou, items, const {
          'yapay-zeka',
        }).map((item) => item.title),
        ['ornek/model'],
      );
    });

    /// Boş bir açılış sekmesi kullanıcıya bir şey seçmediğini anlatmaz,
    /// yalnız bozuk görünür.
    test('seçim yokken SANA ÖZEL akışın tamamıdır', () {
      expect(
        itemsForTab(HomeTab.forYou, items, const {}),
        hasLength(items.length),
      );
    });

    /// Konu sekmesi **kendi** konusuna bakar, kullanıcının seçim kümesinin
    /// tamamına değil. İkisi karışsaydı her konu sekmesi aynı listeyi
    /// gösterirdi ve şerit anlamsız olurdu.
    test('konu sekmesi seçim kümesinden bağımsızdır', () {
      final oyun = itemsForTab(HomeTab.ofInterest(_interest('oyun')), items, {
        'yapay-zeka',
        'oyun',
      });

      expect(oyun, isEmpty);
    });
  });

  group('seçili sekmenin çözülmesi', () {
    test('kimlik listedeyse o sekme döner', () {
      final tabs = homeTabsFor([_interest('bulut')]);

      expect(resolveHomeTab(tabs, 'bulut').key, 'bulut');
    });

    /// Kullanıcı "Oyun" sekmesindeyken Keşfet'ten o konuyu kapatabilir.
    /// Sekme kaybolur ve elde karşılıksız bir kimlik kalır; ekran boş
    /// kalmamalı.
    test('kaybolan sekmeden ilk sekmeye düşülür', () {
      final tabs = homeTabsFor([_interest('bulut')]);

      expect(resolveHomeTab(tabs, 'oyun').key, HomeTab.forYou.key);
      expect(resolveHomeTab(tabs, null).key, HomeTab.forYou.key);
    });
  });

  /// "SANA" gerekçesi ancak **istisna** olduğunda bilgi taşır.
  group('gerekçe bastırma', () {
    test('konu sekmelerinde bastırılır', () {
      expect(suppressesInterestSignal(HomeTab.forYou), isTrue);
      expect(
        suppressesInterestSignal(HomeTab.ofInterest(_interest('bulut'))),
        isTrue,
      );
    });

    test('TÜMÜ sekmesinde bastırılmaz', () {
      expect(
        suppressesInterestSignal(HomeTab.all),
        isFalse,
        reason: 'süzgeçsiz listede eşleşme istisnadır, dolayısıyla bilgidir',
      );
    });
  });
}
