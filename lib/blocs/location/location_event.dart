part of 'location_bloc.dart';

@immutable
sealed class LocationEvent {}

/// Event to trigger fetching the user's current location and address.
final class FetchLocation extends LocationEvent {}
