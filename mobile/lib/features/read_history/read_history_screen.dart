/// "Okuma Geçmişi" listesi.
///
/// Ayarlar bu satırın **sayısını** gösteriyordu ama satıra dokunmak hiçbir
/// yere gitmiyordu. Veri v3 şemasından beri yazılıyor ve tekilleştiriliyor;
/// eksik olan tek şey onu gösteren ekrandı.
///
/// Akışta artık bulunmayan kayıtlar **gizlenmiyor**. Gizlemek kolaydı ve yeni
/// bir tutarsızlık üretirdi: Ayarlar "8 kayıt" derken liste beş satır
/// gösterirdi ve iki ekran birbiriyle çelişirdi. Çözülemeyen satır, ne
/// olduğunu söyleyerek duruyor.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n_context.dart';
import '../../data/feed/feed_schema.dart';
import '../../data/providers.dart';
import '../../data/repositories/read_history_repository.dart';
import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_palette.dart';
import '../../design_system/tokens/app_text.dart';
import '../../design_system/tokens/app_tokens.dart';
import '../../ui/detail_route.dart';
import '../detail/feed_detail_screen.dart';

const readHistoryRoute = '/okuma-gecmisi';

/// Geçmiş satırının ekranda göründüğü hâli.
///
/// [item] `null` ise kayıt akıştan kalkmış demektir; [kind] yine de kaydın
/// kendi türüdür, çünkü geçmişe yazılırken saklanmıştır.
final class ReadHistoryRow {
  const ReadHistoryRow({required this.entry, required this.item});

  final ReadHistoryEntry entry;
  final FeedItem? item;

  bool get resolved => item != null;

  FeedItemKind? get kind {
    if (item != null) return item!.kind;
    for (final value in FeedItemKind.values) {
      if (value.name == entry.kind) return value;
    }
    return null;
  }
}

/// Geçmiş satırlarını akıştaki kayıtlarla eşler.
///
/// Eşleme O(n·m) olmasın diye feed bir kez kimliğe göre indekslenir: geçmiş
/// 200 satıra, feed 200 kayda kadar çıkabiliyor.
List<ReadHistoryRow> buildReadHistoryRows(
  List<ReadHistoryEntry> entries,
  List<FeedItem> feed,
) {
  final byId = {for (final item in feed) item.id: item};
  return [
    for (final entry in entries)
      ReadHistoryRow(entry: entry, item: byId[entry.itemId]),
  ];
}

class ReadHistoryScreen extends ConsumerWidget {
  const ReadHistoryScreen({super.key});

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    // Messenger dialog'dan önce alınır: `await` sonrasında `context` artık
    // güvenle kullanılamaz.
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppConfirmationDialog(
        title: l10n.historyClearTitle,
        message: l10n.historyClearConfirm,
        onConfirm: () => Navigator.of(dialogContext).pop(true),
      ),
    );
    if (confirmed != true) return;

    try {
      // Ayarlar'daki adet bu listeden türüyor; ayrıca tazelemek gerekmiyor.
      await ref.read(readHistoryProvider.notifier).clear();
      messenger.showSnackBar(SnackBar(content: Text(l10n.historyCleared)));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.historyClearFailed('$error'))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(readHistoryProvider);
    final feed = ref.watch(feedProvider);
    final canClear = (history.value ?? const []).isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.palette.background,
        surfaceTintColor: Colors.transparent,
        leading: Semantics(
          button: true,
          label: 'Geri',
          child: IconButton(
            tooltip: 'Geri',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        title: Text(
          context.l10n.settingsReadHistory,
          style: context.text.title,
        ),
        actions: [
          if (canClear)
            IconButton(
              tooltip: context.l10n.historyClearTooltip,
              onPressed: () => _confirmClear(context, ref),
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: SafeArea(child: _body(context, history, feed)),
    );
  }

  /// Durum sırası **içeriğe göre**: elde veri varsa göster, yoksa hata varsa
  /// söyle, o da yoksa yükleniyor. Riverpod 3 hatayı `AsyncLoading(error: …)`
  /// içinde taşıyabildiği için tipe göre eşleştirme hata kolunu ölü bırakır.
  Widget _body(
    BuildContext context,
    AsyncValue<List<ReadHistoryEntry>> history,
    AsyncValue<List<FeedItem>> feed,
  ) {
    if (history.hasValue) {
      final entries = history.value!;
      if (entries.isEmpty) {
        return EmptyStateView(
          key: const Key('read-history-empty'),
          title: context.l10n.historyEmptyTitle,
          message: context.l10n.historyEmptyBody,
        );
      }
      final rows = buildReadHistoryRows(entries, feed.value ?? const []);
      return ListView.separated(
        key: const Key('read-history-list'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        itemCount: rows.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, index) => _HistoryRow(row: rows[index]),
      );
    }

    if (history.hasError) {
      return EmptyStateView(
        key: const Key('read-history-error'),
        title: context.l10n.historyUnreadableTitle,
        message: context.l10n.historyUnreadableBody,
      );
    }

    return const Padding(
      key: Key('read-history-loading'),
      padding: EdgeInsets.all(AppSpacing.lg),
      child: LoadingSkeleton(),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.row});

  final ReadHistoryRow row;

  @override
  Widget build(BuildContext context) {
    final item = row.item;
    final title = item?.title ?? context.l10n.historyRemovedItem;
    final subtitle = item != null
        ? item.sourceName
        : context.l10n.historyRemovedItemBody;

    return Material(
      color: context.palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardBorder,
        side: BorderSide(color: context.palette.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: row.resolved,
        child: InkWell(
          // Çözülemeyen satır dokunulabilir görünmez: gidilecek bir yer yok.
          onTap: row.resolved
              ? () => context.push(detailRoute(row.entry.itemId))
              : null,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detailTitle(row.kind),
                        style: context.text.label.copyWith(
                          color: row.resolved
                              ? context.palette.primary
                              : context.palette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        title,
                        style: context.text.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: row.resolved
                              ? context.palette.textPrimary
                              : context.palette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(subtitle, style: context.text.bodyMuted),
                    ],
                  ),
                ),
                if (row.resolved) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: context.palette.textSecondary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
