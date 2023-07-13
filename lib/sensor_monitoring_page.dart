// ignore_for_file: unused_field
import 'dart:async';
import 'dart:math';
import 'package:auto_route/auto_route.dart';
import 'package:device_policy_manager/device_policy_manager.dart';
import 'package:duration_picker/duration_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:motion_sense_locker/util/foreground_util.dart';
import 'package:motion_sense_locker/util/passcode_util.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'bloc/navigation_bloc.dart';
import 'di/injector.dart';
import 'router/router.dart';
import 'util/shared_preferences_util.dart';

@RoutePage()
class SensorMonitoringPage extends StatefulWidget {
  const SensorMonitoringPage({super.key});

  @override
  State<SensorMonitoringPage> createState() => _SensorMonitoringPageState();
}

class _SensorMonitoringPageState extends State<SensorMonitoringPage> {
  final _sharedPreferencesUtil = getIt<SharedPreferencesUtil>();
  final StreamController<bool> _verificationNotifier =
      StreamController<bool>.broadcast();
  bool isAuthenticated = false;

  List<double>? _userAccelerometerValues;
  List<double>? _gyroscopeValues;
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];
  Duration? screenTime = Duration(minutes: 2);
  Duration? sensorTime = Duration(minutes: 1);
  late int screenTimeInSeconds = screenTime!.inSeconds;
  late int sensorTimeInSeconds = sensorTime!.inSeconds;

  bool _isSitting = true;
  double _sum = 0;
  double _sumGyro = 0;
  double _sum2 = 0;
  List<double> _accSum = [];
  String storedPasscode = '123456';
  Timer? timer;
  bool _isMonitoringStarted = false;

  T? _ambiguate<T>(T? value) => value;

  @override
  void initState() {
    // startTimer();

    _ambiguate(WidgetsBinding.instance)?.addPostFrameCallback((_) async {
      await ForegroundUtil().requestPermissionForAndroid();
      ForegroundUtil().initForegroundTask();

      // You can get the previous ReceivePort without restarting the service.
      if (await FlutterForegroundTask.isRunningService) {
        final newReceivePort = await FlutterForegroundTask.receivePort;
        ForegroundUtil.registerReceivePort(newReceivePort);
      }

      _isMonitoringStarted = _sharedPreferencesUtil.getBool('monitorStarted');
      if (_isMonitoringStarted) {
        screenTimeInSeconds =
            _sharedPreferencesUtil.getInt('showTimeInSecondsSelected')!;
        sensorTimeInSeconds =
            _sharedPreferencesUtil.getInt('sensorTimeInSecondsSelected')!;
        startTimer();
      }

      debugPrint('Is Monitoring started : $_isMonitoringStarted');
      debugPrint(
          'Time In Seconds : $screenTimeInSeconds -- $sensorTimeInSeconds');
    });
    /* _streamSubscriptions.add(
      userAccelerometerEvents.listen(
        (UserAccelerometerEvent event) {
          double x = event.x;
          double y = event.y;
          double z = event.z;
          double sum = sqrt((x * x) + (y * y) + (z * z));

          if (_isSitting && sum > 8.5) {
            setState(() {
              _isSitting = false;
            });
            print('User is standing');
          } else if (!_isSitting && sum < 1) {
            setState(() {
              _isSitting = true;
            });
            print('User is sitting');
          }

          setState(() {
            _sum = double.parse(sum.toStringAsFixed(2));
            _accSum.add(_sum);
            _userAccelerometerValues = <double>[event.x, event.y, event.z];
          });
        },
        onError: (e) {
          showDialog(
              context: context,
              builder: (context) {
                return const AlertDialog(
                  title: Text("Sensor Not Found"),
                  content: Text(
                      "It seems that your device doesn't support Accelerometer Sensor"),
                );
              });
        },
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
          // print('x : $x , y : $y, z : $z');
          setState(() {
            _sumGyro = double.parse(sum.toStringAsFixed(2));
            _gyroscopeValues = <double>[event.x, event.y, event.z];
          });
        },
        onError: (e) {
          showDialog(
              context: context,
              builder: (context) {
                return const AlertDialog(
                  title: Text("Sensor Not Found"),
                  content: Text(
                      "It seems that your device doesn't support User Accelerometer Sensor"),
                );
              });
        },
        cancelOnError: true,
      ),
    );*/

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    // for (final subscription in _streamSubscriptions) {
    //   subscription.cancel();
    // }
  }

  Future<void> startTimer() async {
    if (!await requestPermissions()) {
      showAlertDialog(context);
    } else {
      setState(() {
        _isMonitoringStarted = true;
      });

      timer = Timer.periodic(Duration(seconds: 1), (_) async {
        if (screenTimeInSeconds > 0) {
          setState(() {
            screenTimeInSeconds--;
          });
        } else {
          stopTimer();
          await DevicePolicyManager.lockNow();
        }

        if (sensorTimeInSeconds > 0) {
          if (!_isSitting) {
            sensorTimeInSeconds = 60;
          }
          setState(() {
            sensorTimeInSeconds--;
          });
        } else {
          if (_isSitting) {
            stopTimer();
            await DevicePolicyManager.lockNow();
          }
          // else {
          //   startTimer();
          // }
        }
        await _sharedPreferencesUtil.setInt(
            'showTimeInSecondsSelected', screenTimeInSeconds);
        await _sharedPreferencesUtil.setInt(
            'sensorTimeInSecondsSelected', sensorTimeInSeconds);
        debugPrint('ScreenTime : $screenTimeInSeconds -- $sensorTimeInSeconds');
      });

      // if (_isMonitoringStarted == false) {
      print(
          'Time in start foregorund : $screenTimeInSeconds -- $sensorTimeInSeconds');
      await ForegroundUtil.startForegroundTask(
        'timer',
        screenTimeInSecondsSelected: screenTimeInSeconds,

        // sensorTimeInSecondsSelected: sensorTimeInSeconds,
      );

      await _sharedPreferencesUtil.setBool('monitorStarted', value: true);

      // }
    }
  }

  void stopTimer() async {
    await ForegroundUtil.stopForegroundTask();
    await _sharedPreferencesUtil.setInt(
        'showTimeInSecondsSelected', screenTimeInSeconds);
    await _sharedPreferencesUtil.setInt(
        'sensorTimeInSecondsSelected', sensorTimeInSeconds);
    await _sharedPreferencesUtil.setBool('monitorStarted', value: false);
    timer?.cancel();
    setState(() {
      _isMonitoringStarted = false;
      screenTimeInSeconds =
          screenTime!.inSeconds; //sistema riportalo al max in secondi
      sensorTimeInSeconds = sensorTime!.inSeconds;
    });
  }

  Future<bool> requestPermissions() async {
    bool permissionGranted = await DevicePolicyManager.isPermissionGranted();
    if (!permissionGranted) {
      permissionGranted = await DevicePolicyManager.requestPermession(
          "Your app is requesting the Adminstration permission");
    }
    return permissionGranted;
  }

  showAlertDialog(BuildContext context) {
    // set up the button
    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Required permissions not granted"),
      content: Text("Please give required permissions"),
      actions: [
        okButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   leading: GestureDetector(
      //     onTap: () {
      //       context.read<NavigationBloc>().add(InitialEv());
      //       context.router.replace(HomeRoute());
      //     },
      //     child: Icon(
      //       Icons.arrow_back_ios,
      //     ),
      //   ),
      // ),
      body: Container(
        padding: EdgeInsets.all(16),
        color: Colors.white,
        child: Center(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    child: Text('SUM Gyro: $_sumGyro'),
                  ),
                  Container(
                    padding: EdgeInsets.all(16),
                    child: Text('SUM: $_sum'),
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Screen Time'),
              ),
              createTimer(screenTimeInSeconds),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Sensor Time'),
              ),
              createTimer(sensorTimeInSeconds),
              SizedBox(
                height: 20,
              ),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isSitting == true ? Colors.red : Colors.green,
                ),
              ),
              SizedBox(
                height: 40,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      Duration? selectedtime = await showDurationPicker(
                        context: context,
                        initialTime: const Duration(hours: 2),
                        baseUnit: BaseUnit.minute,
                      );

                      if (selectedtime == null) return;

                      setState(() {
                        screenTime = selectedtime;
                        screenTimeInSeconds = selectedtime.inSeconds;
                      });
                    },
                    child: Text(
                      "Set Screen\nTime",
                      style: TextStyle(
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Duration? selectedtime = await showDurationPicker(
                          context: context,
                          initialTime: const Duration(minutes: 30));

                      if (selectedtime == null) return;

                      setState(() {
                        sensorTime = selectedtime;
                        sensorTimeInSeconds = selectedtime.inSeconds;
                      });
                    },
                    child: Text(
                      "Set Sensor\nTime",
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              ElevatedButton(
                onPressed: () {
                  if (_isMonitoringStarted) {
                    stopTimer();
                    // _showLockScreen(
                    //   context,
                    //   opaque: false,
                    // );
                  } else {
                    startTimer();
                  }
                },
                child: Text(
                  _isMonitoringStarted ? 'Stop Timer' : 'Start Timer',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget createTimer(int time) {
    return Text(
      getDuration(time),
      style: TextStyle(
          color: Colors.black, fontSize: 80, fontWeight: FontWeight.bold),
    );
  }

  String getDuration(int totalSeconds) {
    String seconds = (totalSeconds % 60).toInt().toString().padLeft(2, '0');
    String minutes =
        ((totalSeconds / 60) % 60).toInt().toString().padLeft(2, '0');
    String hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');

    return "$hours\:$minutes\:$seconds";
  }

  // _showLockScreen(
  //   BuildContext context, {
  //   required bool opaque,
  // }) {
  //   Navigator.push(
  //     context,
  //     PageRouteBuilder(
  //       opaque: opaque,
  //       pageBuilder: (context, animation, secondaryAnimation) => PinScreen(),
  //     ),
  //   );
  // }
}
