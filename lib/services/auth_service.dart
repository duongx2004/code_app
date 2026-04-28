import 'package:shared_preferences/shared_preferences.dart';
import 'package:code_app/services/backend_api.dart';

class AuthService {
  static const String _keyUser = 'logged_in_user';
  static const String _keyDisplayName = 'logged_in_display_name';
  static const String _keyIsAdmin = 'logged_in_is_admin';

  Future<void> saveLoggedInUser(String email, String displayName, {required bool isAdmin}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, email);
    await prefs.setString(_keyDisplayName, displayName);
    await prefs.setBool(_keyIsAdmin, isAdmin);
  }

  Future<String?> getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUser);
  }

  Future<String?> getDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    final displayName = prefs.getString(_keyDisplayName);
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
    await prefs.remove(_keyDisplayName);
    await prefs.remove(_keyIsAdmin);
  }

  Future<bool> isLoggedIn() async {
    final user = await getLoggedInUser();
    return user != null && user.isNotEmpty;
  }

  Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsAdmin) ?? false;
  }

  Future<bool> register(String email, String password, String displayName) async {
    if (email.isEmpty || password.isEmpty || displayName.isEmpty) return false;

    try {
      final response = await BackendApi.post('/api/register', {
        'email': email,
        'password': password,
        'display_name': displayName,
      });
      return response['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await BackendApi.post('/api/login', {
        'email': email,
        'password': password,
      });
      if (response['success'] == true) {
        final displayName = response['display_name'] as String? ?? '';
        final rawIsAdmin = response['is_admin'];
        final isAdmin = rawIsAdmin == true || rawIsAdmin == 1 || rawIsAdmin == '1' || rawIsAdmin == 'true';
        await saveLoggedInUser(email, displayName, isAdmin: isAdmin);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateProfile(String newDisplayName, {String? newPassword}) async {
    final currentEmail = await getLoggedInUser();
    if (currentEmail == null) return false;

    final payload = <String, dynamic>{
      'email': currentEmail,
      'display_name': newDisplayName,
    };
    if (newPassword != null && newPassword.isNotEmpty) {
      payload['password'] = newPassword;
    }

    try {
      final response = await BackendApi.post('/api/update_profile', payload);
      if (response['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyDisplayName, newDisplayName);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
