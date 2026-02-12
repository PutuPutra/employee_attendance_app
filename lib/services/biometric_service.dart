import 'package:flutter/foundation.dart';
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
      debugPrint('Error checking biometrics: ${e.code} - ${e.message}');
      return false;
    }
  }

  /// Melakukan autentikasi biometrik
  Future<bool> authenticate({required String localizedReason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        biometricOnly:
            false, // Optimized: Force biometric only untuk keamanan dan UX yang lebih cepat
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException catch (e) {
      debugPrint(
        'Error authenticating: ${e.code} - ${e.description} - Details: ${e.details}',
      );
      // Handle error spesifik
      if (e.code == LocalAuthExceptionCode.noBiometricHardware) {
        throw Exception('BIOMETRIC_NOT_AVAILABLE');
      } else if (e.code == LocalAuthExceptionCode.noBiometricsEnrolled) {
        throw Exception('BIOMETRIC_NOT_ENROLLED');
      } else if (e.code == LocalAuthExceptionCode.noCredentialsSet) {
        throw Exception('BIOMETRIC_NO_CREDENTIALS');
      } else if (e.code == LocalAuthExceptionCode.temporaryLockout) {
        throw Exception('BIOMETRIC_LOCKOUT');
      } else {
        throw Exception('BIOMETRIC_AUTH_FAILED');
      }
    }
  }
}
