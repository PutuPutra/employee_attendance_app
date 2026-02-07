import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../core/enums/theme_mode_option.dart';
import '../core/enums/language_option.dart';
import '../core/enums/font_option.dart';

/// Model immutable untuk menyimpan semua pengaturan aplikasi
///
/// Menggunakan Equatable untuk memudahkan perbandingan state
/// dan mencegah rebuild yang tidak perlu
class AppSettings extends Equatable {
  final ThemeModeOption themeMode;
  final LanguageOption language;
  final FontOption font;

  const AppSettings({
    required this.themeMode,
    required this.language,
    required this.font,
  });

  /// Factory constructor untuk membuat settings dengan nilai default
  /// Default: semua mengikuti sistem
  factory AppSettings.defaultSettings() {
    return const AppSettings(
      themeMode: ThemeModeOption.system,
      language: LanguageOption.system,
      font: FontOption.system,
    );
  }

  /// Copy with method untuk membuat instance baru dengan perubahan tertentu
  AppSettings copyWith({
    ThemeModeOption? themeMode,
    LanguageOption? language,
    FontOption? font,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      font: font ?? this.font,
    );
  }

  /// Konversi ThemeModeOption ke ThemeMode Flutter
  ThemeMode get flutterThemeMode {
    switch (themeMode) {
      case ThemeModeOption.light:
        return ThemeMode.light;
      case ThemeModeOption.dark:
        return ThemeMode.dark;
      case ThemeModeOption.system:
        return ThemeMode.system;
    }
  }

  /// Get Locale untuk aplikasi
  /// Returns null jika mengikuti sistem
  Locale? get locale {
    return language.toLocale();
  }

  /// Get font family name
  /// Returns null jika menggunakan system font
  String? get fontFamily {
    return font.toFontFamily();
  }

  /// Konversi ke Map untuk serialization
  Map<String, String> toMap() {
    return {
      'themeMode': themeMode.toStorageString(),
      'language': language.toStorageString(),
      'font': font.toStorageString(),
    };
  }

  /// Factory constructor dari Map untuk deserialization
  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      themeMode: ThemeModeOption.fromString(map['themeMode'] ?? 'system'),
      language: LanguageOption.fromString(map['language'] ?? 'system'),
      font: FontOption.fromString(map['font'] ?? 'system'),
    );
  }

  @override
  List<Object?> get props => [themeMode, language, font];

  @override
  String toString() {
    return 'AppSettings(themeMode: $themeMode, language: $language, font: $font)';
  }
}
