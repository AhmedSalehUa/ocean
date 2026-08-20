import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/errors/api_exception.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/app_log.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/eyebrow.dart';
import '../../core/widgets/progress_bar.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/models/master_po.dart';
import '../../data/models/master_step.dart';
import '../../data/models/workflow_step.dart';
import '../../data/repositories/delivery_repository.dart';
import '../../l10n/app_l10n.dart';
import '../../routing/routes.dart';
import '../../services/camera_service.dart';
import '../../services/location_service.dart';
import '../auth/auth_provider.dart';
import '../dashboard/master_pos_provider.dart';

/// First page after tapping a master PO: the master's workflow steps
/// (spec §5 `steps` array) in a modern list. Choosing a step drills into the
/// vendors for that step (wired next).
class MasterStepsScreen extends StatelessWidget {
  const MasterStepsScreen({super.key, required this.masterId});
  final String masterId;

  MasterPo? _master(BuildContext context) {
    for (final m in context.read<MasterPosProvider>().items) {
      if (m.id == masterId) return m;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final locale = t.locale.languageCode;
    // Subscribe so the list reflects status changes (e.g. after an LPO
    // capture refreshes the masters).
    context.watch<MasterPosProvider>();
    final master = _master(context);
    final steps = master?.steps ?? const <MasterStep>[];
    final isRep = context.read<AuthProvider>().user?.isRepresentative ?? false;

    return Scaffold(
      appBar: TrailTopBar(
        leading: RoundIconBtn(
          icon: Icons.chevron_left_rounded,
          onPressed: () => context.pop(),
        ),
        title: master?.masterPoNumber ?? t.masterStepsTitle,
        trailing: RoundIconBtn(icon: Icons.more_horiz_rounded, onPressed: () {}),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            if (steps.isEmpty)
              _EmptyState(message: t.noStepsYet)
            else ...[
              Eyebrow('${t.masterStepsEyebrow} · ${steps.length}'),
              const SizedBox(height: 4),
              Text(t.chooseStepSubtitle, style: AppType.bodyMuted),
              const SizedBox(height: 16),
              for (var i = 0; i < steps.length; i++) ...[
                _StepCard(
                  step: steps[i],
                  localeCode: locale,
                  onTap: () => _openStep(context, steps[i]),
                ),
                const SizedBox(height: 12),
              ],
            ],
            // Representative-only entry into assignment. Kept out of the
            // capture path: it opens the vendor list → vendor detail, where
            // the assign-assistant action lives.
            if (isRep) ...[
              const SizedBox(height: 4),
              _AssignAssistantCard(
                onTap: () => context.push(Routes.assignVendorsPath(masterId)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openStep(BuildContext context, MasterStep step) {
    // A not-applicable step has no targets under this master → nothing to do.
    if (!step.status.isApplicable) return;
    // LPO is captured once at the Master-PO level — there's no per-vendor
    // breakdown, so open the camera straight away and skip the vendor list.
    if (step.stepLevel == StepLevel.lpo) {
      _captureLpo(context, step);
      return;
    }
    context.push(Routes.stepVendorsPath(masterId, step.id));
  }

  /// Direct-to-camera LPO capture: snap a photo, attach GPS, and post it to
  /// the master-scoped lpo-steps endpoint. Mirrors the master card's LPO
  /// strip, minus the source picker.
  Future<void> _captureLpo(BuildContext context, MasterStep step) async {
    final t = AppL10n.of(context);
    final repo = context.read<DeliveryRepository>();
    final location = context.read<LocationService>();
    final camera = context.read<CameraService>();
    final masters = context.read<MasterPosProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final file = await camera.takePhoto();
    if (file == null || !context.mounted) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      duration: const Duration(minutes: 1),
      content: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(t.uploadingLpoProof)),
        ],
      ),
    ));
    try {
      final fix = await location.currentFix();
      await repo.lpoPhoto(
        masterPoId: masterId,
        stepId: step.id,
        file: file,
        lat: fix?.lat,
        lng: fix?.lng,
        accuracyMeters: fix?.accuracyMeters,
      );
      messenger.hideCurrentSnackBar();
      await masters.refresh();
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(t.lpoProofUploaded)));
    } on ApiException catch (e, st) {
      messenger.hideCurrentSnackBar();
      AppLog.error('MasterStepsScreen._captureLpo', e, st);
      messenger.showSnackBar(SnackBar(content: Text('${t.lpoProofUploadFailed} (${e.message})')));
    } catch (e, st) {
      messenger.hideCurrentSnackBar();
      AppLog.error('MasterStepsScreen._captureLpo', e, st);
      messenger.showSnackBar(SnackBar(content: Text('${t.lpoProofUploadFailed} ($e)')));
    }
  }
}

