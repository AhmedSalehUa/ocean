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
import '../../core/widgets/top_bar.dart';
import '../../data/models/assistant_task.dart';
import '../../data/models/workflow_step.dart';
import '../../l10n/app_l10n.dart';
import '../../routing/routes.dart';
import '../../services/locale_service.dart';
import '../auth/auth_provider.dart';
import '../dashboard/master_pos_provider.dart' show LoadState;
import '../vendor_detail/vendor_detail_provider.dart';
import 'assistant_tasks_provider.dart';

/// Home screen for a SUB_LOGISTICS_OFFICER: the flat list of assigned steps.
class AssistantHomeScreen extends StatefulWidget {
  const AssistantHomeScreen({super.key});

  @override
  State<AssistantHomeScreen> createState() => _AssistantHomeScreenState();
}

class _AssistantHomeScreenState extends State<AssistantHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AssistantTasksProvider>().refresh();
    });
  }

  Future<void> _openTask(BuildContext context, AssistantTask task) async {
    final t = AppL10n.of(context);
    if (task.stepLevel == StepLevel.lpo) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.lpoNotSupportedYet)),
      );
      return;
    }
    final detail = context.read<VendorDetailProvider>();
    // Load the vendor so the capture screen has items + steps, then pin the
    // assigned step so it becomes the active target regardless of server
    // current-step state.
    await detail.load(task.vendorPoId);
    detail.pinStep(task.workflowStepId);
    if (!context.mounted) return;
    if (task.stepLevel == StepLevel.item) {
      context.push(Routes.guidedItemsPath(task.vendorPoId));
    } else {
      context.push(Routes.shipmentPath(task.vendorPoId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final p = context.watch<AssistantTasksProvider>();
    final auth = context.watch<AuthProvider>();
    final locale = context.watch<LocaleService>().locale.languageCode;
    final user = auth.user;

    return Scaffold(
      appBar: TrailTopBar(
        leading: RoundIconBtn(
          icon: Icons.logout_rounded,
          tooltip: t.logout,
          onPressed: () async {
            await context.read<AuthProvider>().signOut();
            if (context.mounted) context.go(Routes.login);
          },
        ),
        title: t.assistantHomeTitle,
        trailing: RoundIconBtn(
          icon: Icons.translate,
          tooltip: t.toggleLanguage,
          onPressed: () => context.read<LocaleService>().toggle(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => p.refresh(),
        color: AppColors.accentInk,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            if (user != null) ...[
              Eyebrow(user.fullName),
              const SizedBox(height: 4),
              Text(t.assistantHomeTitle, style: AppType.h2),
              const SizedBox(height: 16),
            ],
            if (p.state == LoadState.loading)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(child: CircularProgressIndicator(color: AppColors.accentInk)),
              )
            else if (p.state == LoadState.error)
              _ErrorBox(message: p.error ?? '—', onRetry: p.refresh)
            else if (p.tasks.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Center(
                  child: Text(t.assistantNoTasks, style: AppType.bodyMuted),
                ),
              )
            else ...[
              Eyebrow('${t.assistantTasksEyebrow} · ${p.tasks.length}'),
              const SizedBox(height: 10),
              for (final task in p.tasks) ...[
                _TaskCard(
                  task: task,
                  localeCode: locale,
                  onTap: () => _openTask(context, task),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.localeCode, required this.onTap});
  final AssistantTask task;
  final String localeCode;
  final VoidCallback onTap;

  ({String label, ChipTone tone, IconData icon}) _levelBadge(AppL10n t) {
    return switch (task.stepLevel) {
      StepLevel.lpo => (label: t.stepLevelLpo, tone: ChipTone.dark, icon: Icons.description_outlined),
      StepLevel.item => (label: t.stepLevelItem, tone: ChipTone.warn, icon: Icons.inventory_2_outlined),
      StepLevel.vendor ||
      StepLevel.unknown =>
        (label: t.stepLevelVendor, tone: ChipTone.soft, icon: Icons.local_shipping_outlined),
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final badge = _levelBadge(t);
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(badge.icon, size: 18, color: AppColors.ink2),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.stepNameFor(localeCode),
                  style: AppType.bodyLg.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              AppChip(label: badge.label, tone: badge.tone),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${task.masterPoNumber} · ${task.supplierName}',
            style: AppType.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (task.vesselName != null && task.vesselName!.trim().isNotEmpty)
                _MetaChip(icon: Icons.directions_boat_outlined, label: task.vesselName!),
              if (task.portName != null && task.portName!.trim().isNotEmpty)
                _MetaChip(icon: Icons.anchor_outlined, label: task.portName!),
              if (task.etaDate != null)
                _MetaChip(icon: Icons.event_available_outlined, label: Fmt.date(task.etaDate!)),
              if (task.stepLevel == StepLevel.item && task.targets.isNotEmpty)
                _MetaChip(
                  icon: Icons.photo_camera_outlined,
                  label: t.itemsToCapture(task.targets.length),
                ),
            ],
          ),
          if (task.representativeName != null && task.representativeName!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${t.assistantRepLabel}: ${task.representativeName}',
              style: AppType.caption.copyWith(color: AppColors.muted),
            ),
          ],
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
          Text(label, style: AppType.mono11.copyWith(color: AppColors.ink2)),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 40),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: AppType.body.copyWith(color: AppColors.danger)),
          const SizedBox(height: 12),
          AppButton(label: t.retry, variant: AppBtnVariant.dark, full: false, onPressed: onRetry),
        ],
      ),
    );
  }
}
