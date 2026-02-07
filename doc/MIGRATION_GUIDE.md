# Migration Guide - Settings Implementation

## Overview

Panduan untuk mengintegrasikan Settings BLoC ke dalam screen yang sudah ada.

## Untuk Screen yang Sudah Ada

### 1. Home Screen Integration

Jika ingin menampilkan greeting berdasarkan bahasa yang dipilih:

```dart
// lib/UI/home_screen.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/settings/settings_bloc.dart';
import '../blocs/settings/settings_state.dart';
import '../l10n/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.home), // Akan otomatis berubah sesuai bahasa
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          if (state is SettingsLoaded) {
            // Akses settings jika diperlukan
            final currentTheme = state.settings.themeMode;
            final currentLanguage = state.settings.language;
          }

          return YourHomeContent();
        },
      ),
    );
  }
}
```

### 2. Navigasi ke Settings Screen

Dari screen manapun:

```dart
// Contoh: dari drawer atau menu
ListTile(
  leading: Icon(Icons.settings),
  title: Text('Settings'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  },
)
```

### 3. Menggunakan Theme di Widget Custom

```dart
class CustomWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Otomatis mengikuti theme yang dipilih
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: isDark ? Colors.grey[800] : Colors.white,
      child: Text(
        'Hello',
        style: theme.textTheme.bodyLarge,
      ),
    );
  }
}
```

### 4. Conditional Rendering Based on Settings

```dart
BlocBuilder<SettingsBloc, SettingsState>(
  builder: (context, state) {
    if (state is SettingsLoaded) {
      // Tampilkan widget berbeda berdasarkan font
      if (state.settings.font == FontOption.poppins) {
        return PoppinsStyledWidget();
      }
      return SystemStyledWidget();
    }
    return DefaultWidget();
  },
)
```

## Menambahkan Localization ke Screen Existing

### Step 1: Update AppLocalizations

```dart
// lib/l10n/app_localizations.dart

// Tambahkan getter baru
String get home => _localizedValues[locale.languageCode]!['home']!;
String get profile => _localizedValues[locale.languageCode]!['profile']!;

// Tambahkan translations
static const Map<String, Map<String, String>> _localizedValues = {
  'en': {
    'home': 'Home',
    'profile': 'Profile',
    // ... existing translations
  },
  'id': {
    'home': 'Beranda',
    'profile': 'Profil',
    // ... existing translations
  },
};
```

### Step 2: Gunakan di Screen

```dart
class YourScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.yourScreenTitle),
      ),
      body: Column(
        children: [
          Text(l10n.someText),
          ElevatedButton(
            onPressed: () {},
            child: Text(l10n.buttonText),
          ),
        ],
      ),
    );
  }
}
```

## Testing Settings Integration

### Test 1: Theme Switching

```dart
testWidgets('Theme changes when user selects new theme', (tester) async {
  await tester.pumpWidget(MyApp(settingsRepository: mockRepository));

  // Navigate to settings
  await tester.tap(find.byIcon(Icons.settings));
  await tester.pumpAndSettle();

  // Change theme
  await tester.tap(find.text('Theme'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Dark'));
  await tester.pumpAndSettle();

  // Verify theme changed
  final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
  expect(materialApp.themeMode, ThemeMode.dark);
});
```

### Test 2: Language Switching

```dart
testWidgets('Language changes when user selects new language', (tester) async {
  await tester.pumpWidget(MyApp(settingsRepository: mockRepository));

  // Navigate to settings
  await tester.tap(find.byIcon(Icons.settings));
  await tester.pumpAndSettle();

  // Change language
  await tester.tap(find.text('Language'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Indonesia'));
  await tester.pumpAndSettle();

  // Verify language changed
  expect(find.text('Pengaturan'), findsOneWidget);
});
```

## Best Practices

### ✅ DO

```dart
// Use localization
final l10n = AppLocalizations.of(context);
Text(l10n.title)

// Use Theme.of(context)
final theme = Theme.of(context);
Container(color: theme.primaryColor)

// Listen to settings changes
BlocBuilder<SettingsBloc, SettingsState>(...)
```

### ❌ DON'T

```dart
// Don't hardcode strings
Text('Settings') // ❌

// Don't hardcode colors
Container(color: Colors.blue) // ❌ (unless intentional)

// Don't access settings without BLoC
SharedPreferences.getInstance() // ❌ (use BLoC instead)
```

## Rollback Plan

Jika perlu rollback ke implementasi lama:

1. **Backup files** yang sudah dimodifikasi
2. **Revert main.dart** ke versi sebelumnya
3. **Remove BLoC dependencies** dari pubspec.yaml
4. **Restore old settings_screen.dart**
5. **Run** `flutter pub get`

## Checklist Migrasi

- [ ] Install dependencies (`flutter pub get`)
- [ ] Test theme switching
- [ ] Test language switching
- [ ] Test font switching
- [ ] Test persistence (restart app)
- [ ] Test first launch behavior
- [ ] Update existing screens dengan localization
- [ ] Test navigation ke Settings screen
- [ ] Verify no breaking changes di existing features
- [ ] Update documentation jika perlu

## Support

Jika ada pertanyaan atau issue:

1. Check SETTINGS_IMPLEMENTATION.md untuk detail lengkap
2. Check SETTINGS_QUICK_REFERENCE.md untuk contoh cepat
3. Review kode di lib/UI/settings_screen.dart sebagai referensi
4. Test dengan `flutter analyze` untuk check errors

## Next Steps

1. ✅ Implementasi sudah selesai
2. 🧪 Test semua fitur
3. 📝 Update screens lain dengan localization
4. 🚀 Deploy ke production

---

**Note**: Implementasi ini backward compatible. Screen yang sudah ada akan tetap berfungsi normal tanpa perlu modifikasi, kecuali jika ingin menggunakan fitur localization atau reactive theme.
