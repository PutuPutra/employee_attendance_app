# Settings Implementation Documentation

## Overview

Implementasi backend dan state management untuk halaman Settings menggunakan **BLoC (Business Logic Component)** pattern dengan prinsip clean architecture.

## Fitur yang Diimplementasikan

### 1. Theme Management

- **Light Mode**: Tema terang
- **Dark Mode**: Tema gelap
- **System Default**: Mengikuti tema sistem device

### 2. Language Management

- **English**: Bahasa Inggris
- **Indonesian**: Bahasa Indonesia
- **System Default**: Mengikuti bahasa sistem device

### 3. Font Management

- **System Font**: Menggunakan font sistem device
- **App Default (Poppins)**: Menggunakan font Poppins

## Arsitektur

### Clean Architecture Layers

```
┌─────────────────────────────────────────┐
│           Presentation Layer            │
│  (UI/settings_screen.dart)              │
│  - BlocBuilder untuk reactive UI        │
│  - Event dispatching ke BLoC            │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│           BLoC Layer                    │
│  (blocs/settings/)                      │
│  - SettingsBloc: Business logic         │
│  - SettingsEvent: User actions          │
│  - SettingsState: UI states             │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│           Data Layer                    │
│  (repositories/settings_repository.dart)│
│  - Persistent storage management        │
│  - SharedPreferences operations         │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│           Model Layer                   │
│  (models/app_settings.dart)             │
│  - Immutable data models                │
│  - Type-safe enums                      │
└─────────────────────────────────────────┘
```

## Struktur File

```
lib/
├── core/
│   ├── enums/
│   │   ├── theme_mode_option.dart      # Enum untuk opsi tema
│   │   ├── language_option.dart        # Enum untuk opsi bahasa
│   │   └── font_option.dart            # Enum untuk opsi font
│   └── constants/
│       └── storage_keys.dart           # Konstanta untuk SharedPreferences keys
│
├── models/
│   └── app_settings.dart               # Model immutable untuk settings
│
├── repositories/
│   └── settings_repository.dart        # Repository untuk persistent storage
│
├── blocs/
│   └── settings/
│       ├── settings_event.dart         # Events (LoadSettings, ChangeTheme, dll)
│       ├── settings_state.dart         # States (Loading, Loaded, Error)
│       └── settings_bloc.dart          # Business logic handler
│
├── l10n/
│   └── app_localizations.dart          # Localization untuk EN dan ID
│
├── UI/
│   └── settings_screen.dart            # Settings UI dengan BLoC integration
│
└── main.dart                           # App initialization dengan BlocProvider
```

## Cara Kerja

### 1. Initialization (First Launch)

```dart
// Di main.dart
void main() async {
  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Create repository
  final settingsRepository = SettingsRepository(prefs);

  // Provide SettingsBloc ke seluruh app
  runApp(MyApp(settingsRepository: settingsRepository));
}
```

### 2. Load Settings

```dart
// SettingsBloc automatically loads settings on initialization
SettingsBloc(settingsRepository)..add(const LoadSettings())

// Flow:
// 1. Check if first launch
// 2. If first launch → use system defaults
// 3. If not → load saved settings from SharedPreferences
// 4. Emit SettingsLoaded state
```

### 3. Change Settings

```dart
// User changes theme
context.read<SettingsBloc>().add(ChangeThemeMode(ThemeModeOption.dark));

// Flow:
// 1. BLoC receives event
// 2. Update state immediately (for UI responsiveness)
// 3. Save to SharedPreferences in background
// 4. Emit new SettingsLoaded state
```

### 4. Persistence

```dart
// Settings automatically saved to SharedPreferences
// Keys defined in StorageKeys class:
// - 'app_theme_mode'
// - 'app_language'
// - 'app_font'
// - 'is_first_launch'
```

## Penggunaan

### Mengakses Settings di UI

```dart
// Menggunakan BlocBuilder
BlocBuilder<SettingsBloc, SettingsState>(
  builder: (context, state) {
    if (state is SettingsLoaded) {
      final settings = state.settings;

      // Access theme
      final theme = settings.themeMode;

      // Access language
      final language = settings.language;

      // Access font
      final font = settings.font;
    }
    return YourWidget();
  },
)
```

### Mengubah Settings

```dart
// Change theme
context.read<SettingsBloc>().add(
  ChangeThemeMode(ThemeModeOption.dark)
);

// Change language
context.read<SettingsBloc>().add(
  ChangeLanguage(LanguageOption.indonesian)
);

// Change font
context.read<SettingsBloc>().add(
  ChangeFont(FontOption.poppins)
);
```

### Menggunakan Localization

```dart
// Get localized strings
final l10n = AppLocalizations.of(context);

Text(l10n.settings)        // "Settings" atau "Pengaturan"
Text(l10n.theme)           // "Theme" atau "Tema"
Text(l10n.language)        // "Language" atau "Bahasa"
```

