import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../design_system/tokens/app_tokens.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  /// Marka duraklaması: açılışın anlık yanıp sönmesini engeller.
  static const brandPause = Duration(milliseconds: 900);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  /// Bayrak okuma duraklamayla **paralel** başlar: kullanıcı 900 ms'yi
  /// zaten bekliyor, veritabanı açılışı bunun üstüne binmemeli.
  late final Future<bool> _onboardingCompleted = _readOnboardingFlag();

  /// `Future.delayed` iptal edilemez; ekran erken dispose edilirse timer
  /// askıda kalır ve widget testleri "Pending timers" ile düşer.
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(SplashScreen.brandPause, _navigate);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Bayrak okunamazsa onboarding gösterilir: kullanıcıyı yarım kurulumla
  /// akışa düşürmektense tekrar sormak daha güvenlidir.
  Future<bool> _readOnboardingFlag() async {
    try {
      final preferences = await ref.read(appPreferencesProvider.future);
      return preferences.onboardingCompleted;
    } catch (_) {
      return false;
    }
  }

  Future<void> _navigate() async {
    final completed = await _onboardingCompleted;
    if (!mounted) return;
    context.go(completed ? '/home' : '/onboarding/0');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Semantics(
          label: 'Tecnow açılış ekranı',
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
                'TecNow',
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
