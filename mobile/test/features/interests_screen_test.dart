import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tecos/app/router.dart';
import 'package:tecos/data/app_preferences.dart';
import 'package:tecos/design_system/theme/app_theme.dart';
import 'package:tecos/features/interests/interests_screen.dart';

import '../support/test_overrides.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  FilledButton action(WidgetTester tester) => tester.widget<FilledButton>(
    find.widgetWithText(FilledButton, 'Akışa geç'),
  );

  testWidgets('interest selection requires at least three choices', (
    tester,
  ) async {
    await tester.pumpWidget(memoryDataHarness(const InterestsScreen()));
    await tester.pumpAndSettle();

    expect(action(tester).onPressed, isNull);

    for (final label in ['Yapay Zekâ', 'Mobil', 'Açık Kaynak']) {
      await tester.tap(find.text(label));
      await tester.pump();
    }

    expect(find.text('3/3 seçildi'), findsOneWidget);
    expect(action(tester).onPressed, isNotNull);
  });

  /// Faz 1'de bu veri `shared_preferences`'tan geliyordu; artık sqflite
  /// tablosu asıl kaynaktır (taşıma: `InterestsMigration`).
  testWidgets('saved interests are restored from the local database', (
    tester,
  ) async {
    await tester.pumpWidget(
      memoryDataHarness(
        const InterestsScreen(),
        interests: const ['Yapay Zekâ', 'Mobil', 'Açık Kaynak'],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('3/3 seçildi'), findsOneWidget);
    expect(action(tester).onPressed, isNotNull);
  });

  /// Gerçek router ile: hem bayrağın yazıldığını hem akışa geçildiğini ölçer.
  testWidgets('continuing marks onboarding as completed and opens the feed', (
    tester,
  ) async {
    final router = createRouter(initialLocation: '/interests');
    addTearDown(router.dispose);

    await tester.pumpWidget(
      memoryDataScope(
        MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
        interests: const ['Yapay Zekâ', 'Mobil', 'Açık Kaynak'],
      ),
    );
    await tester.pumpAndSettle();

    final before = await SharedPreferences.getInstance();
    expect(
      before.getBool(AppPreferences.onboardingCompletedKey),
      isNull,
      reason: 'bayrak yalnız akışa geçildiğinde yazılmalı',
    );

    await tester.tap(find.text('Akışa geç'));
    await tester.pumpAndSettle();

    final after = await SharedPreferences.getInstance();
    expect(after.getBool(AppPreferences.onboardingCompletedKey), isTrue);
    expect(router.routeInformationProvider.value.uri.path, '/home');
  });

  /// Ayarlar'dan açıldığında ekran bir **düzenleme**, akışın son adımı değil.
  ///
  /// Öncesinde ikisi ayrılmıyordu: başlık çubuğunda geri düğmesi yoktu
  /// (`AppTopBar` `automaticallyImplyLeading: false`) ve tek çıkış olan düğme
  /// `go('/home')` yapıyordu. Ayarlarını değiştiren kullanıcı Ana Sayfa'ya
  /// atılıyor ve geldiği yere dönemiyordu.
  group('Ayarlar\'dan düzenleme', () {
    Future<GoRouter> pumpFromSettings(WidgetTester tester) async {
      final router = createRouter(initialLocation: '/settings');
      addTearDown(router.dispose);

      await tester.pumpWidget(
        memoryDataScope(
          MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
          interests: const ['yapay-zeka', 'mobil', 'acik-kaynak'],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('İlgi Alanları'));
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('geri düğmesi ve "Kaydet" etiketi gelir', (tester) async {
      await pumpFromSettings(tester);

      expect(find.byTooltip('Geri'), findsOneWidget);
      expect(find.text('Kaydet'), findsOneWidget);
      expect(find.text('Akışa geç'), findsNothing);
    });

    testWidgets('kaydetmek Ayarlar\'a döner, akışa atmaz', (tester) async {
      await pumpFromSettings(tester);

      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();

      // Ekran ölçülüyor, rota yolu değil: bir kabuk dalından yapılan `push`
      // sonrasında GoRouter'ın bildirdiği yol dalın konumunda kalıyor.
      expect(find.text('KİŞİSELLEŞTİRME'), findsOneWidget);
      expect(find.text('Akışını şekillendir'), findsNothing);
    });

    testWidgets('geri düğmesi de Ayarlar\'a döner', (tester) async {
      await pumpFromSettings(tester);

      await tester.tap(find.byTooltip('Geri'));
      await tester.pumpAndSettle();

      expect(find.text('KİŞİSELLEŞTİRME'), findsOneWidget);
    });

    /// Kurulum zaten tamamlanmış; tekrar işaretlemek anlamsız bir yazma.
    testWidgets('düzenleme onboarding bayrağını yeniden yazmaz', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await pumpFromSettings(tester);

      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();

      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getBool(AppPreferences.onboardingCompletedKey),
        isNull,
      );
    });
  });

  /// Onboarding'de geri dönülecek bir yer yok: `go` yığını temizliyor.
  testWidgets('onboarding son adımında geri düğmesi yok', (tester) async {
    final router = createRouter(initialLocation: '/onboarding/2');
    addTearDown(router.dispose);

    await tester.pumpWidget(
      memoryDataScope(
        MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('İlgi alanlarını seç'));
    await tester.pumpAndSettle();

    expect(find.text('Akışa geç'), findsOneWidget);
    expect(find.text('Kaydet'), findsNothing);
    expect(find.byTooltip('Geri'), findsNothing);
  });

  /// Bir çipi seçmek diğerlerini yerinden oynatmamalı.
  ///
  /// Material'in `showCheckmark` davranışında onay işareti yalnız seçiliyken
  /// çiziliyor ve çipi genişletiyordu; `Wrap` içinde bu, satır düzeninin
  /// yeniden akması ve **komşu çiplerin parmağın altından kayması** demekti.
  /// Cihazda görüldü (2026-07-28): art arda üç çipe dokunulduğunda üçüncüsü,
  /// o konumdaki çip yer değiştirdiği için boşluğa düştü.
  ///
  /// Test görünüşe değil **geometriye** bakıyor: seçim yalnız rengi
  /// değiştirmeli, ölçüyü değil.
  group('çip düzeni', () {
    testWidgets('bir çipin genişliği seçilince değişmez', (tester) async {
      await tester.pumpWidget(memoryDataHarness(const InterestsScreen()));
      await tester.pumpAndSettle();

      final chip = find.byKey(const Key('interest-yapay-zeka'));
      final before = tester.getSize(chip);

      await tester.tap(chip);
      await tester.pumpAndSettle();

      expect(tester.getSize(chip), before);
    });

    testWidgets('bir çip seçmek komşularını yerinden oynatmaz', (tester) async {
      await tester.pumpWidget(memoryDataHarness(const InterestsScreen()));
      await tester.pumpAndSettle();

      final positionsBefore = {
        for (final interest in [
          'mobil',
          'acik-kaynak',
          'siber-guvenlik',
          'oyun',
        ])
          interest: tester.getTopLeft(find.byKey(Key('interest-$interest'))),
      };

      await tester.tap(find.byKey(const Key('interest-yapay-zeka')));
      await tester.pumpAndSettle();

      for (final entry in positionsBefore.entries) {
        expect(
          tester.getTopLeft(find.byKey(Key('interest-${entry.key}'))),
          entry.value,
          reason: '${entry.key} çipi seçim sonrası yer değiştirdi',
        );
      }
    });

    /// Üç çipe art arda dokunmak gerçekten üçünü seçmeli — cihazda düşen
    /// senaryonun ta kendisi.
    testWidgets('art arda üç dokunuş üç seçim yapar', (tester) async {
      await tester.pumpWidget(memoryDataHarness(const InterestsScreen()));
      await tester.pumpAndSettle();

      // Konumlar **önceden** alınıyor: gerçek bir kullanıcı da gördüğü yere
      // dokunur, dokunacağı an yeniden hesaplamaz.
      final targets = [
        for (final id in ['yapay-zeka', 'mobil', 'acik-kaynak'])
          tester.getCenter(find.byKey(Key('interest-$id'))),
      ];

      for (final target in targets) {
        await tester.tapAt(target);
        await tester.pumpAndSettle();
      }

      expect(find.text('3/3 seçildi'), findsOneWidget);
    });
  });

  /// Sekme sırası — Bundle'ın ana sayfasındaki en ayırt edici mekanik.
  ///
  /// Sürükleme **gerçekten** yapılıyor, `onReorderItem` elle çağrılmıyor:
  /// bu geri çağrının indeks sözleşmesi (aşağı sürüklerken hedefin bir
  /// kayması) tam olarak elle çağrıldığında görünmeyen şey. Kapının değer
  /// taşıdığı yer burası.
  group('sekme sırası', () {
    Future<void> pumpOrdering(
      WidgetTester tester, {
      List<String> interests = const ['bulut', 'oyun', 'mobil'],
    }) async {
      // Üç sıra satırı + çip ızgarası varsayılan yüzeye sığmıyor; sürükleme
      // hedefi ekran dışındaysa jest hiç başlamaz.
      await tester.binding.setSurfaceSize(const Size(390, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        memoryDataHarness(const InterestsScreen(), interests: interests),
      );
      await tester.pumpAndSettle();
    }

    /// Sürükleme tutamağını yakalayıp [rows] satır aşağı taşır.
    Future<void> dragBy(
      WidgetTester tester,
      String id, {
      required double rows,
    }) async {
      final handle = find.descendant(
        of: find.byKey(Key('interest-order-$id')),
        matching: find.byType(ReorderableDragStartListener),
      );
      final height = tester
          .getSize(find.byKey(Key('interest-order-$id')))
          .height;
      final gesture = await tester.startGesture(tester.getCenter(handle));
      // `ReorderableDragStartListener` anında başlar (uzun basma yok), ama
      // hareket adım adım veriliyor: tek sıçrayış listenin kendini yeniden
      // düzenlemesine fırsat vermeden düşüyor.
      await tester.pump(const Duration(milliseconds: 50));
      const steps = 4;
      for (var step = 0; step < steps; step++) {
        await gesture.moveBy(Offset(0, height * rows / steps));
        await tester.pump(const Duration(milliseconds: 20));
      }
      await gesture.up();
      await tester.pumpAndSettle();
    }

    List<String> orderOnScreen(WidgetTester tester) =>
        [
          for (final id in ['bulut', 'oyun', 'mobil'])
            if (find.byKey(Key('interest-order-$id')).evaluate().isNotEmpty) id,
        ]..sort(
          (a, b) => tester
              .getTopLeft(find.byKey(Key('interest-order-$a')))
              .dy
              .compareTo(
                tester.getTopLeft(find.byKey(Key('interest-order-$b'))).dy,
              ),
        );

    testWidgets('seçili konular sıralanabilir listede çıkar', (tester) async {
      await pumpOrdering(tester);

      expect(find.text('Sekme sırası'), findsOneWidget);
      expect(orderOnScreen(tester), ['bulut', 'oyun', 'mobil']);
    });

    /// Tek öğeli bir liste sıralanamaz; çizilirse yapılamayan bir şeyi
    /// vaat eder.
    testWidgets('iki konunun altında bölüm hiç çizilmez', (tester) async {
      await pumpOrdering(tester, interests: const ['bulut']);

      expect(find.text('Sekme sırası'), findsNothing);
    });

    testWidgets('sürüklemek sırayı değiştirir', (tester) async {
      await pumpOrdering(tester);

      await dragBy(tester, 'bulut', rows: 1);

      expect(orderOnScreen(tester), ['oyun', 'bulut', 'mobil']);
    });

    /// Aşağı sürüklemede `onReorder`'ın indeksi bir kayar. Kod
    /// `onReorderItem` kullandığı için düzeltme gerekmiyor; bu test o seçimi
    /// kilitliyor — eski geri çağrıya dönülürse üç öğe **iki** kayar.
    testWidgets('sona sürüklemek sırayı bir kaydırmaz', (tester) async {
      await pumpOrdering(tester);

      await dragBy(tester, 'bulut', rows: 2);

      expect(orderOnScreen(tester), ['oyun', 'mobil', 'bulut']);
    });

    /// Sıra bir tercih: bırakıldığı anda diske yazılmalı. Alttaki düğmeyi
    /// beklemek, geri tuşuyla çıkan kullanıcının düzenini kaybetmesi demek.
    testWidgets('yeni sıra hemen kalıcı olur', (tester) async {
      final repository = InMemoryInterestsRepository(const [
        'bulut',
        'oyun',
        'mobil',
      ]);
      await tester.binding.setSurfaceSize(const Size(390, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        memoryDataHarness(
          const InterestsScreen(),
          interestsRepository: repository,
        ),
      );
      await tester.pumpAndSettle();

      await dragBy(tester, 'mobil', rows: -2);

      expect(await repository.readAll(), ['mobil', 'bulut', 'oyun']);
    });
  });
}
