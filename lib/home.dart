import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/navigation_bloc.dart';
import 'router/router.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Container(
        color: Colors.white,
        padding: EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Silahkan Pilih Tipe Monitoring Yang Anda Inginkan'),
              SizedBox(
                height: 15,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      context.read<NavigationBloc>().add(SensorEv());
                      Future.delayed(
                        Duration(milliseconds: 500),
                      );
                      context.router.replace(SensorMonitoringRoute());
                    },
                    child: Text('Automatic Monitoring'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      context.read<NavigationBloc>().add(TimerEv());
                      Future.delayed(
                        Duration(milliseconds: 500),
                      );
                      context.router.replace(TimerMonitoringRoute());
                    },
                    child: Text('Manual Monitoring'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
