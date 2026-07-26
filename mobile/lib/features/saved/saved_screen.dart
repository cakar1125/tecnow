import 'package:flutter/material.dart';

import '../../design_system/components/app_components.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      AppTopBar(title: 'Kaydedilenler'),
      Expanded(
        child: EmptyStateView(
          title: 'Henüz kaydedilen içerik yok.',
          message: 'Kaydettiğin içerikler yalnız bu cihazda saklanır.',
        ),
      ),
    ],
  );
}
