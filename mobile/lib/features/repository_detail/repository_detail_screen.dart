import 'package:flutter/material.dart';

import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_tokens.dart';
import '../../fixtures/fixtures.dart';

class RepositoryDetailScreen extends StatelessWidget {
  const RepositoryDetailScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const AppBackTopBar(title: 'Repository Detayı'),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const CategoryBadge(label: 'REPOSITORY · FIXTURE'),
          const SizedBox(height: AppSpacing.md),
          Text(repositoryFixture.name, style: AppTypography.headline),
          const SizedBox(height: AppSpacing.sm),
          Text(repositoryFixture.description, style: AppTypography.bodyMuted),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Star',
                  value: repositoryFixture.stars,
                  icon: Icons.star_outline,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _Stat(
                  label: 'Fork',
                  value: repositoryFixture.forks,
                  icon: Icons.fork_right,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _Stat(
                  label: 'Issue',
                  value: repositoryFixture.issues,
                  icon: Icons.error_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Teknoloji dağılımı', style: AppTypography.title),
          const SizedBox(height: AppSpacing.md),
          const _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dart 72%', style: AppTypography.body),
                SizedBox(height: AppSpacing.sm),
                LinearProgressIndicator(value: 0.72),
                SizedBox(height: AppSpacing.md),
                Text('Kotlin 18% · Swift 10%', style: AppTypography.technical),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('README.md', style: AppTypography.title),
          const SizedBox(height: AppSpacing.md),
          const _Panel(
            accent: true,
            child: Text(
              '# Akış Motoru\n\nBu içerik DESIGN_FIXTURE_ONLY olarak hazırlanmış hayalî bir repository açıklamasıdır.\n\nflutter test\nflutter analyze',
              style: AppTypography.technical,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(height: AppSpacing.sm),
        Text(value, style: AppTypography.title),
        Text(label, style: AppTypography.label),
      ],
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.accent = false});
  final Widget child;
  final bool accent;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadius.cardBorder,
      border: Border.all(color: accent ? AppColors.primary : AppColors.outline),
      boxShadow: accent ? AppShadows.cyanGlow : AppShadows.card,
    ),
    child: child,
  );
}
