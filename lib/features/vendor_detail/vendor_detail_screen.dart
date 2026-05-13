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
import '../../core/widgets/step_pipeline.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/models/enums.dart';
import '../../data/models/vendor_po.dart';
import '../../l10n/app_l10n.dart';
import '../../routing/routes.dart';
import '../../services/locale_service.dart';
import 'vendor_detail_provider.dart';

class VendorDetailScreen extends StatefulWidget {
  const VendorDetailScreen({super.key, required this.vendorId});
  final String vendorId;
  @override
  State<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends State<VendorDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VendorDetailProvider>().load(widget.vendorId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final locale = context.watch<LocaleService>().locale.languageCode;
    final p = context.watch<VendorDetailProvider>();
    final v = p.vendor;

    return Scaffold(
      appBar: TrailTopBar(
        leading: RoundIconBtn(
          icon: Icons.chevron_left_rounded,
          onPressed: () => context.pop(),
        ),
        title: v?.vendorRef ?? v?.supplierName ?? '',
        trailing: RoundIconBtn(
          icon: Icons.history_outlined,
          tooltip: t.viewProofs,
          onPressed: () =>
              v != null ? context.push(Routes.proofsPath(v.id)) : null,
        ),
      ),
      body: p.state == LoadState.loading || v == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentInk))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
              children: [
                _Header(vendor: v),
                const SizedBox(height: 16),
                _StepCard(vendor: v, localeCode: locale),
                const SizedBox(height: 16),
                _ItemTable(vendor: v),
              ],
            ),
      bottomNavigationBar: v == null ? null : _BottomCta(vendor: v),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.vendor});
  final VendorPo vendor;
  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            PoStatusPill(vendor.status),
            const SizedBox(width: 8),
            Text(vendor.vendorRef ?? '',
                style: AppType.mono10.copyWith(color: AppColors.muted)),
          ],
        ),
        const SizedBox(height: 8),
        Text(vendor.supplierName, style: AppType.h2),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            AppChip(label: '${vendor.items.length} ${t.items}'),
            AppChip(label: Fmt.money(vendor.totalAmount)),
            if (vendor.assignedAt != null)
              AppChip(label: 'Assigned · ${Fmt.time(vendor.assignedAt!)}'),
            if (vendor.finalizedAt != null)
              AppChip(
                tone: ChipTone.green,
                label: 'Finalized · ${Fmt.time(vendor.finalizedAt!)}',
              ),
          ],
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.vendor, required this.localeCode});
  final VendorPo vendor;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final step = vendor.currentStep;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(t.stepCurrent),
          const SizedBox(height: 8),
          if (step != null) ...[
            Text(step.nameFor(localeCode), style: AppType.h3),
            const SizedBox(height: 4),
            Text(
              step.nameFor(localeCode == 'ar' ? 'en' : 'ar'),
              style: AppType.caption,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (step.requiresShipmentPhoto)
                  AppChip(label: t.shipmentPhoto, tone: ChipTone.soft),
                if (step.requiresItemPhoto)
                  AppChip(label: t.itemPhoto, tone: ChipTone.soft),
                if (step.isFinalStep) AppChip(label: t.finalStep, tone: ChipTone.dark),
              ],
            ),
            const SizedBox(height: 14),
          ],
          StepPipeline(
            steps: vendor.steps,
            currentStepId: vendor.currentStepId,
            showLabels: true,
            localeCode: localeCode,
          ),
        ],
      ),
    );
  }
}

class _ItemTable extends StatelessWidget {
  const _ItemTable({required this.vendor});
  final VendorPo vendor;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    if (vendor.items.isEmpty) {
      return AppCard(
        child: Center(child: Text(t.items, style: AppType.bodyMuted)),
      );
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Expanded(child: Eyebrow('${t.items} · ${vendor.items.length}')),
                Text(
                  '${vendor.items.where((i) => i.status.isResolved).length}/${vendor.items.length}',
                  style: AppType.mono10.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.lineSoft),
          for (var i = 0; i < vendor.items.length; i++) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(vendor.items[i].itemName, style: AppType.body),
                        const SizedBox(height: 4),
                        Text(
                          '${vendor.items[i].itemCode} · ${Fmt.quantity(vendor.items[i].quantity, vendor.items[i].unit)} · ${Fmt.money(vendor.items[i].totalPrice, decimals: true)}',
                          style: AppType.mono10.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ItemStatusPill(vendor.items[i].status),
                ],
              ),
            ),
            if (i < vendor.items.length - 1) const Divider(height: 1, color: AppColors.lineSoft),
          ],
        ],
      ),
    );
  }
}

class _BottomCta extends StatelessWidget {
  const _BottomCta({required this.vendor});
  final VendorPo vendor;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final p = context.read<VendorDetailProvider>();
    final step = vendor.currentStep;

    Future<void> handle(String label) async {
      if (vendor.status == PoStatus.newPo) {
        final ok = await p.startVendor();
        if (!ok || !context.mounted) return;
        // Route based on current step requirements
        final s = p.vendor?.currentStep;
        if (s == null) return;
        if (s.requiresShipmentPhoto && !s.shipmentCompleted) {
          context.push(Routes.shipmentPath(vendor.id));
        } else if (s.requiresItemPhoto) {
          context.push(Routes.itemLoopPath(vendor.id));
        }
        return;
      }

      if (step != null && step.requiresShipmentPhoto && !step.shipmentCompleted) {
        context.push(Routes.shipmentPath(vendor.id));
        return;
      }
      if (step != null && step.requiresItemPhoto) {
        context.push(Routes.itemLoopPath(vendor.id));
        return;
      }
      if (vendor.allItemsResolved) {
        context.push(Routes.finalizePath(vendor.id));
      }
    }

    String label;
    AppBtnVariant variant = AppBtnVariant.primary;
    bool enabled = true;

    if (vendor.status == PoStatus.newPo) {
      label = t.startVendor;
    } else if (step != null && step.requiresShipmentPhoto && !step.shipmentCompleted) {
      label = t.captureShipment;
    } else if (step != null && step.requiresItemPhoto) {
      label = t.captureItems;
    } else if (vendor.allItemsResolved) {
      label = t.finalize;
    } else if (vendor.status == PoStatus.fullyDelivered ||
        vendor.status == PoStatus.partiallyDelivered) {
      label = t.done;
      enabled = false;
      variant = AppBtnVariant.soft;
    } else {
      label = t.captureItems;
      enabled = false;
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton(
              label: p.busy ? t.verifyingToken : label,
              loading: p.busy,
              variant: variant,
              trailing: enabled ? const Icon(Icons.arrow_forward_rounded) : null,
              onPressed: enabled ? () => handle(label) : null,
            ),
            const SizedBox(height: 8),
            AppButton(
              label: t.viewProofs,
              variant: AppBtnVariant.ghost,
              leading: const Icon(Icons.history_outlined),
              onPressed: () => context.push(Routes.proofsPath(vendor.id)),
            ),
          ],
        ),
      ),
    );
  }
}
