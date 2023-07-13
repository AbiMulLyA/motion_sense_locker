import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:device_policy_manager/device_policy_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:motion_sense_locker/util/sensor_util.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  SendPort? _sendPort;
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];
  Timer? timer;
  Duration? screenTime = Duration(minutes: 2);
  Duration? sensortime = Duration(minutes: 1);
  late int? screenTimeInSeconds = screenTime!.inSeconds;
  late int? sensorTimeInSeconds = sensortime!.inSeconds;
  bool _isMoving = false;
  bool _isSlowRotate = false;

  String getDuration(int totalSeconds) {
    String seconds = (totalSeconds % 60).toInt().toString().padLeft(2, '0');
    String minutes =
        ((totalSeconds / 60) % 60).toInt().toString().padLeft(2, '0');
    String hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    return "$hours\:$minutes\:$seconds";
  }

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    final SharedPreferences _sharedPreferencesUtil =
        await SharedPreferences.getInstance();
    _sendPort = sendPort;

    _streamSubscriptions.add(
      userAccelerometerEvents.listen(
        (UserAccelerometerEvent event) {
          double x = event.x;
          double y = event.y;
          double z = event.z;
          double sum = sqrt((x * x) + (y * y) + (z * z));

          _sharedPreferencesUtil.setDouble('accSum', sum);

          if (!_isMoving && sum > 5.5) {
            _isMoving = true;
          } else if (_isMoving && sum < 5.5) {
            _isMoving = false;
          }

          _sharedPreferencesUtil.setBool('isMoving', _isMoving);
        },
        /* onError: (e) {
          showDialog(
              context: context,
              builder: (context) {
                return const AlertDialog(
                  title: Text("Sensor Not Found"),
                  content: Text(
                      "It seems that your device doesn't support Accelerometer Sensor"),
                );
              });
        },*/
        cancelOnError: true,
      ),
    );
    _streamSubscriptions.add(
      gyroscopeEvents.listen(
        (GyroscopeEvent event) {
          double x = event.x;
          double y = event.y;
          double z = event.z;
          double sum = sqrt((x * x) + (y * y) + (z * z));
          // debugPrint('x : $x , y : $y, z : $z');
          _sharedPreferencesUtil.setDouble('accGyro', sum);

          if (_isSlowRotate && sum > 3.5) {
            _isSlowRotate = false;
          } else if (!_isSlowRotate && sum < 3.5) {
            _isSlowRotate = true;
          }
          _sharedPreferencesUtil.setBool('isSlowRotate', _isSlowRotate);
        },
        /* onError: (e) {
          showDialog(
              context: context,
              builder: (context) {
                return const AlertDialog(
                  title: Text("Sensor Not Found"),
                  content: Text(
                      "It seems that your device doesn't support User Accelerometer Sensor"),
                );
              });
        },*/
        cancelOnError: true,
      ),
    );

    final typeMonitoring =
        await FlutterForegroundTask.getData<String>(key: 'typeMonitoring');

    if (typeMonitoring == 'timer') {
      screenTimeInSeconds = await FlutterForegroundTask.getData<int>(
          key: 'screenTimeInSecondsSelected');

      sensorTimeInSeconds = await FlutterForegroundTask.getData<int>(
          key: 'sensorTimeInSecondsSelected');

      timer = Timer.periodic(Duration(seconds: 1), (_) async {
        // bool _isMoving = _sharedPreferencesUtil.getBool('isMoving') ?? false;
        // debugPrint('IS MOVING : $_isMoving');

        if (screenTimeInSeconds! > 0) {
          screenTimeInSeconds = screenTimeInSeconds! - 1;

          await FlutterForegroundTask.saveData(
            key: 'screenTimeInSecondsSelected',
            value: screenTimeInSeconds!,
          );

          await _sharedPreferencesUtil.setInt(
              'screenTimeInSecondsSelected', screenTimeInSeconds!);
        } else {
          timer?.cancel();

          // screenTimeInSeconds =
          //     screenTime!.inSeconds;
          await DevicePolicyManager.lockNow();
          await ForegroundUtil.stopForegroundTask();
        }

        if (sensorTimeInSeconds! > 0) {
          if (_isMoving == true && _isSlowRotate == true) {
            sensorTimeInSeconds =
                await _sharedPreferencesUtil.getInt('selectedSensorTime') ?? 60;
          }

          sensorTimeInSeconds = sensorTimeInSeconds! - 1;

          await FlutterForegroundTask.saveData(
            key: 'sensorTimeInSecondsSelected',
            value: sensorTimeInSeconds!,
          );

          await _sharedPreferencesUtil.setInt(
              'sensorTimeInSecondsSelected', sensorTimeInSeconds!);
        } else {
          if (!_isMoving) {
            timer!.cancel();
            await DevicePolicyManager.lockNow();
            await ForegroundUtil.stopForegroundTask();
          }
        }
        // debugPrint(
        //     'Showed Time : $screenTimeInSeconds -- $sensorTimeInSeconds');
      });
    }
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    final typeMonitoring =
        await FlutterForegroundTask.getData<String>(key: 'typeMonitoring');

    if (typeMonitoring == 'timer') {
      FlutterForegroundTask.updateService(
        notificationTitle: 'Motion Sense Locker',
        notificationText: 'Waktu Tersisa: ${getDuration(screenTimeInSeconds!)}',
      );
    }

    sendPort?.send(screenTimeInSeconds);

    // screenTimeInSeconds++;
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    print('onDestroy');
  }

  @override
  void onNotificationButtonPressed(String id) {
    print('onNotificationButtonPressed >> $id');
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp("/timer");
    _sendPort?.send('onNotificationPressed');
  }
}

