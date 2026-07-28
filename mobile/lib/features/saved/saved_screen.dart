import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/feed/feed_schema.dart' show FeedItemKind;
import '../../data/providers.dart';
import '../../data/repositories/saved_items_repository.dart';
import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_tokens.dart';
import '../../fixtures/fixtures.dart';
import '../../ui/content_card_model.dart';
import '../../ui/detail_route.dart';

class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  SavedItemKind? _selectedKind;

  Future<void> _remove(SavedItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(savedItemsProvider.notifier).remove(item.id);
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Kayıt bu cihazdan kaldırıldı.')),
    );
  }

  /// Tür ne olursa olsun aynı detay ekranı. Burada da bir tür `switch`'i
  /// vardı ve kaydedilen içeriğin bir kısmı açılamıyordu.
  void _openDetails(SavedItem item) => context.push(detailRoute(item.id));

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(savedItemsProvider);

    return Column(
      children: [
        const AppTopBar(title: 'Kaydedilenler'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              _filterChip('Tümü', null),
              const SizedBox(width: AppSpacing.sm),
              _filterChip('Repository', SavedItemKind.repository),
              const SizedBox(width: AppSpacing.sm),
              _filterChip('AI', SavedItemKind.aiModel),
              const SizedBox(width: AppSpacing.sm),
              _filterChip('Araçlar', SavedItemKind.tool),
              const SizedBox(width: AppSpacing.sm),
              _filterChip('Skills', SavedItemKind.skill),
              const SizedBox(width: AppSpacing.sm),
              _filterChip('Asistan Projeleri', SavedItemKind.assistantProject),
            ],
          ),
        ),
        Expanded(
          child: switch (saved) {
            AsyncData(:final value) => _list(
              _filter(value),
              anySaved: value.isNotEmpty,
            ),
            AsyncError(:final error) => ErrorStateView(
              title: 'Kayıtlar okunamadı',
              message: '$error',
            ),
            _ => const LoadingSkeleton(),
          },
        ),
      ],
    );
  }

  List<SavedItem> _filter(List<SavedItem> items) {
    final selected = _selectedKind;
    if (selected == null) return items;
    final kinds = _kindsOf(selected);
    return items
        .where((item) => kinds.contains(_feedKindOf(item)))
        .toList(growable: false);
  }

  /// Boş liste iki farklı şey olabilir ve ikisi aynı cümleyle anlatılamaz:
  /// hiç kaydın olmaması (ilk açılış) ile seçili süzgecin boş olması.
  Widget _empty(bool anySaved) => anySaved
      ? const EmptyStateView(
          key: Key('saved-filter-empty'),
          title: 'Bu filtrede kayıt kalmadı.',
          message:
              'Başka bir kategori seçerek bu cihazdaki kayıtları görebilirsin.',
        )
      : const EmptyStateView(
          key: Key('saved-none'),
          title: 'Henüz kayıt yok',
          message:
              'Akışta veya Keşfet\'te bir içeriğin yer imi simgesine dokunarak '
              'bu cihaza kaydedebilirsin.',
        );

  Widget _list(List<SavedItem> items, {required bool anySaved}) => items.isEmpty
      ? _empty(anySaved)
      : ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final item = items[index];
            return SavedItemCard(
              key: ValueKey(item.id),
              item: _toCardModel(item),
              onRemove: () => _remove(item),
              onOpenDetails: () => _openDetails(item),
            );
          },
        );

  Widget _filterChip(String label, SavedItemKind? kind) => AppFilterChip(
    label: label,
    selected: _selectedKind == kind,
    onSelected: (_) => setState(() => _selectedKind = kind),
  );
}

/// Satırdaki `kind` serbest metindir; feed türüne çözülür.
///
/// Kaydetme artık `FeedItemKind.name` yazıyor, yani çözülememesi yalnız
/// 2026-07-28 öncesi yazılmış satırlarda mümkün — onları da açılıştaki
/// örnek temizliği siliyor (`saved_items_sample_cleanup.dart`).
FeedItemKind? _feedKindOf(SavedItem item) {
  for (final kind in FeedItemKind.values) {
    if (kind.name == item.kind) return kind;
  }
  return null;
}

/// Süzgeç çipi → eşleşen feed türleri.
///
/// `Araçlar` hem `tool` hem `mcp` alır: MCP sunucusu bir araçtır ve onaylı
/// tasarımda ayrı bir çipi yok. `Asistan Projeleri` bugün hiçbir şeyle
/// eşleşmez, çünkü asistan henüz hiçbir şey yazmıyor. **Duyurular** da
/// hiçbir çiple eşleşmiyor; yalnız `Tümü` altında görünürler — açık tasarım
/// kararı olarak `docs/NEXT_ACTION.md`'de kayıtlı.
Set<FeedItemKind> _kindsOf(SavedItemKind chip) => switch (chip) {
  SavedItemKind.repository => const {FeedItemKind.repository},
  SavedItemKind.aiModel => const {FeedItemKind.aiModel},
  SavedItemKind.tool => const {FeedItemKind.tool, FeedItemKind.mcp},
  SavedItemKind.skill => const {FeedItemKind.skill},
  SavedItemKind.assistantProject => const {},
};

ContentCardModel _toCardModel(SavedItem item) => ContentCardModel(
  kind: _feedKindOf(item) ?? FeedItemKind.tool,
  id: item.id,
  title: item.title,
  sourceLabel: item.sourceLabel ?? 'Bilinmeyen kaynak',
  summary: item.summary ?? '',
);
