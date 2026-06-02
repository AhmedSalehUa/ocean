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
import '../../data/models/vendor_po_item.dart';
import '../../data/models/workflow_step.dart';
import '../../l10n/app_l10n.dart';
import '../../routing/routes.dart';
import '../../services/locale_service.dart';
import '../dashboard/master_pos_provider.dart';
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
          onPressed: () => v != null ? context.push(Routes.proofsPath(v.id)) : null,
        ),
      ),
      body: p.state == LoadState.error && v == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  p.error ?? 'Failed to load',
                  textAlign: TextAlign.center,
                  style: AppType.bodyLg,
                ),
              ),
            )
          : p.state == LoadState.loading || v == null
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
            Text(vendor.vendorRef ?? '', style: AppType.mono10.copyWith(color: AppColors.muted)),
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
                if (step.requiresItemPhoto) AppChip(label: t.itemPhoto, tone: ChipTone.soft),
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
            onStepTap: (s) => _jumpToStep(context, vendor, s),
          ),
        ],
      ),
    );
  }

  void _jumpToStep(BuildContext context, VendorPo vendor, WorkflowStep step) {
    final localeCode = Localizations.localeOf(context).languageCode;
    // Block jumps until every earlier step is complete. The user always has
    // to march through the workflow in order — the pipeline taps are just
    // a faster way to re-enter the step the workflow is *already* on.
    final idx = vendor.steps.indexWhere((s) => s.id == step.id);
    for (var i = 0; i < idx; i++) {
      final prior = vendor.steps[i];
      if (!prior.isComplete) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
            AppL10n.of(context).stepLockedHint(prior.nameFor(localeCode)),
          )),
        );
        return;
      }
    }
    // Final step gates finalize: only allowed when every prior step is done
    // AND every item is resolved.
    if (step.isFinalStep && !vendor.readyToFinalize) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppL10n.of(context).finalizeBlockedSteps)),
      );
      return;
    }

    final p = context.read<VendorDetailProvider>();
    p.pinStep(step.id);
    if (step.isFinalStep || (!step.requiresShipmentPhoto && !step.requiresItemPhoto)) {
      context.push(Routes.finalizePath(vendor.id));
      return;
    }
    if (step.requiresShipmentPhoto && !step.shipmentCompleted) {
      context.push(Routes.shipmentPath(vendor.id));
      return;
    }
    if (step.requiresItemPhoto) {
      context.push(Routes.guidedItemsPath(vendor.id));
    }
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
            _ItemRow(item: vendor.items[i], index: i + 1),
            if (i < vendor.items.length - 1)
              const Divider(height: 1, color: AppColors.lineSoft),
          ],
        ],
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
            decoration: BoxDecoration(
              color: AppColors.warnSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              index.toString().padLeft(2, '0'),
              style: AppType.mono11.copyWith(
                color: AppColors.warnInk,
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
                  style: AppType.mono10.copyWith(
                    color: AppColors.muted,
                    letterSpacing: 1.0,
                  ),
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
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _MetaChip(
                      icon: Icons.inventory_2_outlined,
                      label: Fmt.quantity(item.quantity, item.unit),
                    ),
                    _MetaChip(
                      icon: Icons.payments_outlined,
                      label: Fmt.money(item.totalPrice, decimals: true),
                    ),
                  ],
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

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgDeep,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.muted),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppType.mono11.copyWith(
              color: AppColors.ink2,
              fontWeight: FontWeight.w500,
            ),
          ),
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
          context.push(Routes.guidedItemsPath(vendor.id));
        }
        return;
      }

      if (step != null && step.requiresShipmentPhoto && !step.shipmentCompleted) {
        context.push(Routes.shipmentPath(vendor.id));
        return;
      }
      if (step != null && step.requiresItemPhoto) {
        context.push(Routes.guidedItemsPath(vendor.id));
        return;
      }
      if (vendor.allItemsResolved) {
        context.push(Routes.finalizePath(vendor.id));
      }
    }

    // The vendor PO is done once /finalize has been called (finalizedAt is
    // set) or every workflow step is complete. In either case there is no
    // more capture to do, so the primary CTA disappears entirely and only
    // the "View proofs" button stays.
    final lastStep = vendor.steps.isEmpty ? null : vendor.steps.last;
    final workflowFinished = vendor.finalizedAt != null ||
        (lastStep != null && lastStep.isFinalStep && lastStep.isComplete);

    String label;
    AppBtnVariant variant = AppBtnVariant.primary;
    bool enabled = true;

    if (workflowFinished) {
      label = t.done;
      enabled = false;
      variant = AppBtnVariant.soft;
    } else if (vendor.status == PoStatus.newPo) {
      label = t.startVendor;
    } else if (step != null && step.requiresShipmentPhoto && !step.shipmentCompleted) {
      label = t.captureShipment;
    } else if (step != null && step.requiresItemPhoto) {
      label = t.captureItems;
    } else if (vendor.allItemsResolved) {
      label = t.finalize;
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
            if (!workflowFinished) ...[
              AppButton(
                label: p.busy ? t.verifyingToken : label,
                loading: p.busy,
                variant: variant,
                trailing: enabled ? const Icon(Icons.arrow_forward_rounded) : null,
                onPressed: enabled ? () => handle(label) : null,
              ),
              const SizedBox(height: 8),
            ],
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
