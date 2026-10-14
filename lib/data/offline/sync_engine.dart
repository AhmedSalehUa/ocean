import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/errors/api_exception.dart';
import '../../core/utils/app_log.dart';
import '../../services/connectivity_service.dart';
import '../api/delivery_api.dart';
import 'outbox_op.dart';
import 'outbox_store.dart';

/// Drains the outbox by replaying queued writes against the real API when the
/// device is online. Stops on a connectivity failure (retry later); marks an
/// op "failed" on a real error (4xx/validation) so it surfaces in the sync
/// center instead of blocking the queue forever.
class SyncEngine extends ChangeNotifier {
  SyncEngine({
    required DeliveryApi inner,
    required OutboxStore outbox,
    required ConnectivityService connectivity,
  })  : _inner = inner,
        _outbox = outbox,
        _conn = connectivity;

  final DeliveryApi _inner;
  final OutboxStore _outbox;
  final ConnectivityService _conn;

  bool _syncing = false;
  bool get syncing => _syncing;

  void start() {
    _conn.addListener(_onConnectivity);
    if (_conn.online) drain();
  }

  void _onConnectivity() {
    if (_conn.online) drain();
  }

  bool _isConnectivity(Object e) =>
      (e is ApiException && e.statusCode == null) ||
      e is SocketException ||
      e.toString().contains('SocketException');

  /// Flush all sendable ops in order. Safe to call repeatedly.
  Future<void> drain() async {
    if (_syncing || _conn.offline) return;
    _syncing = true;
    notifyListeners();
    try {
      while (true) {
        final op = _outbox.firstSendable();
        if (op == null) break;
        try {
          await _replay(op);
          if (op.filePath != null) {
            try {
              await File(op.filePath!).delete();
            } catch (_) {}
          }
          await _outbox.remove(op.id);
        } catch (e, st) {
          if (_isConnectivity(e)) {
            // Lost connection mid-drain — keep the op, try again later.
            break;
          }
          AppLog.error('SyncEngine.replay(${op.type.name})', e, st);
          op.attempts += 1;
          op.error = e is ApiException ? e.message : e.toString();
          await _outbox.update(op); // mark failed; skipped until retried
        }
      }
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  Future<void> _replay(OutboxOp op) async {
    final a = op.args;
    double? d(String k) => (a[k] as num?)?.toDouble();
    final file = op.filePath != null ? File(op.filePath!) : null;

    switch (op.type) {
      case OutboxType.vendorStepPhoto:
        await _inner.uploadShipmentPhoto(
            vendorPoId: a['vendorPoId'] as String,
            stepId: a['stepId'] as String,
            file: file!,
            lat: d('lat'),
            lng: d('lng'),
            accuracyMeters: d('acc'));
      case OutboxType.lpoStepPhoto:
        await _inner.uploadLpoPhoto(
            masterPoId: a['masterPoId'] as String,
            stepId: a['stepId'] as String,
            file: file!,
            lat: d('lat'),
            lng: d('lng'),
            accuracyMeters: d('acc'));
      case OutboxType.itemStepPhoto:
        await _inner.uploadItemPhoto(
            vendorPoId: a['vendorPoId'] as String,
            itemId: a['itemId'] as String,
            stepId: a['stepId'] as String,
            file: file!,
            lat: d('lat'),
            lng: d('lng'),
            accuracyMeters: d('acc'));
      case OutboxType.itemMissing:
        await _inner.markItemMissing(
            vendorPoId: a['vendorPoId'] as String, itemId: a['itemId'] as String);
      case OutboxType.itemRejected:
        await _inner.markItemRejected(
            vendorPoId: a['vendorPoId'] as String,
            itemId: a['itemId'] as String,
            stepId: a['stepId'] as String);
      case OutboxType.startVendor:
        await _inner.startVendorPo(a['vendorPoId'] as String);
      case OutboxType.finalizeVendor:
        await _inner.finalizeVendorPo(a['vendorPoId'] as String);
      case OutboxType.finalizeMaster:
        await _inner.finalizeMaster(a['masterPoId'] as String);
      case OutboxType.assignSubLogistics:
        await _inner.putSubLogisticsAssignment(
            vendorPoId: a['vendorPoId'] as String,
            subLogisticsUserId: a['subLogisticsUserId'] as String?,
            workflowStepIds: (a['workflowStepIds'] as List? ?? const []).cast<String>());
      case OutboxType.deliveryNote:
        await _inner.uploadDeliveryNote(masterPoId: a['masterPoId'] as String, file: file!);
    }
  }

  @override
  void dispose() {
    _conn.removeListener(_onConnectivity);
    super.dispose();
  }
}
