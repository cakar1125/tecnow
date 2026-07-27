/// Bir feed kaydının detay gövdesi.
///
/// İki ekran de (`/repository/:id`, `/ai-model/:id`) bunu kullanır; aralarındaki
/// fark yalnız başlık ve vurgu rengidir.
///
/// **Burada yalnız kayıtta gerçekten bulunan bilgi gösterilir.** Önceki hâli
/// `widget.id`'yi hiç okumuyordu: gerçek bir karta dokunan kullanıcı sabit bir
/// fixture görüyordu — uydurma yıldız/fork/issue sayıları, hayalî bir README,
/// kurgusal "yetenekler" ve bunların üstünde bir "doğrulanmış" rozeti.
/// `CLAUDE.md` değişmez kuralı bunu yasaklıyor: kurgusal tasarım verisi gerçek
/// veya doğrulanmış veri gibi sunulmaz.
///
/// Feed'de olmayan hiçbir alan uydurulmaz. Dil dağılımı, README, benchmark ve
/// fork/issue sayıları kaynaklardan gelmiyor; bu yüzden **hiç çizilmiyorlar**.
library;

import 'package:flutter/material.dart';

import '../../data/feed/feed_schema.dart';
import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_tokens.dart';

class FeedItemDetail extends StatelessWidget {
  const FeedItemDetail({
    required this.item,
    required this.accent,
    required this.onOpenSource,
    super.key,
  });

  final FeedItem item;
  final Color accent;

  /// Orijinal kaynağı açar. Dışarıdan veriliyor ki ekran testleri gerçek bir
  /// tarayıcı çağrısı yapmadan düğmenin bağlı olduğunu ölçebilsin.
  final void Function(Uri url) onOpenSource;

  @override
  Widget build(BuildContext context) {
    final (categoryLabel, _, categoryIcon) = categoryOf(item.kind);

    return ListView(
      key: const Key('detail-content'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppBadge(label: categoryLabel, color: accent, icon: categoryIcon),
            if (item.summaryOrigin != SummaryOrigin.original)
              const AppBadge(
                label: 'TEKNOAKIŞ ÖZETİ',
                color: AppColors.aiAccent,
              ),
            if (!item.language.toLowerCase().startsWith('tr'))
              AppBadge(
                label: item.language.toUpperCase(),
                color: AppColors.textSecondary,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          item.title,
          key: const Key('detail-title'),
          style: AppTypography.headline.copyWith(color: accent),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(item.sourceName, style: AppTypography.bodyMuted),
        const SizedBox(height: AppSpacing.lg),
        Text(item.summary, style: AppTypography.body),

        // Geri çekilmiş içerik akışta gösterilmiyor ama elle girilen bir
        // adresle buraya gelinebilir; düzeltme kaydı saklanmaz.
        if (item.correctionNote case final note?) ...[
          const SizedBox(height: AppSpacing.lg),
          _Panel(
            accent: AppColors.warning,
            child: Text('Düzeltme: $note', style: AppTypography.body),
          ),
        ],

        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          key: const Key('detail-open-source'),
          label: 'Kaynağa git',
          icon: Icons.open_in_new_rounded,
          onPressed: () => onOpenSource(item.url),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          item.url.host,
          style: AppTypography.technical,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppSpacing.xl),
        Text('Güven sinyalleri', style: AppTypography.title),
        const SizedBox(height: AppSpacing.md),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Signal(
                label: 'Kaynağın kendi duyurusu',
                met: item.trust.officialSource,
              ),
              _Signal(label: 'Bakımda', met: item.trust.maintained),
              _Signal(
                label: 'Yakın zamanda güncellendi',
                met: item.trust.recentlyUpdated,
              ),
              _Signal(label: 'Lisansı belirtilmiş', met: item.trust.hasLicense),
              // Popülerlik yalnız **varsa** gösterilir: bir blog yazısının
              // yıldızı yoktur ve "0" yazmak yanlış bir olumsuzluk olurdu.
              if (item.trust.popularity case final count? when count > 0)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    'Popülerlik: $count',
                    style: AppTypography.technical,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Fact('Yayın tarihi', _formatDate(item.publishedAt)),
              const SizedBox(height: AppSpacing.sm),
              _Fact('Son kontrol', _formatDate(item.checkedAt)),
            ],
          ),
        ),

        if (item.topics.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          Text('Konular', style: AppTypography.title),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final topic in item.topics)
                AppBadge(label: topic, color: AppColors.textSecondary),
            ],
          ),
        ],

        // Kopya birleştirme şeffaflığı: aynı gelişmenin diğer adresleri
        // gizlenmez (`CONTENT_TRUST_POLICY.md`).
        if (item.mergedUrls.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          Text('Aynı gelişmenin diğer kaynakları', style: AppTypography.title),
          const SizedBox(height: AppSpacing.md),
          for (final url in item.mergedUrls)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: TextButton(
                onPressed: () => onOpenSource(url),
                child: Text(url.host, style: AppTypography.technical),
              ),
            ),
        ],
      ],
    );
  }

  /// `28 Temmuz 2026`. `intl` paketi eklemek yerine tek biçim elle yazıldı:
  /// uygulamanın tek dili Türkçe ve tek bir tarih biçimi gerekiyor.
  static String _formatDate(DateTime value) {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    final local = value.toLocal();
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }
}

class _Signal extends StatelessWidget {
  const _Signal({required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Row(
      children: [
        Icon(
          met ? Icons.check_circle_outline : Icons.remove_circle_outline,
          size: 18,
          color: met ? AppColors.success : AppColors.textSecondary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: met
                ? AppTypography.body
                : AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    ),
  );
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: AppTypography.bodyMuted),
      Text(value, style: AppTypography.body),
    ],
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.accent});

  final Widget child;
  final Color? accent;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadius.cardBorder,
      border: Border.all(color: accent ?? AppColors.outline),
    ),
    child: child,
  );
}
