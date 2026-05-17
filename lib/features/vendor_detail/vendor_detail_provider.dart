import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/errors/api_exception.dart';
import '../../core/utils/app_log.dart';
import '../../data/models/enums.dart';
import '../../data/models/proof_log.dart';
import '../../data/models/vendor_po.dart';
import '../../data/models/vendor_po_item.dart';
import '../../data/models/workflow_step.dart';
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
  // Items the user has successfully photographed in this session. We re-apply
  // DELIVERED locally on every hydrate because the backend doesn't always flip
  // the item status on photo upload.
  final Set<String> _locallyDelivered = <String>{};
  // Shipment-photo steps we've successfully uploaded a photo for. Backend
  // doesn't always set shipment_completed=true on next fetch, so we patch it
  // locally to ensure the workflow advances past the shipment step.
  final Set<String> _locallyCompletedShipmentSteps = <String>{};
  // Background upload queue used by the guided capture flow so the camera can
  // immediately advance to the next item while the previous photo uploads.
  final List<_PendingItemUpload> _queue = [];
  final List<_PendingItemUpload> _failed = [];
  bool _draining = false;

  int get pendingUploadCount => _queue.length + (_draining ? 1 : 0);
  int get failedUploadCount => _failed.length;
  bool get hasUploadActivity =>
      _queue.isNotEmpty || _draining || _failed.isNotEmpty;

  String? get vendorPoId => _vendorPoId;
  VendorPo? get vendor => _vendor;
  ProofHistory? get proofs => _proofs;
  LoadState get state => _state;
  String? get error => _error;
  bool get busy => _busy;

  Future<void> load(String vendorPoId) async {
    if (_vendorPoId != vendorPoId) {
      _locallyDelivered.clear();
      _locallyCompletedShipmentSteps.clear();
      _queue.clear();
      _failed.clear();
    }
    _vendorPoId = vendorPoId;
    _state = LoadState.loading;
    _error = null;
    notifyListeners();
    try {
      _vendor = await _fetchHydrated(vendorPoId);
      _state = LoadState.ready;
    } catch (e, st) {
      AppLog.error('VendorDetailProvider.load', e, st);
      _error = _readableError(e);
      _state = LoadState.error;
    }
    notifyListeners();
  }

  /// GET /vendor-pos/:id returns items but no steps, and /start returns
  /// neither. Fetch both in parallel and merge so currentStep is available.
  Future<VendorPo> _fetchHydrated(String vendorPoId) async {
    final results = await Future.wait([
      _repo.vendor(vendorPoId),
      _repo.steps(vendorPoId),
    ]);
    final v = results[0] as VendorPo;
    final rawSteps = (results[1] as List<WorkflowStep>)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final steps = _applyLocalShipmentComplete(rawSteps);
    AppLog.info(
      'VendorDetailProvider._fetchHydrated',
      'vendor=$vendorPoId status=${v.status} items=${v.items.length} '
          'steps=${steps.length} currentStepId=${v.currentStepId} '
          'localShipmentDone=$_locallyCompletedShipmentSteps',
    );
    String? currentStepId = v.currentStepId;
    // If the server still points at a shipment step we've locally completed,
    // advance to the next incomplete step instead of staying put.
    if (currentStepId != null &&
        _locallyCompletedShipmentSteps.contains(currentStepId)) {
      currentStepId = null;
    }
    if (currentStepId == null && steps.isNotEmpty) {
      final next = steps.firstWhere(
        (s) => !s.isComplete,
        orElse: () => steps.last,
      );
      currentStepId = next.id;
      AppLog.info(
        'VendorDetailProvider._fetchHydrated',
        'derived currentStepId=$currentStepId from steps',
      );
    }
    final items = _applyLocalDelivered(v.items);
    return v.copyWith(
      steps: steps,
      currentStepId: currentStepId,
      items: items,
    );
  }

  List<VendorPoItem> _applyLocalDelivered(List<VendorPoItem> items) {
    if (_locallyDelivered.isEmpty) return items;
    return items.map((i) {
      if (_locallyDelivered.contains(i.id) && !i.status.isResolved) {
        return i.copyWith(status: ItemStatus.delivered);
      }
      return i;
    }).toList();
  }

  List<WorkflowStep> _applyLocalShipmentComplete(List<WorkflowStep> steps) {
    if (_locallyCompletedShipmentSteps.isEmpty) return steps;
    return steps.map((s) {
      if (_locallyCompletedShipmentSteps.contains(s.id) && !s.shipmentCompleted) {
        return s.copyWith(shipmentCompleted: true);
      }
      return s;
    }).toList();
  }

  Future<void> loadProofs() async {
    if (_vendorPoId == null) return;
    try {
      _proofs = await _repo.proofs(_vendorPoId!);
      notifyListeners();
    } catch (e, st) {
      AppLog.error('VendorDetailProvider.loadProofs', e, st);
      _error = _readableError(e);
      notifyListeners();
    }
  }

  Future<bool> startVendor() => _wrap(() async {
        await _repo.start(_vendorPoId!);
        // The /start response is thin (no items/steps). Refetch full detail
        // so the next screen has items and a populated current step.
        _vendor = await _fetchHydrated(_vendorPoId!);
      });

  Future<bool> uploadShipmentPhoto({
    required String stepId,
    required File file,
    double? lat,
    double? lng,
    double? accuracyMeters,
  }) =>
      _wrap(() async {
        await _repo.shipmentPhoto(
          vendorPoId: _vendorPoId!,
          stepId: stepId,
          file: file,
          lat: lat,
          lng: lng,
          accuracyMeters: accuracyMeters,
        );
        // Backend doesn't reliably flip shipment_completed on the step, so
        // remember the upload locally and patch on every hydrate.
        _locallyCompletedShipmentSteps.add(stepId);
        AppLog.info('VendorDetailProvider.uploadShipmentPhoto',
            'optimistically marking step $stepId as shipmentCompleted');
        _vendor = await _fetchHydrated(_vendorPoId!);
      });

  Future<bool> uploadItemPhoto({
    required String itemId,
    required String stepId,
    required File file,
    double? lat,
    double? lng,
    double? accuracyMeters,
  }) =>
      _wrap(() async {
        await _repo.itemPhoto(
          vendorPoId: _vendorPoId!,
          itemId: itemId,
          stepId: stepId,
          file: file,
          lat: lat,
          lng: lng,
          accuracyMeters: accuracyMeters,
        );
        // Backend doesn't always flip the item to DELIVERED on photo upload.
        // A successful proof is the authoritative confirmation, so remember
        // the id and re-apply DELIVERED on every hydrate while this vendor
        // is loaded.
        _locallyDelivered.add(itemId);
        AppLog.info('VendorDetailProvider.uploadItemPhoto',
            'optimistically marking item $itemId as DELIVERED');
        _vendor = await _fetchHydrated(_vendorPoId!);
      });

  /// Adds a photo to the background upload queue and immediately marks the
  /// item as delivered locally so the guided capture screen can move on to the
  /// next item. The actual POST runs sequentially in [_drainQueue].
  void queueItemPhoto({
    required String itemId,
    required String stepId,
    required File file,
    double? lat,
    double? lng,
    double? accuracyMeters,
  }) {
    if (_vendorPoId == null) return;
    _locallyDelivered.add(itemId);
    _queue.add(_PendingItemUpload(
      vendorPoId: _vendorPoId!,
      itemId: itemId,
      stepId: stepId,
      file: file,
      lat: lat,
      lng: lng,
      accuracyMeters: accuracyMeters,
    ));
    // Reflect optimistic state in the current vendor snapshot right away.
    final v = _vendor;
    if (v != null) {
      _vendor = v.copyWith(items: _applyLocalDelivered(v.items));
    }
    notifyListeners();
    _drainQueue();
  }

  Future<void> retryFailedUploads() async {
    if (_failed.isEmpty) return;
    _queue.addAll(_failed);
    _failed.clear();
    notifyListeners();
    await _drainQueue();
  }

  Future<void> _drainQueue() async {
    if (_draining) return;
    _draining = true;
    notifyListeners();
    while (_queue.isNotEmpty) {
      final job = _queue.removeAt(0);
      notifyListeners();
      try {
        await _repo.itemPhoto(
          vendorPoId: job.vendorPoId,
          itemId: job.itemId,
          stepId: job.stepId,
          file: job.file,
          lat: job.lat,
          lng: job.lng,
          accuracyMeters: job.accuracyMeters,
        );
        AppLog.info('VendorDetailProvider._drainQueue',
            'uploaded item ${job.itemId}');
      } catch (e, st) {
        AppLog.error('VendorDetailProvider._drainQueue', e, st);
        _failed.add(job);
      }
      notifyListeners();
    }
    _draining = false;
    notifyListeners();
  }

  Future<bool> markItemMissing(String itemId) => _wrap(() async {
        await _repo.markMissing(vendorPoId: _vendorPoId!, itemId: itemId);
        _vendor = await _fetchHydrated(_vendorPoId!);
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
    } catch (e, st) {
      AppLog.error('VendorDetailProvider._wrap', e, st);
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

class _PendingItemUpload {
  _PendingItemUpload({
    required this.vendorPoId,
    required this.itemId,
    required this.stepId,
    required this.file,
    this.lat,
    this.lng,
    this.accuracyMeters,
  });
  final String vendorPoId;
  final String itemId;
  final String stepId;
  final File file;
  final double? lat;
  final double? lng;
  final double? accuracyMeters;
}
