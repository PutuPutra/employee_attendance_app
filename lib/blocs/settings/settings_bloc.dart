import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/settings_repository.dart';
import '../../models/app_settings.dart';
import 'settings_event.dart';
import 'settings_state.dart';

/// BLoC untuk mengelola state dan business logic settings
///
/// Bertanggung jawab untuk:
/// - Handle semua events terkait settings
/// - Update state berdasarkan event
/// - Koordinasi dengan repository untuk persistence
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _repository;

  SettingsBloc(this._repository) : super(const SettingsInitial()) {
    // Register event handlers
    on<LoadSettings>(_onLoadSettings);
    on<ChangeThemeMode>(_onChangeThemeMode);
    on<ChangeLanguage>(_onChangeLanguage);
    on<ChangeFont>(_onChangeFont);
    on<ResetSettings>(_onResetSettings);
  }

  /// Handler untuk LoadSettings event
  ///
  /// Load settings dari repository dan emit SettingsLoaded state
  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      emit(const SettingsLoading());

      // Load settings dari repository
      final settings = await _repository.loadSettings();

      // Check apakah first launch
      final isFirstLaunch = await _repository.isFirstLaunch();

      if (isFirstLaunch) {
        // Jika first launch, gunakan default settings (system)
        // dan tandai bahwa first launch sudah selesai
        await _repository.setFirstLaunchComplete();
        emit(SettingsLoaded(AppSettings.defaultSettings()));
      } else {
        // Jika bukan first launch, gunakan settings yang tersimpan
        emit(SettingsLoaded(settings));
      }
    } catch (e) {
      emit(SettingsError('Failed to load settings: ${e.toString()}'));
    }
  }

  /// Handler untuk ChangeThemeMode event
  ///
  /// Update theme mode dan simpan ke storage
  Future<void> _onChangeThemeMode(
    ChangeThemeMode event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      // Pastikan state saat ini adalah SettingsLoaded
      if (state is! SettingsLoaded) return;

      final currentSettings = (state as SettingsLoaded).settings;

      // Buat settings baru dengan theme mode yang diupdate
      final newSettings = currentSettings.copyWith(themeMode: event.themeMode);

      // Emit state baru terlebih dahulu untuk UI responsiveness
      emit(SettingsLoaded(newSettings));

      // Simpan ke storage di background
      await _repository.saveThemeMode(event.themeMode);
    } catch (e) {
      emit(SettingsError('Failed to change theme: ${e.toString()}'));
    }
  }

  /// Handler untuk ChangeLanguage event
  ///
  /// Update language dan simpan ke storage
  Future<void> _onChangeLanguage(
    ChangeLanguage event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      if (state is! SettingsLoaded) return;

      final currentSettings = (state as SettingsLoaded).settings;

      final newSettings = currentSettings.copyWith(language: event.language);

      emit(SettingsLoaded(newSettings));

      await _repository.saveLanguage(event.language);
    } catch (e) {
      emit(SettingsError('Failed to change language: ${e.toString()}'));
    }
  }

  /// Handler untuk ChangeFont event
  ///
  /// Update font dan simpan ke storage
  Future<void> _onChangeFont(
    ChangeFont event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      if (state is! SettingsLoaded) return;

      final currentSettings = (state as SettingsLoaded).settings;

      final newSettings = currentSettings.copyWith(font: event.font);

      emit(SettingsLoaded(newSettings));

      await _repository.saveFont(event.font);
    } catch (e) {
      emit(SettingsError('Failed to change font: ${e.toString()}'));
    }
  }

  /// Handler untuk ResetSettings event
  ///
  /// Reset semua settings ke default (system)
  Future<void> _onResetSettings(
    ResetSettings event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      emit(const SettingsLoading());

      // Clear semua settings dari storage
      await _repository.clearAllSettings();

      // Emit default settings
      emit(SettingsLoaded(AppSettings.defaultSettings()));
    } catch (e) {
      emit(SettingsError('Failed to reset settings: ${e.toString()}'));
    }
  }
}
