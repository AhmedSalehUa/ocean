import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/colors.dart';
import '../theme/typography.dart';
import '../../data/offline/outbox_store.dart';
import '../../data/offline/sync_engine.dart';
import '../../l10n/app_l10n.dart';
import '../../routing/routes.dart';
import '../../services/connectivity_service.dart';

/// A thin status bar pinned to the top of every screen:
/// - offline → "You're offline…"
/// - online + syncing → "Syncing…"
/// - online + queued writes → "N change(s) waiting" (tap → sync center)
/// Hidden when online with an empty outbox.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final offline = context.watch<ConnectivityService>().offline;
    final outbox = context.watch<OutboxStore>();
    final sync = context.watch<SyncEngine>();
    final t = AppL10n.of(context);
    final queued = outbox.pendingCount + outbox.failedCount;

    String? text;
    IconData icon;
    Color bg;
    if (offline) {
      text = t.offlineBanner;
      icon = Icons.cloud_off_rounded;
      bg = AppColors.warnInk;
    } else if (sync.syncing) {
      text = t.syncBannerSyncing;
      icon = Icons.sync_rounded;
      bg = AppColors.accentInk;
    } else if (queued > 0) {
      text = t.syncBannerPending(queued);
      icon = Icons.cloud_upload_outlined;
      bg = AppColors.accentInk;
    } else {
      text = null;
      icon = Icons.cloud_done_outlined;
      bg = AppColors.accentInk;
    }

    return Column(
      children: [
        if (text != null)
          Material(
            color: bg,
            child: InkWell(
              onTap: (offline || queued > 0) ? () => _openSync(context) : null,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 14, color: Colors.white),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          text,
                          textAlign: TextAlign.center,
                          style: AppType.mono10.copyWith(color: Colors.white, letterSpacing: 0.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        Expanded(child: child),
      ],
    );
  }

  void _openSync(BuildContext context) {
    try {
      context.push(Routes.sync);
    } catch (_) {
      // Navigation from the app-shell builder isn't critical; ignore.
    }
  }
}
