import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/feed/feed_schema.dart';
import '../../data/feed/feed_sync_state.dart';
import '../../data/interests/interest_taxonomy.dart';
import '../../data/providers.dart';
import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_tokens.dart';
import '../../ui/content_card_model.dart';
import '../../ui/detail_route.dart';
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
        // Eşleşme `interest_taxonomy.dart`'ta: ilgi alanı kimliği, feed'in
        // konu slug'larıyla anahtar kelime üzerinden eşleşir. Burada
        // doğrudan karşılaştırma yapılıyordu ve iki sözcük dağarcığı hiç
        // kesişmediği için sekme **kalıcı olarak boştu** (cihazda bulundu,
        // 28 Temmuz 2026).
        HomeTab.sanaOzel => filterByInterests(items, interests),
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

  /// Her tür aynı detay ekranına gider.
  ///
  /// Burada bir tür `switch`'i vardı ve `tool` ile `announcement` dalları
  /// yalnız "detay ekranı henüz uygulanmadı" diyordu. Ölçüldü (2026-07-28):
  /// üretilen 200 kaydın 146'sı duyuru — akışın dörtte üçü kapalı kapıydı.
  /// Ekran zaten tür bağımsız çalışıyordu.
  void _openItem(BuildContext context, FeedItem item) =>
      context.push(detailRoute(item.id));

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
                        'TecNow',
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
              // Yer imi durumu kayıt listesinden okunur; kartın kendi
              // `bool`'undan değil. Aynı kayıt Keşfet'te de görünüyor ve
              // ikisi aynı şeyi göstermeli.
              final saved = ref.watch(savedItemIdsProvider);
              return FeedItemCard(
                key: ValueKey(item.id),
                item: ContentCardModel.fromFeedItem(item),
                onTap: () => _openItem(context, item),
                isSaved: saved.contains(item.id),
                onToggleSave: () =>
                    ref.read(savedItemsProvider.notifier).toggleFeedItem(item),
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
        // Dokunma alanı 44 dp'ye tamamlanır, **çizilen kutu değişmez.**
        //
        // Ölçüldü (2026-07-28, 360 dp, gerçek yazı tipi): sekme 39 dp
        // yüksekliğindeydi ve 44x44'lük bir kutunun **dört köşesi de**
        // ıskalıyordu — yani `QUALITY_GATES.md`'nin "minimum 44x44 dokunma
        // alanı" kuralı uygulamanın en çok kullanılan kontrolünde geçerli
        // değildi. Material'in çipleri görünenden geniş bir dokunma alanı
        // ekliyor; ham `InkWell` eklemiyor.
        //
        // `minHeight` `Column`'a uygulanır, `Container`'a değil: `Container`
        // gevşek kısıtla kendi doğal yüksekliğinde (39 dp) kalır ve alt
        // çizgisi tam olduğu yerde durur. Aradaki fark saydam dokunma
        // alanıdır. Büyük yazı ölçeğinde kutu zaten 44'ü aşar ve bu sarmalayıcı
        // hiçbir şey eklemez.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppTouchTarget.minimum),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
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
                // (CLAUDE.md değişmez kural). Mono yalnız teknik metadata
                // içindir.
                child: Text(
                  label,
                  style: AppTypography.label.copyWith(
                    fontSize: 13,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
