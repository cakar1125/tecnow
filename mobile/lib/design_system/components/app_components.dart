import 'package:flutter/material.dart';

import '../../fixtures/fixtures.dart';
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
  const AppTopBar({this.title = 'TeknoAkış', this.actions, super.key});

  final String title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      title: Semantics(
        header: true,
        child: Text(
          title,
          style: AppTypography.title.copyWith(color: AppColors.primary),
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
      backgroundColor: AppColors.background,
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
      title: Text(title, style: AppTypography.title),
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
      style: FilledButton.styleFrom(backgroundColor: AppColors.critical),
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
  const AppSearchField({this.onChanged, super.key});
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    onChanged: onChanged,
    decoration: const InputDecoration(
      hintText: 'Repository, model veya konu ara',
      prefixIcon: Icon(Icons.search_rounded),
      suffixIcon: Icon(Icons.tune_rounded),
    ),
  );
}

class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
  });
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) => FilterChip(
    label: Text(label),
    selected: selected,
    onSelected: onSelected,
    showCheckmark: true,
  );
}

class CategoryBadge extends StatelessWidget {
  const CategoryBadge({required this.label, super.key});
  final String label;
  @override
  Widget build(BuildContext context) =>
      _Badge(label: label, color: AppColors.primary);
}

class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key});
  @override
  Widget build(BuildContext context) => const _Badge(
    label: 'DOĞRULANMIŞ ÖRNEK',
    color: AppColors.success,
    icon: Icons.verified_outlined,
  );
}

