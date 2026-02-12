import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:safe_device/safe_device.dart';

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

      // --- SECURITY CHECK: DEVICE INTEGRITY (SafeDevice) ---
      // Cek Root/Jailbreak sebelum mengambil lokasi
      if (await SafeDevice.isJailBroken) {
        emit(
          LocationFailure(
            'KEAMANAN: Perangkat terdeteksi Root/Jailbreak. Akses ditolak demi keamanan data.',
          ),
        );
        return;
      }

      // 2. Get the current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy:
              LocationAccuracy.best, // Gunakan akurasi terbaik (GPS Hardware)
          timeLimit: Duration(seconds: 20),
        ),
      );

      // --- SECURITY CHECK (ANTI FAKE GPS) ---

      // 1. Deteksi Mock Location (Geolocator - Flag OS)
      if (position.isMocked) {
        emit(
          LocationFailure(
            'KEAMANAN: Terdeteksi lokasi palsu (Geolocator). Mohon matikan Fake GPS.',
          ),
        );
        return;
      }

      // 2. Deteksi Mock Location (SafeDevice)
      if (await SafeDevice.isMockLocation) {
        emit(
          LocationFailure(
            'KEAMANAN: Terdeteksi aplikasi lokasi palsu (SafeDevice).',
          ),
        );
        return;
      }

      // 3. Validasi Akurasi
      // GPS asli biasanya akurat (5-20m). Jika >100m, kemungkinan sinyal buruk atau spoofing kasar.
      if (position.accuracy > 100) {
        emit(
          LocationFailure(
            'Akurasi GPS terlalu rendah (${position.accuracy.toInt()}m). Pastikan Anda berada di area terbuka untuk presensi.',
          ),
        );
        return;
      }

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
