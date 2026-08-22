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
import '../../data/models/sub_logistics.dart';
import '../../data/models/vendor_po.dart';
import '../../data/models/workflow_step.dart';
import '../../data/repositories/delivery_repository.dart';
import '../../l10n/app_l10n.dart';
import '../../routing/routes.dart';
import '../auth/auth_provider.dart';
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

  // Step-level assistant assignment (representative only).
  bool _isRep = false;
  bool _assignLoading = false;
  bool _assignBusy = false;
  List<SubLogisticsOfficer> _officers = const [];
  String? _assigneeId;
  String? _assigneeName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VendorListProvider>().load(widget.masterId);
      _isRep = context.read<AuthProvider>().user?.isRepresentative ?? false;
      if (_isRep) _loadAssignment();
    });
  }

  Future<void> _loadAssignment() async {
    setState(() => _assignLoading = true);
    final repo = context.read<DeliveryRepository>();
    try {
      final officers = await repo.subLogisticsOfficers();
      final a = await repo.stepAssignee(masterId: widget.masterId, stepId: widget.stepId);
      if (!mounted) return;
      // Prefer the name from the assignment; fall back to the officer list.
      String? name = a.officerName;
      if (name == null && a.officerId != null) {
        for (final o in officers) {
          if (o.id == a.officerId) {
            name = o.fullName;
            break;
          }
        }
      }
      setState(() {
        _officers = officers;
        _assigneeId = a.officerId;
        _assigneeName = name;
        _assignLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _assignLoading = false);
    }
  }

  Future<void> _pickAssistant() async {
    final choice = await showModalBottomSheet<_AssignChoice>(
      context: context,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AssistantPickerSheet(
        officers: _officers,
        selectedId: _assigneeId,
      ),
    );
    if (choice == null || !mounted) return;
    await _applyAssign(choice.officerId);
  }

  Future<void> _applyAssign(String? officerId) async {
    final t = AppL10n.of(context);
    final repo = context.read<DeliveryRepository>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _assignBusy = true);
    try {
      final r = await repo.assignStepAcrossVendors(
        masterId: widget.masterId,
        stepId: widget.stepId,
        assistantUserId: officerId,
      );
      await _loadAssignment();
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(
          officerId == null ? t.assignmentCleared : t.assignedToVendors(r.applied, r.total),
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('${t.assignmentSaveFailed} ($e)')));
    } finally {
      if (mounted) setState(() => _assignBusy = false);
    }
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
      // ITEM steps open the products page first (list of items + a capture
      // button); VENDOR steps are a single photo captured directly on the
      // shipment screen.
      if (level == StepLevel.item) {
        context.push(Routes.stepItemsPath(vendor.id, widget.stepId));
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
                        if (_isRep) ...[
                          const SizedBox(height: 14),
                          _AssignBanner(
                            loading: _assignLoading,
                            busy: _assignBusy,
                            assigneeName: _assigneeName,
                            onAssign: _assignBusy ? null : _pickAssistant,
                          ),
                        ],
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

/// Representative-only banner: shows who this step is assigned to (across all
/// vendors) and lets them assign/change — no per-vendor selection.
class _AssignBanner extends StatelessWidget {
  const _AssignBanner({
    required this.loading,
    required this.busy,
    required this.assigneeName,
    required this.onAssign,
  });
  final bool loading;
  final bool busy;
  final String? assigneeName;
  final VoidCallback? onAssign;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final has = assigneeName != null && assigneeName!.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgDeep,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: has ? AppColors.accentSoft : AppColors.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.person_outline_rounded,
                size: 19, color: has ? AppColors.accentInk : AppColors.muted),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.assigneeForStep,
                    style: AppType.mono10.copyWith(color: AppColors.muted, letterSpacing: 0.5)),
                const SizedBox(height: 3),
                loading
                    ? Text('…', style: AppType.body.copyWith(color: AppColors.muted))
                    : Text(
                        has ? assigneeName! : t.notAssigned,
                        style: AppType.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: has ? AppColors.ink : AppColors.muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AppButton(
            label: has ? t.changeAction : t.assignAssistant,
            variant: AppBtnVariant.ghost,
            full: false,
            loading: busy,
            onPressed: onAssign,
          ),
        ],
      ),
    );
  }
}

/// Result of the assistant picker sheet. [officerId] null means "unassign".
class _AssignChoice {
  const _AssignChoice(this.officerId);
  final String? officerId;
}

class _AssistantPickerSheet extends StatelessWidget {
  const _AssistantPickerSheet({required this.officers, required this.selectedId});
  final List<SubLogisticsOfficer> officers;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Eyebrow(t.selectAssistant),
            const SizedBox(height: 4),
            Text(t.assignAcrossVendorsHint, style: AppType.bodyMuted),
            const SizedBox(height: 12),
            if (officers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(t.noAssistantsAvailable, style: AppType.bodyMuted),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final o in officers)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          o.id == selectedId
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: o.id == selectedId ? AppColors.accentInk : AppColors.muted,
                        ),
                        title: Text(o.fullName, style: AppType.body),
                        subtitle: o.phone != null
                            ? Text(o.phone!, style: AppType.mono10.copyWith(color: AppColors.muted))
                            : null,
                        onTap: () => Navigator.of(context).pop(_AssignChoice(o.id)),
                      ),
                  ],
                ),
              ),
            const Divider(height: 20, color: AppColors.lineSoft),
            if (selectedId != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_off_outlined, color: AppColors.danger),
                title: Text(t.unassignedOption,
                    style: AppType.body.copyWith(color: AppColors.danger)),
                onTap: () => Navigator.of(context).pop(const _AssignChoice(null)),
              ),
          ],
        ),
      ),
    );
  }
}
