import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_version.dart';
import '../../data/providers.dart';
import '../../data/repositories/local_data_repository.dart';
import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_tokens.dart';
import '../read_history/read_history_screen.dart';
import 'about_screen.dart';
import 'local_data_eraser.dart';
import 'source_policy_screen.dart';

/// Ayarlar.
///
/// Bu ekranın uzun süre en büyük kusuru şuydu: **on bir satırın dokuzu hiçbir
/// yere gitmiyordu.** Hepsinde `>` oku vardı — yani "arkada bir ekran var"
/// diyorlardı — ve dokunulduğunda "Bu ekran sonraki fazda uygulanacak."
/// yazan bir SnackBar açılıyordu. Kullanıcı için bunlar bozuk düğmelerdi.
///
/// Ayrım artık şu: **gerçekten yapılabilecekler yapıldı**, geri kalanı da
/// dokunulabilir görünmeyi bıraktı. Yakında gelecek bir satır listede
/// duruyor (yol haritasını anlatıyor) ama okunu ve dokunma davranışını
/// kaybediyor, yerine "Yakında" etiketi geliyor. Söz vermeyen bir satır,
/// verip tutmayan bir satırdan iyidir.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

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
        const AppTopBar(title: 'Tecnow'),
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
                    // Tek dil ve tek tema var; seçilecek bir şey olmadığı için
                    // bunlar bir ekran değil, birer olgu. Değer gösteriliyor,
                    // gidilecek yer olduğu iddia edilmiyor.
                    const _SettingsRow.upcoming(
                      icon: Icons.language_rounded,
                      title: 'Dil',
                      value: 'Türkçe',
                    ),
                    const _SettingsRow.upcoming(
                      icon: Icons.palette_outlined,
                      title: 'Tema',
                      value: 'Koyu',
                    ),
                    const _SettingsRow.upcoming(
                      icon: Icons.tune_rounded,
                      title: 'İçerik Tercihleri',
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
                    _SettingsRow.upcoming(
                      icon: Icons.forum_outlined,
                      title: 'Asistan Konuşmaları',
                      value: _countLabel(
                        counts,
                        (c) => c.assistantConversations,
                      ),
                    ),
                    _SettingsRow(
                      icon: Icons.history_rounded,
                      title: 'Okuma Geçmişi',
                      value: _countLabel(counts, (c) => c.readHistory),
                      onTap: () => context.push(readHistoryRoute),
                    ),
                    _SettingsRow.upcoming(
                      icon: Icons.download_outlined,
                      title: 'Verileri Dışa Aktar',
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
                          'Tecnow hesap veya sosyal profil oluşturmaz.',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                _SettingsSection(
                  title: 'HAKKINDA',
                  children: [
                    _SettingsRow(
                      icon: Icons.info_outline_rounded,
                      title: 'Tecnow Hakkında',
                      onTap: () => context.push(aboutRoute),
                    ),
                    _SettingsRow(
                      icon: Icons.policy_outlined,
                      title: 'Kaynak Politikası',
                      onTap: () => context.push(sourcePolicyRoute),
                    ),
                    // Flutter'ın yerleşik lisans ekranı. Kendi ekranımızı
                    // yazmak, bağımlılıkların lisanslarını elle listelemek ve
                    // her `pub upgrade` sonrası güncellemeyi hatırlamak
                    // demekti; `showLicensePage` listeyi derlemeden okur.
                    //
                    // `useRootNavigator` şart: varsayılan hâlinde sayfa
                    // Ayarlar sekmesinin **dal** yönlendiricisine itiliyor ve
                    // cihazda görüldüğü gibi (2026-07-28) altta uygulama
                    // navigasyonu duruyordu. Bu ekrandaki diğer sayfalar
                    // (Hakkında, Kaynak Politikası, Okuma Geçmişi) kök
                    // rotalar olduğu için tam ekran açılıyor; lisans sayfası
                    // tek başına farklı davranıyordu.
                    _SettingsRow(
                      icon: Icons.description_outlined,
                      title: 'Lisanslar',
                      onTap: () => showLicensePage(
                        context: context,
                        useRootNavigator: true,
                        applicationName: 'Tecnow',
                        applicationVersion: appVersionLabel,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                // Biçim onaylı tasarımdan olduğu gibi kalıyor: sürüm numarası
                // teknik bir tanımlayıcıdır ve `technical` token'ı tam bunun
                // için var. Değişen tek şey içerik.
                Text(
                  'Uygulama Sürümü: $appVersionLabel',
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
    required VoidCallback this.onTap,
    this.value,
    this.color = AppColors.textPrimary,
  });

  /// Henüz uygulanmamış bir satır.
  ///
  /// `onTap` **yoktur** — bu, "sonra uygulanacak" diyen bir SnackBar'ın
  /// yerini alan şey değil, onun tam tersi: satır dokunulabilir olduğunu hiç
  /// iddia etmiyor. `>` oku yerine "Yakında" etiketi gösterilir, metin
  /// soluklaşır ve erişilebilirlik ağacına devre dışı olarak geçer, böylece
  /// ekran okuyucu da tıklanabilir bir düğme duyurmaz.
  const _SettingsRow.upcoming({
    required this.icon,
    required this.title,
    this.value,
  }) : onTap = null,
       color = AppColors.textSecondary;

  final IconData icon;
  final String title;
  final String? value;
  final Color color;
  final VoidCallback? onTap;

  bool get _enabled => onTap != null;

  @override
  Widget build(BuildContext context) => Semantics(
    button: _enabled,
    enabled: _enabled,
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
              if (_enabled)
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: AppColors.textSecondary,
                )
              else
                const _UpcomingTag(),
            ],
          ),
        ),
      ),
    ),
  );
}

/// "Yakında" etiketi.
///
/// Okun yerini alıyor ve bilinçli olarak **oktan dar değil**: satır yüksekliği
/// ve hizası korunsun diye. Kendi rengi yok, kenarlığı `outline` — dikkat
/// çekmesi değil, sözü geri alması gerekiyor.
class _UpcomingTag extends StatelessWidget {
  const _UpcomingTag();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      borderRadius: AppRadius.smallBorder,
      border: Border.all(color: AppColors.outline),
    ),
    child: Text(
      'Yakında',
      style: AppTypography.label.copyWith(color: AppColors.textSecondary),
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
