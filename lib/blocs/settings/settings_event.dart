import 'package:equatable/equatable.dart';
import '../../core/enums/theme_mode_option.dart';
import '../../core/enums/language_option.dart';
import '../../core/enums/font_option.dart';

/// Base class untuk semua Settings Events
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Event untuk load settings dari storage
///
/// Dipanggil saat aplikasi pertama kali dibuka
class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

/// Event untuk mengubah theme mode
class ChangeThemeMode extends SettingsEvent {
  final ThemeModeOption themeMode;

  const ChangeThemeMode(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}

/// Event untuk mengubah language
class ChangeLanguage extends SettingsEvent {
  final LanguageOption language;

  const ChangeLanguage(this.language);

  @override
  List<Object?> get props => [language];
}

/// Event untuk mengubah font
class ChangeFont extends SettingsEvent {
  final FontOption font;

  const ChangeFont(this.font);

  @override
  List<Object?> get props => [font];
}

/// Event untuk reset semua settings ke default
class ResetSettings extends SettingsEvent {
  const ResetSettings();
}
