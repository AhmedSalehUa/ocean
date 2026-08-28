import 'package:flutter/foundation.dart';

import '../../core/utils/app_log.dart';
import '../../data/models/master_po.dart';
import '../../data/repositories/delivery_repository.dart';

enum LoadState { idle, loading, ready, error }

class MasterPosProvider extends ChangeNotifier {
  MasterPosProvider(this._repo);
  final DeliveryRepository _repo;

  LoadState _state = LoadState.idle;
  List<MasterPo> _items = const [];
  String? _error;
  bool _assistantMode = false;

  LoadState get state => _state;
  List<MasterPo> get items => _items;
  String? get error => _error;

  /// When the signed-in user is a SUB_LOGISTICS_OFFICER, the list is narrowed
  /// to only the master POs they have an assigned mission in.
  void setAssistantMode(bool value) => _assistantMode = value;

  List<MasterPo> get open =>
      _items.where((m) => m.deliveredVendorPoCount < m.vendorPoCount).toList();
  List<MasterPo> get closed =>
      _items.where((m) => m.deliveredVendorPoCount >= m.vendorPoCount).toList();

  Future<void> refresh() async {
    _state = LoadState.loading;
    _error = null;
    notifyListeners();
    try {
      final masters = await _repo.listMasters();
      if (_assistantMode) {
        // Keep only masters the assistant has a mission in (defensive — the
        // backend already scopes this, but guarantee it client-side too).
        final missionMasterIds =
            (await _repo.assistantTasks()).map((t) => t.masterPoId).toSet();
        _items = masters.where((m) => missionMasterIds.contains(m.id)).toList();
      } else {
        _items = masters;
      }
      _state = LoadState.ready;
    } catch (e, st) {
      AppLog.error('MasterPosProvider.refresh', e, st);
      _error = e.toString();
      _state = LoadState.error;
    }
    notifyListeners();
  }
}
