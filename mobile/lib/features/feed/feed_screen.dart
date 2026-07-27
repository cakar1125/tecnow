import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/feed/feed_schema.dart';
import '../../data/feed/feed_sync_state.dart';
import '../../data/providers.dart';
import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_tokens.dart';
import '../../ui/content_card_model.dart';
import '../../ui/feed_sync_label.dart';

/// Akış sekmeleri.
///
/// `lib/fixtures`'taki `FeedTab` yerine burada duruyor: sekmeler artık
/// fixture alanından değil, **kaydın kendi verisinden** türetiliyor.
enum HomeTab { sanaOzel, gundem, github, aiModelleri }

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  HomeTab _selectedTab = HomeTab.sanaOzel;

  @override
  void initState() {
    super.initState();
    // İlk kare çizildikten sonra: açılış ağ beklemez, içerik önce gelir.
    // Deneme yalnız içerik bayatsa yapılır (`refreshIfStale`).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(feedSyncProvider.notifier).refreshIfStale();
    });
  }

  static const _tabLabels = {
    HomeTab.sanaOzel: 'SANA ÖZEL',
    HomeTab.gundem: 'GÜNDEM',
    HomeTab.github: 'GİTHUB',
    HomeTab.aiModelleri: 'AI MODELLERİ',
  };

  /// Sekme filtresi.
  ///
  /// **Sana Özel**, ilgi alanları seçilmişse konu kesişimine bakar; hiç ilgi
  /// alanı yoksa akışın tamamını gösterir. Boş bir "sana özel" sekmesi,
  /// kullanıcıya bir şey seçmediğini anlatmaz — sadece bozuk görünür.
  List<FeedItem> _filter(List<FeedItem> items, Set<String> interests) =>
      switch (_selectedTab) {
        HomeTab.sanaOzel =>
          interests.isEmpty
              ? items
              : items
                    .where(
                      (item) => item.topics.any(
                        (topic) => interests.contains(topic.toLowerCase()),
                      ),
                    )
                    .toList(growable: false),
        HomeTab.gundem =>
          items
              .where((item) => item.kind == FeedItemKind.announcement)
              .toList(growable: false),
        HomeTab.github =>
          items
              .where((item) => item.sourceKind == FeedSourceKind.github)
              .toList(growable: false),
        HomeTab.aiModelleri =>
          items
              .where((item) => item.kind == FeedItemKind.aiModel)
              .toList(growable: false),
      };

  void _openItem(BuildContext context, FeedItem item) {
    switch (item.kind) {
      case FeedItemKind.repository:
      case FeedItemKind.mcp:
      case FeedItemKind.skill:
        context.push('/repository/${item.id}');
      case FeedItemKind.aiModel:
        context.push('/ai-model/${item.id}');
      case FeedItemKind.tool:
      case FeedItemKind.announcement:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bu içerik türü için detay ekranı henüz uygulanmadı.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sync = ref.watch(feedSyncProvider).value;
    final scrollView = _scrollView(context, sync);

    // Tazeleme kontrolü yalnız gerçekten çalışacağı zaman var. Uzak adres
    // yapılandırılmamışken aşağı çekme jesti hiçbir şey yapmazdı; işlevsiz
    // bir kontrol, sahte bir işlev vaadidir.
    if (sync == null || !sync.remoteEnabled) return scrollView;

    return RefreshIndicator(
      key: const Key('feed-refresh'),
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceHigh,
      onRefresh: () => ref.read(feedSyncProvider.notifier).refresh(),
      child: scrollView,
    );
  }

  Widget _scrollView(BuildContext context, FeedSyncState? sync) {
    final feed = ref.watch(feedProvider);
    final interests = ref.watch(interestsProvider).value ?? const <String>{};

    return CustomScrollView(
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
                      if (sync != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          feedSyncLabel(sync, DateTime.now()),
                          key: const Key('feed-sync-status'),
                          style: AppTypography.label.copyWith(
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
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
                for (final tab in HomeTab.values)
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
        _content(feed, interests, context),
      ],
    );
  }

  /// Durum sırası **tipe göre değil, içeriğe göre**.
  ///
  /// `AsyncLoading()` deseniyle başlamak sessiz bir hataydı: Riverpod 3 hatayı
  /// `AsyncLoading(error: …)` içinde taşıyabiliyor, bu yüzden `AsyncError()`
  /// arm'ı hiç eşleşmiyordu ve **bozuk bir feed sonsuza dek yükleme iskeleti
  /// gösteriyordu**. "İçerik okunamadı" ekranı ölü koddu.
  Widget _content(
    AsyncValue<List<FeedItem>> feed,
    Set<String> interests,
    BuildContext context,
  ) {
    if (feed.value case final items?) {
      return _list(_filter(items, interests), context);
    }

    // Bozuk bir feed sessizce boş liste gibi görünmez: hata olduğu söylenir,
    // çünkü "içerik yok" ile "içerik okunamadı" farklı şeyler.
    if (feed.hasError) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyStateView(
          key: Key('feed-error'),
          title: 'İçerik okunamadı',
          message:
              'İçerik dosyası açılamadı. Uygulamayı güncellemek sorunu '
              'çözebilir.',
        ),
      );
    }

    // `LoadingSkeleton`, iptal edilebilir bir Timer kullanır;
    // `CircularProgressIndicator` sonsuz animasyonuyla her ekranın
    // `pumpAndSettle`'ını zaman aşımına uğratıyordu.
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        key: Key('feed-loading'),
        padding: EdgeInsets.all(AppSpacing.lg),
        child: LoadingSkeleton(),
      ),
    );
  }

  Widget _list(List<FeedItem> items, BuildContext context) => SliverPadding(
    padding: const EdgeInsets.all(AppSpacing.lg),
    sliver: items.isEmpty
        ? SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyStateView(
              title: 'İçerik bulunamadı',
              message: _selectedTab == HomeTab.sanaOzel
                  ? 'Seçtiğin ilgi alanlarına uyan içerik yok. '
                        'Ayarlardan ilgi alanlarını genişletebilirsin.'
                  : 'Bu sekme için henüz içerik yok.',
            ),
          )
        : SliverList.separated(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return FeedItemCard(
                key: ValueKey(item.id),
                item: ContentCardModel.fromFeedItem(item),
                onTap: () => _openItem(context, item),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
          ),
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
