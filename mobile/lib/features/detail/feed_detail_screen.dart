/// İki detay rotasının ortak ekranı.
///
/// `/repository/:id` ve `/ai-model/:id` aynı veriyi gösterir; aralarındaki
/// fark başlık ve vurgu rengidir. Ayrı iki ekran olarak yazılsaydı yükleme,
/// hata ve "bulunamadı" davranışları iki yerde ayrı ayrı yaşar ve biri
/// düzeltilip diğeri unutulurdu.
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

class FeedDetailScreen extends ConsumerStatefulWidget {
  const FeedDetailScreen({
    required this.id,
    required this.title,
    required this.accent,
    required this.historyKind,
    super.key,
  });

  final String id;
  final String title;
  final Color accent;

  /// Okuma geçmişine yazılan tür etiketi.
  final String historyKind;

  @override
  ConsumerState<FeedDetailScreen> createState() => _FeedDetailScreenState();
}

class _FeedDetailScreenState extends ConsumerState<FeedDetailScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(recordRead(ref, itemId: widget.id, kind: widget.historyKind));
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

    return Scaffold(
      appBar: AppBackTopBar(title: widget.title),
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
        accent: widget.accent,
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

/// Depo, MCP ve skill kayıtları — ana vurgu cyan.
class RepositoryDetailScreen extends StatelessWidget {
  const RepositoryDetailScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context) => FeedDetailScreen(
    id: id,
    title: 'Repository Detayı',
    accent: AppColors.primary,
    historyKind: FeedItemKind.repository.name,
  );
}

/// AI modelleri — mor **yalnız** bu bağlamda (`CLAUDE.md` değişmez kuralı).
class AiModelDetailScreen extends StatelessWidget {
  const AiModelDetailScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context) => FeedDetailScreen(
    id: id,
    title: 'AI Model Detayı',
    accent: AppColors.aiAccent,
    historyKind: FeedItemKind.aiModel.name,
  );
}