class ForegroundUtil {
  static ReceivePort? _receivePort;

  Future<void> requestPermissionForAndroid() async {
    if (!Platform.isAndroid) {
      return;
    }

    if (!await FlutterForegroundTask.canDrawOverlays) {
      await FlutterForegroundTask.openSystemAlertWindowSettings();
    }

    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }

    final NotificationPermission notificationPermissionStatus =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermissionStatus != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  }

  void initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        id: 500,
        channelId: 'notification_channel_id',
        channelName: 'Foreground Notification',
        channelDescription:
            'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
          backgroundColor: Colors.orange,
        ),
        buttons: [
          const NotificationButton(
            id: 'stopMonitoring',
            text: 'StopMonitoring',
            textColor: Colors.orange,
          ),
        ],
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000,
        isOnceEvent: false,
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<bool> startForegroundTask(
    String typeMonitoring, {
    int? screenTimeInSecondsSelected,
    int? sensorTimeInSecondsSelected,
  }) async {
    // You can save data using the saveData function.
    await FlutterForegroundTask.saveData(
        key: 'typeMonitoring', value: typeMonitoring);

    if (screenTimeInSecondsSelected != null) {
      await FlutterForegroundTask.saveData(
        key: 'screenTimeInSecondsSelected',
        value: screenTimeInSecondsSelected,
      );
    }

    if (sensorTimeInSecondsSelected != null) {
      await FlutterForegroundTask.saveData(
        key: 'sensorTimeInSecondsSelected',
        value: sensorTimeInSecondsSelected,
      );
    }
    // SensorUtil().startStep();

    // Register the receivePort before starting the service.
    final ReceivePort? receivePort = FlutterForegroundTask.receivePort;
    final bool isRegistered = registerReceivePort(receivePort);
    if (!isRegistered) {
      print('Failed to register receivePort!');
      return false;
    }

    if (await FlutterForegroundTask.isRunningService) {
      return FlutterForegroundTask.restartService();
    } else {
      return FlutterForegroundTask.startService(
        notificationTitle: 'Foreground Service is running',
        notificationText: 'Tap to return to the app',
        callback: startCallback,
      );
    }
  }

  static Future<bool> stopForegroundTask() {
    return FlutterForegroundTask.stopService();
  }

  static bool registerReceivePort(ReceivePort? newReceivePort) {
    if (newReceivePort == null) {
      return false;
    }

    closeReceivePort();

    _receivePort = newReceivePort;
    _receivePort?.listen((data) {
      if (data is int) {
        // print('eventCount: $data');
      } else if (data is String) {
        if (data == 'onNotificationPressed') {
          // Navigator.of(context).pushNamed('/resume-route');
        }
      } else if (data is DateTime) {
        // print('timestamp: ${data.toString()}');
      }
    });

    return _receivePort != null;
  }

  static void closeReceivePort() {
    _receivePort?.close();
    _receivePort = null;
  }
}
