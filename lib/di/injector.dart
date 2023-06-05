import 'package:get_it/get_it.dart';

import 'package:injectable/injectable.dart';
import 'package:motion_sense_locker/di/injector.config.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

//* Initial authGetIt
@InjectableInit(
  initializerName: 'initGetIt', // default\
  generateForDir: ['lib'],
  preferRelativeImports: true,
)
// GetIt configureAuthScope() => authGetIt.initAuthScope();

configureInjector() => getIt.initGetIt();

//* For Thirdparty Plugins
@module
abstract class RegisterModule {
  @lazySingleton
  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
}
