/// Wraps SharedPreferences calls used by the app.
library;
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesDataSource {
  PreferencesDataSource(this._prefs);

  final SharedPreferences _prefs;

  // SharedPreferences keys used across app restarts.
  static const String selectedBranchKey = 'selected_branch_id';
  static const String authTokenKey = 'auth_token';
  static const String authUserKey = 'auth_user';

  String? getSelectedBranchId() => _prefs.getString(selectedBranchKey);

  Future<void> setSelectedBranchId(String branchId) async {
    await _prefs.setString(selectedBranchKey, branchId);
  }

  String? getAuthToken() => _prefs.getString(authTokenKey);

  String? getAuthUser() => _prefs.getString(authUserKey);

  Future<void> saveAuth({required String token, required String userName}) async {
    // Persist minimal auth payload required for silent bootstrap.
    await _prefs.setString(authTokenKey, token);
    await _prefs.setString(authUserKey, userName);
  }

  Future<void> clearAuth() async {
    await _prefs.remove(authTokenKey);
    await _prefs.remove(authUserKey);
  }
}