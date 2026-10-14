import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/eyebrow.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/offline/outbox_op.dart';
import '../../data/offline/outbox_store.dart';
import '../../data/offline/sync_engine.dart';
import '../../l10n/app_l10n.dart';
import '../../services/connectivity_service.dart';

/// Lists queued offline writes and lets the user trigger a sync or retry a
/// failed operation.
class SyncCenterScreen extends StatelessWidget {
  const SyncCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final outbox = context.watch<OutboxStore>();
    final sync = context.watch<SyncEngine>();
    final online = context.watch<ConnectivityService>().online;
    final ops = outbox.ops;

    return Scaffold(
      appBar: TrailTopBar(
        leading: RoundIconBtn(
          icon: Icons.chevron_left_rounded,
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: t.syncTitle,
      ),
      body: SafeArea(
        top: false,
        child: ops.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_done_outlined, size: 40, color: AppColors.accentInk),
                      const SizedBox(height: 12),
                      Text(t.syncAllDone, style: AppType.bodyMuted, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Eyebrow(
                            '${t.syncPending(outbox.pendingCount)} · ${t.syncFailed(outbox.failedCount)}'),
                      ),
                      if (sync.syncing)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentInk),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final op in ops) ...[
                    _OpRow(op: op, onRetry: () => outbox.retry(op.id).then((_) => sync.drain())),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
      ),
      bottomNavigationBar: ops.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: AppButton(
                  label: t.syncNow,
                  loading: sync.syncing,
                  trailing: const Icon(Icons.sync_rounded),
                  onPressed: (!online || sync.syncing) ? null : () => sync.drain(),
                ),
              ),
            ),
    );
  }
}

class _OpRow extends StatelessWidget {
  const _OpRow({required this.op, required this.onRetry});
  final OutboxOp op;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return AppCard(
      child: Row(
        children: [
          Icon(
            op.failed ? Icons.error_outline_rounded : Icons.schedule_rounded,
            size: 18,
            color: op.failed ? AppColors.danger : AppColors.muted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(op.label, style: AppType.body.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  op.failed ? (op.error ?? '—') : Fmt.relativeDay(op.createdAt, locale: t.locale.languageCode),
                  style: AppType.mono10.copyWith(color: op.failed ? AppColors.danger : AppColors.muted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (op.failed)
            AppButton(
              label: t.retry,
              variant: AppBtnVariant.ghost,
              full: false,
              onPressed: onRetry,
            )
          else
            AppChip(label: t.syncQueued, tone: ChipTone.warn),
        ],
      ),
    );
  }
}
