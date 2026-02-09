import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:meta/meta.dart';

part 'location_event.dart';
part 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  LocationBloc() : super(LocationInitial()) {
    on<FetchLocation>(_onFetchLocation);
  }

  Future<void> _onFetchLocation(
    FetchLocation event,
    Emitter<LocationState> emit,
  ) async {
    emit(LocationLoading());

    try {
      // 1. Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          emit(
            LocationFailure(
              'Izin lokasi ditolak. Fitur ini tidak dapat digunakan.',
            ),
          );
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        emit(
          LocationFailure(
            'Izin lokasi ditolak permanen. Mohon aktifkan di pengaturan aplikasi.',
          ),
        );
        return;
      }

      // 2. Get the current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 3. Convert coordinates to a readable address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks[0];
        // Create a formatted, readable address
        final address =
            '${placemark.street}, ${placemark.subLocality}, ${placemark.locality}, ${placemark.postalCode}';
        emit(LocationSuccess(position, address));
      } else {
        emit(
          LocationFailure(
            'Tidak dapat menemukan alamat untuk lokasi saat ini.',
          ),
        );
      }
    } catch (e) {
      emit(LocationFailure('Gagal mendapatkan lokasi: ${e.toString()}'));
    }
  }
}
