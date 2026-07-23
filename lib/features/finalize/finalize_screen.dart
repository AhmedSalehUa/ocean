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
import '../../data/models/enums.dart';
import '../../data/models/vendor_po.dart';
import '../../l10n/app_l10n.dart';
import '../../routing/routes.dart';
import '../vendor_detail/vendor_detail_provider.dart';

class FinalizeScreen extends StatefulWidget {
  const FinalizeScreen({super.key, required this.vendorId});
  final String vendorId;
  @override
  State<FinalizeScreen> createState() => _FinalizeScreenState();
}

class _FinalizeScreenState extends State<FinalizeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<VendorDetailProvider>();
      if (p.vendor?.id != widget.vendorId) p.load(widget.vendorId);
    });
  }

  Future<void> _submit() async {
    final p = context.read<VendorDetailProvider>();
    final ok = await p.finalize();
    if (!ok || !mounted) return;
    final v = p.vendor;
    if (v == null) return;
    context.replace(Routes.handoffPath(v.id));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final p = context.watch<VendorDetailProvider>();
    final v = p.vendor;

    return Scaffold(
      appBar: TrailTopBar(
        leading: RoundIconBtn(icon: Icons.chevron_left_rounded, onPressed: () => context.pop()),
        title: t.finalizeTitle,
      ),
      body: v == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentInk))
          : _FinalizeBody(vendor: v),
      bottomNavigationBar: v == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: AppButton(
                  label: v.readyToFinalize
                      ? t.confirmFinalDelivery
                      : (v.allItemsResolved ? t.finalizeBlockedSteps : t.finalizeBlocked),
                  loading: p.busy,
                  variant: v.readyToFinalize ? AppBtnVariant.primary : AppBtnVariant.ghost,
                  trailing: v.readyToFinalize ? const Icon(Icons.check_rounded) : null,
                  onPressed: v.readyToFinalize ? _submit : null,
                ),
              ),
            ),
    );
  }
}

class _FinalizeBody extends StatelessWidget {
  const _FinalizeBody({required this.vendor});
  final VendorPo vendor;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final delivered = vendor.items.where((i) => i.status == ItemStatus.delivered).length;
    final missing = vendor.items.where((i) => i.status == ItemStatus.missing).length;
    final outcome = missing == 0 ? t.fullyDelivered : t.partiallyDelivered;
    final outcomeTone = missing == 0 ? ChipTone.green : ChipTone.warn;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
      children: [
        Eyebrow(vendor.vendorRef ?? ''),
        const SizedBox(height: 4),
        Text(vendor.supplierName, style: AppType.h2),
        const SizedBox(height: 8),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Eyebrow(t.finalizeTitle),
                  const Spacer(),
                  AppChip(label: outcome, tone: outcomeTone),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                t.finalizeBody(
                  delivered: delivered,
                  missing: missing,
                  total: vendor.items.length,
                  outcome: outcome,
                ),
                style: AppType.bodyMuted,
              ),
              if (vendor.etaDate != null || vendor.portName != null) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.lineSoft),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (vendor.etaDate != null)
                      Expanded(
                        child: _MetaCell(
                          label: t.etaDate,
                          value: Fmt.relativeDay(
                            vendor.etaDate!,
                            locale: t.isAr ? 'ar' : 'en',
                          ),
                        ),
                      ),
                    if (vendor.portName != null)
                      Expanded(
                        child: _MetaCell(
                          label: t.portName,
                          value: vendor.portName!,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Eyebrow('${t.items} · ${vendor.items.length}'),
        const SizedBox(height: 10),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
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
                            const SizedBox(height: 2),
                            Text(
                              vendor.items[i].itemCode,
                              style: AppType.mono10.copyWith(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      ItemStatusPill(vendor.items[i].status),
                    ],
                  ),
                ),
                if (i < vendor.items.length - 1)
                  const Divider(height: 1, color: AppColors.lineSoft),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaCell extends StatelessWidget {
  const _MetaCell({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: AppType.mono10.copyWith(color: AppColors.muted, letterSpacing: 1.2)),
        const SizedBox(height: 4),
        Text(value, style: AppType.body.copyWith(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
