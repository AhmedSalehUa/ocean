import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/eyebrow.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/models/master_po.dart';
import '../../data/models/master_step.dart';
import '../../data/models/vendor_po.dart';
import '../../data/models/workflow_step.dart';
import '../../l10n/app_l10n.dart';
import '../../routing/routes.dart';
import '../dashboard/master_pos_provider.dart';
import '../vendor_detail/vendor_detail_provider.dart';
import '../vendor_list/vendor_list_provider.dart';
import '../vendor_list/widgets/vendor_po_card.dart';

/// Vendors under a master PO for one chosen workflow step. Tapping a vendor
/// jumps straight into capturing *that step* for the vendor — the shipment
/// screen for VENDOR/LPO steps, the guided items screen for ITEM steps — so
/// the step list is never shown again once a vendor is picked.
class StepVendorsScreen extends StatefulWidget {
  const StepVendorsScreen({super.key, required this.masterId, required this.stepId});
  final String masterId;
  final String stepId;

  @override
  State<StepVendorsScreen> createState() => _StepVendorsScreenState();
}

class _StepVendorsScreenState extends State<StepVendorsScreen> {
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VendorListProvider>().load(widget.masterId);
    });
  }

  MasterPo? get _master {
    for (final m in context.read<MasterPosProvider>().items) {
      if (m.id == widget.masterId) return m;
    }
    return null;
  }

  MasterStep? get _step {
    for (final s in _master?.steps ?? const <MasterStep>[]) {
      if (s.id == widget.stepId) return s;
    }
    return null;
  }

  Future<void> _openVendor(VendorPo vendor, StepLevel level) async {
    if (_opening) return;
    setState(() => _opening = true);
    final detail = context.read<VendorDetailProvider>();
    try {
      await detail.load(vendor.id);
      detail.pinStep(widget.stepId);
      if (!mounted) return;
      // ITEM steps open the per-item capture loop; VENDOR/LPO steps are a
      // single photo captured on the shipment screen (which routes LPO to the
      // master-scoped endpoint).
      if (level == StepLevel.item) {
        context.push(Routes.guidedItemsPath(vendor.id));
      } else {
        context.push(Routes.shipmentPath(vendor.id));
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final locale = t.locale.languageCode;
    final p = context.watch<VendorListProvider>();
    final step = _step;
    final level = step?.stepLevel ?? StepLevel.unknown;
    final stepName = step?.nameFor(locale) ?? t.masterStepsTitle;

    return Scaffold(
      appBar: TrailTopBar(
        leading: RoundIconBtn(
          icon: Icons.chevron_left_rounded,
          onPressed: () => context.pop(),
        ),
        title: stepName,
        trailing: RoundIconBtn(icon: Icons.more_horiz_rounded, onPressed: () {}),
      ),
      body: Stack(
        children: [
          p.state == LoadState.loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.accentInk))
              : p.state == LoadState.error
                  ? _ErrorState(message: p.error ?? '—')
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
                      children: [
                        _StepHeader(step: step, localeCode: locale),
                        const SizedBox(height: 18),
                        Eyebrow('${t.vendorPos} · ${p.items.length}'),
                        const SizedBox(height: 10),
                        for (final v in p.items) ...[
                          VendorPoCard(
                            vendor: v,
                            onTap: () => _openVendor(v, level),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (p.items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Text('—',
                                textAlign: TextAlign.center, style: AppType.bodyMuted),
                          ),
                      ],
                    ),
          if (_opening)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x66000000),
                child: Center(child: CircularProgressIndicator(color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small banner naming the chosen step + its level so the user knows what
/// they're capturing across the vendors below.
class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step, required this.localeCode});
  final MasterStep? step;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = step;
    final level = switch (s?.stepLevel) {
      StepLevel.lpo => t.stepLevelLpo,
      StepLevel.item => t.stepLevelItem,
      _ => t.stepLevelVendor,
    };
    // Tell the user how this step is captured per vendor: an ITEM step is
    // photographed for every item; a VENDOR step is a single photo across the
    // whole vendor's products.
    final isItem = s?.stepLevel == StepLevel.item;
    final scopeLabel = isItem ? t.captureScopeItem : t.captureScopeVendor;
    final scopeIcon = isItem ? Icons.inventory_2_outlined : Icons.collections_outlined;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(t.masterStepsEyebrow),
        const SizedBox(height: 4),
        Text(s?.nameFor(localeCode) ?? t.masterStepsTitle, style: AppType.h2),
        const SizedBox(height: 10),
        AppChip(label: level, tone: ChipTone.dark),
        const SizedBox(height: 12),
        // Capture-scope banner.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.bgDeep,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lineSoft),
          ),
          child: Row(
            children: [
              Icon(scopeIcon, size: 16, color: AppColors.ink2),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  scopeLabel,
                  style: AppType.caption.copyWith(
                    color: AppColors.ink2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(t.chooseVendorSubtitle, style: AppType.bodyMuted),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, style: AppType.body.copyWith(color: AppColors.danger)),
      ),
    );
  }
}
