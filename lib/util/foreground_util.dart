import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:device_policy_manager/device_policy_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  SendPort? _sendPort;
  Timer? timer;
  Duration? showtime = Duration(minutes: 10);
  late int? showTimeInSeconds = showtime!.inSeconds;

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

    final typeMonitoring =
        await FlutterForegroundTask.getData<String>(key: 'typeMonitoring');

    if (typeMonitoring == 'timer') {
      showTimeInSeconds = await FlutterForegroundTask.getData<int>(
          key: 'showTimeInSecondsSelected');

      timer = Timer.periodic(Duration(seconds: 1), (_) async {
        if (showTimeInSeconds! > 0) {
          showTimeInSeconds = showTimeInSeconds! - 1;
          debugPrint('Showed Time : $showTimeInSeconds');

          await FlutterForegroundTask.saveData(
            key: 'showTimeInSecondsSelected',
            value: showTimeInSeconds!,
          );

          await _sharedPreferencesUtil.setInt(
              'showTimeInSecondsSelected', showTimeInSeconds!);
        } else {
          timer?.cancel();

          // showTimeInSeconds =
          //     showtime!.inSeconds;
          await DevicePolicyManager.lockNow();
          await ForegroundUtil.stopForegroundTask();
        }
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
        notificationText: 'Waktu Tersisa: ${getDuration(showTimeInSeconds!)}',
      );
    }

    sendPort?.send(showTimeInSeconds);

    // showTimeInSeconds++;
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

  static Future<bool> startForegroundTask(String typeMonitoring,
      {int? showTimeInSecondsSelected}) async {
    // You can save data using the saveData function.
    await FlutterForegroundTask.saveData(
        key: 'typeMonitoring', value: typeMonitoring);

    if (showTimeInSecondsSelected != null) {
      await FlutterForegroundTask.saveData(
          key: 'showTimeInSecondsSelected', value: showTimeInSecondsSelected);
    }

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
