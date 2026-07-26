import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_tokens.dart';
import '../../fixtures/fixtures.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) => CustomScrollView(
    key: const Key('feed-scroll'),
    slivers: [
      const SliverAppBar(
        pinned: true,
        title: Text('TEKNOAKIŞ'),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.sm),
            child: Icon(Icons.search_rounded),
          ),
        ],
      ),
      SliverPadding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        sliver: SliverList.list(
          children: [
            Text(
              'SANA ÖZEL',
              style: AppTypography.label.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            RepositoryCard(
              item: repositoryFixture,
              onTap: () => context.push('/repository/example'),
            ),
            const SizedBox(height: AppSpacing.lg),
            AIModelCard(
              item: aiModelFixture,
              onTap: () => context.push('/ai-model/example'),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Bugünün gelişmeleri', style: AppTypography.title),
            const SizedBox(height: AppSpacing.md),
            ...technologyFixtures.expand(
              (item) => [
                TechnologyCard(item: item),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}
