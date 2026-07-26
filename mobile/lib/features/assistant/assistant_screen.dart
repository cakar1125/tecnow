import 'package:flutter/material.dart';

import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_tokens.dart';

class AssistantScreen extends StatelessWidget {
  const AssistantScreen({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const AppTopBar(title: 'Proje Asistanı'),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('Proje Asistanı', style: AppTypography.headline),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Proje fikrini anlatınca uygun AI, skill, MCP ve teknoloji '
              'yolunu öneren asistan.',
              style: AppTypography.bodyMuted,
            ),
            const SizedBox(height: AppSpacing.xl),
            const EmptyStateView(
              title: 'Bu ekran Faz 4’te uygulanacak.',
              message: 'Şu an canlı AI bağlantısı yoktur.',
            ),
          ],
        ),
      ),
    ],
  );
}
