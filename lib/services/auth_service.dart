import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _keyUser = 'logged_in_user';
  static const String _keyDisplayName = 'logged_in_display_name';
  static const String _keyUsers = 'registered_users';

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

  Future<bool> register(String email, String password, String displayName) async {
    final prefs = await SharedPreferences.getInstance();
    final usersString = prefs.getString(_keyUsers);
    Map<String, Map<String, String>> users = {};
    if (usersString != null && usersString.isNotEmpty) {
      final parts = usersString.split('|');
      for (var part in parts) {
        final pair = part.split(':');
        if (pair.length == 3) {
          users[pair[0]] = {'password': pair[1], 'displayName': pair[2]};
        }
      }
    }

    if (users.containsKey(email)) return false;

    users[email] = {'password': password, 'displayName': displayName};
    final newUsersString = users.entries.map((e) => '${e.key}:${e.value['password']}:${e.value['displayName']}').join('|');
    await prefs.setString(_keyUsers, newUsersString);
    return true;
  }

  Future<bool> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersString = prefs.getString(_keyUsers);
    if (usersString == null || usersString.isEmpty) return false;

    final parts = usersString.split('|');
    for (var part in parts) {
      final pair = part.split(':');
      if (pair.length == 3 && pair[0] == email && pair[1] == password) {
        await saveLoggedInUser(email, pair[2]);
        return true;
      }
    }
    return false;
  }

  Future<bool> updateProfile(String newDisplayName, {String? newPassword}) async {
    final currentEmail = await getLoggedInUser();
    if (currentEmail == null) return false;

    final prefs = await SharedPreferences.getInstance();
    final usersString = prefs.getString(_keyUsers);
    if (usersString == null || usersString.isEmpty) return false;

    final parts = usersString.split('|');
    Map<String, Map<String, String>> users = {};
    for (var part in parts) {
      final pair = part.split(':');
      if (pair.length == 3) {
        users[pair[0]] = {'password': pair[1], 'displayName': pair[2]};
      }
    }

    if (!users.containsKey(currentEmail)) return false;

    if (newPassword != null && newPassword.isNotEmpty) {
      users[currentEmail]!['password'] = newPassword;
    }
    users[currentEmail]!['displayName'] = newDisplayName;

    final newUsersString = users.entries.map((e) => '${e.key}:${e.value['password']}:${e.value['displayName']}').join('|');
    await prefs.setString(_keyUsers, newUsersString);
    await prefs.setString(_keyDisplayName, newDisplayName);
    return true;
  }
}