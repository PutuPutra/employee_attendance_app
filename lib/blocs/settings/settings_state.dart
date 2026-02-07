import 'package:equatable/equatable.dart';
import '../../models/app_settings.dart';

/// Base class untuk semua Settings States
abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

/// State awal sebelum settings di-load
class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

/// State saat settings sedang di-load
class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

/// State saat settings berhasil di-load
class SettingsLoaded extends SettingsState {
  final AppSettings settings;

  const SettingsLoaded(this.settings);

  @override
  List<Object?> get props => [settings];
}

/// State saat terjadi error
class SettingsError extends SettingsState {
  final String message;

  const SettingsError(this.message);

  @override
  List<Object?> get props => [message];
}
