/// Akış satırlarının yeni anatomisi.
///
/// ## Neden kart yok
///
/// Önceki düzende **her kayıt aynı kutuydu**: yuvarlak köşe, kenarlık, iç
/// boşluk, üstte rozet şeridi, ortada başlık, altında üç satır özet. Tür
/// ayrımını yalnız kenarlığın rengi taşıyordu. Kullanıcının şikâyeti buydu —
/// "her şey birbiri ile aynı" — ve ölçüm onu doğruladı:
///
/// | Ne | Kontrast |
/// |---|---|
/// | Kart yüzeyi / sayfa zemini (koyu) | **1.07:1** |
/// | Kart kenarlığı / yüzey | **1.45:1** |
///
/// Yani kartın sınırı zaten görünmüyordu. Görünmeyen bir çerçeve, ayrım
/// üretmeden yer kaplar. Çerçeve kaldırıldı; ayrımı **punto, ağırlık ve
/// boşluk** taşıyor, satırları ince bir ayraç bölüyor.
///
/// ## İki anatomi
///
/// - [FeedHeroItem] — bölümün ilk kaydı. Geniş marka bloğu, **altında**
///   başlık. Göz nereye bakacağını buradan öğreniyor.
/// - [FeedRowItem] — sonraki kayıtlar. Başlık solda, marka işareti sağda,
///   altında `KAYNAK · GEREKÇE`.
///
/// Ritim bilinçli: sabit bir liste her kaydı eşit önemde gösterir, oysa
/// akışın bir başı vardır.
library;

import 'package:flutter/material.dart';

import '../../ui/feed_signal.dart';
import '../../ui/source_brand.dart';
import '../tokens/app_palette.dart';
import '../tokens/app_text.dart';
import '../tokens/app_tokens.dart';

/// Kaynağın marka işareti: markanın rengiyle tonlanmış kare, içinde harfleri.
///
/// Gerçek logo yok — sebebi ve alternatifi [SourceBrand] içinde yazılı.
class SourceMark extends StatelessWidget {
  const SourceMark({
    required this.sourceName,
    this.size = 48,
    this.radius = AppRadius.smallBorder,
    super.key,
  });

  final String sourceName;
  final double size;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final brand = SourceBrand.of(sourceName);
    final color = brand.resolve(palette);

