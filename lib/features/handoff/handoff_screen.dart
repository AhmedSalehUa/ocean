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
import '../../data/models/enums.dart';
import '../../l10n/app_l10n.dart';
import '../../routing/routes.dart';
import '../dashboard/master_pos_provider.dart';
import '../vendor_detail/vendor_detail_provider.dart';

class HandoffScreen extends StatelessWidget {
  const HandoffScreen({super.key, required this.vendorId});
  final String vendorId;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final v = context.watch<VendorDetailProvider>().vendor;
    final outcome =
        v?.status == PoStatus.partiallyDelivered ? t.partiallyDelivered : t.fullyDelivered;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 84, height: 84,
                  decoration: const BoxDecoration(
                    color: AppColors.accentSoft, shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: AppColors.accentInk, size: 44),
                ),
              ),
              const SizedBox(height: 28),
              Eyebrow(t.handoffTitle),
              const SizedBox(height: 6),
              Text(
                outcome,
                style: AppType.h2,
              ),
              const SizedBox(height: 8),
              Text(t.handoffBody, style: AppType.bodyMuted),
              const SizedBox(height: 24),
              if (v != null)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Eyebrow(v.vendorRef ?? ''),
                          const Spacer(),
                          AppChip(
                            label: outcome,
                            tone: v.status == PoStatus.partiallyDelivered
                                ? ChipTone.warn
                                : ChipTone.green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(v.supplierName, style: AppType.bodyLg),
                      const SizedBox(height: 4),
                      if (v.finalizedAt != null)
                        Text(
                          '${t.finalize.toUpperCase()} · ${Fmt.time(v.finalizedAt!)}',
                          style: AppType.mono10.copyWith(color: AppColors.muted),
                        ),
                    ],
                  ),
                ),
              const Spacer(),
              AppButton(
                label: t.backToDashboard,
                onPressed: () async {
                  await context.read<MasterPosProvider>().refresh();
                  if (context.mounted) context.go(Routes.dashboard);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
