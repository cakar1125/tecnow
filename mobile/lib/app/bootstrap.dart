import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import 'app.dart';

export 'app.dart' show TecOsApp;

/// Uygulamayı, yerel veri tohumlaması bir kez tamamlandıktan sonra başlatır.
///
/// Tohumlama bilinçli olarak burada, okuma yolundan **dışarıda** durur.
/// Konteyner elle oluşturulur ki `runApp`'ten önce provider'lar okunabilsin;
/// aynı konteyner `UncontrolledProviderScope` ile ağaca verilir.
Future<void> bootstrap({
  Widget Function(ProviderContainer container)? builder,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  await seedLocalData(container);
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: builder?.call(container) ?? const TecOsApp(),
    ),
  );
}

/// Açılışta bir kez çalışan yerel veri hazırlıkları.
///
/// Herhangi biri başarısız olursa uygulama yine de açılır: ilgili liste o
/// oturumda boş görünür, bu açılışı tamamen engellemekten iyidir ve hata
/// sessizce yutulmaz. Adımlar birbirinden bağımsızdır — taşıma düşerse
/// tohumlama yine denenir.
@visibleForTesting
Future<void> seedLocalData(ProviderContainer container) async {
  await _step('ilgi alanları taşıması', () async {
    final migration = await container.read(interestsMigrationProvider.future);
    await migration.migrateIfNeeded();
  });
  await _step('örnek kayıt temizliği', () async {
    final cleanup = await container.read(
      savedItemsSampleCleanupProvider.future,
    );
    await cleanup.removeIfNeeded();
  });
  // Tema tercihi `runApp`'ten önce okunur. Sonra okunsaydı uygulama önce
  // varsayılan temayla bir kare çizer, ardından kullanıcının seçtiğine
  // atlardı — koyu tema seçmiş birine açılışta beyaz bir parlama.
  //
  // İçerik dili de burada: gecikmenin bedeli bir kare değil, **yanlış dilde
  // bir indirme** olurdu. Açılış tazelemesi tercih okunmadan başlarsa Türkçe
  // dosya iner, hemen ardından İngilizcesi bir kez daha inerdi.
  await _step('tema, dil ve kaynak tercihleri', () async {
    final preferences = await container.read(appPreferencesProvider.future);
    container.read(themeModeProvider.notifier).restore(preferences.themeMode);
    container
        .read(feedLanguageProvider.notifier)
        .restore(preferences.feedLanguage);
    container
        .read(mutedSourcesProvider.notifier)
        .restore(preferences.mutedSources);
  });
}

Future<void> _step(String description, Future<void> Function() run) async {
  try {
    await run();
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'tecos',
        context: ErrorDescription('$description sırasında'),
      ),
    );
  }
}
