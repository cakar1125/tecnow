import 'package:flutter/material.dart';

import '../design_system/tokens/app_palette.dart';
import '../design_system/tokens/app_text.dart';
import '../design_system/tokens/app_tokens.dart';
import '../fixtures/fixtures.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      const SliverAppBar(
        pinned: true,
        title: Text('Bildirimler'),
        centerTitle: true,
      ),
      SliverPadding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        sliver: SliverList.separated(
          itemCount: notificationFixtures.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, index) {
            final item = notificationFixtures[index];
            return Semantics(
              button: true,
              label: '${item.title}, ${item.time}',
              child: Material(
                color: context.palette.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.cardBorder,
                  side: BorderSide(color: context.palette.outline),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Bu bildirim yalnız fixture önizlemesidir.',
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: context.palette.primary.withValues(
                            alpha: 0.15,
                          ),
                          child: Icon(
                            Icons.notifications_outlined,
                            color: context.palette.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title, style: context.text.title),
                              Text(item.detail, style: context.text.bodyMuted),
                            ],
                          ),
                        ),
                        Text(item.time, style: context.text.technical),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}
