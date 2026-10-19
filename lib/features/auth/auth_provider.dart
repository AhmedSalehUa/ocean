import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/api_exception.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus { signedOut, signingIn, signedIn, error }

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repo, this._prefs);
  final AuthRepository _repo;
  final SharedPreferences _prefs;

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

  /// Restore a signed-in session from the saved token + user on startup — no
  /// network required, so returning users land straight in the app and keep
  /// working offline. A saved session is trusted; the server is only consulted
  /// (and can sign the user out) when a real request later returns 401.
  Future<void> restore() async {
    final hasToken = await _repo.hasStoredToken();
    final cached = _readCachedUser();
    _hasCachedSession = hasToken && cached != null;
    if (_hasCachedSession) {
      _user = cached;
      _status = AuthStatus.signedIn;
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
      if (!user.isRepresentative) {
        _error = 'Only REPRESENTATIVE users can use this app';
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
    } on ApiException catch (e) {
      _error = e.message;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _repo.logout();
    } finally {
      _user = null;
      await _persistUser(null);
      _hasCachedSession = false;
      _status = AuthStatus.signedOut;
      notifyListeners();
    }
  }
}
