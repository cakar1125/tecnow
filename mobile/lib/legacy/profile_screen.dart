import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design_system/components/app_components.dart';
import '../design_system/tokens/app_tokens.dart';
import '../fixtures/fixtures.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverAppBar(
        pinned: true,
        title: const Text('Profil'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Ayarlar',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      SliverPadding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        sliver: SliverList.list(
          children: [
            const Center(child: SourceAvatar(label: 'Ö')),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Örnek Kullanıcı',
              style: AppTypography.headline,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '@ornek_profil · FIXTURE_ONLY',
              style: AppTypography.technical,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ProfileStat('12', 'Gönderi'),
                _ProfileStat('48', 'Takip'),
                _ProfileStat('126', 'Takipçi'),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SecondaryButton(label: 'Profili düzenle', onPressed: () {}),
            const SizedBox(height: AppSpacing.xl),
            Text('Kaydedilen örnekler', style: AppTypography.title),
            const SizedBox(height: AppSpacing.md),
            const RepositoryCard(item: repositoryFixture),
          ],
        ),
      ),
    ],
  );
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat(this.value, this.label);
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: AppTypography.title),
      Text(label, style: AppTypography.label),
    ],
  );
}
