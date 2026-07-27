import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import 'app.dart';

export 'app.dart' show TeknoakisApp;

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
      child: builder?.call(container) ?? const TeknoakisApp(),
    ),
  );
}

/// Tohumlama başarısız olursa uygulama yine de açılır.
///
/// Kaydedilenler o oturumda boş görünür; bu, açılışı tamamen engellemekten
/// iyidir ve hata sessizce yutulmaz.
@visibleForTesting
Future<void> seedLocalData(ProviderContainer container) async {
  try {
    final seeder = await container.read(savedItemsSeederProvider.future);
    await seeder.seedIfNeeded();
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'teknoakis',
        context: ErrorDescription('yerel veri tohumlaması sırasında'),
      ),
    );
  }
}
