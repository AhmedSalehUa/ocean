import 'workflow_step.dart';

/// Aggregate status of a workflow step across a whole Master PO, as returned
/// inline in each master's `steps` array by `GET /mobile/master-pos`
/// (spec §5). Unlike a per-Vendor-PO step, the counts here are rolled up
/// over every visible target under the master.
enum MasterStepStatus { completed, inProgress, pending, notApplicable, unknown }

extension MasterStepStatusX on MasterStepStatus {
  static MasterStepStatus parse(String? value) {
    return switch (value?.toLowerCase()) {
      'completed' => MasterStepStatus.completed,
      'in_progress' => MasterStepStatus.inProgress,
      'pending' => MasterStepStatus.pending,
      'not_applicable' => MasterStepStatus.notApplicable,
      _ => MasterStepStatus.unknown,
    };
  }

  bool get isCompleted => this == MasterStepStatus.completed;
  bool get isInProgress => this == MasterStepStatus.inProgress;
  bool get isPending => this == MasterStepStatus.pending;

  /// A `not_applicable` step has no targets at this level under the master,
  /// so there are no vendors to drill into.
  bool get isApplicable => this != MasterStepStatus.notApplicable;
}

class MasterStep {
  final String id;
  final String nameEn;
  final String nameAr;
  final StepLevel stepLevel;
  final int sortOrder;
  final bool isRequired;
  final bool isFinalStep;
  final String? activationRule;
  final MasterStepStatus status;
  final bool isCompleted;
  final int targetCount;
  final int completedCount;
  final DateTime? lastPhotoAt;
  final DateTime? completedAt;

  const MasterStep({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.stepLevel,
    this.sortOrder = 0,
    this.isRequired = true,
    this.isFinalStep = false,
    this.activationRule,
    this.status = MasterStepStatus.unknown,
    this.isCompleted = false,
    this.targetCount = 0,
    this.completedCount = 0,
    this.lastPhotoAt,
    this.completedAt,
  });

  String nameFor(String localeCode) => localeCode.startsWith('ar') ? nameAr : nameEn;

  /// 0..1 completion for the progress bar. When the step carries no target
  /// count, fall back to the binary completed flag.
  double get progress {
    if (targetCount <= 0) return isCompleted ? 1 : 0;
    final v = completedCount / targetCount;
    return v.clamp(0, 1).toDouble();
  }

  factory MasterStep.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) =>
        v is int ? v : (v is String ? int.tryParse(v) ?? 0 : (v as num?)?.toInt() ?? 0);
    DateTime? date(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());

    return MasterStep(
      id: (json['id'] ?? json['workflow_step_id'] ?? '') as String,
      nameEn: (json['name_en'] as String?) ?? '',
      nameAr: (json['name_ar'] as String?) ?? '',
      stepLevel: StepLevelX.parse(json['step_level'] as String?),
      sortOrder: asInt(json['sort_order']),
      isRequired: json['is_required'] as bool? ?? true,
      isFinalStep: json['is_final_step'] as bool? ?? false,
      activationRule: json['activation_rule'] as String?,
      status: MasterStepStatusX.parse(json['status'] as String?),
      isCompleted: json['is_completed'] as bool? ?? false,
      targetCount: asInt(json['target_count']),
      completedCount: asInt(json['completed_count']),
      lastPhotoAt: date(json['last_photo_at']),
      completedAt: date(json['completed_at']),
    );
  }
}
