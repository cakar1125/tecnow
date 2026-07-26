import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teknoakis/design_system/theme/app_theme.dart';

Widget testHarness(Widget child, {double textScale = 1}) => ProviderScope(
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: child,
  ),
);