class TrendingBadge extends StatelessWidget {
  const TrendingBadge({super.key});
  @override
  Widget build(BuildContext context) => const _Badge(
    label: 'YÜKSELEN',
    color: AppColors.warning,
    icon: Icons.trending_up_rounded,
  );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, this.icon});
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
          child: Text(label, style: AppTypography.label.copyWith(color: color)),
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
  Widget build(BuildContext context) => Semantics(
    label: '$label kaynağı',
    child: CircleAvatar(
      radius: 22,
      backgroundColor: (ai ? AppColors.aiAccent : AppColors.primary).withValues(
        alpha: 0.16,
      ),
      foregroundColor: ai ? AppColors.aiAccent : AppColors.primary,
      child: Text(label.characters.first.toUpperCase()),
    ),
  );
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
        Text(item.title, style: AppTypography.title),
        const SizedBox(height: AppSpacing.sm),
        Text(item.summary, style: AppTypography.bodyMuted),
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
      accent: AppColors.primary,
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
          Text(item.name, style: AppTypography.title),
          const SizedBox(height: AppSpacing.sm),
          Text(item.description, style: AppTypography.bodyMuted),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              Text('★ ${item.stars}', style: AppTypography.technical),
              Text('⑂ ${item.forks}', style: AppTypography.technical),
              Text('! ${item.issues}', style: AppTypography.technical),
              Text(
                '● ${item.language}',
                style: AppTypography.technical.copyWith(
                  color: AppColors.primary,
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
      accent: AppColors.aiAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SourceAvatar(label: 'S', ai: true),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(item.name, style: AppTypography.title)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const VerifiedBadge(),
          const SizedBox(height: AppSpacing.md),
          Text(
            item.maker,
            style: AppTypography.label.copyWith(color: AppColors.aiAccent),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(item.summary, style: AppTypography.bodyMuted),
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
    decoration: const BoxDecoration(
      color: AppColors.background,
      borderRadius: AppRadius.smallBorder,
    ),
    child: Text('$label\n$value', style: AppTypography.technical),
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
          const Icon(Icons.inbox_outlined, size: 48, color: AppColors.primary),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: AppTypography.title, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: AppTypography.bodyMuted,
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
          const Icon(Icons.error_outline, size: 48, color: AppColors.critical),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: AppTypography.title, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: AppTypography.bodyMuted,
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
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(AppDurations.slow, () {
      if (mounted) setState(() => bright = true);
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: AppDurations.slow,
    height: 120,
    decoration: BoxDecoration(
      color: bright ? AppColors.surfaceHigh : AppColors.surface,
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
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: AppRadius.cardBorder,
      side: BorderSide(
        color: accent?.withValues(alpha: 0.45) ?? AppColors.outline,
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

  final SavedItemFixture item;
  final VoidCallback onRemove;
  final VoidCallback onOpenDetails;

  (String, Color, IconData) get _category => switch (item.kind) {
    SavedItemKind.repository => (
      'REPOSITORY',
      AppColors.primary,
      Icons.code_rounded,
    ),
    SavedItemKind.aiModel => (
      'AI',
      AppColors.aiAccent,
      Icons.psychology_outlined,
    ),
    SavedItemKind.tool => ('ARAÇLAR', AppColors.warning, Icons.build_outlined),
    SavedItemKind.skill => ('SKILLS', AppColors.success, Icons.school_outlined),
    SavedItemKind.assistantProject => (
      'ASİSTAN PROJESİ',
      AppColors.aiAccent,
      Icons.auto_awesome_outlined,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = _category;

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
                  child: _Badge(label: label, color: color, icon: icon),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('Örnek kayıt', style: AppTypography.technical),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(item.title, style: AppTypography.title),
          const SizedBox(height: AppSpacing.sm),
          Text('Kaynak: ${item.sourceLabel}', style: AppTypography.technical),
          const SizedBox(height: AppSpacing.sm),
          Text(item.summary, style: AppTypography.bodyMuted),
          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 1, color: AppColors.outline),
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

class FeedItemCard extends StatefulWidget {
  const FeedItemCard({required this.item, this.onTap, super.key});

  final FeedItemFixture item;
  final VoidCallback? onTap;

  @override
  State<FeedItemCard> createState() => _FeedItemCardState();
}

class _FeedItemCardState extends State<FeedItemCard> {
  bool _isSaved = false;

  (String, Color, IconData) get _category => switch (widget.item.kind) {
    FeedSourceKind.github => ('GİTHUB', AppColors.primary, Icons.code_rounded),
    FeedSourceKind.aiModel => (
      'AI MODEL',
      AppColors.aiAccent,
      Icons.psychology_outlined,
    ),
    FeedSourceKind.tool => ('ARAÇ', AppColors.warning, Icons.build_outlined),
    FeedSourceKind.announcement => (
      'DUYURU',
      AppColors.success,
      Icons.campaign_outlined,
    ),
  };

  void _toggleSaved() {
    setState(() => _isSaved = !_isSaved);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kaydetme yalnız yerel fixture etkileşimidir.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = _category;

    return Semantics(
      button: widget.onTap != null,
      label: '${widget.item.title} akış kartı',
      child: _AppCard(
        onTap: widget.onTap,
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
                      _Badge(label: label, color: color, icon: icon),
                      Text(
                        widget.item.sourceLabel,
                        style: AppTypography.technical,
                      ),
                      const _Badge(
                        label: 'ÖRNEK',
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Semantics(
                  button: true,
                  selected: _isSaved,
                  label: _isSaved ? 'Kaydı kaldır' : 'Kaydet',
                  child: IconButton(
                    key: Key('feed-bookmark-${widget.item.id}'),
                    tooltip: _isSaved ? 'Kaydı kaldır' : 'Kaydet',
                    onPressed: _toggleSaved,
                    icon: Icon(
                      _isSaved ? Icons.bookmark : Icons.bookmark_outline,
                      color: _isSaved
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(widget.item.title, style: AppTypography.headline),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.item.summary,
              style: AppTypography.bodyMuted,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: AppRadius.smallBorder,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NE İŞE YARAR?',
                    style: AppTypography.label.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(widget.item.whatItDoes, style: AppTypography.bodyMuted),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final tag in widget.item.tags)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: AppRadius.smallBorder,
                    ),
                    child: Text(tag, style: AppTypography.technical),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
