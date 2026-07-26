import 'package:flutter/material.dart';

import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_tokens.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool compactCards = false;
  bool reducedMotion = false;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.background,
    child: Column(
      children: [
        const AppTopBar(title: 'Ayarlar'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                'Görünüm',
                style: AppTypography.label.copyWith(color: AppColors.primary),
              ),
              _SettingsSwitch(
                value: compactCards,
                onChanged: (value) => setState(() => compactCards = value),
                title: 'Kompakt kartlar',
                subtitle: 'Yalnız yerel görünümü etkiler.',
              ),
              _SettingsSwitch(
                value: reducedMotion,
                onChanged: (value) => setState(() => reducedMotion = value),
                title: 'Hareketi azalt',
                subtitle: 'Dekoratif animasyonları azaltır.',
              ),
              const Divider(height: AppSpacing.xxl),
              Text(
                'Tercihler',
                style: AppTypography.label.copyWith(color: AppColors.primary),
              ),
              const ListTile(
                leading: Icon(Icons.language_rounded),
                title: Text('Dil'),
                subtitle: Text('Türkçe'),
                trailing: Icon(Icons.chevron_right),
              ),
              const ListTile(
                leading: Icon(Icons.interests_outlined),
                title: Text('İlgi alanları'),
                subtitle: Text('Yerel seçimler'),
                trailing: Icon(Icons.chevron_right),
              ),
              const ListTile(
                leading: Icon(Icons.notifications_outlined),
                title: Text('Bildirim tercihleri'),
                subtitle: Text('Push bağlantısı yok'),
                trailing: Icon(Icons.chevron_right),
              ),
              const Divider(height: AppSpacing.xxl),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Demo durumu'),
                subtitle: Text('FIXTURE_ONLY · NOT_LIVE_DATA'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SettingsSwitch extends StatelessWidget {
  const _SettingsSwitch({
    required this.value,
    required this.onChanged,
    required this.title,
    required this.subtitle,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Semantics(
    toggled: value,
    label: title,
    child: InkWell(
      onTap: () => onChanged(!value),
      borderRadius: AppRadius.cardBorder,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.title),
                  const SizedBox(height: AppSpacing.xs),
                  Text(subtitle, style: AppTypography.bodyMuted),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            ExcludeSemantics(
              child: Switch(value: value, onChanged: onChanged),
            ),
          ],
        ),
      ),
    ),
  );
}
