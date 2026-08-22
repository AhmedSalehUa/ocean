import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/eyebrow.dart';
import '../../data/models/sub_logistics.dart';
import '../../data/repositories/delivery_repository.dart';
import '../../l10n/app_l10n.dart';

/// Result of the assistant picker sheet. [officerId] null means "unassign".
class AssignChoice {
  const AssignChoice(this.officerId);
  final String? officerId;
}

/// Loads the assistant list + the step's current assignee, shows the picker,
/// and applies the choice to the step across ALL vendors of the master (no
/// per-vendor selection). Returns true when an assignment change was applied
/// (so callers can refresh any assignee display).
Future<bool> pickAndAssignStep(
  BuildContext context, {
  required String masterId,
  required String stepId,
}) async {
  final t = AppL10n.of(context);
  final repo = context.read<DeliveryRepository>();
  final messenger = ScaffoldMessenger.of(context);

  List<SubLogisticsOfficer> officers;
  String? currentId;
  try {
    officers = await repo.subLogisticsOfficers();
    currentId = (await repo.stepAssignee(masterId: masterId, stepId: stepId)).officerId;
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('${t.assignmentSaveFailed} ($e)')));
    return false;
  }
  if (!context.mounted) return false;

  final choice = await showModalBottomSheet<AssignChoice>(
    context: context,
    backgroundColor: AppColors.bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => AssistantPickerSheet(officers: officers, selectedId: currentId),
  );
  if (choice == null || !context.mounted) return false;

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
        Expanded(child: Text(t.saveAssignment)),
      ],
    ),
  ));
  try {
    final r = await repo.assignStepAcrossVendors(
      masterId: masterId,
      stepId: stepId,
      assistantUserId: choice.officerId,
    );
    messenger.hideCurrentSnackBar();
    if (!context.mounted) return true;
    messenger.showSnackBar(SnackBar(
      content: Text(
        choice.officerId == null ? t.assignmentCleared : t.assignedToVendors(r.applied, r.total),
      ),
    ));
    return true;
  } catch (e) {
    messenger.hideCurrentSnackBar();
    if (context.mounted) {
      messenger.showSnackBar(SnackBar(content: Text('${t.assignmentSaveFailed} ($e)')));
    }
    return false;
  }
}

/// Radio-style list of assistants (+ an unassign row when one is set).
class AssistantPickerSheet extends StatelessWidget {
  const AssistantPickerSheet({super.key, required this.officers, required this.selectedId});
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
                        onTap: () => Navigator.of(context).pop(AssignChoice(o.id)),
                      ),
                  ],
                ),
              ),
            if (selectedId != null) ...[
              const Divider(height: 20, color: AppColors.lineSoft),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_off_outlined, color: AppColors.danger),
                title: Text(t.unassignedOption,
                    style: AppType.body.copyWith(color: AppColors.danger)),
                onTap: () => Navigator.of(context).pop(const AssignChoice(null)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
