part of 'location_bloc.dart';

@immutable
sealed class LocationState {}

final class LocationInitial extends LocationState {}

final class LocationLoading extends LocationState {}

final class LocationSuccess extends LocationState {
  final Position position;
  final String address;

  LocationSuccess(this.position, this.address);
}

final class LocationFailure extends LocationState {
  final String error;

  LocationFailure(this.error);
}
