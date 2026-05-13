import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/progress_bar.dart';
import '../../../data/models/master_po.dart';
import '../../../l10n/app_l10n.dart';

class MasterPoCard extends StatelessWidget {
  const MasterPoCard({
    super.key,
    required this.master,
    required this.onTap,
    this.muted = false,
  });
  final MasterPo master;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final pct = (master.progress * 100).round();
    final allDone = master.isClosed;

    return AppCard(
      onTap: onTap,
      muted: muted,
      borderColor: master.urgent && !muted ? AppColors.accent : null,
      glow: master.urgent && !muted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          master.masterPoNumber,
                          style: AppType.mono10.copyWith(color: AppColors.muted),
                        ),
                        if (master.urgent)
                          AppChip(label: master.priorityLabel ?? '⏱', tone: ChipTone.warn),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${t.vendors(master.vendorPoCount)} · ${master.site ?? ''}',
                      style: AppType.bodyLg,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Fmt.relativeDay(master.operationDate, locale: t.locale.languageCode),
                      style: AppType.caption,
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: allDone ? AppColors.accentSoft : AppColors.accentInk,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  allDone ? Icons.check_rounded : Icons.arrow_forward_rounded,
                  size: 18,
                  color: allDone ? AppColors.accentInk : Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  t.clearedRatio(master.deliveredVendorPoCount, master.vendorPoCount),
                  style: AppType.mono10.copyWith(color: AppColors.muted),
                ),
              ),
              Text('$pct%', style: AppType.mono10.copyWith(color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 6),
          SimpleProgressBar(
            value: master.progress,
            color: allDone ? AppColors.accent : AppColors.accentInk,
          ),
        ],
      ),
    );
  }
}
