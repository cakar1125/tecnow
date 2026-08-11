import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/feed/feed_schema.dart' show FeedItemKind;
import '../../fixtures/fixtures.dart';
import '../../ui/content_card_model.dart';
import '../tokens/app_palette.dart';
import '../tokens/app_text.dart';
import '../tokens/app_tokens.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.child,
    this.currentIndex,
    this.onDestinationSelected,
    super.key,
  });

  final Widget child;
  final int? currentIndex;
  final ValueChanged<int>? onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: currentIndex == null
          ? null
          : AppBottomNavigation(
              currentIndex: currentIndex!,
              onDestinationSelected: onDestinationSelected!,
            ),
    );
  }
}

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({this.title = 'tecOS', this.actions, super.key});

  final String title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: context.palette.background,
      surfaceTintColor: Colors.transparent,
      title: Semantics(
        header: true,
        child: Text(
          title,
          style: context.text.title.copyWith(color: context.palette.primary),
        ),
      ),
      centerTitle: true,
      actions: actions,
    );
  }
}

class AppBackTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppBackTopBar({required this.title, super.key});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: context.palette.background,
      surfaceTintColor: Colors.transparent,
      leading: Semantics(
        button: true,
        label: 'Geri',
        child: IconButton(
          tooltip: 'Geri',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      title: Text(title, style: context.text.title),
    );
  }
}

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    required this.currentIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Ana Sayfa',
        ),
        NavigationDestination(
          icon: Icon(Icons.explore_outlined),
          selectedIcon: Icon(Icons.explore),
          label: 'Keşfet',
        ),
        NavigationDestination(
          icon: Icon(Icons.auto_awesome_outlined),
          selectedIcon: Icon(Icons.auto_awesome),
          label: 'Asistan',
        ),
        NavigationDestination(
          icon: Icon(Icons.bookmark_outline),
          selectedIcon: Icon(Icons.bookmark),
          label: 'Kaydedilenler',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Ayarlar',
        ),
      ],
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.arrow_forward_rounded),
        label: Text(label),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.onPressed,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: OutlinedButton(onPressed: onPressed, child: Text(label)),
  );
}

class DestructiveButton extends StatelessWidget {
  const DestructiveButton({
    required this.label,
    required this.onPressed,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: context.palette.critical,
        foregroundColor: context.palette.onPrimary,
      ),
      onPressed: onPressed,
      child: Text(label),
    ),
  );
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    this.hint,
    this.maxLines = 1,
    super.key,
  });
  final String label;
  final String? hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) => TextField(
    maxLines: maxLines,
    decoration: InputDecoration(labelText: label, hintText: hint),
  );
}

class AppSearchField extends StatelessWidget {
  const AppSearchField({
    this.controller,
    this.hintText = 'Repository, model veya konu ara',
    this.onChanged,
    super.key,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    decoration: InputDecoration(
      hintText: hintText,
      prefixIcon: const Icon(Icons.search_rounded),
      // Dekoratif bir filtre ikonu koymuyoruz: düğme değildi, hiçbir şey
      // yapmıyordu ve gerçek filtre çipleriyle çelişiyordu (sahte affordance).
    ),
  );
}

class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.stableWidth = false,
    super.key,
  });
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  /// Çipin genişliği seçili durumdan **bağımsız** olsun mu?
  ///
  /// Material'in onay işareti yalnız seçiliyken çiziliyor ve çipi
  /// genişletiyor. Tek başına zararsız; birden çok satıra sarılan bir `Wrap`
  /// içinde ise düzenin yeniden akmasına ve **komşu çiplerin parmağın altından
  /// kaymasına** yol açıyor. Cihazda görüldü (2026-07-28): ilgi alanları
  /// ekranında art arda üç çipe dokunulduğunda üçüncü dokunuş, o konumdaki
  /// çip yer değiştirdiği için boşluğa düştü.
  ///
  /// Açıkken onay işaretinin yeri her zaman ayrılır (seçili değilken saydam).
  /// Bedeli ölçüldü (gerçek yazı tipiyle, 360 dp): çip başına **+20 px**,
  /// sekiz ilgi alanı için `Wrap` 3 satırdan 4 satıra çıkıyor.
  ///
  /// **Varsayılan kapalı**, çünkü bedel her yerde aynı ama kazanç değil. Tek
  /// satırlık yatay süzgeç şeritlerinde (Kaydedilenler, Keşfet) kullanıcı tek
  /// seçim yapıp sonuca bakıyor: kayma riski düşük, yatay yer ise en kıt
  /// kaynak. Çok satırlı seçim ekranlarında tam tersi.
  final bool stableWidth;

  @override
  Widget build(BuildContext context) => FilterChip(
    label: Text(label),
    selected: selected,
    onSelected: onSelected,
    showCheckmark: !stableWidth,
    avatar: stableWidth
        ? Icon(
            Icons.check_rounded,
            size: 18,
            color: selected ? context.palette.textPrimary : Colors.transparent,
          )
        : null,
  );
}

