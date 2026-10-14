import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists raw API read responses (the `{success, data, ...}` envelope) so
/// GET requests can be served from disk when the device is offline.
/// Phase 1 of the offline plan — read cache only.
class OfflineCacheStore {
  OfflineCacheStore(this._prefs);
  final SharedPreferences _prefs;

  static const _prefix = 'offline_cache:';

  String _k(String key) => '$_prefix$key';

  /// Stores [data] (a decoded JSON Map/List) under [key] with a timestamp.
  Future<void> put(String key, Object data) async {
    try {
      await _prefs.setString(
        _k(key),
        jsonEncode({'at': DateTime.now().toIso8601String(), 'data': data}),
      );
    } catch (_) {
      // Caching is best-effort; never let it break a live request.
    }
  }

  /// Returns the cached payload for [key] and when it was stored, or null.
  ({dynamic data, DateTime? at})? get(String key) {
    final raw = _prefs.getString(_k(key));
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return (data: m['data'], at: DateTime.tryParse(m['at'] as String? ?? ''));
    } catch (_) {
      return null;
    }
  }

  /// Clears all cached read responses (e.g. on sign-out).
  Future<void> clear() async {
    for (final key in _prefs.getKeys().where((k) => k.startsWith(_prefix))) {
      await _prefs.remove(key);
    }
  }
}
