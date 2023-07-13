import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:motion_sense_locker/util/shared_preferences_util.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorUtil {
  final prefs = SharedPreferencesUtil();
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];
  bool _isMoving = false;
  bool _isSlowRotate = false;

  Future<void> startStep() async {
    _streamSubscriptions.add(
      userAccelerometerEvents.listen(
        (UserAccelerometerEvent event) {
          double x = event.x;
          double y = event.y;
          double z = event.z;
          double sum = sqrt((x * x) + (y * y) + (z * z));

          prefs.setDouble('accSum', sum);

          if (!_isMoving && sum > 8.5) {
            _isMoving = true;
          } else if (_isMoving && sum < 1) {
            _isMoving = false;
          }
          // debugPrint('User is sitting');
          // debugPrint('User is sitting');

          debugPrint('Is Moving From Sensor Util : $_isMoving -- $sum');

          prefs.setBool('isMoving', value: _isMoving);
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
          if (!_isSlowRotate && sum < 3.5) {
            _isSlowRotate = true;
          } else {
            _isSlowRotate = false;
          }
          debugPrint('IS SLOW ROTATE : $_isSlowRotate');
          prefs.setDouble('accGyro', sum);
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
  }
}