class CategoryBadge extends StatelessWidget {
  const CategoryBadge({required this.label, super.key});
  final String label;
  @override
  Widget build(BuildContext context) =>
      AppBadge(label: label, color: context.palette.primary);
}

class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key});
  @override
  Widget build(BuildContext context) => AppBadge(
    label: 'DOĞRULANMIŞ ÖRNEK',
    color: context.palette.success,
    icon: Icons.verified_outlined,
  );
}

class TrendingBadge extends StatelessWidget {
  const TrendingBadge({super.key});
  @override
  Widget build(BuildContext context) => AppBadge(
    label: 'YÜKSELEN',
    color: context.palette.warning,
    icon: Icons.trending_up_rounded,
  );
}

/// Etiket rozeti. Detay ekranları da kullandığı için görünür.
class AppBadge extends StatelessWidget {
  const AppBadge({
    required this.label,
    required this.color,
    this.icon,
    super.key,
  });
  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: AppRadius.smallBorder,
      border: Border.all(color: color.withValues(alpha: 0.5)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
        ],
        Flexible(
          child: Text(label, style: context.text.label.copyWith(color: color)),
        ),
      ],
    ),
  );
}

class SourceAvatar extends StatelessWidget {
  const SourceAvatar({required this.label, this.ai = false, super.key});
  final String label;
  final bool ai;

  @override
  Widget build(BuildContext context) {
    final accent = ai ? context.palette.aiAccent : context.palette.primary;
    return Semantics(
      label: '$label kaynağı',
      child: CircleAvatar(
        radius: 22,
        backgroundColor: accent.withValues(alpha: 0.16),
        foregroundColor: accent,
        child: Text(label.characters.first.toUpperCase()),
      ),
    );
  }
}

class SocialActionBar extends StatelessWidget {
  const SocialActionBar({super.key});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      _SemanticIcon(
        icon: Icons.favorite_border,
        label: 'Beğen',
        value: '24',
        onTap: () => _showFixtureFeedback(context, 'Beğen'),
      ),
      _SemanticIcon(
        icon: Icons.chat_bubble_outline,
        label: 'Yorumlar',
        value: '8',
        onTap: () => _showFixtureFeedback(context, 'Yorumlar'),
      ),
      _SemanticIcon(
        icon: Icons.bookmark_border,
        label: 'Kaydet',
        onTap: () => _showFixtureFeedback(context, 'Kaydet'),
      ),
      _SemanticIcon(
        icon: Icons.share_outlined,
        label: 'Paylaş',
        onTap: () => _showFixtureFeedback(context, 'Paylaş'),
      ),
    ],
  );

  void _showFixtureFeedback(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label yalnız yerel fixture etkileşimidir.')),
    );
  }
}

class _SemanticIcon extends StatelessWidget {
  const _SemanticIcon({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? value;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: InkResponse(
      onTap: onTap,
      radius: 24,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(icon, size: 20), if (value != null) Text(' $value')],
        ),
      ),
    ),
  );
}

