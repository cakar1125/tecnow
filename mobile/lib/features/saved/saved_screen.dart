import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_tokens.dart';
import '../../fixtures/fixtures.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final List<SavedItemFixture> _items = List.of(savedItemFixtures);
  SavedItemKind? _selectedKind;

  List<SavedItemFixture> get _filteredItems => _selectedKind == null
      ? _items
      : _items.where((item) => item.kind == _selectedKind).toList();

  void _remove(SavedItemFixture item) {
    setState(() => _items.remove(item));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kaydı kaldırma yalnız yerel fixture etkileşimidir.'),
      ),
    );
  }

  void _openDetails(SavedItemFixture item) {
    switch (item.kind) {
      case SavedItemKind.repository:
        context.push('/repository/${item.id}');
        return;
      case SavedItemKind.aiModel:
        context.push('/ai-model/${item.id}');
        return;
      case SavedItemKind.tool:
      case SavedItemKind.skill:
      case SavedItemKind.assistantProject:
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
    final items = _filteredItems;

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
          child: items.isEmpty
              ? const EmptyStateView(
                  title: 'Bu filtrede kayıt kalmadı.',
                  message:
                      'Başka bir kategori seçerek hayalî fixture kayıtlarını '
                      'görebilirsin.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return SavedItemCard(
                      key: ValueKey(item.id),
                      item: item,
                      onRemove: () => _remove(item),
                      onOpenDetails: () => _openDetails(item),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, SavedItemKind? kind) => AppFilterChip(
    label: label,
    selected: _selectedKind == kind,
    onSelected: (_) => setState(() => _selectedKind = kind),
  );
}
