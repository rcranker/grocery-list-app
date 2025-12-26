import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String _userNameKey = 'user_name';
  static String? _cachedUserName;

  // Get current user's name
  static Future<String> getUserName() async {
    if (_cachedUserName != null) {
      return _cachedUserName!;
    }

    final prefs = await SharedPreferences.getInstance();
    _cachedUserName = prefs.getString(_userNameKey) ?? 'Me';
    return _cachedUserName!;
  }

  // Set user's name
  static Future<void> setUserName(String name) async {
    _cachedUserName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }

  // Check if user name is set
  static Future<bool> hasUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_userNameKey);
  }
}