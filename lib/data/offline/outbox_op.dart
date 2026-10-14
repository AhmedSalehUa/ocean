/// A durable, queued write operation (outbox pattern). Created when a write
/// can't reach the server; replayed by the sync engine once back online.
enum OutboxType {
  vendorStepPhoto,
  lpoStepPhoto,
  itemStepPhoto,
  itemMissing,
  itemRejected,
  startVendor,
  finalizeVendor,
  finalizeMaster,
  assignSubLogistics,
  deliveryNote,
}

OutboxType _typeFrom(String s) =>
    OutboxType.values.firstWhere((t) => t.name == s, orElse: () => OutboxType.itemStepPhoto);

class OutboxOp {
  OutboxOp({
    required this.id,
    required this.type,
    required this.args,
    this.filePath,
    required this.createdAt,
    this.attempts = 0,
    this.error,
  });

  final String id;
  final OutboxType type;

  /// Scalar args needed to replay: ids, stepId, lat/lng, workflow_step_ids…
  final Map<String, dynamic> args;

  /// Local path of the file to upload (already converted to its final form,
  /// e.g. the merged PDF), copied to permanent storage.
  final String? filePath;

  final DateTime createdAt;
  int attempts;

  /// Last non-connectivity failure (4xx/validation). When set the op is
  /// "needs attention" and is skipped by auto-sync until retried.
  String? error;

  bool get failed => error != null;

  String? get vendorPoId => args['vendorPoId'] as String?;
  String? get masterPoId => args['masterPoId'] as String?;
  String? get stepId => args['stepId'] as String?;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'args': args,
        'filePath': filePath,
        'createdAt': createdAt.toIso8601String(),
        'attempts': attempts,
        'error': error,
      };

  factory OutboxOp.fromJson(Map<String, dynamic> j) => OutboxOp(
        id: j['id'] as String,
        type: _typeFrom(j['type'] as String),
        args: Map<String, dynamic>.from(j['args'] as Map? ?? const {}),
        filePath: j['filePath'] as String?,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
        attempts: (j['attempts'] as num?)?.toInt() ?? 0,
        error: j['error'] as String?,
      );

  /// Short human label for the sync center.
  String get label => switch (type) {
        OutboxType.vendorStepPhoto => 'Vendor step photo',
        OutboxType.lpoStepPhoto => 'LPO step photo',
        OutboxType.itemStepPhoto => 'Item photo',
        OutboxType.itemMissing => 'Mark item missing',
        OutboxType.itemRejected => 'Reject item',
        OutboxType.startVendor => 'Start vendor PO',
        OutboxType.finalizeVendor => 'Finalize vendor PO',
        OutboxType.finalizeMaster => 'Finish order',
        OutboxType.assignSubLogistics => 'Assign assistant',
        OutboxType.deliveryNote => 'Upload delivery note',
      };
}
