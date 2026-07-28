/// "Kaynak Politikası".
///
/// İki bölümü var ve ikisi de bilinçli olarak farklı yerden besleniyor:
///
/// 1. **Kurallar** sabit metindir, çünkü politika sabittir.
/// 2. **Kaynaklar listesi** ekrana gömülü değil, o an yüklü olan feed'den
///    hesaplanır.
///
/// İkincisi önemli. Kaynak adlarını buraya elle yazmak kolaydı ve tam da bu
/// ekranda yalan söyleyebilecek tek şey oydu: küratörlü liste değişip metin
/// güncellenmediğinde, kullanıcıya kaynakları saydığını iddia eden ama
/// gerçekte eski bir kopyayı gösteren bir ekran kalırdı. Listeyi feed'in
/// kendisinden türetince sapma **imkânsız** — gösterilen şey, okuduğu
/// içeriğin geldiği yerin ta kendisi.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/feed/feed_schema.dart';
import '../../data/providers.dart';
import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_tokens.dart';

const sourcePolicyRoute = '/kaynak-politikasi';

/// Bir kaynağın akışa kaç kayıt verdiği.
final class SourceUsage {
  const SourceUsage({
    required this.name,
    required this.kind,
    required this.itemCount,
  });

  final String name;
  final FeedSourceKind kind;
  final int itemCount;
}

String sourceKindLabel(FeedSourceKind kind) => switch (kind) {
  FeedSourceKind.github => 'GitHub',
  FeedSourceKind.huggingFace => 'Hugging Face',
  FeedSourceKind.officialBlog => 'Resmi bloglar',
  FeedSourceKind.documentation => 'Resmi dokümantasyon',
};

/// Kaynağın altında gösterilecek tür etiketi — ad zaten aynı şeyi söylüyorsa
/// `null`.
///
/// Cihazda görüldü (2026-07-28): platform kaynaklarında ad ile tür aynı olduğu
/// için satır **"Hugging Face"** başlığının altına yine "Hugging Face" yazıyordu.
/// Aynı sözcüğü iki kez yazmak bilgi vermiyor, hata gibi duruyor.
String? sourceKindSubtitle(SourceUsage source) {
  final label = sourceKindLabel(source.kind);
  return label == source.name ? null : label;
}

/// Akıştaki kaynakları, kayıt sayılarıyla birlikte çıkarır.
///
/// Sıralama önce sayıya, eşitlikte ada göre: aynı feed iki kez sayıldığında
/// aynı sırayı vermesi gerekiyor, yoksa liste kendiliğinden oynardı.
List<SourceUsage> sourcesInFeed(List<FeedItem> items) {
  final counts = <String, int>{};
  final kinds = <String, FeedSourceKind>{};
  for (final item in items) {
    counts.update(item.sourceName, (value) => value + 1, ifAbsent: () => 1);
    kinds.putIfAbsent(item.sourceName, () => item.sourceKind);
  }
  final usages =
      [
        for (final entry in counts.entries)
          SourceUsage(
            name: entry.key,
            kind: kinds[entry.key]!,
            itemCount: entry.value,
          ),
      ]..sort((a, b) {
        final byCount = b.itemCount.compareTo(a.itemCount);
        return byCount != 0 ? byCount : a.name.compareTo(b.name);
      });
  return usages;
}

class SourcePolicyScreen extends ConsumerWidget {
  const SourcePolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(feedProvider);
    return Scaffold(
      appBar: const AppBackTopBar(title: 'Kaynak Politikası'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('İçerik nereden geliyor?', style: AppTypography.headline),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'TeknoAkış haber yazmaz. Başkalarının yayımladığı gelişmeleri '
                'derler, kaynağıyla birlikte gösterir ve orijinaline yönlendirir.',
                style: AppTypography.bodyMuted,
              ),
              const SizedBox(height: AppSpacing.xl),

              const _PolicyRule(
                icon: Icons.lock_outline_rounded,
                title: 'Kapalı liste',
                body:
                    'Yalnızca önceden onaylanmış adreslerden içerik alınır. '
                    'Listede olmayan bir site, ne kadar popüler olursa olsun '
                    'akışa giremez.',
              ),
              const _PolicyRule(
                icon: Icons.verified_outlined,
                title: 'Önce birincil kaynak',
                body:
                    'GitHub, Hugging Face, kurumların kendi blogları ve resmi '
                    'dokümantasyon. Bir gelişmeyi aktaran değil, yapan yazar.',
              ),
              const _PolicyRule(
                icon: Icons.event_outlined,
                title: 'Tarih uydurulmaz',
                body:
                    'Yayın tarihini vermeyen bir kaynak listeye alınmaz. '
                    'Eksik tarihi bugünle doldurmak, eski bir yazıyı yeni '
                    'göstermek olurdu.',
              ),
              const _PolicyRule(
                icon: Icons.person_off_outlined,
                title: 'Kullanıcı içeriği yok',
                body:
                    'Akışta gönderi, yorum veya kullanıcı katkısı bulunmaz. '
                    'Yayımlayan taraf yalnızca TeknoAkış\'ın kaynak hattıdır.',
              ),

              const SizedBox(height: AppSpacing.lg),
              Text(
                'BU AKIŞTAKİ KAYNAKLAR',
                style: AppTypography.label.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.md),
              _SourceList(feed: feed),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceList extends StatelessWidget {
  const _SourceList({required this.feed});

  final AsyncValue<List<FeedItem>> feed;

  @override
  Widget build(BuildContext context) {
    // Durum sırası: elde veri varsa göster, yoksa hata, o da yoksa yükleniyor.
    // Riverpod 3 hatayı `AsyncLoading(error: …)` içinde taşıyabildiği için
    // `AsyncLoading()` ile başlayan bir eşleştirme hata kolunu ölü bırakır.
    if (feed.hasValue) {
      final sources = sourcesInFeed(feed.value!);
      if (sources.isEmpty) {
        return Text(
          'Akış henüz yüklenmedi.',
          key: const Key('source-policy-empty'),
          style: AppTypography.bodyMuted,
        );
      }
      return Column(
        key: const Key('source-policy-list'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (final source in sources) _SourceRow(source: source)],
      );
    }
    if (feed.hasError) {
      return Text(
        'Kaynak listesi okunamadı.',
        key: const Key('source-policy-error'),
        style: AppTypography.bodyMuted,
      );
    }
    return const LoadingSkeleton(key: Key('source-policy-loading'));
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.source});

  final SourceUsage source;

  @override
  Widget build(BuildContext context) {
    final subtitle = sourceKindSubtitle(source);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source.name,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null)
                  Text(subtitle, style: AppTypography.bodyMuted),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text('${source.itemCount} içerik', style: AppTypography.bodyMuted),
        ],
      ),
    );
  }
}

class _PolicyRule extends StatelessWidget {
  const _PolicyRule({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 22, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(body, style: AppTypography.bodyMuted),
            ],
          ),
        ),
      ],
    ),
  );
}
