import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/vendor_po.dart';
import '../../../l10n/app_l10n.dart';

class VendorPoCard extends StatelessWidget {
  const VendorPoCard({super.key, required this.vendor, required this.onTap});
  final VendorPo vendor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final itemsTotal = vendor.items.isNotEmpty ? vendor.items.length : vendor.itemCount;
    final resolved = vendor.items.isNotEmpty
        ? vendor.items.where((i) => i.status.isResolved).length
        : vendor.resolvedItemCount;
    final isFinal = vendor.status == PoStatus.fullyDelivered ||
        vendor.status == PoStatus.partiallyDelivered;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
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
                    Row(
                      children: [
                        PoStatusPill(vendor.status),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            vendor.vendorRef ?? '',
                            style: AppType.mono10.copyWith(color: AppColors.muted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      vendor.supplierName,
                      style: AppType.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$itemsTotal items · ${Fmt.money(vendor.totalAmount)}'
                      '${isFinal && vendor.finalizedAt != null ? ' · ${t.finalizedAt(Fmt.time(vendor.finalizedAt!))}' : ''}',
                      style: AppType.caption,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 22),
            ],
          ),
          if (vendor.items.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                for (final it in vendor.items) ...[
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: _itemColor(it.status).withAlpha(
                          it.status == ItemStatus.pending ? 64 : 255,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                const SizedBox(width: 2),
                Text(
                  '$resolved/$itemsTotal',
                  style: AppType.mono10.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _itemColor(ItemStatus s) {
    return switch (s) {
      ItemStatus.pending => AppColors.muted2,
      ItemStatus.inProgress => AppColors.warn,
      ItemStatus.delivered => AppColors.accent,
      ItemStatus.missing => AppColors.danger,
      ItemStatus.rejected => AppColors.danger,
    };
  }
}
