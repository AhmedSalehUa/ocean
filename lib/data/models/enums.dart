/// Vendor PO lifecycle.
enum PoStatus { newPo, inProgress, fullyDelivered, partiallyDelivered }

extension PoStatusX on PoStatus {
  String get wire => switch (this) {
        PoStatus.newPo => 'NEW',
        PoStatus.inProgress => 'IN_PROGRESS',
        PoStatus.fullyDelivered => 'FULLY_DELIVERED',
        PoStatus.partiallyDelivered => 'PARTIALLY_DELIVERED',
      };

  static PoStatus parse(String? value) {
    return switch (value) {
      'NEW' => PoStatus.newPo,
      'IN_PROGRESS' => PoStatus.inProgress,
      'FULLY_DELIVERED' => PoStatus.fullyDelivered,
      'PARTIALLY_DELIVERED' => PoStatus.partiallyDelivered,
      _ => PoStatus.newPo,
    };
  }
}

/// Individual item resolution state.
enum ItemStatus { pending, inProgress, delivered, missing }

extension ItemStatusX on ItemStatus {
  String get wire => switch (this) {
        ItemStatus.pending => 'PENDING',
        ItemStatus.inProgress => 'IN_PROGRESS',
        ItemStatus.delivered => 'DELIVERED',
        ItemStatus.missing => 'MISSING',
      };

  bool get isResolved => this == ItemStatus.delivered || this == ItemStatus.missing;

  static ItemStatus parse(String? value) {
    return switch (value) {
      'PENDING' => ItemStatus.pending,
      'IN_PROGRESS' => ItemStatus.inProgress,
      'DELIVERED' => ItemStatus.delivered,
      'MISSING' => ItemStatus.missing,
      _ => ItemStatus.pending,
    };
  }
}

/// Master PO aggregate status (server-recomputed).
enum MasterStatus { open, inProgress, fullyDelivered, partiallyDelivered, closed }

extension MasterStatusX on MasterStatus {
  static MasterStatus parse(String? value) {
    return switch (value) {
      'NEW' => MasterStatus.open,
      'IN_PROGRESS' => MasterStatus.inProgress,
      'FULLY_DELIVERED' => MasterStatus.fullyDelivered,
      'PARTIALLY_DELIVERED' => MasterStatus.partiallyDelivered,
      'CLOSED' => MasterStatus.closed,
      _ => MasterStatus.inProgress,
    };
  }

  String get wire => switch (this) {
        MasterStatus.open => 'NEW',
        MasterStatus.inProgress => 'IN_PROGRESS',
        MasterStatus.fullyDelivered => 'FULLY_DELIVERED',
        MasterStatus.partiallyDelivered => 'PARTIALLY_DELIVERED',
        MasterStatus.closed => 'CLOSED',
      };
}