class TechnologyCard extends StatelessWidget {
  const TechnologyCard({required this.item, super.key});
  final TechnologyFixture item;

  @override
  Widget build(BuildContext context) => _AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CategoryBadge(label: item.category),
        const SizedBox(height: AppSpacing.md),
        Text(item.title, style: context.text.title),
        const SizedBox(height: AppSpacing.sm),
        Text(item.summary, style: context.text.bodyMuted),
        const SizedBox(height: AppSpacing.lg),
        const SocialActionBar(),
      ],
    ),
  );
}

class RepositoryCard extends StatelessWidget {
  const RepositoryCard({required this.item, this.onTap, super.key});
  final RepositoryFixture item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    label: '${item.name} repository kartı',
    child: _AppCard(
      onTap: onTap,
      accent: context.palette.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: AppSpacing.sm,
            children: [
              CategoryBadge(label: 'REPOSITORY'),
              TrendingBadge(),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(item.name, style: context.text.title),
          const SizedBox(height: AppSpacing.sm),
          Text(item.description, style: context.text.bodyMuted),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              Text('★ ${item.stars}', style: context.text.technical),
              Text('⑂ ${item.forks}', style: context.text.technical),
              Text('! ${item.issues}', style: context.text.technical),
              Text(
                '● ${item.language}',
                style: context.text.technical.copyWith(
                  color: context.palette.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class AIModelCard extends StatelessWidget {
  const AIModelCard({required this.item, this.onTap, super.key});
  final AiModelFixture item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    label: '${item.name} yapay zekâ modeli kartı',
    child: _AppCard(
      onTap: onTap,
      accent: context.palette.aiAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SourceAvatar(label: 'S', ai: true),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(item.name, style: context.text.title)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const VerifiedBadge(),
          const SizedBox(height: AppSpacing.md),
          Text(
            item.maker,
            style: context.text.label.copyWith(color: context.palette.aiAccent),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(item.summary, style: context.text.bodyMuted),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _Metric(label: 'Bağlam', value: item.context),
              _Metric(label: 'Mimari', value: item.architecture),
            ],
          ),
        ],
      ),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: context.palette.background,
      borderRadius: AppRadius.smallBorder,
    ),
    child: Text('$label\n$value', style: context.text.technical),
  );
}

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({required this.title, required this.message, super.key});
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: context.palette.primary),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: context.text.title, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: context.text.bodyMuted,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    required this.title,
    required this.message,
    this.onRetry,
    super.key,
  });
  final String title;
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: context.palette.critical),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: context.text.title, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: context.text.bodyMuted,
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.lg),
            SecondaryButton(label: 'Yeniden dene', onPressed: onRetry),
          ],
        ],
      ),
    ),
  );
}

class LoadingSkeleton extends StatefulWidget {
  const LoadingSkeleton({super.key});
  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton> {
  bool bright = false;

  /// `Future.delayed` iptal edilemez: widget zamanlayıcı ateşlenmeden dispose
  /// edilirse timer askıda kalır ve widget testleri "Pending timers" ile
  /// başarısız olur. İptal edilebilir bir Timer tutuyoruz.
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(AppDurations.slow, () {
      if (mounted) setState(() => bright = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: AppDurations.slow,
    height: 120,
    decoration: BoxDecoration(
      color: bright ? context.palette.surfaceHigh : context.palette.surface,
      borderRadius: AppRadius.cardBorder,
    ),
  );
}

class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(padding: const EdgeInsets.all(AppSpacing.xl), child: child),
  );
}

class AppConfirmationDialog extends StatelessWidget {
  const AppConfirmationDialog({
    required this.title,
    required this.message,
    required this.onConfirm,
    super.key,
  });
  final String title;
  final String message;
  final VoidCallback onConfirm;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(title),
    content: Text(message),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Vazgeç'),
      ),
      DestructiveButton(label: 'Onayla', onPressed: onConfirm),
    ],
  );
}

