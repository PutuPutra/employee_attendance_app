# Settings - Quick Reference Guide

## 🚀 Quick Start

### Mengubah Theme

```dart
context.read<SettingsBloc>().add(
  ChangeThemeMode(ThemeModeOption.dark)
);
```

### Mengubah Language

```dart
context.read<SettingsBloc>().add(
  ChangeLanguage(LanguageOption.indonesian)
);
```

### Mengubah Font

```dart
context.read<SettingsBloc>().add(
  ChangeFont(FontOption.poppins)
);
```

### Mengakses Current Settings

```dart
BlocBuilder<SettingsBloc, SettingsState>(
  builder: (context, state) {
    if (state is SettingsLoaded) {
      final theme = state.settings.themeMode;
      final language = state.settings.language;
      final font = state.settings.font;
    }
  },
)
```

### Menggunakan Localization

```dart
final l10n = AppLocalizations.of(context);

Text(l10n.settings)     // "Settings" / "Pengaturan"
Text(l10n.theme)        // "Theme" / "Tema"
Text(l10n.language)     // "Language" / "Bahasa"
```

## 📁 File Structure

```
lib/
├── core/enums/              # Type-safe options
├── core/constants/          # Storage keys
├── models/                  # Data models
├── repositories/            # Data persistence
├── blocs/settings/          # Business logic
├── l10n/                    # Translations
└── UI/settings_screen.dart  # UI
```

## 🎯 Available Options

### Theme Options

- `ThemeModeOption.system` → Follows device theme
- `ThemeModeOption.light` → Light mode
- `ThemeModeOption.dark` → Dark mode

### Language Options

- `LanguageOption.system` → Follows device language
- `LanguageOption.english` → English
- `LanguageOption.indonesian` → Indonesian

### Font Options

- `FontOption.system` → System font
- `FontOption.poppins` → Poppins (App Default)

## 🔄 State Flow

```
User Action → Event → BLoC → State → UI Update
                        ↓
                   Repository
                        ↓
                SharedPreferences
```

## 📝 Events

```dart
LoadSettings()                    // Load from storage
ChangeThemeMode(theme)           // Change theme
ChangeLanguage(language)         // Change language
ChangeFont(font)                 // Change font
ResetSettings()                  // Reset to defaults
```

## 📊 States

```dart
SettingsInitial()                // Initial state
SettingsLoading()                // Loading settings
SettingsLoaded(settings)         // Settings loaded
SettingsError(message)           // Error occurred
```

## 🔑 Storage Keys

```dart
StorageKeys.theme          // 'app_theme_mode'
StorageKeys.language       // 'app_language'
StorageKeys.font           // 'app_font'
StorageKeys.isFirstLaunch  // 'is_first_launch'
```

## 🌍 Supported Locales

```dart
const Locale('en')  // English
const Locale('id')  // Indonesian
```

## ⚡ Common Patterns

### Listen to Settings Changes

```dart
BlocListener<SettingsBloc, SettingsState>(
  listener: (context, state) {
    if (state is SettingsLoaded) {
      // React to settings change
    }
  },
  child: YourWidget(),
)
```

### Get Settings Without Rebuild

```dart
final settings = context.read<SettingsBloc>().state;
if (settings is SettingsLoaded) {
  final theme = settings.settings.themeMode;
}
```

### Conditional UI Based on Settings

```dart
BlocBuilder<SettingsBloc, SettingsState>(
  builder: (context, state) {
    if (state is SettingsLoaded) {
      return state.settings.themeMode == ThemeModeOption.dark
        ? DarkWidget()
        : LightWidget();
    }
    return LoadingWidget();
  },
)
```

## 🛠️ Debugging

### Check Current Settings

```dart
print(context.read<SettingsBloc>().state);
```

### Clear All Settings (Testing)

```dart
final repo = SettingsRepository(prefs);
await repo.clearAllSettings();
```

### Force Reload Settings

```dart
context.read<SettingsBloc>().add(const LoadSettings());
```

## 📦 Dependencies Required

```yaml
flutter_bloc: ^8.1.6
equatable: ^2.0.7
shared_preferences: ^2.5.4
flutter_localizations:
  sdk: flutter
```

## ✅ Checklist untuk Developer Baru

- [ ] Pahami BLoC pattern
- [ ] Review struktur folder
- [ ] Lihat contoh di settings_screen.dart
- [ ] Test theme switching
- [ ] Test language switching
- [ ] Test font switching
- [ ] Verify persistence works
- [ ] Read SETTINGS_IMPLEMENTATION.md untuk detail lengkap

## 🐛 Common Issues

**Settings tidak tersimpan?**
→ Check SharedPreferences initialization di main.dart

**Theme tidak berubah?**
→ Pastikan MaterialApp wrapped dengan BlocBuilder

**Language tidak berubah?**
→ Verify localizationsDelegates configured

**Error saat build?**
→ Run `flutter pub get` untuk install dependencies

## 📚 Further Reading

- [BLoC Documentation](https://bloclibrary.dev/)
- [Flutter Localization](https://docs.flutter.dev/development/accessibility-and-localization/internationalization)
- [SharedPreferences](https://pub.dev/packages/shared_preferences)
- SETTINGS_IMPLEMENTATION.md (detailed documentation)
