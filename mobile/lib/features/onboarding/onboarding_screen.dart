import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_tokens.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({required this.step, super.key});
  final int step;

  /// Tanıtım metinleri.
  ///
  /// Öncesinde burada "**örnek** gelişmeler" ve "yerel **fixture** akışı"
  /// yazıyordu. O metinler, akış gerçekten uydurma kayıtlardan oluştuğu
  /// dönemde doğruydu ve dürüstlük gereğiydi. İçerik gerçek kaynaklara
  /// bağlandıktan sonra (2026-07-28) aynı cümleler ters yönde yanlış hâle
  /// geldi: kullanıcıya gerçek içeriği örnek diye tanıtıyor, üstüne bir de
  /// geliştirici jargonunu ("fixture") ekranda gösteriyorlardı.
  static const pages = [
    (
      Icons.explore_outlined,
      'Keşfet',
      'Teknoloji dünyasındaki gelişmeleri tek akışta keşfet.',
    ),
    (
      Icons.tune_rounded,
      'Kişiselleştir',
      'İlgi alanlarını seç; akış sana göre süzülsün.',
    ),
    (
      Icons.bolt_rounded,
      'Başlat',
      'Repository, yapay zekâ modeli ve geliştirici araçlarını birlikte incele.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final safeStep = step.clamp(0, pages.length - 1);
    final page = pages[safeStep];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.go('/interests'),
                  child: const Text('Atla'),
                ),
              ),
              const Spacer(),
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: AppRadius.featuredBorder,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35),
                  ),
                  boxShadow: AppShadows.cyanGlow,
                ),
                child: Icon(page.$1, size: 72, color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                page.$2,
                style: AppTypography.display,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                page.$3,
                style: AppTypography.bodyMuted,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (index) => Container(
                    width: index == safeStep ? 28 : 8,
                    height: 8,
                    margin: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: index == safeStep
                          ? AppColors.primary
                          : AppColors.outline,
                      borderRadius: AppRadius.smallBorder,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: safeStep == pages.length - 1
                    ? 'İlgi alanlarını seç'
                    : 'Devam et',
                onPressed: () {
                  if (safeStep == pages.length - 1) {
                    context.go('/interests');
                    return;
                  }
                  context.push('/onboarding/${safeStep + 1}');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
