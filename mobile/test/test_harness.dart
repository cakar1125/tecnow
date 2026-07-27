import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teknoakis/design_system/theme/app_theme.dart';

/// Uygulama kabuğu olmadan tek bir widget'ı gerçek tema altında render eder.
///
/// `ProviderScope` **dışarıda** bırakıldı: veri katmanına bağlı ekranlar
/// override'lı bir scope ister (`support/test_overrides.dart`), bağlı olmayanlar
/// [testHarness] ile sade scope kullanır.
Widget testApp(Widget child, {double textScale = 1}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.dark,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: child,
);

Widget testHarness(Widget child, {double textScale = 1}) =>
    ProviderScope(child: testApp(child, textScale: textScale));
