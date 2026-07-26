import 'package:flutter/material.dart';

import '../design_system/theme/app_theme.dart';
import 'router.dart';

class TeknoakisApp extends StatelessWidget {
  const TeknoakisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TeknoAkış',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
