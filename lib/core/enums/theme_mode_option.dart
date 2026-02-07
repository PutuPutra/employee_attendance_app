/// Enum untuk opsi tema aplikasi
///
/// - [system]: Mengikuti tema sistem device
/// - [light]: Mode terang
/// - [dark]: Mode gelap
enum ThemeModeOption {
  system,
  light,
  dark;

  /// Konversi dari string ke enum
  static ThemeModeOption fromString(String value) {
    switch (value.toLowerCase()) {
      case 'light':
        return ThemeModeOption.light;
      case 'dark':
        return ThemeModeOption.dark;
      case 'system':
      default:
        return ThemeModeOption.system;
    }
  }

  /// Konversi enum ke string untuk display
  String get displayName {
    switch (this) {
      case ThemeModeOption.system:
        return 'System';
      case ThemeModeOption.light:
        return 'Light';
      case ThemeModeOption.dark:
        return 'Dark';
    }
  }

  /// Konversi enum ke string untuk storage
  String toStorageString() {
    return name;
  }
}
