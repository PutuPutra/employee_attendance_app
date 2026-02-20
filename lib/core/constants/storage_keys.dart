/// Konstanta untuk keys yang digunakan di SharedPreferences
///
/// Menggunakan class dengan static const untuk menghindari hardcoded values
/// dan memudahkan maintenance
class StorageKeys {
  // Private constructor untuk mencegah instantiation
  StorageKeys._();

  /// Key untuk menyimpan pilihan tema
  static const String theme = 'app_theme_mode';

  /// Key untuk menyimpan pilihan bahasa
  static const String language = 'app_language';

  /// Key untuk menyimpan pilihan font
  static const String font = 'app_font';

  /// Key untuk menyimpan status first launch
  /// Digunakan untuk mendeteksi apakah ini pertama kali app dibuka
  static const String isFirstLaunch = 'is_first_launch';

  /// Key untuk menyimpan status login biometrik
  static const String isBiometricEnabled = 'is_biometric_enabled';

  /// Key untuk menyimpan email terakhir (untuk login biometrik)
  static const String savedEmail = 'saved_email';

  /// Key untuk menyimpan password terakhir (untuk login biometrik)
  static const String savedPassword = 'saved_password';

  /// Key untuk menyimpan ID Karyawan
  /// Field di Firebase users collection: id_karyawan
  static const String employeeId = 'id_karyawan';
}