    return Semantics(
      label: '$sourceName kaynağı',
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          // Dolgu markanın rengi ama **saydam**: tam doygun bir kare iki
          // temada da zeminden fazla kopuyor ve listeyi renk kırıntılarına
          // çeviriyor. Harf tam doygunlukta kalıyor, kimlik oradan geliyor.
          color: color.withValues(alpha: 0.14),
          borderRadius: radius,
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          brand.initials,
          style: context.text.technical.copyWith(
            color: color,
            fontSize: size * 0.32,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// `Kaynak · GEREKÇE` satırı.
///
/// Kaynak adı okunur renkte, gerekçe soluk. Gerekçe yoksa ayraç da çizilmez —
/// boşta duran bir nokta, olmayan bir bilgiyi varmış gibi gösterir.
///
/// ## Kaynak adı neden büyütülmüyor
///
/// Büyütülüyordu ve **hangi kurala göre** sorusunun doğru cevabı yok. Gerçek
/// kaynak adları ölçüldü (2026-08-11, 14 kaynak / 200 kayıt) ve on tanesi
/// **iki dilli**: bir marka adı + Türkçe bir kelime.
///
/// | Kaynak | `toUpperCase()` | Türkçe kural |
/// |---|---|---|
/// | `NVIDIA Geliştirici` | NVIDIA GEL**I**ŞT**I**R**I**C**I** | NVIDIA GELİŞTİRİCİ |
/// | `GitHub Değişiklikler` | G**I**THUB DEĞ**I**Ş**I**KL**I**KLER | GİTHUB DEĞİŞİKLİKLER |
/// | `Visual Studio Code` | VISUAL STUDIO CODE | V**İ**SUAL STUD**İ**O CODE |
/// | `Google DeepMind` | GOOGLE DEEPMIND | GOOGLE DEEPM**İ**ND |
/// | `Mistral AI` | MISTRAL AI | M**İ**STRAL AI |
///
/// Varsayılan kural **bizim yazdığımız** Türkçe kelimeleri bozuyor
/// (`GELIŞTIRICI` — 40 kayıtta), Türkçe kural **başkasının markasını**
/// bozuyor (`VİSUAL STUDİO`). Tek bir kural iki dilli bir dizgide doğru
/// olamaz.
///
/// Bu yüzden ad **olduğu gibi** yazılıyor: her kaynak kendi adını nasıl
/// yazıyorsa öyle. On dört kaynağın on dördü için doğru olan tek biçim bu, ve
/// büyütme zaten bir üslup tercihiydi — taşıdığı bilgi yoktu, doğru yazımı
/// bozuyordu.
///
/// Gerekçe etiketi (`RESMİ KAYNAK`, `tecOS ÖZETİ`) büyük kalıyor: onları biz
/// yazıyoruz, dolayısıyla zaten doğru yazılmış hâlleriyle duruyorlar. Aradaki
/// büyük/küçük farkı ayrıca işe yarıyor — satırın iki yarısı birbirine
/// karışmıyor.
class FeedMetaLine extends StatelessWidget {
  const FeedMetaLine({required this.sourceName, this.signal, super.key});

  final String sourceName;
  final FeedSignal? signal;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final style = context.text.label.copyWith(
      fontSize: 11,
      letterSpacing: 0.4,
      color: palette.textSecondary,
    );

    return Row(
      children: [
        Flexible(
          child: Text(
            // Kendi yazımıyla — gerekçesi sınıf başlığında ölçümüyle yazılı.
            sourceName,
            style: style.copyWith(
              color: palette.textPrimary,
              fontWeight: FontWeight.w600,
              // Küçük harfli metinde geniş harf aralığı okumayı zorlaştırır;
              // büyütme kalkınca bu da kalkıyor.
              letterSpacing: 0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (signal case final reason?) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: palette.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Flexible(
            child: Text(
              reason.label,
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

/// Bölümün ilk kaydı: geniş marka bloğu, altında başlık.
class FeedHeroItem extends StatelessWidget {
  const FeedHeroItem({
    required this.itemId,
    required this.title,
    required this.sourceName,
    required this.onTap,
    this.signal,
    this.onToggleSave,
    this.isSaved = false,
    super.key,
  });

  final String itemId;
  final String title;
  final String sourceName;
  final FeedSignal? signal;
  final VoidCallback onTap;
  final VoidCallback? onToggleSave;
  final bool isSaved;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = SourceBrand.of(sourceName).resolve(palette);

    return Semantics(
      button: true,
      label: '$title öne çıkan kayıt',
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.lg,
            bottom: AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Görsel yerine **marka şeridi**, kutu değil.
              //
              // İlk denemede burada 16:9 bir blok vardı ve içinde yalnız
              // marka işareti duruyordu. Golden'da görüldü: ekranın üçte
              // birini kaplayan, hiçbir bilgi taşımayan bir dikdörtgen.
              // Görselimiz olmadığı için o alanı dolduracak bir şey yok ve
              // boş bir kutu, kutusuzluktan kötüdür. Hero'nun ağırlığı artık
              // **puntodan** geliyor: işaret büyük, başlık akışın en büyük
              // metni, ve tek kayıt kırpılmadan gösteriliyor.
              Row(
                children: [
                  SourceMark(sourceName: sourceName, size: 56),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1),
                        gradient: LinearGradient(
                          colors: [
                            color.withValues(alpha: 0.55),
                            color.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (onToggleSave case final toggle?) ...[
                    const SizedBox(width: AppSpacing.sm),
                    _SaveButton(
                      isSaved: isSaved,
                      onPressed: toggle,
                      itemId: itemId,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                // Hero başlığı akışın en büyük metni: göz buraya düşsün
                // diye. Kırpılmıyor — bir hero'nun yarım başlığı hero olmaz.
                style: context.text.display.copyWith(
                  fontSize: 28,
                  height: 1.16,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FeedMetaLine(sourceName: sourceName, signal: signal),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sonraki kayıtlar: başlık solda, marka işareti sağda.
class FeedRowItem extends StatelessWidget {
  const FeedRowItem({
    required this.itemId,
    required this.title,
    required this.sourceName,
    required this.onTap,
    this.signal,
    this.onToggleSave,
    this.isSaved = false,
    super.key,
  });

  final String itemId;
  final String title;
  final String sourceName;
  final FeedSignal? signal;
  final VoidCallback onTap;
  final VoidCallback? onToggleSave;
  final bool isSaved;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$title kaydı',
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    // Dört satır: ölçüldü (2026-08-07), 200 başlığın 55'i
                    // 60 karakteri aşıyor ve en uzunu 114 karakter. Üç
                    // satır o başlıkları ortasından kesiyordu.
                    style: context.text.title.copyWith(
                      fontSize: 19,
                      height: 1.28,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                SourceMark(sourceName: sourceName, size: 64),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: FeedMetaLine(sourceName: sourceName, signal: signal),
                ),
                if (onToggleSave case final toggle?)
                  _SaveButton(
                    isSaved: isSaved,
                    onPressed: toggle,
                    itemId: itemId,
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// Satırlar arası ayraç.
///
/// Kart çerçevesinin yerini alan tek çizgi. Dekoratif [AppPalette.outline]
/// kullanıyor ve bu **doğru olan**: ayrımı asıl taşıyan boşluk ve punto,
/// çizgi yalnız ritmi işaretliyor. Tek ayırıcı olsaydı 3:1 gerekirdi.
class FeedDivider extends StatelessWidget {
  const FeedDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, thickness: 1, color: context.palette.outline);
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.isSaved,
    required this.onPressed,
    required this.itemId,
  });

  final bool isSaved;
  final VoidCallback onPressed;

  /// Kaydın kimliği. Anahtar bundan kurulur.
  ///
  /// İlk denemede anahtar anatomiye göreydi (`feed-row-bookmark`) ve
  /// **her satırda tekrarlanıyordu** — aynı ağaçta yinelenen anahtar.
  /// Kayıt kimliği hem benzersiz hem de anatomiden bağımsız: aynı kayıt
  /// hero'dan satıra dönse bile anahtarı değişmiyor.
  final String itemId;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: isSaved,
    label: isSaved ? 'Kaydı kaldır' : 'Kaydet',
    child: IconButton(
      key: Key('feed-bookmark-$itemId'),
      tooltip: isSaved ? 'Kaydı kaldır' : 'Kaydet',
      onPressed: onPressed,
      // `visualDensity: compact` denendi ve **geri alındı**: düğmeyi
      // 38×32 dp'ye indiriyordu, yani `QUALITY_GATES.md`'nin 44×44
      // kuralının altına. `test/app/touch_target_test.dart` yakaladı.
      // Görsel sıkışıklık ikon boyutuyla çözülür, dokunma alanıyla değil.
      constraints: const BoxConstraints(
        minWidth: AppTouchTarget.minimum,
        minHeight: AppTouchTarget.minimum,
      ),
      icon: Icon(
        isSaved ? Icons.bookmark : Icons.bookmark_outline,
        size: 22,
        color: isSaved
            ? context.palette.primary
            : context.palette.textSecondary,
      ),
    ),
  );
}
