import 'package:shared_preferences/shared_preferences.dart';

class CacheHelper {
  static SharedPreferences? sharedPreferences;
  static Future<void>? _initialization;

  static Future<void> init() =>
      _initialization ??= _initialize();

  static Future<void> _initialize() async {
    sharedPreferences = await SharedPreferences.getInstance();
  }

  static Future<void> ensureInitialized() => init();

  static dynamic getData({required String key}) {
    return sharedPreferences!.get(key);
  }

  static Future<bool> saveData(
      {required String key, required dynamic value}) async {
    await ensureInitialized();
    if (value is String) {
      return await sharedPreferences!.setString(key, value);
    }
    if (value is bool) {
      return await sharedPreferences!.setBool(key, value);
    }
    if (value is List<String>) {
      return await sharedPreferences!.setStringList(key, value);
    }
    return await sharedPreferences!.setInt(key, value);
  }

  static Future<bool> removeData({required String key}) async {
    await ensureInitialized();
    return await sharedPreferences!.remove(key);
  }
}
