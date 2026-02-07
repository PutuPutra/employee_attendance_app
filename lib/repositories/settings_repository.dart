import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/storage_keys.dart';
import '../core/enums/theme_mode_option.dart';
import '../core/enums/language_option.dart';
import '../core/enums/font_option.dart';
import '../models/app_settings.dart';

/// Repository untuk mengelola persistent storage settings
///
/// Bertanggung jawab untuk:
/// - Load settings dari SharedPreferences
/// - Save settings ke SharedPreferences
/// - Mendeteksi first launch
class SettingsRepository {
  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  /// Load semua settings dari storage
  ///
  /// Returns AppSettings dengan nilai default jika belum ada data tersimpan
  Future<AppSettings> loadSettings() async {
    try {
      final themeString = _prefs.getString(StorageKeys.theme);
      final languageString = _prefs.getString(StorageKeys.language);
      final fontString = _prefs.getString(StorageKeys.font);

      // Jika semua null, berarti first launch atau belum ada settings
      if (themeString == null && languageString == null && fontString == null) {
        return AppSettings.defaultSettings();
      }

      return AppSettings(
        themeMode: ThemeModeOption.fromString(themeString ?? 'system'),
        language: LanguageOption.fromString(languageString ?? 'system'),
        font: FontOption.fromString(fontString ?? 'system'),
      );
    } catch (e) {
      // Jika terjadi error, return default settings
      return AppSettings.defaultSettings();
    }
  }

  /// Save theme mode ke storage
  Future<bool> saveThemeMode(ThemeModeOption themeMode) async {
    try {
      return await _prefs.setString(
        StorageKeys.theme,
        themeMode.toStorageString(),
      );
    } catch (e) {
      return false;
    }
  }

  /// Save language ke storage
  Future<bool> saveLanguage(LanguageOption language) async {
    try {
      return await _prefs.setString(
        StorageKeys.language,
        language.toStorageString(),
      );
    } catch (e) {
      return false;
    }
  }

  /// Save font ke storage
  Future<bool> saveFont(FontOption font) async {
    try {
      return await _prefs.setString(StorageKeys.font, font.toStorageString());
    } catch (e) {
      return false;
    }
  }

  /// Save semua settings sekaligus
  Future<bool> saveAllSettings(AppSettings settings) async {
    try {
      final results = await Future.wait([
        saveThemeMode(settings.themeMode),
        saveLanguage(settings.language),
        saveFont(settings.font),
      ]);

      // Return true jika semua berhasil
      return results.every((result) => result == true);
    } catch (e) {
      return false;
    }
  }

  /// Check apakah ini first launch
  Future<bool> isFirstLaunch() async {
    try {
      final isFirst = _prefs.getBool(StorageKeys.isFirstLaunch) ?? true;
      return isFirst;
    } catch (e) {
      return true;
    }
  }

  /// Set first launch flag ke false
  Future<bool> setFirstLaunchComplete() async {
    try {
      return await _prefs.setBool(StorageKeys.isFirstLaunch, false);
    } catch (e) {
      return false;
    }
  }

  /// Clear semua settings (untuk testing atau reset)
  Future<bool> clearAllSettings() async {
    try {
      await _prefs.remove(StorageKeys.theme);
      await _prefs.remove(StorageKeys.language);
      await _prefs.remove(StorageKeys.font);
      await _prefs.remove(StorageKeys.isFirstLaunch);
      return true;
    } catch (e) {
      return false;
    }
  }
}
