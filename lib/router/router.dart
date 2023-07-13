import 'package:auto_route/auto_route.dart';

import '../home.dart';
import '../main.dart';
import '../sensor_monitoring_page.dart';
import '../sensor_monitoring_page2.dart';
import '../timer_monitoring_page.dart';

part 'router.gr.dart';

@AutoRouterConfig()
class AppRouter extends _$AppRouter {
  @override
  final List<AutoRoute> routes = [
    AutoRoute(
      path: '/',
      page: MainRoute.page,
    ),
    AutoRoute(
      path: '/home',
      page: HomeRoute.page,
    ),
    AutoRoute(
      path: '/sensor',
      page: SensorMonitoringRoute.page,
    ),
    AutoRoute(
      path: '/sensor2',
      page: SensorMonitoringRoute2.page,
    ),
    AutoRoute(
      path: '/timer',
      page: TimerMonitoringRoute.page,
    ),
  ];
}