/// One workflow step row: level tile, name, status, and a rolled-up progress
/// bar across the whole master PO.
class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.localeCode,
    required this.onTap,
  });

  final MasterStep step;
  final String localeCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final applicable = step.status.isApplicable;
    final level = _levelStyle(t);
    final status = _statusStyle(t);

    return Opacity(
      opacity: applicable ? 1 : 0.55,
      child: AppCard(
        onTap: applicable ? onTap : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Level tile with the step's ordinal.
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: step.status.isCompleted ? AppColors.accentSoft : AppColors.bgDeep,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    level.icon,
                    size: 20,
                    color: step.status.isCompleted ? AppColors.accentInk : AppColors.ink2,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              step.nameFor(localeCode),
                              style: AppType.bodyLg.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AppChip(label: status.label, tone: status.tone),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(level.label, style: AppType.mono10.copyWith(color: AppColors.muted)),
                          const _Dot(),
                          Text(
                            step.isRequired ? t.stepRequired : t.stepOptional,
                            style: AppType.mono10.copyWith(color: AppColors.muted),
                          ),
                          if (step.isFinalStep) ...[
                            const _Dot(),
                            Text(t.stepFinal,
                                style: AppType.mono10.copyWith(color: AppColors.muted)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (applicable) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                ],
              ],
            ),
            if (applicable && step.targetCount > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SimpleProgressBar(
                      value: step.progress,
                      color: step.status.isCompleted ? AppColors.accent : AppColors.accentInk,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    t.stepTargetsProgress(step.completedCount, step.targetCount),
                    style: AppType.mono10.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  ({String label, IconData icon}) _levelStyle(AppL10n t) {
    return switch (step.stepLevel) {
      StepLevel.lpo => (label: t.stepLevelLpo, icon: Icons.description_outlined),
      StepLevel.item => (label: t.stepLevelItem, icon: Icons.inventory_2_outlined),
      StepLevel.vendor ||
      StepLevel.unknown =>
        (label: t.stepLevelVendor, icon: Icons.local_shipping_outlined),
    };
  }

  ({String label, ChipTone tone}) _statusStyle(AppL10n t) {
    return switch (step.status) {
      MasterStepStatus.completed => (label: t.stepStatusCompleted, tone: ChipTone.green),
      MasterStepStatus.inProgress => (label: t.stepStatusInProgress, tone: ChipTone.warn),
      MasterStepStatus.pending => (label: t.stepStatusPending, tone: ChipTone.neutral),
      MasterStepStatus.notApplicable ||
      MasterStepStatus.unknown =>
        (label: t.stepStatusNotApplicable, tone: ChipTone.soft),
    };
  }
}

/// Representative-only shortcut into per-vendor assistant assignment. Styled
/// distinctly from the workflow steps since it's a management action, not a
/// capture step.
class _AssignAssistantCard extends StatelessWidget {
  const _AssignAssistantCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.bgDeep,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.person_add_alt_1_outlined,
                size: 20, color: AppColors.ink2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.assignAssistant,
                  style: AppType.bodyLg.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(t.assignAssistantSubtitle, style: AppType.caption.copyWith(color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) => Text(
        '·',
        style: AppType.mono10.copyWith(color: AppColors.muted),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timeline_outlined, size: 40, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(message, style: AppType.bodyMuted, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
