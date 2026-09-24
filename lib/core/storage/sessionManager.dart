import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/userModel.dart';

class SessionManager {
  static const String keyLogin = "is_login";
  static const String keyUser = "user";
  static const String keyToken = "token";

  /// Menyimpan data user
  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(keyLogin, true);

    await prefs.setString(keyUser, jsonEncode(user.toJson()));
  }

  /// Menyimpan token JWT hasil login
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(keyToken, token);
  }

  /// Mengambil token JWT tersimpan
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(keyToken);
  }

  /// Mengambil data user
  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();

    final json = prefs.getString(keyUser);

    if (json == null) {
      return null;
    }

    return UserModel.fromJson(jsonDecode(json));
  }

  /// Mengecek apakah user sudah login
  static Future<bool> isLogin() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(keyLogin) ?? false;
  }

  /// Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(keyLogin);
    await prefs.remove(keyUser);
    await prefs.remove(keyToken);
  }
}
