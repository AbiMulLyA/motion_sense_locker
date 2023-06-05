part of 'navigation_bloc.dart';

abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object> get props => [];
}

class AppStartedEv extends NavigationEvent {
  const AppStartedEv();

  @override
  String toString() => 'NavigationEvent.AppStartedEv';

  @override
  List<Object> get props => [];
}

class InitialEv extends NavigationEvent {
  const InitialEv();

  @override
  String toString() => 'NavigationEvent.InitialEv';

  @override
  List<Object> get props => [];
}

class SensorEv extends NavigationEvent {
  const SensorEv();

  @override
  String toString() => 'NavigationEvent.SensorEv';

  @override
  List<Object> get props => [];
}

class TimerEv extends NavigationEvent {
  const TimerEv();

  @override
  String toString() => 'NavigationEvent.TimerEv';

  @override
  List<Object> get props => [];
}
