import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/api_exception.dart';
import '../../core/utils/app_log.dart';
import '../../data/api/offline_cache_store.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus { signedOut, signingIn, signedIn, error }

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repo, this._prefs, {OfflineCacheStore? cache}) : _cache = cache;
  final AuthRepository _repo;
  final SharedPreferences _prefs;
  final OfflineCacheStore? _cache;

  static const _userKey = 'auth_user';

  AuthStatus _status = AuthStatus.signedOut;
  User? _user;
  String? _error;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get error => _error;
  bool get isSignedIn => _status == AuthStatus.signedIn && _user != null;

  bool _hasCachedSession = false;

  /// A previous session is cached on this device (token + user) so the app can
  /// be entered offline without re-authenticating. Computed during [restore].
  bool get hasCachedSession => _hasCachedSession;

  User? _readCachedUser() {
    final raw = _prefs.getString(_userKey);
    if (raw == null) return null;
    try {
      return User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistUser(User? user) async {
    try {
      if (user == null) {
        await _prefs.remove(_userKey);
      } else {
        await _prefs.setString(_userKey, jsonEncode(user.toJson()));
      }
    } catch (_) {}
  }

  /// Detect whether a previous session (token + user) is saved on this device.
  /// Does NOT sign in — the caller decides: online, the user still logs in;
  /// offline, [continueOffline] enters with the saved session. Never throws so
  /// it can't block app startup.
  Future<void> restore() async {
    try {
      final hasToken = await _repo.hasStoredToken();
      final cached = _readCachedUser();
      _hasCachedSession = hasToken && cached != null;
    } catch (e, st) {
      AppLog.error('AuthProvider.restore', e, st);
      _hasCachedSession = false;
    }
    notifyListeners();
  }

  /// Explicitly enter the app with the saved session (used by the login
  /// screen's "Continue offline" action). Returns false if nothing is saved.
  bool continueOffline() {
    final cached = _readCachedUser();
    if (_hasCachedSession && cached != null) {
      _user = cached;
      _status = AuthStatus.signedIn;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> signIn({required String username, required String password}) async {
    _status = AuthStatus.signingIn;
    _error = null;
    notifyListeners();
    try {
      final user = await _repo.login(username: username, password: password);
      if (!user.canUseMobileApp) {
        _error = 'This account role cannot use the app';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
      _user = user;
      await _persistUser(user);
      _hasCachedSession = true;
      _status = AuthStatus.signedIn;
      notifyListeners();
      return true;
    } on ApiException catch (e, st) {
      AppLog.error('AuthProvider.signIn (ApiException)', e, st);
      _error = e.message;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e, st) {
      AppLog.error('AuthProvider.signIn', e, st);
      _error = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _repo.logout();
    } catch (e, st) {
      AppLog.error('AuthProvider.signOut', e, st);
    } finally {
      _user = null;
      await _persistUser(null);
      await _cache?.clear();
      _hasCachedSession = false;
      _status = AuthStatus.signedOut;
      notifyListeners();
    }
  }
}
