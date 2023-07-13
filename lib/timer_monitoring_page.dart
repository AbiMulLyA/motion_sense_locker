import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:device_policy_manager/device_policy_manager.dart';
import 'package:duration_picker/duration_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:motion_sense_locker/router/router.dart';
import 'package:motion_sense_locker/util/foreground_util.dart';
import 'package:motion_sense_locker/util/shared_preferences_util.dart';

import 'bloc/navigation_bloc.dart';
import 'di/injector.dart';

@RoutePage()
class TimerMonitoringPage extends StatefulWidget {
  const TimerMonitoringPage({super.key});

  @override
  State<TimerMonitoringPage> createState() => _TimerMonitoringPageState();
}

class _TimerMonitoringPageState extends State<TimerMonitoringPage> {
  final _sharedPreferencesUtil = getIt<SharedPreferencesUtil>();
  Timer? timer;
  Duration? showtime = Duration(minutes: 2);
  late int showtimeInSeconds = showtime!.inSeconds;

  Future<void> startTimer() async {
    if (!await requestPermissions()) {
      showAlertDialog(context);
    } else {
      timer = Timer.periodic(Duration(seconds: 1), (_) async {
        if (showtimeInSeconds > 0) {
          setState(() {
            showtimeInSeconds--;
          });
        } else {
          stopTimer();
        }
      });

      // await ForegroundUtil.startForegroundTask(
      //   'timer',
      //   screenTimeInSecondsSelected: showtimeInSeconds,
      // );

      await _sharedPreferencesUtil.setInt(
          'showTimeInSecondsSelected', showtimeInSeconds);

      await _sharedPreferencesUtil.setBool('monitorStarted', value: true);
    }
  }

  void stopTimer() async {
    await ForegroundUtil.stopForegroundTask();
    timer?.cancel();
    setState(() {
      showtimeInSeconds =
          showtime!.inSeconds; //sistema riportalo al max in secondi
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
    return _sharedPreferencesUtil.getInt('showTimeInSecondsSelected')!;
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
    final bool isMonitorStarted =
        _sharedPreferencesUtil.getBool('monitorStarted');
    if (isMonitorStarted) {
      showtimeInSeconds =
          _sharedPreferencesUtil.getInt('showTimeInSecondsSelected')!;
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
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            context.read<NavigationBloc>().add(InitialEv());
            context.router.replace(HomeRoute());
          },
          child: Icon(
            Icons.arrow_back_ios,
          ),
        ),
      ),
      backgroundColor: Colors.grey[900],
      body: Container(
        padding: EdgeInsets.all(16),
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              createTimer(),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  manageButtons(),
                  timePickerButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget manageButtons() {
    bool isRunning = timer == null ? false : timer!.isActive;
    if (!isRunning || showtimeInSeconds == showtime!.inSeconds) {
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

  Widget createTimer() {
    return Text(
      getDuration(showtimeInSeconds),
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
            showtime = selectedtime;
            showtimeInSeconds = selectedtime.inSeconds;
          });
        },
        child: Text("Select timer", style: TextStyle(fontSize: 20)));
  }
}
