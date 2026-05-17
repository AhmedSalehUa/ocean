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
import '../../l10n/app_l10n.dart';
import '../../routing/routes.dart';
import '../vendor_detail/vendor_detail_provider.dart';

/// Shown after a workflow step's uploads complete. Refetches the vendor PO
/// (status + steps) and offers the user a button to continue to the next
/// capture screen — or to finalize when there are no more steps.
class StepDoneScreen extends StatefulWidget {
  const StepDoneScreen({
    super.key,
    required this.vendorId,
    required this.completedStepId,
  });
  final String vendorId;
  final String completedStepId;

  @override
  State<StepDoneScreen> createState() => _StepDoneScreenState();
}

class _StepDoneScreenState extends State<StepDoneScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = context.read<VendorDetailProvider>();
      if (p.vendor?.id != widget.vendorId) {
        await p.load(widget.vendorId);
      } else {
        await p.refreshVendor();
      }
    });
  }

  WorkflowStep? _completedStep(VendorDetailProvider p) {
    final steps = p.vendor?.steps ?? const <WorkflowStep>[];
    for (final s in steps) {
      if (s.id == widget.completedStepId) return s;
    }
    return null;
  }

  void _continue(VendorDetailProvider p) {
    final v = p.vendor;
    if (v == null) return;
    final next = v.currentStep;
    // If we're already on the final step (or no further requirements) → finalize.
    if (next == null || next.isFinalStep ||
        (!next.requiresShipmentPhoto && !next.requiresItemPhoto)) {
      context.replace(Routes.finalizePath(v.id));
      return;
    }
    if (next.requiresShipmentPhoto && !next.shipmentCompleted) {
      context.replace(Routes.shipmentPath(v.id));
      return;
    }
    if (next.requiresItemPhoto) {
      context.replace(Routes.guidedItemsPath(v.id));
      return;
    }
    // Defensive fallback.
    context.replace(Routes.finalizePath(v.id));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final p = context.watch<VendorDetailProvider>();
    final v = p.vendor;
    final locale = Localizations.localeOf(context).languageCode;
    final completed = _completedStep(p);
    final stepName = completed?.nameFor(locale) ?? '';

    final next = v?.currentStep;
    final goingToFinalize = next == null ||
        next.isFinalStep ||
        (!next.requiresShipmentPhoto && !next.requiresItemPhoto);
    final ctaLabel =
        goingToFinalize ? t.stepDoneFinalize : t.stepDoneContinue;

    final pendingUploads = p.pendingUploadCount;
    final failedUploads = p.failedUploadCount;
    final blocked = pendingUploads > 0 || failedUploads > 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: TrailTopBar(
        leading: RoundIconBtn(
          icon: Icons.chevron_left_rounded,
          onPressed: () => context.pop(),
        ),
        title: t.stepDoneTitle,
      ),
      body: v == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accentInk))
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: const BoxDecoration(
                          color: AppColors.accentSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: AppColors.accentInk, size: 44),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Eyebrow(v.vendorRef ?? v.supplierName),
                    ),
                    const SizedBox(height: 6),
                    Text(t.stepDoneTitle,
                        textAlign: TextAlign.center, style: AppType.h2),
                    const SizedBox(height: 6),
                    Text(
                      t.stepDoneSubtitle(stepName.isEmpty ? '—' : stepName),
                      textAlign: TextAlign.center,
                      style: AppType.bodyMuted,
                    ),
                    const SizedBox(height: 24),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Eyebrow(t.stepCurrent),
                          const SizedBox(height: 6),
                          Text(
                            next?.nameFor(locale) ?? t.finalizeTitle,
                            style: AppType.bodyLg,
                          ),
                        ],
                      ),
                    ),
                    if (pendingUploads > 0) ...[
                      const SizedBox(height: 12),
                      _StatusBanner(
                        icon: Icons.cloud_upload_outlined,
                        text: t.stepDoneAwaitingUploads,
                        tone: _BannerTone.info,
                      ),
                    ],
                    if (failedUploads > 0) ...[
                      const SizedBox(height: 12),
                      _StatusBanner(
                        icon: Icons.error_outline,
                        text: t.stepDoneFailedUploads(failedUploads),
                        tone: _BannerTone.warn,
                      ),
                      const SizedBox(height: 8),
                      AppButton(
                        label: t.retry,
                        variant: AppBtnVariant.ghost,
                        onPressed: () => p.retryFailedUploads(),
                      ),
                    ],
                    const Spacer(),
                    AppButton(
                      label: ctaLabel,
                      loading: p.busy,
                      trailing: const Icon(Icons.arrow_forward_rounded),
                      onPressed: blocked ? null : () => _continue(p),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

enum _BannerTone { info, warn }

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.icon,
    required this.text,
    required this.tone,
  });
  final IconData icon;
  final String text;
  final _BannerTone tone;

  @override
  Widget build(BuildContext context) {
    final bg = tone == _BannerTone.warn
        ? AppColors.warnSoft
        : AppColors.accentSoft;
    final fg = tone == _BannerTone.warn ? AppColors.warnInk : AppColors.accentInk;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppType.body.copyWith(color: fg))),
        ],
      ),
    );
  }
}
