import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/errors/api_exception.dart';
import '../../data/models/proof_log.dart';
import '../../data/models/vendor_po.dart';
import '../../data/repositories/delivery_repository.dart';
import '../dashboard/master_pos_provider.dart';

/// Drives the whole flow under one Vendor PO — detail, capture, items, finalize.
class VendorDetailProvider extends ChangeNotifier {
  VendorDetailProvider(this._repo);
  final DeliveryRepository _repo;

  String? _vendorPoId;
  VendorPo? _vendor;
  ProofHistory? _proofs;
  LoadState _state = LoadState.idle;
  String? _error;
  bool _busy = false;

  String? get vendorPoId => _vendorPoId;
  VendorPo? get vendor => _vendor;
  ProofHistory? get proofs => _proofs;
  LoadState get state => _state;
  String? get error => _error;
  bool get busy => _busy;

  Future<void> load(String vendorPoId) async {
    _vendorPoId = vendorPoId;
    _state = LoadState.loading;
    _error = null;
    notifyListeners();
    try {
      final v = await _repo.vendor(vendorPoId);
      _vendor = v;
      _state = LoadState.ready;
    } catch (e) {
      _error = _readableError(e);
      _state = LoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadProofs() async {
    if (_vendorPoId == null) return;
    try {
      _proofs = await _repo.proofs(_vendorPoId!);
      notifyListeners();
    } catch (e) {
      _error = _readableError(e);
      notifyListeners();
    }
  }

  Future<bool> startVendor() => _wrap(() async {
        final updated = await _repo.start(_vendorPoId!);
        _vendor = updated;
      });

  Future<bool> uploadShipmentPhoto({
    required String stepId,
    required File file,
    double? lat,
    double? lng,
  }) =>
      _wrap(() async {
        await _repo.shipmentPhoto(
          vendorPoId: _vendorPoId!,
          stepId: stepId,
          file: file,
          lat: lat,
          lng: lng,
        );
        // refresh the vendor so steps + current_step_id are current
        _vendor = await _repo.vendor(_vendorPoId!);
      });

  Future<bool> uploadItemPhoto({
    required String itemId,
    required String stepId,
    required File file,
    double? lat,
    double? lng,
  }) =>
      _wrap(() async {
        await _repo.itemPhoto(
          vendorPoId: _vendorPoId!,
          itemId: itemId,
          stepId: stepId,
          file: file,
          lat: lat,
          lng: lng,
        );
        _vendor = await _repo.vendor(_vendorPoId!);
      });

  Future<bool> markItemMissing(String itemId) => _wrap(() async {
        await _repo.markMissing(vendorPoId: _vendorPoId!, itemId: itemId);
        _vendor = await _repo.vendor(_vendorPoId!);
      });

  Future<bool> finalize() => _wrap(() async {
        final updated = await _repo.finalize(_vendorPoId!);
        _vendor = updated;
      });

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<bool> _wrap(Future<void> Function() action) async {
    if (_vendorPoId == null) return false;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      _busy = false;
      notifyListeners();
      return true;
    } catch (e) {
      _busy = false;
      _error = _readableError(e);
      notifyListeners();
      return false;
    }
  }

  String _readableError(Object e) {
    if (e is ApiException) return e.message;
    return e.toString();
  }
}
