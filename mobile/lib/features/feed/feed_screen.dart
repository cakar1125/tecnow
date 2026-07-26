import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_tokens.dart';
import '../../fixtures/fixtures.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  FeedTab _selectedTab = FeedTab.sanaOzel;

  static const _tabLabels = {
    FeedTab.sanaOzel: 'SANA ÖZEL',
    FeedTab.gundem: 'GÜNDEM',
    FeedTab.github: 'GİTHUB',
    FeedTab.aiModelleri: 'AI MODELLERİ',
  };

  List<FeedItemFixture> get _visibleItems => feedItemFixtures
      .where((item) => item.tabs.contains(_selectedTab))
      .toList(growable: false);

  void _openItem(BuildContext context, FeedItemFixture item) {
    switch (item.kind) {
      case FeedSourceKind.github:
        context.push('/repository/${item.id}');
        return;
      case FeedSourceKind.aiModel:
        context.push('/ai-model/${item.id}');
        return;
      case FeedSourceKind.tool:
      case FeedSourceKind.announcement:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bu içerik türü için detay ekranı henüz uygulanmadı.',
            ),
          ),
        );
        return;
    }
  }

  @override
  Widget build(BuildContext context) => CustomScrollView(
    key: const Key('feed-scroll'),
    slivers: [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.lg,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TEKNOAKIŞ',
                      style: AppTypography.display.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Teknoloji dünyasında önemli olanları keşfet.',
                      style: AppTypography.bodyMuted,
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('feed-search'),
                tooltip: 'Keşfet',
                onPressed: () => context.go('/explore'),
                icon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: SingleChildScrollView(
          key: const Key('feed-tab-scroll'),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              for (final tab in FeedTab.values)
                _FeedTabButton(
                  key: Key(
                    'feed-tab-${tab.name}-'
                    '${_selectedTab == tab ? 'selected' : 'idle'}',
                  ),
                  label: _tabLabels[tab]!,
                  selected: _selectedTab == tab,
                  onTap: () => setState(() => _selectedTab = tab),
                ),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        sliver: _visibleItems.isEmpty
            ? const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateView(
                  title: 'İçerik bulunamadı',
                  message: 'Bu sekme için henüz örnek içerik yok.',
                ),
              )
            : SliverList.separated(
                itemCount: _visibleItems.length,
                itemBuilder: (context, index) {
                  final item = _visibleItems[index];
                  return FeedItemCard(
                    key: ValueKey(item.id),
                    item: item,
                    onTap: () => _openItem(context, item),
                  );
                },
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.lg),
              ),
      ),
    ],
  );
}

class _FeedTabButton extends StatelessWidget {
  const _FeedTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    // Kendi Material'ını sahiplenir: ekran golden ve widget testlerinde
    // Scaffold olmadan da pump edilir, ata Material'a güvenilemez.
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          margin: const EdgeInsets.only(right: AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                width: 2,
                color: selected ? AppColors.primary : Colors.transparent,
              ),
            ),
          ),
          // Sekme etiketi normal UI metnidir: monospace kullanılmaz
          // (CLAUDE.md değişmez kural). Mono yalnız teknik metadata içindir.
          child: Text(
            label,
            style: AppTypography.label.copyWith(
              fontSize: 13,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ),
  );
}
