import '../api/delivery_api.dart';
import '../models/user.dart';

class AuthRepository {
  AuthRepository(this._api);
  final DeliveryApi _api;

  Future<User> login({required String username, required String password}) async {
    final result = await _api.login(username: username, password: password);
    return result.user;
  }

  Future<User> me() => _api.me();
  Future<void> logout() => _api.logout();
}
