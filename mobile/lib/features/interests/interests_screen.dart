import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/interests/interest_taxonomy.dart';
import '../../data/providers.dart';
import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_tokens.dart';

/// İlgi alanı seçimi. İki bağlamda açılıyor ve **ikisinde farklı davranıyor**.
///
/// Onboarding'de bu ekran akışın son adımı: geri dönülecek bir yer yok,
/// düğme "Akışa geç" diyor ve kurulumu tamamlıyor.
///
/// Ayarlar'dan ise bir **düzenleme**: kullanıcı ayarlarına dönmek istiyor.
/// Öncesinde ekran ikisini ayırmıyordu ve sonucu şuydu — Ayarlar → İlgi
/// Alanları'na girildiğinde başlık çubuğunda geri düğmesi yoktu
/// (`AppTopBar` `automaticallyImplyLeading: false` kullanıyor) ve tek çıkış
/// olan düğme `go('/home')` yapıyordu. Yani ayarlarını değiştiren kullanıcı
/// **Ana Sayfa'ya atılıyordu** ve geldiği yere dönemiyordu.
///
/// Ayrım `Navigator.canPop` ile yapılıyor: onboarding buraya `go` ile gelir
/// (yığın temizlenir), Ayarlar `push` ile. Kural kendi kendini koruyor —
/// "geri dönülecek bir yer varsa oraya dön" her iki bağlamda da doğru.
class InterestsScreen extends ConsumerWidget {
  const InterestsScreen({super.key});

  static const minimumSelection = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(interestsProvider);
    final editing = Navigator.canPop(context);

    return Scaffold(
      appBar: editing
          ? const AppBackTopBar(title: 'İlgi Alanları')
          : const AppTopBar(title: 'İlgi Alanları'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: switch (selected) {
            AsyncData(:final value) => _Content(
              selected: value,
              editing: editing,
            ),
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
  const _Content({required this.selected, required this.editing});

  final Set<String> selected;

  /// Ayarlar'dan mı açıldı (düzenleme) yoksa onboarding'in son adımı mı?
  final bool editing;

  Future<void> _continue(BuildContext context, WidgetRef ref) async {
    await ref.read(interestsProvider.notifier).persist();

    // Onboarding, ilgi alanı seçimiyle biter: bayrak burada yazılır, böylece
    // sonraki açılışlarda splash doğrudan akışa gider. Düzenleme sırasında
    // yazılmaz — kurulum zaten çoktan tamamlanmış, tekrar işaretlemek anlamsız
    // bir yazma olurdu.
    if (!editing) {
      try {
        final preferences = await ref.read(appPreferencesProvider.future);
        await preferences.markOnboardingCompleted();
      } catch (_) {
        // Bayrak yazılamazsa onboarding tekrar gösterilir; seçimler kalıcı.
      }
    }

    if (!context.mounted) return;
    // Geldiği yere döner. Düzenleyen kullanıcı Ayarlar'a, kurulumu bitiren
    // kullanıcı akışa gider.
    if (editing) {
      Navigator.of(context).maybePop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enough = selected.length >= InterestsScreen.minimumSelection;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Akışını şekillendir', style: AppTypography.headline),
        const SizedBox(height: AppSpacing.sm),
        // "örnek konu" ifadesi fixture döneminden kalmıştı. Seçilen konular
        // artık gerçekten akışı süzüyor (`interest_taxonomy.dart`); onlara
        // "örnek" demek, kullanıcıya seçiminin sonuçsuz olduğunu söylemekti.
        Text(
          'Devam etmek için en az ${InterestsScreen.minimumSelection} '
          'konu seç.',
          style: AppTypography.bodyMuted,
        ),
        const SizedBox(height: AppSpacing.xl),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              // Ekranda **etiket** görünür, veritabanına **kimlik** yazılır.
              // Önceden etiketin kendisi saklanıyordu ve feed'in konuları
              // İngilizce slug olduğu için "Sana Özel" sekmesi hiçbir zaman
              // eşleşme bulamıyordu.
              children: interestTaxonomy
                  .map(
                    (interest) => AppFilterChip(
                      key: Key('interest-${interest.id}'),
                      label: interest.label,
                      selected: selected.contains(interest.id),
                      // Burada zorunlu: kullanıcı arka arkaya en az üç çipe
                      // dokunuyor ve çipin seçilince genişlemesi `Wrap`
                      // düzenini yeniden akıtıp komşuları parmağın altından
                      // kaydırıyordu (cihazda görüldü, 2026-07-28).
                      stableWidth: true,
                      onSelected: (_) => ref
                          .read(interestsProvider.notifier)
                          .toggle(interest.id),
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
          // Etiket ne yaptığını söylemeli: düzenleyen kullanıcı akışa
          // geçmiyor, seçimini kaydedip geldiği yere dönüyor.
          label: editing ? 'Kaydet' : 'Akışa geç',
          onPressed: enough ? () => _continue(context, ref) : null,
        ),
      ],
    );
  }
}
