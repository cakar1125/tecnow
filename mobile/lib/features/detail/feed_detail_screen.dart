/// Tek detay ekranı.
///
/// Önceden iki rota vardı (`/repository/:id`, `/ai-model/:id`) ve tür → rota
/// eşlemesi **çağıran ekranın** içinde yaşıyordu. İki sonucu oldu:
///
/// 1. Eşlemede yeri olmayan türler hiçbir yere gitmiyordu. Ölçüldü
///    (2026-07-28): üretilen 200 kaydın **146'sı** duyuru ve duyuruya
///    dokunmak yalnız "detay ekranı henüz uygulanmadı" diyordu. Akışın
///    dörtte üçü kapalı bir kapıydı — oysa ekran tür bağımsız çalışıyor.
/// 2. Vurgu rengi ve okuma geçmişi türü **rotadan** okunuyordu, kayıttan
///    değil. `/ai-model/<bir-depo-kimliği>` mor bir depo çiziyor ve geçmişe
///    yanlış tür yazıyordu.
///
/// Artık tek rota (`/icerik/:id`) var ve başlık, vurgu ve geçmiş türü
/// kaydın kendisinden türüyor.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/feed/feed_schema.dart';
import '../../data/providers.dart';
import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_tokens.dart';
import '../read_history/read_history_recorder.dart';
import 'feed_item_detail.dart';

/// Başlık çubuğu etiketi. Onaylı tasarımdaki iki başlık ("Repository Detayı",
/// "AI Model Detayı") birebir korunur; kalan türler aynı kalıbı sürdürür.
String detailTitle(FeedItemKind? kind) => switch (kind) {
  FeedItemKind.repository => 'Repository Detayı',
  FeedItemKind.aiModel => 'AI Model Detayı',
  FeedItemKind.tool => 'Araç Detayı',
  FeedItemKind.skill => 'Skill Detayı',
  FeedItemKind.mcp => 'MCP Detayı',
  FeedItemKind.announcement => 'Duyuru Detayı',
  // Kayıt henüz çözülmedi ya da bulunamadı: tür iddia edilmez.
  null => 'İçerik',
};

/// Vurgu rengi. Mor **yalnız** AI bağlamında (`CLAUDE.md` değişmez kuralı);
/// tür bilinmiyorken de mor kullanılmaz, çünkü o bir iddiadır.
Color detailAccent(FeedItemKind? kind) =>
    kind == FeedItemKind.aiModel ? AppColors.aiAccent : AppColors.primary;

class FeedDetailScreen extends ConsumerStatefulWidget {
  const FeedDetailScreen({required this.id, super.key});

  final String id;

  @override
  ConsumerState<FeedDetailScreen> createState() => _FeedDetailScreenState();
}

class _FeedDetailScreenState extends ConsumerState<FeedDetailScreen> {
  /// Geçmiş satırı kayıt başına **bir kez** yazılır. Ekran feed tazelenirken
  /// yeniden çizilir; her çizimde bir satır yazmak geçmişi şişirirdi.
  bool _recorded = false;

  /// Kayıt çözüldüğünde geçmişe yazar.
  ///
  /// `initState` yerine burada: tür kaydın kendisinden okunuyor ve kayıt
  /// açılış anında henüz yüklenmemiş olabiliyor. Bulunamayan bir kimlik için
  /// hiç yazılmaz — geçmişte var olmayan bir içeriğin satırı işe yaramaz.
  void _recordOnce(FeedItem item) {
    if (_recorded) return;
    _recorded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(recordRead(ref, itemId: item.id, kind: item.kind.name));
    });
  }

  Future<void> _openSource(Uri url) async {
    final opened = await ref.read(urlOpenerProvider)(url);
    if (!mounted || opened) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Bağlantı açılamadı.')));
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(feedProvider);
    final item = ref.watch(feedItemProvider(widget.id));
    if (item != null) _recordOnce(item);

    return Scaffold(
      appBar: AppBackTopBar(title: detailTitle(item?.kind)),
      body: SafeArea(child: _body(feed, item)),
    );
  }

  /// Durum sırası **tipe göre değil, içeriğe göre** belirleniyor.
  ///
  /// `AsyncLoading()` deseniyle başlamak sessiz bir hataydı: Riverpod 3 hatayı
  /// `AsyncLoading(error: …)` içinde taşıyabiliyor, bu yüzden `AsyncError()`
  /// arm'ı hiç eşleşmiyordu ve **bozuk bir feed sonsuza dek yükleme iskeleti
  /// gösteriyordu**. Testler yalnız "hata görünmesin" diye baktığı için
  /// görünmedi.
  ///
  /// Sıra: elde veri varsa onu göster (arka planda tazeleme sürse de), yoksa
  /// hata varsa söyle, o da yoksa yükleniyor.
  Widget _body(AsyncValue<List<FeedItem>> feed, FeedItem? item) {
    if (feed.hasValue) {
      if (item == null) {
        return const EmptyStateView(
          key: Key('detail-missing'),
          title: 'İçerik bulunamadı',
          message:
              'Bu kayıt akışta yok. İçerik güncellendiğinde kaldırılmış '
              'olabilir.',
        );
      }
      return FeedItemDetail(
        item: item,
        accent: detailAccent(item.kind),
        onOpenSource: _openSource,
      );
    }

    if (feed.hasError) {
      return const EmptyStateView(
        key: Key('detail-error'),
        title: 'İçerik okunamadı',
        message:
            'İçerik dosyası açılamadı. Uygulamayı güncellemek sorunu '
            'çözebilir.',
      );
    }

    return const Padding(
      key: Key('detail-loading'),
      padding: EdgeInsets.all(AppSpacing.lg),
      child: LoadingSkeleton(),
    );
  }
}
