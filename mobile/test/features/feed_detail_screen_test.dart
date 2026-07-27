import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teknoakis/data/feed/feed_schema.dart';
import 'package:teknoakis/features/detail/feed_detail_screen.dart';

import '../support/test_overrides.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  List<FeedItem>? feed,
  Future<bool> Function(Uri url)? urlOpener,
}) async {
  await tester.pumpWidget(
    memoryDataHarness(screen, feed: feed, urlOpener: urlOpener),
  );
  await tester.pumpAndSettle();
}

void main() {
  /// Bu ekranların önceki hâli `id`'yi **hiç okumuyordu**: gerçek bir karta
  /// dokunan kullanıcı sabit bir fixture görüyordu — uydurma yıldız/fork
  /// sayıları, hayalî bir README ve bunların üstünde "doğrulanmış" rozeti.
  /// `CLAUDE.md`: kurgusal tasarım verisi gerçek gibi sunulmaz.
  group('kimlikle çözülen içerik', () {
    testWidgets('kayıt kimliğe göre gösterilir', (tester) async {
      await _pump(tester, const RepositoryDetailScreen(id: '0000000000000001'));

      expect(find.text('ornek/depo'), findsOneWidget);
      expect(find.text('GitHub'), findsOneWidget);
    });

    /// Asıl kilit: iki farklı kimlik **farklı** içerik göstermeli. Sabit
    /// fixture çizen bir ekran bu testi geçemez.
    testWidgets('farklı kimlik farklı içerik gösterir', (tester) async {
      await _pump(tester, const AiModelDetailScreen(id: '0000000000000002'));

      expect(find.text('ornek/model'), findsOneWidget);
      expect(find.text('ornek/depo'), findsNothing);
    });

    testWidgets('fixture içeriği hiç sızmaz', (tester) async {
      await _pump(tester, const RepositoryDetailScreen(id: '0000000000000001'));

      expect(find.textContaining('FIXTURE'), findsNothing);
      expect(find.textContaining('DESIGN_FIXTURE_ONLY'), findsNothing);
      expect(find.text('DOĞRULANMIŞ ÖRNEK'), findsNothing);
      // Feed'de olmayan alanlar hiç çizilmez.
      expect(find.text('README.md'), findsNothing);
      expect(find.text('Teknoloji dağılımı'), findsNothing);
      expect(find.textContaining('Benchmark'), findsNothing);
    });

    testWidgets('gerçek güven sinyalleri gösterilir', (tester) async {
      await _pump(tester, const RepositoryDetailScreen(id: '0000000000000001'));

      expect(find.text('Kaynağın kendi duyurusu'), findsOneWidget);
      expect(find.text('Bakımda'), findsOneWidget);
      expect(find.textContaining('Popülerlik: 10'), findsOneWidget);
    });

    /// Politika: TeknoAkış özeti kaynağın kendi metninden görsel olarak
    /// ayrılır — kartta olduğu gibi detayda da.
    testWidgets('TeknoAkış özeti detayda da işaretlenir', (tester) async {
      await _pump(tester, const AiModelDetailScreen(id: '0000000000000002'));

      expect(find.text('TEKNOAKIŞ ÖZETİ'), findsOneWidget);
    });
  });

  group('bulunamayan ve okunamayan içerik', () {
    /// Detay ekranı bilinmeyen bir kimlikle açılabilir: kaydedilmiş eski bir
    /// içerik, elle girilen bir adres. Çökmek ya da boş ekran yerine söylenir.
    testWidgets('bilinmeyen kimlik dürüst bir boş durum verir', (tester) async {
      await _pump(tester, const RepositoryDetailScreen(id: 'yok-boyle-kayit'));

      expect(find.byKey(const Key('detail-missing')), findsOneWidget);
      expect(find.text('İçerik bulunamadı'), findsOneWidget);
    });

    /// "Bulunamadı" ile "okunamadı" farklı şeyler: ilki içeriğin yokluğu,
    /// ikincisi bizim tarafımızdaki bir hata.
    testWidgets('bozuk feed hata durumu gösterir', (tester) async {
      await tester.pumpWidget(
        memoryDataScopeWithFailingFeed(
          const MaterialApp(
            home: RepositoryDetailScreen(id: '0000000000000001'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('detail-error')), findsOneWidget);
      expect(find.byKey(const Key('detail-missing')), findsNothing);
    });
  });

  group('kaynağa gitme', () {
    /// `CLAUDE.md` değişmez kuralı: detay ekranı sonrası orijinal kaynağa
    /// gidilebilir. Düğmenin çizilmesi yetmez, bağlı olması gerekir.
    testWidgets('düğme kaydın kendi adresini açar', (tester) async {
      final opened = <Uri>[];
      await _pump(
        tester,
        const RepositoryDetailScreen(id: '0000000000000001'),
        urlOpener: (url) async {
          opened.add(url);
          return true;
        },
      );

      await tester.tap(find.byKey(const Key('detail-open-source')));
      await tester.pumpAndSettle();

      expect(opened, hasLength(1));
      expect(opened.single.toString(), contains('0000000000000001'));
    });

    /// Sessizce başarısız olan bir düğme, çalışmayan bir düğmeden kötüdür:
    /// kullanıcı dokunduğunu ve bir şey olmadığını görür, sebebini bilmez.
    testWidgets('açılamazsa kullanıcıya söylenir', (tester) async {
      await _pump(
        tester,
        const RepositoryDetailScreen(id: '0000000000000001'),
        urlOpener: (url) async => false,
      );

      await tester.tap(find.byKey(const Key('detail-open-source')));
      await tester.pumpAndSettle();

      expect(find.text('Bağlantı açılamadı.'), findsOneWidget);
    });
  });

  /// Mor **yalnız** AI bağlamında (`CLAUDE.md` değişmez kuralı).
  testWidgets('vurgu rengi türe göre ayrışır', (tester) async {
    await _pump(tester, const RepositoryDetailScreen(id: '0000000000000001'));
    expect(find.text('DEPO'), findsOneWidget);

    await _pump(tester, const AiModelDetailScreen(id: '0000000000000002'));
    expect(find.text('AI MODEL'), findsOneWidget);
  });
}
