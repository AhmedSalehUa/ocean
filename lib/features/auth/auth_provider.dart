import 'package:flutter/foundation.dart';

import '../../core/errors/api_exception.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus { signedOut, signingIn, signedIn, error }

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repo);
  final AuthRepository _repo;

  AuthStatus _status = AuthStatus.signedOut;
  User? _user;
  String? _error;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get error => _error;
  bool get isSignedIn => _status == AuthStatus.signedIn && _user != null;

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
      _status = AuthStatus.signedOut;
      notifyListeners();
    }
  }
}
