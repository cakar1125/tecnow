import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../data/repositories/saved_items_repository.dart';
import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_tokens.dart';
import '../../fixtures/fixtures.dart';

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

  void _openDetails(SavedItem item) {
    switch (_kindOf(item)) {
      case SavedItemKind.repository:
        context.push('/repository/${item.id}');
        return;
      case SavedItemKind.aiModel:
        context.push('/ai-model/${item.id}');
        return;
      case SavedItemKind.tool:
      case SavedItemKind.skill:
      case SavedItemKind.assistantProject:
      case null:
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
            AsyncData(:final value) => _list(_filter(value)),
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

  List<SavedItem> _filter(List<SavedItem> items) => _selectedKind == null
      ? items
      : items.where((item) => _kindOf(item) == _selectedKind).toList();

  Widget _list(List<SavedItem> items) => items.isEmpty
      ? const EmptyStateView(
          title: 'Bu filtrede kayıt kalmadı.',
          message:
              'Başka bir kategori seçerek bu cihazdaki kayıtları görebilirsin.',
        )
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

/// Depo `kind` alanını serbest metin olarak saklar; bilinmeyen bir tür
/// çökmeye değil, tür rozeti olmayan bir karta dönüşür.
SavedItemKind? _kindOf(SavedItem item) {
  for (final kind in SavedItemKind.values) {
    if (kind.name == item.kind) return kind;
  }
  return null;
}

/// `SavedItemCard` fixture şeklini bekliyor. Kayıtların tamamı şu an fixture
/// tohumundan geldiği için dönüşüm bilgi kaybetmez; Faz 3'te gerçek içerik
/// gelince kart kendi modeline geçmelidir.
SavedItemFixture _toCardModel(SavedItem item) => SavedItemFixture(
  kind: _kindOf(item) ?? SavedItemKind.tool,
  id: item.id,
  title: item.title,
  sourceLabel: item.sourceLabel ?? 'Bilinmeyen kaynak',
  summary: item.summary ?? '',
);
