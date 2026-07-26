import 'package:flutter/material.dart';

import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_tokens.dart';
import '../../fixtures/fixtures.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();
  ExploreFilter? _selectedFilter = ExploreFilter.github;
  String _query = '';

  static const _filterLabels = {
    ExploreFilter.github: 'GitHub',
    ExploreFilter.aiModelleri: 'AI Modelleri',
    ExploreFilter.aiAraclari: 'AI Araçları',
    ExploreFilter.skills: 'Skills',
    ExploreFilter.mcp: 'MCP',
  };

  List<ExploreResultFixture> get _visibleResults {
    final normalizedQuery = _query.trim().toLowerCase();
    return exploreResultFixtures
        .where((item) {
          final matchesFilter =
              _selectedFilter == null || item.filters.contains(_selectedFilter);
          final matchesQuery =
              normalizedQuery.isEmpty ||
              item.title.toLowerCase().contains(normalizedQuery) ||
              item.summary.toLowerCase().contains(normalizedQuery);
          return matchesFilter && matchesQuery;
        })
        .toList(growable: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleFilter(ExploreFilter filter) {
    setState(() {
      _selectedFilter = _selectedFilter == filter ? null : filter;
    });
  }

  void _clearSearchAndFilter() {
    FocusScope.of(context).unfocus();
    _searchController.clear();
    setState(() {
      _query = '';
      _selectedFilter = null;
    });
  }

  void _showUpcomingNotice() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Bu rehber sonraki fazda uygulanacak.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final visibleResults = _visibleResults;

    return CustomScrollView(
      key: const Key('explore-scroll'),
      slivers: [
        const SliverToBoxAdapter(child: AppTopBar(title: 'TeknoAkış')),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  color: Colors.transparent,
                  child: AppSearchField(
                    key: const Key('explore-search'),
                    controller: _searchController,
                    hintText: 'AI, repository, skill veya MCP ara',
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SingleChildScrollView(
                  key: const Key('explore-filter-scroll'),
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final filter in ExploreFilter.values)
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: Material(
                            color: Colors.transparent,
                            child: AppFilterChip(
                              key: Key(
                                'explore-filter-${filter.name}-'
                                '${_selectedFilter == filter ? 'selected' : 'idle'}',
                              ),
                              label: _filterLabels[filter]!,
                              selected: _selectedFilter == filter,
                              onSelected: (_) => _toggleFilter(filter),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _SectionHeader(
                  title: 'En Uygun Sonuçlar',
                  actionLabel: 'Tümünü Gör',
                  onAction: _clearSearchAndFilter,
                ),
                const SizedBox(height: AppSpacing.md),
                if (visibleResults.isEmpty)
                  const EmptyStateView(
                    key: Key('explore-empty-state'),
                    title: 'Sonuç bulunamadı',
                    message: 'Farklı bir arama veya filtre deneyin.',
                  )
                else
                  for (
                    var index = 0;
                    index < visibleResults.length;
                    index++
                  ) ...[
                    ExploreResultCard(
                      key: ValueKey(visibleResults[index].id),
                      item: visibleResults[index],
                    ),
                    if (index != visibleResults.length - 1)
                      const SizedBox(height: AppSpacing.lg),
                  ],
                const SizedBox(height: AppSpacing.xxl),
                const _SectionHeader(title: 'Başlangıç İçin'),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 260,
                  child: ListView.separated(
                    key: const Key('explore-starter-scroll'),
                    scrollDirection: Axis.horizontal,
                    itemCount: exploreStarterFixtures.length,
                    itemBuilder: (context, index) => ExploreStarterCard(
                      item: exploreStarterFixtures[index],
                      onTap: _showUpcomingNotice,
                    ),
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.md),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                const _SectionHeader(title: 'Popüler'),
                const SizedBox(height: AppSpacing.md),
                for (
                  var index = 0;
                  index < explorePopularFixtures.length;
                  index++
                ) ...[
                  ExplorePopularRow(
                    item: explorePopularFixtures[index],
                    onTap: _showUpcomingNotice,
                  ),
                  if (index != explorePopularFixtures.length - 1)
                    const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(title, style: AppTypography.title)),
      if (actionLabel != null && onAction != null) ...[
        const SizedBox(width: AppSpacing.sm),
        Semantics(
          button: true,
          label: actionLabel,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: AppRadius.smallBorder,
              onTap: onAction,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.md,
                  ),
                  child: Text(
                    actionLabel!,
                    style: AppTypography.label.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ],
  );
}
