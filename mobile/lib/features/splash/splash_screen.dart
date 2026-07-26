import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/tokens/app_tokens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (mounted) context.go('/onboarding/0');
      });
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Semantics(
          label: 'TeknoAkış açılış ekranı',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.featuredBorder,
                  boxShadow: AppShadows.cyanGlow,
                ),
                child: const Icon(
                  Icons.terminal_rounded,
                  size: 44,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'TEKNOAKIŞ',
                style: AppTypography.display.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Teknolojinin nabzı, sana özel.',
                style: AppTypography.bodyMuted,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
