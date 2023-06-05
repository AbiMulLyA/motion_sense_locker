// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

import 'package:motion_sense_locker/util/navigation_util.dart';

part 'navigation_event.dart';
part 'navigation_state.dart';

@injectable
class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  final NavigationUtil navigationUtil;
  NavigationBloc(
    this.navigationUtil,
  ) : super(const InitialSt()) {
    on<AppStartedEv>((event, emit) async {
      debugPrint('APP STARTED');
      final bool isOnHomePage = await navigationUtil.isOnHomePage();
      final bool isOnSensorPage = await navigationUtil.isOnSensorPage();
      final bool isOnTimerPage = await navigationUtil.isOnTimerPage();

      debugPrint(
          'Where is now :  $isOnHomePage -- $isOnSensorPage -- $isOnTimerPage');

      if (isOnHomePage || state == InitialSt()) {
        emit(
          InitialSt(),
        );
      }

      if (isOnSensorPage) {
        emit(
          SensorSt(),
        );
      }

      if (isOnTimerPage) {
        emit(
          TimerSt(),
        );
      }
    });

    on<InitialEv>((event, emit) {
      navigationUtil.setNavigationToHome();
      emit(
        InitialSt(),
      );
    });

    on<SensorEv>((event, emit) {
      navigationUtil.setNavigationToSensor();
      emit(
        SensorSt(),
      );
      debugPrint('Sensor Ev Clicked');
    });

    on<TimerEv>((event, emit) {
      navigationUtil.setNavigationToTimer();
      emit(
        TimerSt(),
      );
    });
  }
}
