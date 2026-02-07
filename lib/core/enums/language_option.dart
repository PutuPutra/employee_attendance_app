import 'package:flutter/material.dart';

/// Enum untuk opsi bahasa aplikasi
///
/// - [system]: Mengikuti bahasa sistem device
/// - [english]: Bahasa Inggris
/// - [indonesian]: Bahasa Indonesia
enum LanguageOption {
  system,
  english,
  indonesian;

  /// Konversi dari string ke enum
  static LanguageOption fromString(String value) {
    switch (value.toLowerCase()) {
      case 'english':
      case 'en':
        return LanguageOption.english;
      case 'indonesian':
      case 'indonesia':
      case 'id':
        return LanguageOption.indonesian;
      case 'system':
      default:
        return LanguageOption.system;
    }
  }

  /// Konversi enum ke string untuk display
  String get displayName {
    switch (this) {
      case LanguageOption.system:
        return 'System';
      case LanguageOption.english:
        return 'English';
      case LanguageOption.indonesian:
        return 'Indonesia';
    }
  }

  /// Konversi enum ke Locale untuk Flutter
  Locale? toLocale() {
    switch (this) {
      case LanguageOption.english:
        return const Locale('en');
      case LanguageOption.indonesian:
        return const Locale('id');
      case LanguageOption.system:
        return null; // null berarti ikuti sistem
    }
  }

  /// Konversi enum ke string untuk storage
  String toStorageString() {
    return name;
  }

  /// Konversi dari Locale ke LanguageOption
  static LanguageOption fromLocale(Locale? locale) {
    if (locale == null) return LanguageOption.system;

    switch (locale.languageCode) {
      case 'en':
        return LanguageOption.english;
      case 'id':
        return LanguageOption.indonesian;
      default:
        return LanguageOption.system;
    }
  }
}
