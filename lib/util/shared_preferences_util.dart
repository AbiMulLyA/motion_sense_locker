import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../di/injector.dart';

@lazySingleton
class SharedPreferencesUtil {
  final SharedPreferences _sharedPreferences = getIt<SharedPreferences>();

  Future<bool> setBool(String key, {bool value = true}) =>
      _sharedPreferences.setBool(key, value);

  bool getBool(String key) => _sharedPreferences.getBool(key) ?? false;

  Future<bool> setDouble(String key, double value) =>
      _sharedPreferences.setDouble(key, value);

  double? getDouble(String key) => _sharedPreferences.getDouble(key);

  Future<bool> setInt(String key, int value) =>
      _sharedPreferences.setInt(key, value);

  int? getInt(String key) => _sharedPreferences.getInt(key);

  Future<bool> setString(String key, String value) =>
      _sharedPreferences.setString(key, value);

  String? getString(String key) => _sharedPreferences.getString(key);

  Future<bool> setStringList(String key, List<String> value) =>
      _sharedPreferences.setStringList(key, value);

  List<String>? getStringList(String key) =>
      _sharedPreferences.getStringList(key);

  bool isKeyExists(String key) => _sharedPreferences.containsKey(key);

  Future<bool> clearKey(String key) => _sharedPreferences.remove(key);

  bool clearKeyPrefix(String prefix) {
    _sharedPreferences.getKeys().forEach((key) {
      if (key.startsWith(prefix)) _sharedPreferences.remove(key);
    });

    return true;
  }

  Future<bool> clearAll() => _sharedPreferences.clear();
}
