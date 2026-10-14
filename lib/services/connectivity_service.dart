import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Tracks whether the device has a network interface, driving the offline
/// banner and the outbox sync triggers. Interface presence (not true internet
/// reachability) is enough here: actual request failures are handled by the
/// read cache and the outbox retry logic.
class ConnectivityService extends ChangeNotifier {
  ConnectivityService() {
    _init();
  }

  final Connectivity _conn = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _online = true;

  bool get online => _online;
  bool get offline => !_online;

  Future<void> _init() async {
    try {
      _apply(await _conn.checkConnectivity());
    } catch (_) {
      // Assume online if the check fails; failures surface via requests.
    }
    _sub = _conn.onConnectivityChanged.listen(_apply);
  }

  void _apply(List<ConnectivityResult> results) {
    final next = results.any((r) => r != ConnectivityResult.none);
    if (next != _online) {
      _online = next;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
