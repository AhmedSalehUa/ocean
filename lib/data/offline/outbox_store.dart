import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'outbox_op.dart';

/// Durable queue of pending write operations, persisted to shared_preferences.
/// Notifies listeners so the UI can show a pending/sync badge and the sync
/// center can list items.
class OutboxStore extends ChangeNotifier {
  OutboxStore(this._prefs);
  final SharedPreferences _prefs;

  static const _key = 'offline_outbox_v1';
  List<OutboxOp> _ops = [];

  List<OutboxOp> get ops => List.unmodifiable(_ops);
  int get pendingCount => _ops.where((o) => !o.failed).length;
  int get failedCount => _ops.where((o) => o.failed).length;
  bool get isEmpty => _ops.isEmpty;

  Future<void> load() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      _ops = list.map(OutboxOp.fromJson).toList();
    } catch (_) {
      _ops = [];
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      await _prefs.setString(_key, jsonEncode(_ops.map((o) => o.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> add(OutboxOp op) async {
    _ops.add(op);
    await _persist();
    notifyListeners();
  }

  OutboxOp? firstSendable() {
    for (final o in _ops) {
      if (!o.failed) return o;
    }
    return null;
  }

  Future<void> remove(String id) async {
    _ops.removeWhere((o) => o.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> update(OutboxOp op) async {
    final i = _ops.indexWhere((o) => o.id == op.id);
    if (i >= 0) _ops[i] = op;
    await _persist();
    notifyListeners();
  }

  /// Clear the "failed" flag so the op is retried on the next sync.
  Future<void> retry(String id) async {
    final i = _ops.indexWhere((o) => o.id == id);
    if (i >= 0) {
      _ops[i].error = null;
      _ops[i].attempts = 0;
      await _persist();
      notifyListeners();
    }
  }
}
