import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../api/auth_api.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient client;
  final AuthApi _authApi = AuthApi();

  String? userName;
  String? fullName;
  String? repCode;
  bool isLoading = false;
  String? errorMessage;

  AuthProvider(this.client);

  bool get isLoggedIn => userName != null;

  /// What the dashboard/menu call the user - the account's full name when
  /// the login reply had one, else the username.
  String get displayName {
    final f = fullName?.trim();
    return (f != null && f.isNotEmpty) ? f : (userName ?? '');
  }

  Future<void> restoreSession() async {
    // Login (vaximobileapi) issues no token, so the persisted username is
    // the session.
    final u = await client.userName;
    if (u != null) {
      userName = u;
      fullName = await client.fullName;
      repCode = await client.repCode;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _authApi.login(username, password);
      // Drop any token left over from the old vaxiCSR.Api login.
      await client.clearToken();
      await client.saveUserName(result.userName);
      await client.saveFullName(result.fullName);
      await client.saveRepCode(result.repCode);
      userName = result.userName;
      fullName = result.fullName;
      repCode = result.repCode;
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await client.clearToken();
    await client.clearUserName();
    await client.saveFullName(null);
    await client.saveRepCode(null);
    userName = null;
    fullName = null;
    repCode = null;
    notifyListeners();
  }
}
