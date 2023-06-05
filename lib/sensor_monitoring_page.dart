import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motion_sense_locker/bloc/navigation_bloc.dart';
import 'package:motion_sense_locker/router/router.dart';

@RoutePage()
class SensorMonitoringPage extends StatefulWidget {
  const SensorMonitoringPage({super.key});

  @override
  State<SensorMonitoringPage> createState() => _SensorMonitoringPageState();
}

class _SensorMonitoringPageState extends State<SensorMonitoringPage> {
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
      body: Container(
        padding: EdgeInsets.all(16),
        child: Text('Sensor Monitoring'),
      ),
    );
  }
}
