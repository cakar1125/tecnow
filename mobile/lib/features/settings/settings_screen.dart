import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_version.dart';
import '../../data/feed/feed_schema.dart' show feedDefaultLanguage;
import '../../data/providers.dart';
import '../../data/repositories/local_data_repository.dart';
import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_palette.dart';
import '../../design_system/tokens/app_text.dart';
import '../../design_system/tokens/app_tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_context.dart';
import '../../ui/language_names.dart';
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
    // Messenger ve çeviriler dialog'dan **önce** alınır: `await`
    // sonrasında `context` artık güvenle kullanılamaz.
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppConfirmationDialog(
        title: l10n.settingsEraseData,
        message: l10n.settingsEraseConfirm,
        onConfirm: () => Navigator.of(dialogContext).pop(true),
      ),
    );
    if (confirmed != true) return;

    try {
      await eraseAllLocalData(ref);
      messenger.showSnackBar(SnackBar(content: Text(l10n.settingsEraseDone)));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsEraseFailed('$error'))),
      );
    }
  }

  /// Adet okunamıyorsa satır sayısız gösterilir — yanlış bir `0` yazmaktansa
  /// hiçbir şey yazmamak dürüsttür.
  String? _countLabel(
    L10n l10n,
    AsyncValue<LocalDataCounts> counts,
    int Function(LocalDataCounts) select,
  ) => switch (counts) {
    AsyncData(:final value) => l10n.settingsRecordCount(select(value)),
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
    color: context.palette.background,
    child: Column(
      children: [
        const AppTopBar(title: 'tecOS'),
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
                Text(context.l10n.settingsTitle, style: context.text.headline),
                const SizedBox(height: AppSpacing.xl),
                _SettingsSection(
                  title: context.l10n.settingsSectionPersonalization,
                  children: [
                    _SettingsRow(
                      icon: Icons.interests_outlined,
                      title: context.l10n.settingsInterests,
                      onTap: () => context.push('/interests'),
                    ),
                    const _LanguageRow(),
                    const _ThemeRow(),
                    _SettingsRow.upcoming(
                      icon: Icons.tune_rounded,
                      title: context.l10n.settingsContentPreferences,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                _SettingsSection(
                  title: context.l10n.settingsSectionLocalData,
                  children: [
                    _SettingsRow(
                      icon: Icons.bookmark_outline,
                      title: context.l10n.settingsSavedItems,
                      value: _countLabel(
                        context.l10n,
                        counts,
                        (c) => c.savedItems,
                      ),
                      onTap: () => context.go('/saved'),
                    ),
                    _SettingsRow.upcoming(
                      icon: Icons.forum_outlined,
                      title: context.l10n.settingsAssistantChats,
                      value: _countLabel(
                        context.l10n,
                        counts,
                        (c) => c.assistantConversations,
                      ),
                    ),
                    _SettingsRow(
                      icon: Icons.history_rounded,
                      title: context.l10n.settingsReadHistory,
                      value: _countLabel(
                        context.l10n,
                        counts,
                        (c) => c.readHistory,
                      ),
                      onTap: () => context.push(readHistoryRoute),
                    ),
                    _SettingsRow.upcoming(
                      icon: Icons.download_outlined,
                      title: context.l10n.settingsExportData,
                    ),
                    _SettingsRow(
                      icon: Icons.delete_outline,
                      title: context.l10n.settingsEraseData,
                      color: context.palette.critical,
                      onTap: () => _confirmLocalDataDeletion(context, ref),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                _SettingsSection(
                  title: context.l10n.settingsSectionPrivacy,
                  children: [
                    _PrivacyItem(
                      icon: Icons.smartphone_rounded,
                      title: context.l10n.settingsPrivacyLocalTitle,
                      description: context.l10n.settingsPrivacyLocalBody,
                    ),
                    _PrivacyItem(
                      icon: Icons.person_off_outlined,
                      title: context.l10n.settingsPrivacyNoAccountTitle,
                      description: context.l10n.settingsPrivacyNoAccountBody,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                _SettingsSection(
                  title: context.l10n.settingsSectionAbout,
                  children: [
                    _SettingsRow(
                      icon: Icons.info_outline_rounded,
                      title: context.l10n.settingsAbout,
                      onTap: () => context.push(aboutRoute),
                    ),
                    _SettingsRow(
                      icon: Icons.policy_outlined,
                      title: context.l10n.settingsSourcePolicy,
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
                        applicationName: 'tecOS',
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
                  context.l10n.settingsAppVersion(appVersionLabel),
                  style: context.text.technical,
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
          style: context.text.label.copyWith(color: context.palette.primary),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Material(
        color: context.palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardBorder,
          side: BorderSide(color: context.palette.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var index = 0; index < children.length; index++) ...[
              children[index],
              if (index < children.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: context.palette.outline,
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
    this.color,
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
       color = null;

  final IconData icon;
  final String title;
  final String? value;

  /// Satırın rengi. `null` ise temadan çözülür — dokunulabilir satır birincil
  /// metin rengini, "yakında" satırı ikincil rengi alır.
  ///
  /// Varsayılan bir renk **sabit olarak yazılamıyor**: yapıcı parametresinin
  /// varsayılanı derleme zamanı sabiti olmak zorunda, tema rengi ise
  /// çalışma zamanında `context`'ten geliyor. Çözüm alanı boş bırakıp
  /// [build] içinde çözmek.
  final Color? color;

  final VoidCallback? onTap;

  bool get _enabled => onTap != null;

  @override
  Widget build(BuildContext context) {
    final resolved =
        color ??
        (_enabled
            ? context.palette.textPrimary
            : context.palette.textSecondary);

    return Semantics(
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
                Icon(icon, size: 22, color: resolved),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    title,
                    style: context.text.body.copyWith(
                      color: resolved,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (value != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(value!, style: context.text.bodyMuted),
                ],
                const SizedBox(width: AppSpacing.sm),
                if (_enabled)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: context.palette.textSecondary,
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
}

/// İçerik dili.
///
/// Satır **yayının sunduğuna göre şekil değiştirir** ve bu, ekranın tek
/// koşullu parçası:
///
/// * Yayın tek dil sunuyorsa (bugünkü durum) satır dokunulabilir değil.
///   Açılınca tek seçenek gösteren bir liste, kullanıcıya seçim yaptığını
///   sandıran boş bir jest olurdu.
/// * Birden fazla dil varsa satır açılır ve seçim yapılır.
///
/// Koşul **derleme zamanında değil, veriden** kuruluyor: yayına İngilizce
/// eklendiği gün kurulu uygulamada seçici kendiliğinden belirir, mağaza
/// güncellemesi gerekmez. `FEED_URL` derleme sabiti olduğu için bu tersine
/// çevrilebilir bir karar değildi — yayından önce kapatılması gereken bir
/// kapıydı.
class _LanguageRow extends ConsumerWidget {
  const _LanguageRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = ref.watch(feedLanguageOptionsProvider).value;
    final selected = ref.watch(feedLanguageProvider);

    // Yükleniyorken de bir şey yazmak zorundayız: satırın yüksekliği
    // değişirse ayarlar listesi açılışta zıplar. Elde veri yokken feed'in
    // varsayılan dili doğru tahmin, çünkü paketlenmiş dosya odur.
    final current = selected ?? options?.current ?? feedDefaultLanguage;

    if (options == null || !options.hasChoice) {
      return _SettingsRow.upcoming(
        icon: Icons.language_rounded,
        title: 'Dil',
        value: languageName(current),
      );
    }

    return _SettingsRow(
      icon: Icons.language_rounded,
      title: 'Dil',
      value: selected == null
          // Cihaza uyulduğunda gösterilen şey seçim değil, **sonuç**:
          // kullanıcı hangi dili okuduğunu görmeli, hangi kuralın onu
          // seçtiğini değil.
          ? '${languageName(options.current)} · otomatik'
          : languageName(selected),
      onTap: () => _choose(context, ref, options),
    );
  }

  Future<void> _choose(
    BuildContext context,
    WidgetRef ref,
    FeedLanguageOptions options,
  ) async {
    final chosen = await showModalBottomSheet<_LanguageChoice>(
      context: context,
      backgroundColor: context.palette.surface,
      builder: (context) => _LanguageSheet(options: options),
    );
    if (chosen == null) return;
    await ref.read(feedLanguageProvider.notifier).select(chosen.code);
  }
}

/// Seçim sonucu. `null` bir kod "cihaza uy" demek, "iptal" değil — ikisini
/// ayırt edebilmek için sarmalayıcı bir tip gerekiyor. `showModalBottomSheet`
/// iptalde zaten `null` döndürüyor ve o `null` ile bu `null` aynı değer
/// olsaydı, "otomatik"i seçen kullanıcının seçimi sessizce yutulurdu.
final class _LanguageChoice {
  const _LanguageChoice(this.code);
  final String? code;
}

class _LanguageSheet extends ConsumerWidget {
  const _LanguageSheet({required this.options});

  final FeedLanguageOptions options;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(feedLanguageProvider);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              context.l10n.languageSheetTitle,
              style: context.text.title,
            ),
          ),
          _LanguageOption(
            label: context.l10n.languageDeviceDefault,
            // Otomatik seçimin **bugün ne getirdiğini** yazıyor. "Otomatik"
            // tek başına, kullanıcının hangi dili okuyacağını söylemez.
            detail: languageName(options.current),
            selected: selected == null,
            onTap: () => Navigator.of(context).pop(const _LanguageChoice(null)),
          ),
          for (final entry in options.available)
            _LanguageOption(
              label: languageName(entry.code),
              selected: selected == entry.code,
              onTap: () =>
                  Navigator.of(context).pop(_LanguageChoice(entry.code)),
            ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
    this.detail,
  });

  final String label;
  final String? detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        // `QUALITY_GATES.md`: minimum 44×44 dokunma alanı.
        constraints: const BoxConstraints(minHeight: AppTouchTarget.minimum),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: context.text.body.copyWith(
                    color: context.palette.textPrimary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (detail != null) ...[
                Text(detail!, style: context.text.bodyMuted),
                const SizedBox(width: AppSpacing.sm),
              ],
              // Seçili olmayan satırda da yer tutuluyor: ikon belirip
              // kaybolsaydı metinler seçime göre yatay olarak kayardı.
              SizedBox(
                width: 22,
                child: selected
                    ? Icon(
                        Icons.check_rounded,
                        size: 22,
                        color: context.palette.textPrimary,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Tema seçimi.
///
/// Diğer ayar satırlarından farklı olarak **kendi ekranını açmıyor**, seçimi
/// yerinde yaptırıyor. Üç seçenek için bir ekran açmak, iki dokunuşu dört
/// dokunuş yapardı; ve seçimin sonucu — uygulamanın rengi — zaten aynı
/// ekranda, anında görülüyor.
///
/// "Sistem" varsayılan ve listede **ilk**: uygulamanın kendi zevkini
/// dayatmaması gereken yer burası.
class _ThemeRow extends ConsumerWidget {
  const _ThemeRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(themeModeProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette_outlined,
                size: 22,
                color: context.palette.textPrimary,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Tema',
                style: context.text.body.copyWith(
                  color: context.palette.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                icon: const Icon(Icons.brightness_auto_outlined),
                label: Text(context.l10n.themeSystem),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: const Icon(Icons.light_mode_outlined),
                label: Text(context.l10n.themeLight),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: const Icon(Icons.dark_mode_outlined),
                label: Text(context.l10n.themeDark),
              ),
            ],
            selected: {selected},
            showSelectedIcon: false,
            onSelectionChanged: (selection) =>
                ref.read(themeModeProvider.notifier).select(selection.first),
            style: ButtonStyle(
              // `QUALITY_GATES.md`: minimum 44×44 dokunma alanı. Material'in
              // varsayılanı 40 dp ve `test/app/touch_target_test.dart` her
              // rotayı gezdiği için bu satır kapının kendisi tarafından
              // ölçülüyor.
              minimumSize: const WidgetStatePropertyAll(
                Size(0, AppTouchTarget.minimum),
              ),
              textStyle: WidgetStatePropertyAll(context.text.label),
            ),
          ),
        ],
      ),
    );
  }
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
      border: Border.all(color: context.palette.outline),
    ),
    child: Text(
      context.l10n.comingSoon,
      style: context.text.label.copyWith(color: context.palette.textSecondary),
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
          child: Icon(icon, size: 22, color: context.palette.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.text.body.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(description, style: context.text.bodyMuted),
            ],
          ),
        ),
      ],
    ),
  );
}
