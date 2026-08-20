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
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/models/vendor_po_item.dart';
import '../../l10n/app_l10n.dart';
import '../../routing/routes.dart';
import '../dashboard/master_pos_provider.dart';
import '../vendor_detail/vendor_detail_provider.dart';

/// The products page for an ITEM-level step: the vendor's items with a single
/// "capture" button that starts the guided per-item camera. Deliberately
/// omits the step pipeline and the assign-assistant action — the rep arrived
/// here to capture one specific step, not to re-navigate the workflow.
class StepItemsScreen extends StatefulWidget {
  const StepItemsScreen({super.key, required this.vendorId, required this.stepId});
  final String vendorId;
  final String stepId;

  @override
  State<StepItemsScreen> createState() => _StepItemsScreenState();
}

class _StepItemsScreenState extends State<StepItemsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = context.read<VendorDetailProvider>();
      if (p.vendor?.id != widget.vendorId) {
        await p.load(widget.vendorId);
      }
      // Keep the chosen step active for the guided camera.
      p.pinStep(widget.stepId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final locale = t.locale.languageCode;
    final p = context.watch<VendorDetailProvider>();
    final v = p.vendor;
    final step = v?.currentStep;
    final stepName = step?.nameFor(locale) ?? t.captureItems;

    return Scaffold(
      appBar: TrailTopBar(
        leading: RoundIconBtn(
          icon: Icons.chevron_left_rounded,
          onPressed: () => context.pop(),
        ),
        title: stepName,
        trailing: RoundIconBtn(icon: Icons.more_horiz_rounded, onPressed: () {}),
      ),
      body: (p.state == LoadState.loading || v == null)
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentInk))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
              children: [
                Eyebrow(t.masterStepsEyebrow),
                const SizedBox(height: 4),
                Text(v.supplierName, style: AppType.h2),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    AppChip(label: '${v.items.length} ${t.items}'),
                    AppChip(
                      label:
                          '${v.items.where((i) => i.status.isResolved).length}/${v.items.length}',
                      tone: v.allItemsResolved ? ChipTone.green : ChipTone.warn,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(t.captureScopeItem, style: AppType.bodyMuted),
                const SizedBox(height: 16),
                Eyebrow('${t.items} · ${v.items.length}'),
                const SizedBox(height: 10),
                if (v.items.isEmpty)
                  AppCard(child: Center(child: Text(t.items, style: AppType.bodyMuted)))
                else
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < v.items.length; i++) ...[
                          _ItemRow(item: v.items[i], index: i + 1),
                          if (i < v.items.length - 1)
                            const Divider(height: 1, color: AppColors.lineSoft),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: v == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: AppButton(
                  label: t.captureItems,
                  trailing: const Icon(Icons.photo_camera_rounded),
                  onPressed: () => context.push(Routes.guidedItemsPath(widget.vendorId)),
                ),
              ),
            ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.index});
  final VendorPoItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.bgDeep,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              index.toString().padLeft(2, '0'),
              style: AppType.mono11.copyWith(
                color: AppColors.ink2,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemCode,
                  style: AppType.mono10.copyWith(color: AppColors.muted, letterSpacing: 1.0),
                ),
                const SizedBox(height: 3),
                Text(
                  item.itemName,
                  style: AppType.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  Fmt.quantity(item.quantity, item.unit),
                  style: AppType.mono10.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ItemStatusPill(item.status),
        ],
      ),
    );
  }
}