## Prinsip Clean Code yang Diterapkan

### 1. Separation of Concerns

- **UI Layer**: Hanya menampilkan data dan dispatch events
- **BLoC Layer**: Business logic dan state management
- **Repository Layer**: Data persistence
- **Model Layer**: Data structures

### 2. Type Safety

```dart
// Menggunakan enum instead of strings
enum ThemeModeOption { system, light, dark }

// NOT: String theme = "dark"
// BUT: ThemeModeOption theme = ThemeModeOption.dark
```

### 3. Immutability

```dart
// AppSettings is immutable
class AppSettings extends Equatable {
  final ThemeModeOption themeMode;
  final LanguageOption language;
  final FontOption font;

  const AppSettings({...});

  // Use copyWith for changes
  AppSettings copyWith({...}) {...}
}
```

### 4. Single Responsibility

- `SettingsRepository`: Hanya handle storage operations
- `SettingsBloc`: Hanya handle business logic
- `AppSettings`: Hanya hold data

### 5. Dependency Injection

```dart
// Repository di-inject ke BLoC
SettingsBloc(SettingsRepository repository)

// BLoC di-provide via BlocProvider
BlocProvider(
  create: (context) => SettingsBloc(settingsRepository),
  child: App(),
)
```

### 6. Constants & Configuration

```dart
// Centralized storage keys
class StorageKeys {
  static const String theme = 'app_theme_mode';
  static const String language = 'app_language';
  static const String font = 'app_font';
}
```

## Testing

### Unit Testing SettingsBloc

```dart
test('should emit SettingsLoaded when LoadSettings is added', () async {
  // Arrange
  final repository = MockSettingsRepository();
  final bloc = SettingsBloc(repository);

  // Act
  bloc.add(const LoadSettings());

  // Assert
  await expectLater(
    bloc.stream,
    emitsInOrder([
      const SettingsLoading(),
      isA<SettingsLoaded>(),
    ]),
  );
});
```

### Integration Testing

```dart
testWidgets('should change theme when user selects new theme', (tester) async {
  // Build app
  await tester.pumpWidget(MyApp());

  // Tap theme option
  await tester.tap(find.text('Theme'));
  await tester.pumpAndSettle();

  // Select dark theme
  await tester.tap(find.text('Dark'));
  await tester.pumpAndSettle();

  // Verify theme changed
  expect(find.byType(DarkTheme), findsOneWidget);
});
```

## Extensibility

### Menambah Setting Baru

1. **Tambah Enum** (jika perlu)

```dart
// lib/core/enums/new_option.dart
enum NewOption { option1, option2 }
```

2. **Update Model**

```dart
class AppSettings {
  final NewOption newSetting;
  // ... existing fields
}
```

3. **Update Repository**

```dart
Future<bool> saveNewSetting(NewOption option) async {
  return await _prefs.setString('new_setting', option.name);
}
```

4. **Tambah Event & Handler di BLoC**

```dart
class ChangeNewSetting extends SettingsEvent {
  final NewOption option;
}

void _onChangeNewSetting(event, emit) {
  // Handle event
}
```

5. **Update UI**

```dart
// Add UI component in settings_screen.dart
```

## Best Practices

1. ✅ **Always use enums** instead of magic strings
2. ✅ **Keep models immutable** using `const` and `final`
3. ✅ **Use copyWith** for creating modified copies
4. ✅ **Emit state immediately** for UI responsiveness
5. ✅ **Save to storage in background** to avoid blocking UI
6. ✅ **Handle errors gracefully** with try-catch
7. ✅ **Document your code** with clear comments
8. ✅ **Use meaningful names** for variables and methods
9. ✅ **Keep functions small** and focused
10. ✅ **Test your code** with unit and integration tests

## Troubleshooting

### Settings tidak tersimpan

- Check SharedPreferences initialization
- Verify storage keys are correct
- Check repository save methods return true

### Theme tidak berubah

- Verify BLoC is provided at app level
- Check MaterialApp is wrapped with BlocBuilder
- Ensure theme is applied to MaterialApp

### Language tidak berubah

- Check locale is set in MaterialApp
- Verify localizationsDelegates are configured
- Ensure AppLocalizations.delegate is included

## Dependencies

```yaml
dependencies:
  flutter_bloc: ^8.1.6 # State management
  equatable: ^2.0.7 # Value equality
  shared_preferences: ^2.5.4 # Persistent storage
  flutter_localizations: # Internationalization
    sdk: flutter
```

## Kesimpulan

Implementasi ini mengikuti best practices dalam Flutter development:

- ✅ Clean Architecture
- ✅ BLoC Pattern
- ✅ Type Safety
- ✅ Immutability
- ✅ Separation of Concerns
- ✅ Testability
- ✅ Scalability
- ✅ Maintainability

Kode mudah dibaca, dipahami, dan di-maintain oleh developer lain.
