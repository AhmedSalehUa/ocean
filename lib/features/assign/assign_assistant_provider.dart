import 'package:flutter/foundation.dart';

import '../../core/utils/app_log.dart';
import '../../data/models/sub_logistics.dart';
import '../../data/repositories/delivery_repository.dart';
import '../dashboard/master_pos_provider.dart' show LoadState;

/// Drives the representative's "assign assistant" screen for one Vendor PO:
/// loads the officer list + current assignment, tracks the pending selection,
/// and saves via PUT.
class AssignAssistantProvider extends ChangeNotifier {
  AssignAssistantProvider(this._repo);
  final DeliveryRepository _repo;

  LoadState _state = LoadState.idle;
  String? _error;
  bool _saving = false;

  List<SubLogisticsOfficer> _officers = const [];
  String? _selectedOfficerId;
  final Set<String> _selectedStepIds = <String>{};

  LoadState get state => _state;
  String? get error => _error;
  bool get saving => _saving;
  List<SubLogisticsOfficer> get officers => _officers;
  String? get selectedOfficerId => _selectedOfficerId;
  Set<String> get selectedStepIds => _selectedStepIds;

  bool get canSave => _selectedOfficerId != null && _selectedStepIds.isNotEmpty;

  Future<void> load(String vendorPoId) async {
    _state = LoadState.loading;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repo.subLogisticsOfficers(),
        _repo.subLogisticsAssignment(vendorPoId),
      ]);
      _officers = results[0] as List<SubLogisticsOfficer>;
      final current = results[1] as SubLogisticsAssignment;
      _selectedOfficerId = current.officerId;
      _selectedStepIds
        ..clear()
        ..addAll(current.stepIds);
      _state = LoadState.ready;
    } catch (e, st) {
      AppLog.error('AssignAssistantProvider.load', e, st);
      _error = e.toString();
      _state = LoadState.error;
    }
    notifyListeners();
  }

  void selectOfficer(String? officerId) {
    _selectedOfficerId = officerId;
    notifyListeners();
  }

  void toggleStep(String stepId) {
    if (!_selectedStepIds.remove(stepId)) _selectedStepIds.add(stepId);
    notifyListeners();
  }

  /// Saves the current selection. Returns true on success. When [clear] is
  /// true (or nothing is selected) it unassigns the Vendor PO entirely.
  Future<bool> save(String vendorPoId, {bool clear = false}) async {
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      final unassign = clear || _selectedOfficerId == null || _selectedStepIds.isEmpty;
      await _repo.saveSubLogisticsAssignment(
        vendorPoId: vendorPoId,
        subLogisticsUserId: unassign ? null : _selectedOfficerId,
        workflowStepIds: unassign ? const [] : _selectedStepIds.toList(),
      );
      if (unassign) {
        _selectedOfficerId = null;
        _selectedStepIds.clear();
      }
      _saving = false;
      notifyListeners();
      return true;
    } catch (e, st) {
      AppLog.error('AssignAssistantProvider.save', e, st);
      _error = e.toString();
      _saving = false;
      notifyListeners();
      return false;
    }
  }
}
