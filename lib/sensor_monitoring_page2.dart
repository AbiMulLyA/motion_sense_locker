import 'dart:async';
import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:device_policy_manager/device_policy_manager.dart';
import 'package:duration_picker/duration_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'di/injector.dart';
import 'util/foreground_util.dart';
import 'util/passcode_util.dart';
import 'util/shared_preferences_util.dart';

@RoutePage()
class SensorMonitoringPage2 extends StatefulWidget {
  const SensorMonitoringPage2({super.key});

  @override
  State<SensorMonitoringPage2> createState() => _SensorMonitoringPage2State();
}

class _SensorMonitoringPage2State extends State<SensorMonitoringPage2> {
  final _sharedPreferencesUtil = getIt<SharedPreferencesUtil>();
  final StreamController<bool> _verificationNotifier =
      StreamController<bool>.broadcast();
  bool isAuthenticated = false;
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];
  Duration? screenTime = Duration(minutes: 2);
  Duration? sensorTime = Duration(minutes: 1);
  late int screenTimeInSeconds = screenTime!.inSeconds;
  late int sensorTimeInSeconds = sensorTime!.inSeconds;

  bool _isMonitoringStarted = false;
  bool _isMoving = false;
  bool _isSlowRotate = false;
  double _sum = 0;
  double _sumGyro = 0;
  String storedPasscode = '123456';
  Timer? timer;

  Future<void> startTimer() async {
    if (!await requestPermissions()) {
      showAlertDialog(context);
    } else {
      _isMonitoringStarted = true;

      timer = Timer.periodic(Duration(microseconds: 1), (_) async {
        setState(() {
          _sum = _sharedPreferencesUtil.getDouble('accSum') ?? 0;
          _sumGyro = _sharedPreferencesUtil.getDouble('accGyro') ?? 0;
          _isMoving = _sharedPreferencesUtil.getBool('isMoving');
          _isSlowRotate = _sharedPreferencesUtil.getBool('isSlowRotate');
        });

        if (screenTimeInSeconds > 0) {
          setState(() {
            screenTimeInSeconds--;
          });
          await _sharedPreferencesUtil.setInt(
              'screenTimeInSecondsSelected', screenTimeInSeconds);
        } else {
          stopTimer();
          await DevicePolicyManager.lockNow();
        }

        if (sensorTimeInSeconds > 0) {
          debugPrint('IS SLOW ROTATE : $_isMoving -- $_isSlowRotate ');
          if (_isMoving == true && _isSlowRotate == true) {
            setState(() {
              sensorTimeInSeconds =
                  _sharedPreferencesUtil.getInt('selectedSensorTime') ?? 60;
            });
          }
          setState(() {
            sensorTimeInSeconds--;
          });
          await _sharedPreferencesUtil.setInt(
              'sensorTimeInSecondsSelected', sensorTimeInSeconds);
        } else {
          if (!_isMoving) {
            stopTimer();
            await DevicePolicyManager.lockNow();
          }
        }
      });
      print(
          'Time in start foregorund : $screenTimeInSeconds -- $sensorTimeInSeconds');
      await ForegroundUtil.startForegroundTask(
        'timer',
        screenTimeInSecondsSelected: screenTimeInSeconds,
        sensorTimeInSecondsSelected: sensorTimeInSeconds,
      );

      await _sharedPreferencesUtil.setBool('monitorStarted', value: true);
    }
  }

  void stopTimer() async {
    await _sharedPreferencesUtil.setBool('monitorStarted', value: false);
    await _sharedPreferencesUtil.clearKey('selectedSensorTime');
    _isMonitoringStarted = false;

    await ForegroundUtil.stopForegroundTask();
    timer?.cancel();
    setState(() {
      screenTimeInSeconds =
          screenTime!.inSeconds; //sistema riportalo al max in secondi
      sensorTimeInSeconds = sensorTime!.inSeconds;
    });
  }

  String getDuration(int totalSeconds) {
    String seconds = (totalSeconds % 60).toInt().toString().padLeft(2, '0');
    String minutes =
        ((totalSeconds / 60) % 60).toInt().toString().padLeft(2, '0');
    String hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');

    return "$hours\:$minutes\:$seconds";
  }

  Future<bool> requestPermissions() async {
    bool permissionGranted = await DevicePolicyManager.isPermissionGranted();
    if (!permissionGranted) {
      permissionGranted = await DevicePolicyManager.requestPermession(
          "Your app is requesting the Adminstration permission");
    }
    return permissionGranted;
  }

  int getTimeFromBg() {
    return _sharedPreferencesUtil.getInt('screenTimeInSecondsSelected')!;
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

  T? _ambiguate<T>(T? value) => value;

  @override
  void initState() {
    _isMonitoringStarted = _sharedPreferencesUtil.getBool('monitorStarted');
    final bool isMonitorStarted =
        _sharedPreferencesUtil.getBool('monitorStarted');
    if (isMonitorStarted) {
      screenTimeInSeconds =
          _sharedPreferencesUtil.getInt('screenTimeInSecondsSelected')!;
      sensorTimeInSeconds =
          _sharedPreferencesUtil.getInt('sensorTimeInSecondsSelected')!;
      startTimer();
    }
    _ambiguate(WidgetsBinding.instance)?.addPostFrameCallback((_) async {
      await ForegroundUtil().requestPermissionForAndroid();
      ForegroundUtil().initForegroundTask();

      // You can get the previous ReceivePort without restarting the service.
      if (await FlutterForegroundTask.isRunningService) {
        final newReceivePort = await FlutterForegroundTask.receivePort;
        ForegroundUtil.registerReceivePort(newReceivePort);
      }
    });

    _streamSubscriptions.add(
      userAccelerometerEvents.listen(
        (UserAccelerometerEvent event) {
          double x = event.x;
          double y = event.y;
          double z = event.z;
          _sum = sqrt((x * x) + (y * y) + (z * z));

          _sharedPreferencesUtil.setDouble('accSum', _sum);

          if (!_isMoving && _sum > 5.5) {
            setState(() {
              _isMoving = true;
            });
          } else if (_isMoving && _sum < 5.5) {
            setState(() {
              _isMoving = false;
            });
          }

          _sharedPreferencesUtil.setBool('isMoving', value: _isMoving);
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
          _sumGyro = sqrt((x * x) + (y * y) + (z * z));

          _sharedPreferencesUtil.setDouble('accGyro', _sumGyro);

          if (_isSlowRotate && _sumGyro > 3.5) {
            setState(() {
              _isSlowRotate = false;
            });
          } else if (!_isSlowRotate && _sumGyro < 3.5) {
            setState(() {
              _isSlowRotate = true;
            });
          }

          _sharedPreferencesUtil.setBool('isSlowRotate', value: _isSlowRotate);
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
    super.initState();
  }

  @override
  void dispose() {
    // if (_isMonitoringStarted) {
    //   ForegroundUtil.startForegroundTask(
    //     'timer',
    //     screenTimeInSecondsSelected: screenTimeInSeconds,
    //     sensorTimeInSecondsSelected: sensorTimeInSeconds,
    //   );
    // }
    super.dispose();
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
              SizedBox(
                height: 20,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    child: Text('Gyroscope: ${_sumGyro.toStringAsFixed(2)}'),
                  ),
                  Container(
                    padding: EdgeInsets.all(16),
                    child: Text('Accelerometer: ${_sum.toStringAsFixed(2)}'),
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
                  color: _isMoving == true && _isSlowRotate == true
                      ? Colors.green
                      : Colors.red,
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
                      await _sharedPreferencesUtil.setInt(
                          'selectedSensorTime', selectedtime.inSeconds);
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
                    // stopTimer();
                    _showLockScreen(
                      context,
                      opaque: false,
                    );
                  } else {
                    startTimer();
                  }
                },
                child: Text(
                  _isMonitoringStarted ? 'Stop Monitoring' : 'Start Monitoring',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget manageButtons() {
    bool isRunning = timer == null ? false : timer!.isActive;
    if (!isRunning || screenTimeInSeconds == screenTime!.inSeconds) {
      return ElevatedButton(
        child: Text("Start timer", style: TextStyle(fontSize: 20)),
        onPressed: () => startTimer(),
      );
    } else {
      return ElevatedButton(
        child: Icon(Icons.restart_alt),
        onPressed: () => stopTimer(),
      );
    }
  }

  Widget createTimer(int time) {
    return Text(
      getDuration(time),
      style: TextStyle(
          color: Colors.black, fontSize: 80, fontWeight: FontWeight.bold),
    );
  }

  Widget timePickerButton() {
    return ElevatedButton(
        onPressed: () async {
          Duration? selectedtime = await showDurationPicker(
              context: context, initialTime: const Duration(minutes: 20));

          if (selectedtime == null) return;

          setState(() {
            screenTime = selectedtime;
            screenTimeInSeconds = selectedtime.inSeconds;
          });
        },
        child: Text("Select timer", style: TextStyle(fontSize: 20)));
  }

  _showLockScreen(
    BuildContext context, {
    required bool opaque,
  }) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: opaque,
        pageBuilder: (context, animation, secondaryAnimation) => PinScreen(
          onValidated: () async {
            debugPrint('ON VALIDATED');
            stopTimer();
          },
        ),
      ),
    );
  }
}
