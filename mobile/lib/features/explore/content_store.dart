/// Keşfet'in üst yarısı: **içerik mağazası**.
///
/// Keşfet uzun süre bir arama sonucu ekranıydı — yazıyordun, kartlar
/// geliyordu, bitiyordu. Akışın kendisine dokunmuyordu.
///
/// Burada yaptığı iş değişti: **akışın kurulduğu yer.** Kaynağı kapatırsan
/// Ana Sayfa'dan çıkar, ilgi alanını açarsan "Sana Özel" değişir. Arama
/// aşağıda duruyor ve hâlâ çalışıyor; ama ekranın birinci işi artık seçim.
///
/// Sayılar gerçek: her kaynağın yanındaki adet o kaynağın akıştaki kayıt
/// sayısı, uydurulmuş bir rozet değil.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/feed/feed_schema.dart';
import '../../data/interests/interest_taxonomy.dart';
import '../../data/providers.dart';
import '../../design_system/components/feed_items.dart';
import '../../design_system/tokens/app_palette.dart';
import '../../design_system/tokens/app_text.dart';
import '../../design_system/tokens/app_tokens.dart';

class ContentStore extends ConsumerWidget {
  const ContentStore({required this.items, super.key});

  /// **Süzülmemiş** akış. Kapatılmış bir kaynak da listede görünmeli, yoksa
  /// geri açılamaz.
  final List<FeedItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muted = ref.watch(mutedSourcesProvider);
    final counts = _sourceCounts(items);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StoreHeader(
          title: 'Kaynaklar',
          trailing: '${counts.length - muted.length}/${counts.length} açık',
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final entry in counts.entries)
          _SourceRow(
            key: Key('store-source-${entry.key}'),
            sourceName: entry.key,
            count: entry.value,
            muted: muted.contains(entry.key),
            onToggle: () =>
                ref.read(mutedSourcesProvider.notifier).toggle(entry.key),
          ),
        const SizedBox(height: AppSpacing.xl),
        const _InterestSection(),
      ],
    );
  }

  /// Kaynak → kayıt sayısı, çoktan aza.
  static Map<String, int> _sourceCounts(List<FeedItem> items) {
    final counts = <String, int>{};
    for (final item in items) {
      counts[item.sourceName] = (counts[item.sourceName] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {for (final entry in sorted) entry.key: entry.value};
  }
}

class _StoreHeader extends StatelessWidget {
  const _StoreHeader({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: [
      // İkisi de esnek: 360 dp'de 1.6 yazı ölçeğiyle "İlgi Alanları" +
      // "12/18 seçili" satırı **7.4 px taşıyordu** (ölçüm:
      // `explore_screen_test.dart` taşma kapısı). Başlık öncelikli, sayaç
      // gerekirse kısalır — sayaç ikincil bilgi.
      Flexible(
        child: Text(
          title,
          style: context.text.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      if (trailing case final label?) ...[
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            label,
            style: context.text.label,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ],
  );
}

/// Bir kaynak satırı: marka işareti, ad, kayıt sayısı ve aç/kapa.
class _SourceRow extends StatelessWidget {
  const _SourceRow({
    required this.sourceName,
    required this.count,
    required this.muted,
    required this.onToggle,
    super.key,
  });

  final String sourceName;
  final int count;
  final bool muted;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Semantics(
      button: true,
      // Ekran okuyucu için durum: "seçili" değil "açık/kapalı" anlamı
      // taşıyor ve etiket bunu söylüyor.
      toggled: !muted,
      label: muted ? '$sourceName kapalı' : '$sourceName açık',
      excludeSemantics: true,
      child: InkWell(
        onTap: onToggle,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppTouchTarget.minimum + AppSpacing.md,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                // Kapalı kaynak soluklaşır ama **kaybolmaz**: kapattığın
                // şeyi göremezsen geri açamazsın.
                Opacity(
                  opacity: muted ? 0.45 : 1,
                  child: SourceMark(sourceName: sourceName, size: 40),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        sourceName,
                        style: context.text.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: muted
                              ? palette.textSecondary
                              : palette.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text('$count kayıt', style: context.text.label),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _ToggleMark(on: !muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Açık/kapalı işareti: açıkken dolu onay, kapalıyken boş artı.
///
/// Biçim durumu tek başına anlatır — yalnız renkle ayırmak, renk körlüğü
/// olan kullanıcı için hiçbir şey anlatmaz.
class _ToggleMark extends StatelessWidget {
  const _ToggleMark({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // Kutu 44×44: bu işaret **dokunulabilir görünüyor** ve öyle görünen her
    // şey dokunulabilir olmalı. `QUALITY_GATES.md` minimumu.
    return Container(
      width: AppTouchTarget.minimum,
      height: AppTouchTarget.minimum,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: on ? palette.primary.withValues(alpha: 0.16) : null,
        borderRadius: AppRadius.smallBorder,
        border: Border.all(color: on ? palette.primary : palette.outlineStrong),
      ),
      child: Icon(
        on ? Icons.check_rounded : Icons.add_rounded,
        size: 18,
        color: on ? palette.primary : palette.textSecondary,
      ),
    );
  }
}

/// İlgi alanları — aynı aç/kapa mekaniği, mevcut depoya bağlı.
class _InterestSection extends ConsumerWidget {
  const _InterestSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(interestsProvider).value ?? const <String>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StoreHeader(
          title: 'İlgi Alanları',
          trailing: '${selected.length}/${interestTaxonomy.length} seçili',
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Seçtiklerin "Sana Özel" sekmesini belirler.',
          style: context.text.bodyMuted,
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final interest in interestTaxonomy)
              _InterestChip(
                key: Key('store-interest-${interest.id}'),
                label: interest.label,
                on: selected.contains(interest.id),
                onToggle: () async {
                  final notifier = ref.read(interestsProvider.notifier);
                  notifier.toggle(interest.id);
                  await notifier.persist();
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({
    required this.label,
    required this.on,
    required this.onToggle,
    super.key,
  });

  final String label;
  final bool on;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Semantics(
      button: true,
      toggled: on,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: AppRadius.largeBorder,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppTouchTarget.minimum,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: on ? palette.primary.withValues(alpha: 0.14) : null,
                borderRadius: AppRadius.largeBorder,
                border: Border.all(
                  color: on ? palette.primary : palette.outlineStrong,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: context.text.label.copyWith(
                      color: on ? palette.primary : palette.textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    on ? Icons.check_rounded : Icons.add_rounded,
                    size: 16,
                    color: on ? palette.primary : palette.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
