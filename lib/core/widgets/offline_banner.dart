import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/colors.dart';
import '../theme/typography.dart';
import '../../l10n/app_l10n.dart';
import '../../services/connectivity_service.dart';

/// A thin persistent banner shown at the very top while the device is offline.
/// Wrap the app's router output with it via MaterialApp.router's `builder`.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final offline = context.watch<ConnectivityService>().offline;
    final t = AppL10n.of(context);
    return Column(
      children: [
        if (offline)
          Material(
            color: AppColors.warnInk,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 14, color: Colors.white),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        t.offlineBanner,
                        textAlign: TextAlign.center,
                        style: AppType.mono10.copyWith(color: Colors.white, letterSpacing: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(child: child),
      ],
    );
  }
}
