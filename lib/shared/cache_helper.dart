import 'package:shared_preferences/shared_preferences.dart';

class CacheHelper {
  static SharedPreferences? sharedPreferences;

  static init() async {
    sharedPreferences = await SharedPreferences.getInstance();
  }

  static dynamic getData({required String key}) {
    return sharedPreferences!.get(key);
  }

  static Future<bool> saveData(
      {required String key, required dynamic value}) async {
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
    return await sharedPreferences!.remove(key);
  }
}
