/// An assistant account (SUB_LOGISTICS_OFFICER) the representative can assign
/// steps to, from `GET /api/delivery/mobile/sub-logistics-officers`.
class SubLogisticsOfficer {
  final String id;
  final String fullName;
  final String username;
  final String? phone;

  const SubLogisticsOfficer({
    required this.id,
    required this.fullName,
    required this.username,
    this.phone,
  });

  factory SubLogisticsOfficer.fromJson(Map<String, dynamic> json) => SubLogisticsOfficer(
        id: json['id'] as String,
        fullName: (json['full_name'] as String?) ?? (json['username'] as String? ?? ''),
        username: (json['username'] as String?) ?? '',
        phone: json['phone'] as String?,
      );
}

/// The current assistant assignment on a Vendor PO, from
/// `GET /api/delivery/mobile/vendor-pos/:id/sub-logistics-assignments`.
/// Tolerant of a few response shapes since the exact envelope may vary.
class SubLogisticsAssignment {
  final String? officerId;
  final String? officerName;
  final List<String> stepIds;

  const SubLogisticsAssignment({
    this.officerId,
    this.officerName,
    this.stepIds = const [],
  });

  bool get hasAssignment => officerId != null && stepIds.isNotEmpty;

  static SubLogisticsAssignment fromData(dynamic data) {
    String? id;
    String? name;
    final steps = <String>{};

    void takeOfficer(Map<String, dynamic> m) {
      id ??= (m['sub_logistics_user_id'] ??
          m['sub_logistics_officer_id'] ??
          m['user_id'] ??
          m['id']) as String?;
      final nested = m['sub_logistics_officer'] ?? m['officer'] ?? m['user'];
      if (nested is Map<String, dynamic>) {
        id ??= nested['id'] as String?;
        name ??= (nested['full_name'] ?? nested['username']) as String?;
      }
      name ??= (m['full_name'] ?? m['officer_name']) as String?;
    }

    void takeSteps(dynamic v) {
      if (v is List) {
        for (final e in v) {
          if (e is String) {
            steps.add(e);
          } else if (e is Map<String, dynamic>) {
            final sid = (e['workflow_step_id'] ?? e['step_id'] ?? e['id']) as String?;
            if (sid != null) steps.add(sid);
          }
        }
      }
    }

    if (data is Map<String, dynamic>) {
      takeOfficer(data);
      takeSteps(data['workflow_step_ids'] ?? data['step_ids']);
      takeSteps(data['assignments'] ?? data['steps']);
    } else if (data is List) {
      for (final e in data) {
        if (e is Map<String, dynamic>) {
          takeOfficer(e);
          takeSteps(e['workflow_step_ids'] ?? e['step_ids']);
          final sid = (e['workflow_step_id'] ?? e['step_id']) as String?;
          if (sid != null) steps.add(sid);
        }
      }
    }

    return SubLogisticsAssignment(officerId: id, officerName: name, stepIds: steps.toList());
  }
}
