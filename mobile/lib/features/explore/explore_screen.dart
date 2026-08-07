import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/feed/feed_schema.dart';
import '../../data/providers.dart';
import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_tokens.dart';
import '../../ui/content_card_model.dart';
import '../../ui/detail_route.dart';
import '../../ui/explore_search.dart';

/// Keşfet.
///
/// 2026-07-28'e kadar bu ekran tamamen `lib/fixtures/` okuyordu: arama
/// hayalî kayıtlar arasında geziniyor, "NEDEN EŞLEŞTİ?" kutusu fixture'a
/// yazılmış sabit bir cümle gösteriyor ve hiçbir kart hiçbir yere
/// gitmiyordu. Artık üçü de gerçek: kayıtlar paketlenmiş/indirilmiş
/// feed'den, gerekçe eşleşmenin **yerinden**, dokunuş detay ekranına.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _searchController = TextEditingController();
  ExploreFilter? _selectedFilter = ExploreFilter.github;
  String _query = '';

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

  Future<void> _toggleSaved(FeedItem item) =>
      ref.read(savedItemsProvider.notifier).toggleFeedItem(item);

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(feedProvider);

    return CustomScrollView(
      key: const Key('explore-scroll'),
      slivers: [
        const SliverToBoxAdapter(child: AppTopBar(title: 'TecNow')),
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
                              label: exploreFilterLabels[filter]!,
                              selected: _selectedFilter == filter,
                              onSelected: (_) => _toggleFilter(filter),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                ..._sections(feed),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Durum sırası **içeriğe göre**: elde veri varsa göster, yoksa hata varsa
  /// söyle, o da yoksa yükleniyor. `AsyncLoading()` ile başlayan bir `switch`
  /// Riverpod 3'te hata durumunu ölü koda çeviriyor (TASK-0019 dersi).
  List<Widget> _sections(AsyncValue<List<FeedItem>> feed) {
    if (feed.value case final items?) return _loaded(items);

    if (feed.hasError) {
      return const [
        EmptyStateView(
          key: Key('explore-error'),
          title: 'İçerik okunamadı',
          message:
              'İçerik dosyası açılamadı. Uygulamayı güncellemek sorunu '
              'çözebilir.',
        ),
      ];
    }

    return const [
      Padding(
        key: Key('explore-loading'),
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: LoadingSkeleton(),
      ),
    ];
  }

  List<Widget> _loaded(List<FeedItem> items) {
    final matches = searchFeed(items, query: _query, filter: _selectedFilter);
    final popular = popularItems(items);
    final savedIds = ref.watch(savedItemIdsProvider);

    return [
      _SectionHeader(
        title: 'En Uygun Sonuçlar',
        actionLabel: 'Tümünü Gör',
        onAction: _clearSearchAndFilter,
      ),
      const SizedBox(height: AppSpacing.md),
      if (matches.isEmpty)
        const EmptyStateView(
          key: Key('explore-empty-state'),
          title: 'Sonuç bulunamadı',
          message: 'Farklı bir arama veya filtre deneyin.',
        )
      else
        for (var index = 0; index < matches.length; index++) ...[
          ExploreResultCard(
            key: ValueKey(matches[index].item.id),
            item: ContentCardModel.fromFeedItem(matches[index].item),
            matchReason: matches[index].reason,
            isSaved: savedIds.contains(matches[index].item.id),
            onToggleSave: () => _toggleSaved(matches[index].item),
            onTap: () => context.push(detailRoute(matches[index].item.id)),
          ),
          if (index != matches.length - 1)
            const SizedBox(height: AppSpacing.lg),
        ],
      const SizedBox(height: AppSpacing.xxl),
      const _SectionHeader(title: 'Başlangıç İçin'),
      const SizedBox(height: AppSpacing.md),
      // Bu bölüm TecNow'un kendi yazacağı başlangıç rehberleri için
      // ayrıldı. Feed'de rehber diye bir kayıt türü yok; buraya kayıt
      // koymak, okuma süresi dahil her alanını uydurmak olurdu. Bölüm
      // kaldırılmadı çünkü boşluğun **sebebini** söylemek, boşluğu
      // gizlemekten dürüst.
      const EmptyStateView(
        key: Key('explore-starter-placeholder'),
        title: 'Rehberler henüz hazır değil',
        message:
            'Başlangıç rehberleri TecNow tarafından yazılacak. Hazır '
            'olmadan örnek metin gösterilmiyor.',
      ),
      const SizedBox(height: AppSpacing.xxl),
      const _SectionHeader(title: 'Popüler'),
      const SizedBox(height: AppSpacing.md),
      if (popular.isEmpty)
        const EmptyStateView(
          key: Key('explore-popular-empty'),
          title: 'Popülerlik ölçülemedi',
          message:
              'Bu akıştaki kayıtların hiçbirinde yıldız veya indirme sinyali '
              'yok.',
        )
      else
        for (var index = 0; index < popular.length; index++) ...[
          ExplorePopularRow(
            key: ValueKey('popular-${popular[index].id}'),
            item: ContentCardModel.fromFeedItem(popular[index]),
            onTap: () => context.push(detailRoute(popular[index].id)),
          ),
          if (index != popular.length - 1)
            const SizedBox(height: AppSpacing.md),
        ],
    ];
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
