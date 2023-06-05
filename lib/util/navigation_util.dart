import 'package:injectable/injectable.dart';
import 'package:motion_sense_locker/util/shared_preferences_util.dart';

import '../di/injector.dart';

@lazySingleton
class NavigationUtil {
  final SharedPreferencesUtil _sharedPreferencesUtil =
      getIt<SharedPreferencesUtil>();

  static const String prefNavigationKey = 'NAVIGATION';
  static const String prefOnHomePage = 'HOME_PAGE';
  static const String prefOnSensorPage = 'SENSOR_PAGE';
  static const String prefOnTimerPage = 'TIMER_PAGE';

  Future<void> setNavigationToSensor() async {
    await _sharedPreferencesUtil.setString(prefNavigationKey, prefOnSensorPage);
  }

  Future<void> setNavigationToTimer() async {
    await _sharedPreferencesUtil.setString(prefNavigationKey, prefOnTimerPage);
  }

  Future<void> setNavigationToHome() async {
    await _sharedPreferencesUtil.setString(prefNavigationKey, prefOnHomePage);
  }

  Future<bool> isOnHomePage() async {
    final String? where =
        await _sharedPreferencesUtil.getString(prefNavigationKey);

    return where != null && where != '' && where == prefOnSensorPage;
  }

  Future<bool> isOnSensorPage() async {
    final String? where =
        await _sharedPreferencesUtil.getString(prefNavigationKey);

    return where != null && where != '' && where == prefOnSensorPage;
  }

  Future<bool> isOnTimerPage() async {
    final String? where =
        await _sharedPreferencesUtil.getString(prefNavigationKey);

    return where != null && where != '' && where == prefOnTimerPage;
  }
}
