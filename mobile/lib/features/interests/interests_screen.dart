import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_tokens.dart';
import '../../fixtures/fixtures.dart';

class InterestsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    _restore();
    return <String>{};
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('selected_interests');
    if (state.isEmpty && stored != null) {
      state = stored.toSet();
    }
  }

  void toggle(String value) {
    state = state.contains(value)
        ? ({...state}..remove(value))
        : {...state, value};
  }

  Future<void> persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'selected_interests',
      state.toList(growable: false),
    );
  }
}

final interestsProvider = NotifierProvider<InterestsNotifier, Set<String>>(
  InterestsNotifier.new,
);

class InterestsScreen extends ConsumerWidget {
  const InterestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(interestsProvider);
    return Scaffold(
      appBar: const AppTopBar(title: 'İlgi Alanları'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Akışını şekillendir', style: AppTypography.headline),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Devam etmek için en az 3 örnek konu seç.',
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
                            onSelected: (_) => ref
                                .read(interestsProvider.notifier)
                                .toggle(item),
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
                  '${selected.length}/3 seçildi',
                  style: AppTypography.label,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: 'Akışa geç',
                onPressed: selected.length < 3
                    ? null
                    : () async {
                        await ref.read(interestsProvider.notifier).persist();
                        if (context.mounted) context.go('/home');
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
