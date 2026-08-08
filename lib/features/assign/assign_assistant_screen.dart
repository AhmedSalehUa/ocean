import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/eyebrow.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/models/workflow_step.dart';
import '../../data/repositories/delivery_repository.dart';
import '../../l10n/app_l10n.dart';
import '../../services/locale_service.dart';
import '../dashboard/master_pos_provider.dart' show LoadState;
import '../vendor_detail/vendor_detail_provider.dart';
import 'assign_assistant_provider.dart';

/// Representative-only screen to assign a SUB_LOGISTICS_OFFICER a set of
/// steps within one Vendor PO. Steps come from the already-loaded
/// VendorDetailProvider; officers + current assignment load here.
class AssignAssistantScreen extends StatelessWidget {
  const AssignAssistantScreen({super.key, required this.vendorId});
  final String vendorId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => AssignAssistantProvider(ctx.read<DeliveryRepository>())..load(vendorId),
      child: _AssignAssistantView(vendorId: vendorId),
    );
  }
}

class _AssignAssistantView extends StatelessWidget {
  const _AssignAssistantView({required this.vendorId});
  final String vendorId;

  Future<void> _save(BuildContext context, {bool clear = false}) async {
    final t = AppL10n.of(context);
    final p = context.read<AssignAssistantProvider>();
    final messenger = ScaffoldMessenger.of(context);
    if (!clear && !p.canSave) {
      messenger.showSnackBar(SnackBar(content: Text(t.chooseAssistantAndSteps)));
      return;
    }
    final ok = await p.save(vendorId, clear: clear);
    if (!context.mounted) return;
    if (ok) {
      messenger.showSnackBar(
        SnackBar(content: Text(clear ? t.assignmentCleared : t.assignmentSaved)),
      );
      context.pop();
    } else {
      messenger.showSnackBar(SnackBar(content: Text(p.error ?? t.assignmentSaveFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final locale = context.watch<LocaleService>().locale.languageCode;
    final p = context.watch<AssignAssistantProvider>();
    final steps = context.watch<VendorDetailProvider>().vendor?.steps ?? const <WorkflowStep>[];

    return Scaffold(
      appBar: TrailTopBar(
        leading: RoundIconBtn(icon: Icons.chevron_left_rounded, onPressed: () => context.pop()),
        title: t.assignAssistantTitle,
      ),
      body: switch (p.state) {
        LoadState.loading || LoadState.idle =>
          const Center(child: CircularProgressIndicator(color: AppColors.accentInk)),
        LoadState.error => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(p.error ?? '—', textAlign: TextAlign.center, style: AppType.bodyLg),
            ),
          ),
        LoadState.ready => ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
            children: [
              Eyebrow(t.selectAssistant),
              const SizedBox(height: 8),
              if (p.officers.isEmpty)
                AppCard(child: Text(t.noAssistantsAvailable, style: AppType.bodyMuted))
              else
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      RadioListTile<String?>(
                        value: null,
                        groupValue: p.selectedOfficerId,
                        onChanged: (v) => p.selectOfficer(v),
                        activeColor: AppColors.accentInk,
                        title: Text(t.unassignedOption, style: AppType.body),
                      ),
                      for (final o in p.officers)
                        RadioListTile<String?>(
                          value: o.id,
                          groupValue: p.selectedOfficerId,
                          onChanged: (v) => p.selectOfficer(v),
                          activeColor: AppColors.accentInk,
                          title: Text(o.fullName, style: AppType.body),
                          subtitle: Text('@${o.username}', style: AppType.caption),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: Eyebrow(t.selectSteps)),
                  Text('${p.selectedStepIds.length}/${steps.length}',
                      style: AppType.mono10.copyWith(color: AppColors.muted)),
                ],
              ),
              const SizedBox(height: 8),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < steps.length; i++) ...[
                      CheckboxListTile(
                        value: p.selectedStepIds.contains(steps[i].id),
                        onChanged: (_) => p.toggleStep(steps[i].id),
                        activeColor: AppColors.accentInk,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(steps[i].nameFor(locale), style: AppType.body),
                        subtitle: Text(
                          _levelLabel(t, steps[i]),
                          style: AppType.caption.copyWith(color: AppColors.muted),
                        ),
                      ),
                      if (i < steps.length - 1)
                        const Divider(height: 1, color: AppColors.lineSoft),
                    ],
                  ],
                ),
              ),
            ],
          ),
      },
      bottomNavigationBar: p.state == LoadState.ready
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppButton(
                      label: t.saveAssignment,
                      loading: p.saving,
                      trailing: const Icon(Icons.check_rounded),
                      onPressed: p.saving ? null : () => _save(context),
                    ),
                    const SizedBox(height: 8),
                    AppButton(
                      label: t.clearAssignment,
                      variant: AppBtnVariant.ghost,
                      onPressed: p.saving ? null : () => _save(context, clear: true),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  String _levelLabel(AppL10n t, WorkflowStep s) => switch (s.stepLevel) {
        StepLevel.lpo => t.stepLevelLpo,
        StepLevel.item => t.stepLevelItem,
        StepLevel.vendor || StepLevel.unknown => t.stepLevelVendor,
      };
}
