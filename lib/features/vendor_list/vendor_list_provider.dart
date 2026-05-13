import 'package:flutter/foundation.dart';

import '../../core/utils/app_log.dart';
import '../../data/models/vendor_po.dart';
import '../../data/repositories/delivery_repository.dart';
import '../dashboard/master_pos_provider.dart';

class VendorListProvider extends ChangeNotifier {
  VendorListProvider(this._repo);
  final DeliveryRepository _repo;

  LoadState _state = LoadState.idle;
  List<VendorPo> _items = const [];
  String _masterPoNumber = '';
  String? _error;
  String? _masterId;

  LoadState get state => _state;
  List<VendorPo> get items => _items;
  String get masterPoNumber => _masterPoNumber;
  String? get error => _error;
  String? get masterId => _masterId;

  Future<void> load(String masterId) async {
    _masterId = masterId;
    _state = LoadState.loading;
    _error = null;
    notifyListeners();
    try {
      final r = await _repo.listVendors(masterId);
      _items = r.vendors;
      _masterPoNumber = r.masterPoNumber;
      _state = LoadState.ready;
    } catch (e, st) {
      AppLog.error('VendorListProvider.load', e, st);
      _error = e.toString();
      _state = LoadState.error;
    }
    notifyListeners();
  }
}