class _AppCard extends StatelessWidget {
  const _AppCard({required this.child, this.onTap, this.accent});
  final Widget child;
  final VoidCallback? onTap;
  final Color? accent;
  @override
  Widget build(BuildContext context) => Material(
    color: context.palette.surface,
    shape: RoundedRectangleBorder(
      borderRadius: AppRadius.cardBorder,
      side: BorderSide(
        color: accent?.withValues(alpha: 0.45) ?? context.palette.outline,
      ),
    ),
    child: InkWell(
      borderRadius: AppRadius.cardBorder,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: child,
      ),
    ),
  );
}

class SavedItemCard extends StatelessWidget {
  const SavedItemCard({
    required this.item,
    required this.onRemove,
    required this.onOpenDetails,
    super.key,
  });

  final ContentCardModel item;
  final VoidCallback onRemove;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = categoryOf(context.palette, item.kind);

    return _AppCard(
      accent: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AppBadge(label: label, color: color, icon: icon),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Yalnız fixture kaydında. Gerçek içerikte bu etiket yalan olur.
              if (item.isSample)
                Text('Örnek kayıt', style: context.text.technical),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(item.title, style: context.text.title),
          const SizedBox(height: AppSpacing.sm),
          Text('Kaynak: ${item.sourceLabel}', style: context.text.technical),
          const SizedBox(height: AppSpacing.sm),
          Text(item.summary, style: context.text.bodyMuted),
          const SizedBox(height: AppSpacing.lg),
          Divider(height: 1, color: context.palette.outline),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Kaydı Kaldır',
                  onPressed: onRemove,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: PrimaryButton(
                  label: 'Detaya Git',
                  onPressed: onOpenDetails,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// İçerik türünün rozet etiketi, rengi ve simgesi.
///
/// Mor **yalnız AI/Asistan bağlamında** kullanılır (`CLAUDE.md` değişmez
/// kuralı); model kartı dışında hiçbir tür bu rengi almaz.
///
/// Palet parametre olarak alınıyor çünkü bu bir widget değil, düz bir
/// fonksiyon — `context`'i yok. Çağıran `context.palette` verir; renkler
/// böylece temayla birlikte değişir.
(String, Color, IconData) categoryOf(AppPalette palette, FeedItemKind kind) =>
    switch (kind) {
      FeedItemKind.repository => ('DEPO', palette.primary, Icons.code_rounded),
      FeedItemKind.aiModel => (
        'AI MODEL',
        palette.aiAccent,
        Icons.psychology_outlined,
      ),
      FeedItemKind.tool => ('ARAÇ', palette.warning, Icons.build_outlined),
      FeedItemKind.skill => ('SKILL', palette.success, Icons.school_outlined),
      FeedItemKind.mcp => ('MCP', palette.primary, Icons.hub_outlined),
      FeedItemKind.announcement => (
        'DUYURU',
        palette.success,
        Icons.campaign_outlined,
      ),
    };

/// Özetin dilini gösteren etiket. Anahtarsız üretilen feed'de özetler
/// kaynağın kendi dilindedir; kullanıcı bunu **kartın üzerinde** görmeli,
/// tıkladıktan sonra değil.
String? languageBadge(ContentCardModel item) =>
    item.language.toLowerCase().startsWith('tr')
    ? null
    : item.language.toUpperCase();

/// Akış kartı.
///
/// Yer imi durumunu **kendi içinde tutmaz**. Tuttuğu sürece düğme yalnız
/// kendi rengini çeviriyordu: hiçbir şey kaydedilmiyor, kart yeniden
/// çizildiğinde durum sıfırlanıyordu. Durum artık kayıt listesinden gelir.
///
/// [onToggleSave] verilmezse düğme **hiç çizilmez**. İşlevsiz bir kontrol,
/// sahte bir işlev vaadidir (`CLAUDE.md` değişmez kuralı).
class FeedItemCard extends StatelessWidget {
  const FeedItemCard({
    required this.item,
    this.onTap,
    this.isSaved = false,
    this.onToggleSave,
    super.key,
  });

  final ContentCardModel item;
  final VoidCallback? onTap;
  final bool isSaved;
  final VoidCallback? onToggleSave;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final (label, color, icon) = categoryOf(palette, item.kind);

    return Semantics(
      button: onTap != null,
      label: '${item.title} akış kartı',
      child: _AppCard(
        onTap: onTap,
        accent: color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      AppBadge(label: label, color: color, icon: icon),
                      Text(item.sourceLabel, style: context.text.technical),
                      // Örnek işareti yalnız fixture kartlarında. Gerçek
                      // içerikte "ÖRNEK" yazmak yalan olurdu.
                      if (item.isSample)
                        AppBadge(label: 'ÖRNEK', color: palette.textSecondary),
                      // Politika: tecOS özeti kaynağın kendi metninden
                      // görsel olarak ayrılır.
                      //
                      // Marka **kendi yazımını korur** (`tecOS`), açıklama
                      // büyük harf. Rozetin tümünü büyük harfe çevirmek adı
                      // `TECOS` yapar ve markanın biçimini yok eder.
                      //
                      // Ad buraya "TecNow"dan taşındı. TÜRKPATENT sicilinde
                      // TECNO, Transsion'ın markası olarak sınıf 09'da üç
                      // (2018 104811 · 2023 040621 · 2024 051932) ve sınıf
                      // 42'de bir (2025 027616) tescille kayıtlı; "TecNow"
                      // o markayı **bütünüyle içeriyordu**. "tecOS" yalnız
                      // `TEC` önekini paylaşıyor — sicilde 11.421 marka o
                      // öneki taşıyor, yani tek başına ayırt edici değil.
                      // Bkz. DECISION_LOG D-018.
                      if (item.summaryAuthor == SummaryAuthor.generated)
                        AppBadge(label: 'tecOS ÖZETİ', color: palette.aiAccent),
                      if (languageBadge(item) case final code?)
                        AppBadge(label: code, color: palette.textSecondary),
                    ],
                  ),
                ),
                if (onToggleSave case final toggle?) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Semantics(
                    button: true,
                    selected: isSaved,
                    label: isSaved ? 'Kaydı kaldır' : 'Kaydet',
                    child: IconButton(
                      key: Key('feed-bookmark-${item.id}'),
                      tooltip: isSaved ? 'Kaydı kaldır' : 'Kaydet',
                      onPressed: toggle,
                      constraints: const BoxConstraints(
                        minWidth: AppTouchTarget.minimum,
                        minHeight: AppTouchTarget.minimum,
                      ),
                      icon: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_outline,
                        color: isSaved
                            ? palette.primary
                            : palette.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(item.title, style: context.text.headline),
            const SizedBox(height: AppSpacing.sm),
            Text(
              item.summary,
              style: context.text.bodyMuted,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            // Kaynaklar "ne işe yarar" diye bir alan vermiyor ve onu biz
            // uydurmayız: alan yoksa bölüm hiç çizilmez.
            if (item.whatItDoes case final explanation?) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: palette.surfaceHigh,
                  borderRadius: AppRadius.smallBorder,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NE İŞE YARAR?', style: context.text.labelAccent),
                    const SizedBox(height: AppSpacing.xs),
                    Text(explanation, style: context.text.bodyMuted),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final tag in item.tags)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surfaceHigh,
                      borderRadius: AppRadius.smallBorder,
                    ),
                    child: Text(tag, style: context.text.technical),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Keşfet sonuç kartı.
///
/// Artık fixture değil, gerçek feed kaydı gösterir. "NEDEN EŞLEŞTİ?" kutusu
/// da uydurulmaz: aramanın kaydın **neresinde** eşleştiğinden türetilir
/// (`lib/ui/explore_search.dart`).
class ExploreResultCard extends StatelessWidget {
  const ExploreResultCard({
    required this.item,
    required this.matchReason,
    this.onTap,
    this.isSaved = false,
    this.onToggleSave,
    super.key,
  });

  final ContentCardModel item;

  /// Kaydın bu aramaya neden geldiği. Kullanıcıya gösterilen gerekçe.
  final String matchReason;

  final VoidCallback? onTap;
  final bool isSaved;
  final VoidCallback? onToggleSave;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final (categoryLabel, accent, _) = categoryOf(palette, item.kind);

    return _AppCard(
      onTap: onTap,
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  categoryLabel,
                  style: context.text.technical.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onToggleSave case final toggle?) ...[
                const SizedBox(width: AppSpacing.sm),
                Semantics(
                  button: true,
                  selected: isSaved,
                  label: isSaved ? 'Kaydı kaldır' : 'Kaydet',
                  child: IconButton(
                    key: Key('explore-bookmark-${item.id}'),
                    tooltip: isSaved ? 'Kaydı kaldır' : 'Kaydet',
                    onPressed: toggle,
                    // 44x44 açıkça: Material'in varsayılanı yoğunluk
                    // ayarına göre 40 dp'ye inebiliyor ve
                    // `touch_target_test` bunu yakaladı.
                    constraints: const BoxConstraints(
                      minWidth: AppTouchTarget.minimum,
                      minHeight: AppTouchTarget.minimum,
                    ),
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_outline,
                      color: isSaved ? palette.primary : palette.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(item.title, style: context.text.title),
              // Örnek işareti yalnız fixture kartlarında. Gerçek içerikte
              // "ÖRNEK" yazmak yalan olurdu.
              if (item.isSample)
                AppBadge(label: 'ÖRNEK', color: palette.textSecondary),
              if (item.summaryAuthor == SummaryAuthor.generated)
                AppBadge(label: 'tecOS ÖZETİ', color: palette.aiAccent),
              if (languageBadge(item) case final code?)
                AppBadge(label: code, color: palette.textSecondary),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            item.summary,
            style: context.text.bodyMuted,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: palette.surfaceHigh,
              borderRadius: AppRadius.smallBorder,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 20, color: palette.warning),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NEDEN EŞLEŞTİ?',
                        style: context.text.label.copyWith(
                          color: palette.warning,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(matchReason, style: context.text.bodyMuted),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: palette.outline),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(Icons.public, size: 18, color: palette.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  item.sourceLabel,
                  style: context.text.technical,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// `ExploreStarterCard` buradan kaldırıldı (2026-07-28).
//
// "Başlangıç İçin" bölümü rehber içeriği gösteriyordu; feed'de rehber diye
// bir kayıt türü yok ve okuma süresi gibi alanları uydurmak gerekiyordu.
// Bölüm artık neden boş olduğunu söyleyen bir not gösteriyor. Kart, gerçek
// rehberler yazıldığında geri gelir; o güne kadar testi olmayan ölü koddur.

class ExplorePopularRow extends StatelessWidget {
  const ExplorePopularRow({required this.item, required this.onTap, super.key});

  /// Gerçek feed kaydı. Vurgu ve ikon kaydın **türünden** türetiliyor;
  /// fixture'daki serbest `accentKind` alanı aynı türü iki ekranda iki farklı
  /// renkte gösterebiliyordu ve moru AI dışına taşıma riski taşıyordu.
  final ContentCardModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final (_, accent, icon) = categoryOf(palette, item.kind);

    return Semantics(
      button: true,
      label: item.title,
      child: _AppCard(
        onTap: onTap,
        accent: accent,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: AppRadius.smallBorder,
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(item.title, style: context.text.title),
                      if (item.isSample)
                        AppBadge(label: 'ÖRNEK', color: palette.textSecondary),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.summary,
                    style: context.text.bodyMuted,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right_rounded, color: palette.textSecondary),
          ],
        ),
      ),
    );
  }
}
