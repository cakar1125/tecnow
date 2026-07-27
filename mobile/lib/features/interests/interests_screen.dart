import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_tokens.dart';
import '../../fixtures/fixtures.dart';

class InterestsScreen extends ConsumerWidget {
  const InterestsScreen({super.key});

  static const minimumSelection = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(interestsProvider);

    return Scaffold(
      appBar: const AppTopBar(title: 'İlgi Alanları'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: switch (selected) {
            AsyncData(:final value) => _Content(selected: value),
            AsyncError(:final error) => ErrorStateView(
              title: 'İlgi alanları okunamadı',
              message: '$error',
            ),
            _ => const LoadingSkeleton(),
          },
        ),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.selected});

  final Set<String> selected;

  Future<void> _continue(BuildContext context, WidgetRef ref) async {
    await ref.read(interestsProvider.notifier).persist();

    // Onboarding, ilgi alanı seçimiyle biter: bayrak burada yazılır, böylece
    // sonraki açılışlarda splash doğrudan akışa gider.
    try {
      final preferences = await ref.read(appPreferencesProvider.future);
      await preferences.markOnboardingCompleted();
    } catch (_) {
      // Bayrak yazılamazsa onboarding tekrar gösterilir; seçimler yine kalıcı.
    }

    if (context.mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enough = selected.length >= InterestsScreen.minimumSelection;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Akışını şekillendir', style: AppTypography.headline),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Devam etmek için en az ${InterestsScreen.minimumSelection} '
          'örnek konu seç.',
          style: AppTypography.bodyMuted,
        ),
        const SizedBox(height: AppSpacing.xl),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: interestFixtures
                  .map(
                    (item) => AppFilterChip(
                      label: item,
                      selected: selected.contains(item),
                      onSelected: (_) =>
                          ref.read(interestsProvider.notifier).toggle(item),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ),
        Semantics(
          liveRegion: true,
          label: '${selected.length} ilgi alanı seçildi',
          child: Text(
            '${selected.length}/${InterestsScreen.minimumSelection} seçildi',
            style: AppTypography.label,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        PrimaryButton(
          label: 'Akışa geç',
          onPressed: enough ? () => _continue(context, ref) : null,
        ),
      ],
    );
  }
}
