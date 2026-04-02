import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _keyUser = 'logged_in_user';
  static const String _keyDisplayName = 'logged_in_display_name';
  static const String _keyUsers = 'registered_users_json'; // Changed key to avoid conflict with old format

  Future<void> saveLoggedInUser(String email, String displayName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, email);
    await prefs.setString(_keyDisplayName, displayName);
  }

  Future<String?> getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUser);
  }

  Future<String?> getDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDisplayName);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
    await prefs.remove(_keyDisplayName);
  }

  Future<bool> isLoggedIn() async {
    final user = await getLoggedInUser();
    return user != null && user.isNotEmpty;
  }

  Future<Map<String, dynamic>> _getUsersMap() async {
    final prefs = await SharedPreferences.getInstance();
    final usersString = prefs.getString(_keyUsers);
    if (usersString == null || usersString.isEmpty) return {};
    try {
      return json.decode(usersString) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  Future<bool> register(String email, String password, String displayName) async {
    if (email.isEmpty || password.isEmpty || displayName.isEmpty) return false;
    
    final users = await _getUsersMap();
    if (users.containsKey(email)) return false;

    users[email] = {
      'password': password,
      'displayName': displayName,
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsers, json.encode(users));
    return true;
  }

  Future<bool> login(String email, String password) async {
    final users = await _getUsersMap();
    if (users.containsKey(email) && users[email]['password'] == password) {
      await saveLoggedInUser(email, users[email]['displayName']);
      return true;
    }
    return false;
  }

  Future<bool> updateProfile(String newDisplayName, {String? newPassword}) async {
    final currentEmail = await getLoggedInUser();
    if (currentEmail == null) return false;

    final users = await _getUsersMap();
    if (!users.containsKey(currentEmail)) return false;

    if (newPassword != null && newPassword.isNotEmpty) {
      users[currentEmail]['password'] = newPassword;
    }
    users[currentEmail]['displayName'] = newDisplayName;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsers, json.encode(users));
    await prefs.setString(_keyDisplayName, newDisplayName);
    return true;
  }
}
