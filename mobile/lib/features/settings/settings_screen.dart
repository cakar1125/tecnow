import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../data/repositories/local_data_repository.dart';
import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_tokens.dart';
import 'local_data_eraser.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _comingSoonMessage = 'Bu ekran sonraki fazda uygulanacak.';

  /// Geçmiş listesi onaylı ekran haritasında yok; sayı gösteriliyor ama
  /// liste ekranı bir tasarım kararı bekliyor.
  static const _historyViewMessage =
      'Okuma geçmişi kaydediliyor. Liste ekranı onaylı tasarımda henüz yok.';

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmLocalDataDeletion(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Messenger dialog'dan önce alınır: `await` sonrasında `context` artık
    // güvenle kullanılamaz.
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppConfirmationDialog(
        title: 'Verileri Sil',
        message:
            'Bu cihazdaki yerel verileri silmek istediğinizden emin misiniz?',
        onConfirm: () => Navigator.of(dialogContext).pop(true),
      ),
    );
    if (confirmed != true) return;

    try {
      await eraseAllLocalData(ref);
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Yerel veriler silindi. Uygulama yeniden açıldığında kurulum '
            'baştan sorulacak.',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Yerel veriler silinemedi: $error')),
      );
    }
  }

  /// Adet okunamıyorsa satır sayısız gösterilir — yanlış bir `0` yazmaktansa
  /// hiçbir şey yazmamak dürüsttür.
  String? _countLabel(
    AsyncValue<LocalDataCounts> counts,
    int Function(LocalDataCounts) select,
  ) => switch (counts) {
    AsyncData(:final value) => '${select(value)} kayıt',
    _ => null,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(localDataCountsProvider);
    return _build(context, ref, counts);
  }

  Widget _build(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<LocalDataCounts> counts,
  ) => Material(
    color: AppColors.background,
    child: Column(
      children: [
        const AppTopBar(title: 'TeknoAkış'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Ayarlar', style: AppTypography.headline),
                const SizedBox(height: AppSpacing.xl),
                _SettingsSection(
                  title: 'KİŞİSELLEŞTİRME',
                  children: [
                    _SettingsRow(
                      icon: Icons.interests_outlined,
                      title: 'İlgi Alanları',
                      onTap: () => context.push('/interests'),
                    ),
                    _SettingsRow(
                      icon: Icons.language_rounded,
                      title: 'Dil',
                      value: 'Türkçe',
                      onTap: () => _showMessage(context, _comingSoonMessage),
                    ),
                    _SettingsRow(
                      icon: Icons.palette_outlined,
                      title: 'Tema',
                      value: 'Koyu',
                      onTap: () => _showMessage(context, _comingSoonMessage),
                    ),
                    _SettingsRow(
                      icon: Icons.tune_rounded,
                      title: 'İçerik Tercihleri',
                      onTap: () => _showMessage(context, _comingSoonMessage),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                _SettingsSection(
                  title: 'YEREL VERİLER',
                  children: [
                    _SettingsRow(
                      icon: Icons.bookmark_outline,
                      title: 'Kaydedilen İçerikler',
                      value: _countLabel(counts, (c) => c.savedItems),
                      onTap: () => context.go('/saved'),
                    ),
                    _SettingsRow(
                      icon: Icons.forum_outlined,
                      title: 'Asistan Konuşmaları',
                      value: _countLabel(
                        counts,
                        (c) => c.assistantConversations,
                      ),
                      onTap: () => _showMessage(context, _comingSoonMessage),
                    ),
                    _SettingsRow(
                      icon: Icons.history_rounded,
                      title: 'Okuma Geçmişi',
                      value: _countLabel(counts, (c) => c.readHistory),
                      onTap: () => _showMessage(context, _historyViewMessage),
                    ),
                    _SettingsRow(
                      icon: Icons.download_outlined,
                      title: 'Verileri Dışa Aktar',
                      onTap: () => _showMessage(context, _comingSoonMessage),
                    ),
                    _SettingsRow(
                      icon: Icons.delete_outline,
                      title: 'Verileri Sil',
                      color: AppColors.critical,
                      onTap: () => _confirmLocalDataDeletion(context, ref),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                const _SettingsSection(
                  title: 'GİZLİLİK',
                  children: [
                    _PrivacyItem(
                      icon: Icons.smartphone_rounded,
                      title: 'Verileriniz bu cihazda saklanır.',
                      description:
                          'İlgi alanlarınız, kaydedilen içerikler ve sohbet '
                          'geçmişi bu cihazda saklanır.',
                    ),
                    _PrivacyItem(
                      icon: Icons.person_off_outlined,
                      title: 'Hesap gerekmez.',
                      description:
                          'Proje Asistanı yanıt üretirken gerekli mesaj '
                          'içeriği seçilen AI hizmetine gönderilebilir. '
                          'TeknoAkış hesap veya sosyal profil oluşturmaz.',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                _SettingsSection(
                  title: 'HAKKINDA',
                  children: [
                    _SettingsRow(
                      icon: Icons.info_outline_rounded,
                      title: 'TeknoAkış Hakkında',
                      onTap: () => _showMessage(context, _comingSoonMessage),
                    ),
                    _SettingsRow(
                      icon: Icons.policy_outlined,
                      title: 'Kaynak Politikası',
                      onTap: () => _showMessage(context, _comingSoonMessage),
                    ),
                    _SettingsRow(
                      icon: Icons.description_outlined,
                      title: 'Lisanslar',
                      onTap: () => _showMessage(context, _comingSoonMessage),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'Uygulama Sürümü: [DESIGN_FIXTURE_ONLY]',
                  style: AppTypography.technical,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: AppSpacing.sm),
        child: Text(
          title,
          style: AppTypography.label.copyWith(color: AppColors.primary),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Material(
        color: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.cardBorder,
          side: BorderSide(color: AppColors.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var index = 0; index < children.length; index++) ...[
              children[index],
              if (index < children.length - 1)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.outline,
                ),
            ],
          ],
        ),
      ),
    ],
  );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.value,
    this.color = AppColors.textPrimary,
  });

  final IconData icon;
  final String title;
  final String? value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.body.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(value!, style: AppTypography.bodyMuted),
              ],
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PrivacyItem extends StatelessWidget {
  const _PrivacyItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.lg),
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
              Text(description, style: AppTypography.bodyMuted),
            ],
          ),
        ),
      ],
    ),
  );
}
