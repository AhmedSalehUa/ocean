import 'package:shared_preferences/shared_preferences.dart';

/// Tiny key→JSON store for the last successful response of each GET endpoint,
/// backed by [SharedPreferences] so it survives app restarts. Used by
/// `HttpDeliveryApi._getJson` to serve last-synced data when the network is
/// unreachable (offline).
class OfflineCacheStore {
  OfflineCacheStore(this._prefs);
  final SharedPreferences _prefs;

  static const _prefix = 'offline_cache:';

  String? get(String key) {
    try {
      return _prefs.getString('$_prefix$key');
    } catch (_) {
      return null;
    }
  }

  Future<void> put(String key, String value) async {
    try {
      await _prefs.setString('$_prefix$key', value);
    } catch (_) {}
  }

  /// Drop every cached endpoint (e.g. on sign-out so the next user can't see
  /// the previous user's data offline).
  Future<void> clear() async {
    try {
      final keys = _prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
      for (final k in keys) {
        await _prefs.remove(k);
      }
    } catch (_) {}
  }
}
