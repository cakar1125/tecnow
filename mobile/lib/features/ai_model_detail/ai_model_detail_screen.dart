import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_tokens.dart';
import '../../fixtures/fixtures.dart';
import '../read_history/read_history_recorder.dart';

class AiModelDetailScreen extends ConsumerStatefulWidget {
  const AiModelDetailScreen({required this.id, super.key});

  final String id;

  @override
  ConsumerState<AiModelDetailScreen> createState() =>
      _AiModelDetailScreenState();
}

class _AiModelDetailScreenState extends ConsumerState<AiModelDetailScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(recordRead(ref, itemId: widget.id, kind: 'aiModel'));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const AppBackTopBar(title: 'AI Model Detayı'),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const Align(alignment: Alignment.centerLeft, child: VerifiedBadge()),
          const SizedBox(height: AppSpacing.md),
          Text(
            aiModelFixture.name,
            style: AppTypography.headline.copyWith(color: AppColors.aiAccent),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(aiModelFixture.maker, style: AppTypography.bodyMuted),
          const SizedBox(height: AppSpacing.xl),
          AIModelCard(item: aiModelFixture),
          const SizedBox(height: AppSpacing.xl),
          Text('Örnek yetenekler', style: AppTypography.title),
          const SizedBox(height: AppSpacing.md),
          const _Capability(
            icon: Icons.description_outlined,
            title: 'Belge analizi',
            detail: 'Uzun metinlerle yerel demo etkileşimi.',
          ),
          const SizedBox(height: AppSpacing.md),
          const _Capability(
            icon: Icons.image_outlined,
            title: 'Görsel açıklama',
            detail: 'Doğrulanmamış, yalnız tasarım amaçlı örnek.',
          ),
          const SizedBox(height: AppSpacing.md),
          const _Capability(
            icon: Icons.code_rounded,
            title: 'Kod yorumlama',
            detail: 'Canlı model çağrısı yapılmaz.',
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Benchmark yerine örnek göstergeler',
            style: AppTypography.title,
          ),
          const SizedBox(height: AppSpacing.md),
          const _Indicator(label: 'Yerel demo kapsamı', value: 0.78),
          const _Indicator(label: 'Arayüz erişilebilirliği', value: 0.86),
        ],
      ),
    ),
  );
}

class _Capability extends StatelessWidget {
  const _Capability({
    required this.icon,
    required this.title,
    required this.detail,
  });
  final IconData icon;
  final String title;
  final String detail;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadius.cardBorder,
      border: Border.all(color: AppColors.outline),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.aiAccent),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.title),
              Text(detail, style: AppTypography.bodyMuted),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Indicator extends StatelessWidget {
  const _Indicator({required this.label, required this.value});
  final String label;
  final double value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.technical),
        const SizedBox(height: AppSpacing.sm),
        LinearProgressIndicator(value: value, color: AppColors.aiAccent),
      ],
    ),
  );
}
