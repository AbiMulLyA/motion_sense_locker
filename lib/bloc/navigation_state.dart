part of 'navigation_bloc.dart';

abstract class NavigationState extends Equatable {
  const NavigationState();

  @override
  List<Object> get props => [];
}

class InitialSt extends NavigationState {
  const InitialSt();

  @override
  String toString() => 'NavigationState.InitialSt';

  @override
  List<Object> get props => [];
}

class SensorSt extends NavigationState {
  const SensorSt();

  @override
  String toString() => 'NavigationState.SensorSt';

  @override
  List<Object> get props => [];
}

class TimerSt extends NavigationState {
  const TimerSt();

  @override
  String toString() => 'NavigationState.TimerSt';

  @override
  List<Object> get props => [];
}
