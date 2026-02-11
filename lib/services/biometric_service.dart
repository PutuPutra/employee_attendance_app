import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Cek apakah perangkat mendukung biometrik dan ada biometrik yang terdaftar
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) return false;

      final List<BiometricType> availableBiometrics = await _auth
          .getAvailableBiometrics();

      return availableBiometrics.isNotEmpty;
    } on PlatformException catch (e) {
      print('Error checking biometrics: ${e.code} - ${e.message}');
      return false;
    }
  }

  /// Melakukan autentikasi biometrik
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason:
            'Silakan otentikasi untuk mengaktifkan login biometrik',
        biometricOnly:
            false, // Ubah ke true kalo udah fix, ini allow fallback PIN buat tes
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException catch (e) {
      print(
        'Error authenticating: ${e.code} - ${e.description} - Details: ${e.details}',
      );
      // Handle error spesifik
      if (e.code == LocalAuthExceptionCode.noBiometricHardware) {
        throw Exception('Biometrik tidak tersedia atau tidak diaktifkan.');
      } else if (e.code == LocalAuthExceptionCode.noBiometricsEnrolled) {
        throw Exception('Tidak ada biometrik yang terdaftar di perangkat ini.');
      } else if (e.code == LocalAuthExceptionCode.noCredentialsSet) {
        throw Exception('Tidak ada passcode/PIN yang diset di perangkat.');
      } else if (e.code == LocalAuthExceptionCode.temporaryLockout) {
        throw Exception(
          'Biometrik terkunci sementara karena terlalu banyak kegagalan.',
        );
      } else {
        throw Exception('Autentikasi gagal: ${e.description}');
      }
    }
  }
}
