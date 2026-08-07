/// "TecNow Hakkında".
///
/// Ayarlar'daki satır önceden yalnız "Bu ekran sonraki fazda uygulanacak."
/// diyen bir SnackBar açıyordu; satırın sağında ise gidilecek bir ekran
/// olduğunu söyleyen `>` oku duruyordu.
///
/// Ekranda **iddia yok**: yazılan her cümle ya `CLAUDE.md`'deki değişmez ürün
/// kuralına ya da ölçülebilir bir olguya karşılık geliyor. Gelecek vaadi
/// verilmiyor, çünkü bir "hakkında" ekranı ürünün ne olduğunu anlatır, ne
/// olacağını değil.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_version.dart';
import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_tokens.dart';
import 'source_policy_screen.dart';

const aboutRoute = '/hakkinda';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const AppBackTopBar(title: 'TecNow Hakkında'),
    body: SafeArea(
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
            Text('TecNow', style: AppTypography.display),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Teknoloji dünyasında olan biteni tek akışta izlemek için bir '
              'rehber. Sosyal ağ değil: burada gönderi paylaşılmaz, yorum '
              'yazılmaz, kimse takip edilmez.',
              style: AppTypography.bodyMuted,
            ),
            const SizedBox(height: AppSpacing.xl),

            const _AboutFact(
              icon: Icons.person_off_outlined,
              title: 'Hesap yok',
              body:
                  'Kayıt, giriş, kullanıcı adı ve şifre yok. Uygulamayı '
                  'kullanmak için hiçbir kimlik vermeniz gerekmiyor.',
            ),
            const _AboutFact(
              icon: Icons.smartphone_rounded,
              title: 'Veriler bu cihazda',
              body:
                  'İlgi alanlarınız, kaydettiğiniz içerikler ve okuma '
                  'geçmişiniz yalnızca bu telefonda saklanır. Bulut '
                  'senkronizasyonu yok; Ayarlar\'dan hepsini tek işlemle '
                  'silebilirsiniz.',
            ),
            const _AboutFact(
              icon: Icons.link_rounded,
              title: 'Kaynak her zaman görünür',
              body:
                  'Her içerikte onu kimin yayımladığı yazar ve detay '
                  'ekranından orijinal adrese gidilebilir. İçerik burada '
                  'yeniden yazılmaz.',
            ),

            const SizedBox(height: AppSpacing.lg),
            SecondaryButton(
              label: 'Kaynak Politikası',
              onPressed: () => context.push(sourcePolicyRoute),
            ),

            const SizedBox(height: AppSpacing.xxl),
            Center(
              child: Text(
                'Sürüm $appVersionLabel',
                style: AppTypography.bodyMuted,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AboutFact extends StatelessWidget {
  const _AboutFact({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 22, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(body, style: AppTypography.bodyMuted),
            ],
          ),
        ),
      ],
    ),
  );
}
