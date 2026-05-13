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

  LoadState get state => _state;
  List<MasterPo> get items => _items;
  String? get error => _error;

  List<MasterPo> get open =>
      _items.where((m) => m.deliveredVendorPoCount < m.vendorPoCount).toList();
  List<MasterPo> get closed =>
      _items.where((m) => m.deliveredVendorPoCount >= m.vendorPoCount).toList();

  Future<void> refresh() async {
    _state = LoadState.loading;
    _error = null;
    notifyListeners();
    try {
      _items = await _repo.listMasters();
      _state = LoadState.ready;
    } catch (e, st) {
      AppLog.error('MasterPosProvider.refresh', e, st);
      _error = e.toString();
      _state = LoadState.error;
    }
    notifyListeners();
  }
}
