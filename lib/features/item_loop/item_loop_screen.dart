import 'dart:io';

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
import '../../core/widgets/progress_bar.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/models/enums.dart';
import '../../data/models/vendor_po.dart';
import '../../data/models/vendor_po_item.dart';
import '../../l10n/app_l10n.dart';
import '../../routing/routes.dart';
import '../../services/camera_service.dart';
import '../../services/location_service.dart';
import '../vendor_detail/vendor_detail_provider.dart';

class ItemLoopScreen extends StatefulWidget {
  const ItemLoopScreen({super.key, required this.vendorId});
  final String vendorId;
  @override
  State<ItemLoopScreen> createState() => _ItemLoopScreenState();
}

class _ItemLoopScreenState extends State<ItemLoopScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<VendorDetailProvider>();
      if (p.vendor?.id != widget.vendorId) p.load(widget.vendorId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final p = context.watch<VendorDetailProvider>();
    final v = p.vendor;

    return Scaffold(
      appBar: TrailTopBar(
        leading: RoundIconBtn(
          icon: Icons.chevron_left_rounded,
          onPressed: () => context.pop(),
        ),
        title: t.itemLoopTitle,
        trailing: RoundIconBtn(
          icon: Icons.history_outlined,
          onPressed: () =>
              v != null ? context.push(Routes.proofsPath(v.id)) : null,
        ),
      ),
      body: v == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentInk))
          : Builder(builder: (_) {
              final sorted = [...v.items]..sort((a, b) {
                  final ar = a.status.isResolved ? 1 : 0;
                  final br = b.status.isResolved ? 1 : 0;
                  if (ar != br) return ar - br;
                  return (int.tryParse(a.serial ?? '') ?? 0)
                      .compareTo(int.tryParse(b.serial ?? '') ?? 0);
                });
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
                children: [
                  _LoopHeader(vendor: v),
                  const SizedBox(height: 14),
                  for (var i = 0; i < sorted.length; i++) ...[
                    _ItemRow(vendor: v, item: sorted[i]),
                    const SizedBox(height: 10),
                  ],
                ],
              );
            }),
      bottomNavigationBar: v == null ? null : _LoopBottom(vendor: v),
    );
  }
}

class _LoopHeader extends StatelessWidget {
  const _LoopHeader({required this.vendor});
  final VendorPo vendor;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final delivered = vendor.items.where((i) => i.status == ItemStatus.delivered).length;
    final missing = vendor.items.where((i) => i.status == ItemStatus.missing).length;
    final pending = vendor.items.length - delivered - missing;
    final delPct = vendor.items.isEmpty ? 0.0 : delivered / vendor.items.length;
    final misPct = vendor.items.isEmpty ? 0.0 : missing / vendor.items.length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(vendor.supplierName),
          const SizedBox(height: 4),
          Text(t.itemLoopSubtitle, style: AppType.bodyMuted),
          const SizedBox(height: 12),
          SplitProgressBar(deliveredPct: delPct, missingPct: misPct, height: 7),
          const SizedBox(height: 10),
          Row(
            children: [
              _LegendDot(color: AppColors.accent, label: t.deliveredCount(delivered)),
              const SizedBox(width: 12),
              _LegendDot(color: AppColors.danger, label: t.missingCount(missing)),
              const SizedBox(width: 12),
              _LegendDot(color: AppColors.muted2, label: t.pendingCount(pending)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: AppType.mono10.copyWith(color: AppColors.muted)),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.vendor, required this.item});
  final VendorPo vendor;
  final VendorPoItem item;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final canAct = item.status == ItemStatus.inProgress || item.status == ItemStatus.pending;

    return AppCard(
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
                    Text(item.itemName, style: AppType.body.copyWith(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(
                      '${item.itemCode} · ${Fmt.quantity(item.quantity, item.unit)} · ${Fmt.money(item.totalPrice, decimals: true)}',
                      style: AppType.mono10.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              ItemStatusPill(item.status),
            ],
          ),
          if (canAct) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: t.captureNow,
                    variant: AppBtnVariant.primary,
                    leading: const Icon(Icons.photo_camera_outlined, size: 18),
                    height: 44,
                    onPressed: () => _capture(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: t.markMissing,
                    variant: AppBtnVariant.danger,
                    height: 44,
                    onPressed: () => _missing(context),
                  ),
                ),
              ],
            ),
          ],
          if (item.status == ItemStatus.delivered) ...[
            const SizedBox(height: 8),
            const AppChip(label: 'Verified · photo logged', tone: ChipTone.green),
          ],
        ],
      ),
    );
  }

  Future<void> _capture(BuildContext context) async {
    final t = AppL10n.of(context);
    final detail = context.read<VendorDetailProvider>();
    final step = detail.vendor?.currentStep;
    if (step == null) return;

    final fixFuture = context.read<LocationService>().currentFix();
    final file = await context.read<CameraService>().takePhoto();
    if (file == null || !context.mounted) return;
    final fix = await fixFuture;

    final preview = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _PhotoConfirmSheet(file: file, label: item.itemCode, gps: fix?.pretty),
    );
    if (preview != true || !context.mounted) return;

    final ok = await detail.uploadItemPhoto(
      itemId: item.id,
      stepId: step.id,
      file: file,
      lat: fix?.lat,
      lng: fix?.lng,
    );
    if (!ok || !context.mounted) return;
    final fresh = detail.vendor;
    final remaining =
        fresh?.items.where((i) => !i.status.isResolved).length ?? 0;
    final message = remaining == 0
        ? t.allItemsCaptured
        : t.capturedItem(item.itemCode, remaining);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _missing(BuildContext context) async {
    final t = AppL10n.of(context);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(t.markMissingTitle, style: AppType.h3),
              const SizedBox(height: 8),
              Text(t.markMissingBody, style: AppType.bodyMuted),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgDeep,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${item.itemCode} · ${item.itemName}',
                  style: AppType.mono11,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: t.cancel,
                      variant: AppBtnVariant.ghost,
                      onPressed: () => Navigator.pop(sheetContext, false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      label: t.confirm,
                      variant: AppBtnVariant.dark,
                      onPressed: () => Navigator.pop(sheetContext, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    if (ok != true || !context.mounted) return;
    final detail = context.read<VendorDetailProvider>();
    final success = await detail.markItemMissing(item.id);
    if (!success || !context.mounted) return;
    final remaining =
        detail.vendor?.items.where((i) => !i.status.isResolved).length ?? 0;
    final message = remaining == 0
        ? t.allItemsCaptured
        : t.markedMissingItem(item.itemCode, remaining);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PhotoConfirmSheet extends StatelessWidget {
  const _PhotoConfirmSheet({required this.file, required this.label, this.gps});
  final File file;
  final String label;
  final String? gps;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.file(file, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text(label, style: AppType.bodyLg)),
              if (gps != null) Text(gps!, style: AppType.mono10.copyWith(color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: t.retake,
                  variant: AppBtnVariant.ghost,
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  label: t.submit,
                  onPressed: () => Navigator.pop(context, true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoopBottom extends StatelessWidget {
  const _LoopBottom({required this.vendor});
  final VendorPo vendor;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final allDone = vendor.allItemsResolved;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: AppButton(
          label: allDone ? t.finalize : t.finalizeBlocked,
          variant: allDone ? AppBtnVariant.primary : AppBtnVariant.ghost,
          trailing: allDone ? const Icon(Icons.arrow_forward_rounded) : null,
          onPressed: allDone
              ? () => context.push(Routes.finalizePath(vendor.id))
              : null,
        ),
      ),
    );
  }
}
