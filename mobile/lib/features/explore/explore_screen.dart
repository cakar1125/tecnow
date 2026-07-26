import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_tokens.dart';
import '../../fixtures/fixtures.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String filter = 'Tümü';

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      const SliverAppBar(
        pinned: true,
        title: Text('Keşfet'),
        centerTitle: true,
      ),
      SliverPadding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        sliver: SliverList.list(
          children: [
            const AppSearchField(),
            const SizedBox(height: AppSpacing.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Tümü', 'AI', 'Repository', 'Mobil']
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: AppFilterChip(
                          label: item,
                          selected: filter == item,
                          onSelected: (_) => setState(() => filter = item),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Öne çıkanlar', style: AppTypography.title),
            const SizedBox(height: AppSpacing.md),
            AIModelCard(
              item: aiModelFixture,
              onTap: () => context.push('/ai-model/example'),
            ),
            const SizedBox(height: AppSpacing.md),
            RepositoryCard(
              item: repositoryFixture,
              onTap: () => context.push('/repository/example'),
            ),
            const SizedBox(height: AppSpacing.xl),
            ...technologyFixtures.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: TechnologyCard(item: item),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
