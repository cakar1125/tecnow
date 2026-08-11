import 'package:flutter/material.dart';

import '../design_system/components/app_components.dart';
import '../design_system/tokens/app_text.dart';
import '../design_system/tokens/app_tokens.dart';

class CreatePostScreen extends StatelessWidget {
  const CreatePostScreen({super.key});

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      const SliverAppBar(
        pinned: true,
        title: Text('Gönderi Oluştur'),
        centerTitle: true,
      ),
      SliverPadding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        sliver: SliverList.list(
          children: [
            const CategoryBadge(label: 'YEREL FORM'),
            const SizedBox(height: AppSpacing.md),
            Text('Bir teknoloji notu paylaş', style: context.text.headline),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Bu form canlı bir servise bağlanmaz ve gönderi yayınlamaz.',
              style: context.text.bodyMuted,
            ),
            const SizedBox(height: AppSpacing.xl),
            const AppTextField(
              label: 'Başlık',
              hint: 'Örnek teknoloji başlığı',
            ),
            const SizedBox(height: AppSpacing.md),
            const AppTextField(
              label: 'Açıklama',
              hint: 'Fixture açıklaması',
              maxLines: 6,
            ),
            const SizedBox(height: AppSpacing.md),
            const AppTextField(
              label: 'Bağlantı (isteğe bağlı)',
              hint: 'https://example.invalid',
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Yerel taslağı hazırla',
              icon: Icons.save_outlined,
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Taslak yalnız bu demo oturumunda hazırlandı; yayınlanmadı.',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
