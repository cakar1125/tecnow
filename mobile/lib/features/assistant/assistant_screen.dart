import 'package:flutter/material.dart';

import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_palette.dart';
import '../../design_system/tokens/app_text.dart';
import '../../design_system/tokens/app_tokens.dart';

const _starterSuggestions = <({String label, IconData icon})>[
  (label: 'Bir uygulama fikrim var', icon: Icons.lightbulb_outline),
  (label: 'Hangi AI\'ı kullanmalıyım?', icon: Icons.smart_toy_outlined),
  (label: 'Bir skill veya MCP arıyorum', icon: Icons.extension_outlined),
  (label: 'İki aracı karşılaştır', icon: Icons.compare_arrows_rounded),
  (label: 'Mevcut projemi analiz et', icon: Icons.insights_outlined),
  (label: 'Öğrenme yol haritası oluştur', icon: Icons.route_outlined),
];

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _promptController = TextEditingController();
  String? _selectedSuggestion;

  bool get _canStart => _promptController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _promptController.addListener(_handlePromptChanged);
  }

  @override
  void dispose() {
    _promptController
      ..removeListener(_handlePromptChanged)
      ..dispose();
    super.dispose();
  }

  void _handlePromptChanged() {
    if (_selectedSuggestion != null &&
        _promptController.text != _selectedSuggestion) {
      _selectedSuggestion = null;
    }
    setState(() {});
  }

  void _selectSuggestion(String suggestion) {
    _selectedSuggestion = suggestion;
    _promptController.value = TextEditingValue(
      text: suggestion,
      selection: TextSelection.collapsed(offset: suggestion.length),
    );
  }

  void _showPhaseNotice() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Proje Asistanı Faz 4\'te uygulanacak. '
            'Şu an hiçbir AI servisine bağlanılmıyor.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const AppTopBar(title: 'tecOS'),
      Expanded(
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
              const _AssistantHeading(),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Fikrini anlat. Sana en uygun AI\'ları, araçları ve geliştirme '
                'yolunu birlikte belirleyelim.',
                style: context.text.bodyMuted,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'NEREDEN BAŞLAYALIM?',
                style: context.text.label.copyWith(
                  color: context.palette.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final suggestion in _starterSuggestions) ...[
                _AssistantStarterCard(
                  icon: suggestion.icon,
                  label: suggestion.label,
                  selected: _selectedSuggestion == suggestion.label,
                  onTap: () => _selectSuggestion(suggestion.label),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              const SizedBox(height: AppSpacing.md),
              _PromptCard(
                controller: _promptController,
                canStart: _canStart,
                onStart: _showPhaseNotice,
              ),
              const SizedBox(height: AppSpacing.xl),
              const _LocalStorageNote(),
              const SizedBox(height: AppSpacing.md),
              const _PhaseWarning(),
            ],
          ),
        ),
      ),
    ],
  );
}

class _AssistantHeading extends StatelessWidget {
  const _AssistantHeading();

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: context.palette.aiAccent.withValues(alpha: 0.14),
        borderRadius: AppRadius.largeBorder,
        border: Border.all(
          color: context.palette.aiAccent.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, color: context.palette.aiAccent),
          const SizedBox(width: AppSpacing.sm),
          Flexible(child: Text('Proje Asistanı', style: context.text.headline)),
        ],
      ),
    ),
  );
}

class _AssistantStarterCard extends StatelessWidget {
  const _AssistantStarterCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: Material(
      color: selected
          ? context.palette.aiAccent.withValues(alpha: 0.14)
          : context.palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardBorder,
        side: BorderSide(
          color: selected ? context.palette.aiAccent : context.palette.outline,
        ),
      ),
      child: InkWell(
        borderRadius: AppRadius.cardBorder,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52, minWidth: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected
                      ? context.palette.aiAccent
                      : context.palette.textSecondary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(label, style: context.text.body)),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.controller,
    required this.canStart,
    required this.onStart,
  });

  final TextEditingController controller;
  final bool canStart;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: context.palette.surface,
      borderRadius: AppRadius.cardBorder,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          minLines: 3,
          maxLines: 4,
          textInputAction: TextInputAction.newline,
          decoration: const InputDecoration(
            hintText:
                'Yapmak istediğin projeyi veya öğrenmek istediğin konuyu '
                'anlat...',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            height: 48,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: context.palette.aiAccent,
                foregroundColor: context.palette.textPrimary,
                disabledBackgroundColor: context.palette.aiAccent.withValues(
                  alpha: 0.28,
                ),
                disabledForegroundColor: context.palette.textPrimary.withValues(
                  alpha: 0.55,
                ),
              ),
              onPressed: canStart ? onStart : null,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Başlayalım'),
            ),
          ),
        ),
      ],
    ),
  );
}

class _LocalStorageNote extends StatelessWidget {
  const _LocalStorageNote();

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        Icons.lock_outline_rounded,
        size: 20,
        color: context.palette.textSecondary,
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Text(
          'Konuşma geçmişin ve kaydettiğin projeler bu cihazda saklanır.',
          style: context.text.bodyMuted,
        ),
      ),
    ],
  );
}

class _PhaseWarning extends StatelessWidget {
  const _PhaseWarning();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: context.palette.warning.withValues(alpha: 0.12),
      borderRadius: AppRadius.cardBorder,
      border: Border.all(
        color: context.palette.warning.withValues(alpha: 0.55),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 20,
          color: context.palette.warning,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'Asistan henüz uygulanmadı. Bu ekran yalnız giriş tasarımıdır.',
            style: context.text.body.copyWith(color: context.palette.warning),
          ),
        ),
      ],
    ),
  );
}
