/// Enum untuk opsi font aplikasi
///
/// - [system]: Menggunakan font sistem device
/// - [poppins]: Menggunakan font Poppins (App Default)
enum FontOption {
  system,
  poppins;

  /// Konversi dari string ke enum
  static FontOption fromString(String value) {
    switch (value.toLowerCase()) {
      case 'poppins':
      case 'app default':
        return FontOption.poppins;
      case 'system':
      default:
        return FontOption.system;
    }
  }

  /// Konversi enum ke string untuk display
  String get displayName {
    switch (this) {
      case FontOption.system:
        return 'System';
      case FontOption.poppins:
        return 'App Default';
    }
  }

  /// Konversi enum ke font family name untuk Flutter
  /// Returns null untuk system font (menggunakan default)
  String? toFontFamily() {
    switch (this) {
      case FontOption.poppins:
        return 'Poppins';
      case FontOption.system:
        return null; // null berarti gunakan system font
    }
  }

  /// Konversi enum ke string untuk storage
  String toStorageString() {
    return name;
  }
}
