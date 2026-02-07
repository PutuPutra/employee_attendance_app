# Employee Attendance App

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.10.7-02569B?style=for-the-badge&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.10.7-0175C2?style=for-the-badge&logo=dart)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![License](https://img.shields.io/badge/License-Private-red?style=for-the-badge)

**Aplikasi Presensi Karyawan dengan Face Recognition**

[Features](#-features) • [Screenshots](#-screenshots) • [Installation](#-installation) • [Architecture](#-architecture) • [Documentation](#-documentation)

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Screenshots](#-screenshots)
- [Tech Stack](#-tech-stack)
- [Architecture](#-architecture)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Usage](#-usage)
- [Project Structure](#-project-structure)
- [Documentation](#-documentation)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🌟 Overview

**Employee Attendance App** adalah aplikasi mobile modern untuk manajemen presensi karyawan dengan teknologi face recognition. Aplikasi ini dibangun menggunakan Flutter dengan arsitektur clean code dan BLoC pattern untuk state management yang robust dan scalable.

### Key Highlights

- ✅ **Face Recognition** - Presensi menggunakan pengenalan wajah
- ✅ **Multi-Language** - Mendukung Bahasa Indonesia dan English
- ✅ **Dark Mode** - Tema terang dan gelap yang dapat disesuaikan
- ✅ **Real-time Updates** - Perubahan settings langsung diterapkan
- ✅ **Offline Support** - Data tersimpan secara lokal
- ✅ **Clean Architecture** - Mudah di-maintain dan dikembangkan

---

## ✨ Features

### 🔐 Authentication

- **Firebase Authentication** - Login aman dengan email & password
- **Password Reset** - Reset password via email
- **Session Management** - Auto-login untuk user yang sudah login

### 👤 Face Recognition

- **Face Registration** - Daftarkan wajah untuk presensi
- **Face Scan** - Scan wajah untuk check-in/out
- **Multiple Faces** - Kelola multiple face data

### ⏰ Attendance Management

- **Check In/Out** - Presensi masuk dan pulang
- **Break Time** - Catat waktu istirahat
- **Return Time** - Catat waktu kembali dari istirahat
- **History** - Lihat riwayat kehadiran
- **Date Filter** - Filter riwayat berdasarkan tanggal

### ⚙️ Settings & Customization

- **Theme Management**
  - Light Mode
  - Dark Mode
  - System Default (mengikuti tema device)
- **Language Support**
  - 🇬🇧 English
  - 🇮🇩 Bahasa Indonesia
  - System Default (mengikuti bahasa device)
- **Font Options**
  - System Font
  - Poppins (App Default)

- **Security**
  - Biometric Login (Coming Soon)
  - Change Password
  - Face Data Management

### 📊 Additional Features

- **Real-time Clock** - Tampilan waktu real-time
- **Location Tracking** - Catat lokasi saat presensi
- **Persistent Storage** - Settings tersimpan otomatis
- **Responsive UI** - Tampilan optimal di berbagai ukuran layar

---

## 📱 Screenshots

### Light Mode

| Login                                       | Home                                      | Settings                                          |
| ------------------------------------------- | ----------------------------------------- | ------------------------------------------------- |
| ![Login Light](screenshots/login_light.png) | ![Home Light](screenshots/home_light.png) | ![Settings Light](screenshots/settings_light.png) |

### Dark Mode

| Login                                     | Home                                    | Settings                                        |
| ----------------------------------------- | --------------------------------------- | ----------------------------------------------- |
| ![Login Dark](screenshots/login_dark.png) | ![Home Dark](screenshots/home_dark.png) | ![Settings Dark](screenshots/settings_dark.png) |

### Face Recognition

| Face Registration                                       | Face Scan                               |
| ------------------------------------------------------- | --------------------------------------- |
| ![Face Registration](screenshots/face_registration.png) | ![Face Scan](screenshots/face_scan.png) |

---

## 🛠️ Tech Stack

### Frontend

- **Flutter** 3.10.7 - UI Framework
- **Dart** 3.10.7 - Programming Language

### State Management

- **flutter_bloc** 8.1.6 - BLoC Pattern implementation
- **equatable** 2.0.7 - Value equality

### Backend & Services

- **Firebase Core** 4.4.0 - Firebase SDK
- **Firebase Auth** 6.1.4 - Authentication

### Storage

- **shared_preferences** 2.5.4 - Local data persistence

### UI/UX

- **animate_do** 4.2.0 - Animations
- **lottie** 3.3.2 - Lottie animations
- **cupertino_icons** 1.0.8 - iOS-style icons

### Localization

- **flutter_localizations** - Multi-language support
- **intl** 0.20.2 - Internationalization

---

## 🏗️ Architecture

Aplikasi ini menggunakan **Clean Architecture** dengan **BLoC Pattern** untuk memastikan kode yang maintainable dan scalable.

```
┌─────────────────────────────────────────────────────────┐
│                  Presentation Layer                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│  │  Login   │  │   Home   │  │ Settings │  ... (6 UI)  │
│  └──────────┘  └──────────┘  └──────────┘              │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                    BLoC Layer                            │
│  ┌──────────────┐  ┌──────────────┐                     │
│  │SettingsBloc  │  │  AuthService │  ...                │
│  └──────────────┘  └──────────────┘                     │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                 Repository Layer                         │
│  ┌────────────────────┐  ┌──────────────────┐           │
│  │SettingsRepository  │  │ Other Repos...   │           │
│  └────────────────────┘  └──────────────────┘           │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                   Data Layer                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ SharedPrefs  │  │   Firebase   │  │  Local DB    │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Layer Responsibilities

#### 1. **Presentation Layer** (UI)

- Menampilkan data ke user
- Menangani user interactions
- Menggunakan BLoC untuk state management

#### 2. **BLoC Layer** (Business Logic)

- Mengelola application state
- Memproses business logic
- Berkomunikasi dengan Repository

#### 3. **Repository Layer** (Data Access)

- Abstraksi untuk data sources
- Mengelola data persistence
- Caching dan data synchronization

#### 4. **Data Layer** (Data Sources)

- SharedPreferences untuk local storage
- Firebase untuk authentication & cloud data
- Local database untuk offline support

---

## 📥 Installation

### Prerequisites

- Flutter SDK 3.10.7 atau lebih baru
- Dart SDK 3.10.7 atau lebih baru
- Android Studio / VS Code
- Git

### Steps

1. **Clone Repository**

   ```bash
   git clone https://github.com/PutuPutra/employee_attendance_app.git
   cd employee_attendance_app
   ```

2. **Install Dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Buat project di [Firebase Console](https://console.firebase.google.com/)
   - Download `google-services.json` (Android) dan `GoogleService-Info.plist` (iOS)
   - Letakkan file di lokasi yang sesuai:
     - Android: `android/app/google-services.json`
     - iOS: `ios/Runner/GoogleService-Info.plist`

4. **Run the App**

   ```bash
   # Debug mode
   flutter run

   # Release mode
   flutter run --release
   ```

---

## ⚙️ Configuration

### Firebase Setup

1. **Enable Authentication**
   - Buka Firebase Console → Authentication
   - Enable Email/Password authentication

2. **Configure Firebase Options**
   - File sudah tersedia di `lib/firebase_options.dart`
   - Generated menggunakan FlutterFire CLI

### App Configuration

Edit `pubspec.yaml` untuk konfigurasi tambahan:

```yaml
name: employee_attendance
description: "Employee Attendance App with Face Recognition"
version: 1.0.0+1

environment:
  sdk: ^3.10.7
```

---

## 🚀 Usage

### First Launch

Saat pertama kali membuka aplikasi:

1. Semua settings akan mengikuti pengaturan sistem device
2. Theme mengikuti tema sistem (Light/Dark)
3. Language mengikuti bahasa sistem
4. Font menggunakan system default

### Login

1. Masukkan email dan password
2. Klik tombol "Login"
3. Jika lupa password, klik "Forgot Password?"

### Presensi

#### Check In

1. Dari Home screen, tap "Check In"
2. Posisikan wajah di dalam lingkaran
3. Tap "Capture" untuk mengambil foto
4. Konfirmasi data dan lokasi
5. Tap "Submit"

#### Break & Return

- Sama seperti Check In
- Pilih "Break" untuk istirahat
- Pilih "Return" untuk kembali

#### Check Out

- Sama seperti Check In
- Pilih "Check Out" untuk pulang

### Settings

#### Change Theme

1. Buka Settings
2. Tap "Theme"
3. Pilih: System / Light / Dark
4. Theme langsung berubah

#### Change Language

1. Buka Settings
2. Tap "Language"
3. Pilih: System / English / Indonesia
4. Bahasa langsung berubah

#### Change Font

1. Buka Settings
2. Tap "Font"
3. Pilih: System / App Default (Poppins)
4. Font langsung berubah

---

## 📁 Project Structure

```
employee_attendance_app/
├── android/                    # Android native code
├── ios/                        # iOS native code
├── lib/                        # Main application code
│   ├── core/                   # Core utilities
│   │   ├── enums/             # Type-safe enumerations
│   │   │   ├── theme_mode_option.dart
│   │   │   ├── language_option.dart
│   │   │   └── font_option.dart
│   │   └── constants/         # App constants
│   │       └── storage_keys.dart
│   │
│   ├── models/                # Data models
│   │   └── app_settings.dart
│   │
│   ├── repositories/          # Data access layer
│   │   └── settings_repository.dart
│   │
│   ├── blocs/                 # Business logic (BLoC)
│   │   └── settings/
│   │       ├── settings_event.dart
│   │       ├── settings_state.dart
│   │       └── settings_bloc.dart
│   │
│   ├── l10n/                  # Localization
│   │   └── app_localizations.dart
│   │
│   ├── auth/                  # Authentication
│   │   └── auth_service.dart
│   │
│   ├── UI/                    # User Interface
│   │   ├── login_screen.dart
│   │   ├── home_screen.dart
│   │   ├── reset_password.dart
│   │   ├── settings_screen.dart
│   │   ├── face_screen.dart
│   │   └── face_scan.dart
│   │
│   ├── firebase_options.dart  # Firebase configuration
│   └── main.dart              # App entry point
│
├── fonts/                     # Custom fonts (Poppins)
├── doc/                       # Documentation
│   ├── SETTINGS_IMPLEMENTATION.md
│   ├── SETTINGS_QUICK_REFERENCE.md
│   ├── MIGRATION_GUIDE.md
│   ├── ARCHITECTURE_DIAGRAM.md
│   ├── IMPLEMENTATION_SUMMARY.md
│   ├── DARK_MODE_LOCALIZATION_UPDATE.md
│   └── COMPLETE_IMPLEMENTATION_SUMMARY.md
│
├── pubspec.yaml              # Dependencies & assets
├── README.md                 # This file
└── analysis_options.yaml    # Linter rules
```

---

## 📚 Documentation

### Comprehensive Guides

1. **[Settings Implementation Guide](doc/SETTINGS_IMPLEMENTATION.md)**
   - Detailed architecture explanation
   - Code examples and patterns
   - Best practices
   - Testing guidelines

2. **[Quick Reference](doc/SETTINGS_QUICK_REFERENCE.md)**
   - Quick code snippets
   - Common usage patterns
   - Troubleshooting tips

3. **[Migration Guide](doc/MIGRATION_GUIDE.md)**
   - Step-by-step integration guide
   - Migration checklist
   - Testing procedures

4. **[Architecture Diagrams](doc/ARCHITECTURE_DIAGRAM.md)**
   - Visual architecture diagrams
   - Data flow illustrations
   - Component interactions

5. **[Implementation Summary](doc/IMPLEMENTATION_SUMMARY.md)**
   - Complete implementation report
   - Requirements checklist
   - Code quality metrics

6. **[Dark Mode & Localization](doc/DARK_MODE_LOCALIZATION_UPDATE.md)**
   - Dark mode implementation details
   - Localization guide
   - Screen-by-screen breakdown

7. **[Complete Summary](doc/COMPLETE_IMPLEMENTATION_SUMMARY.md)**
   - Final summary
   - Complete feature list
   - Production readiness checklist

### Code Documentation

Setiap file dalam project memiliki:

- **Class documentation** - Penjelasan purpose dan usage
- **Method documentation** - Parameter dan return value
- **Inline comments** - Penjelasan logic yang kompleks

---

## 🧪 Testing

### Run Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/widget_test.dart
```

### Static Analysis

```bash
# Run analyzer
flutter analyze

# Check for issues
dart analyze
```

### Code Quality

```bash
# Format code
flutter format .

# Check formatting
flutter format --set-exit-if-changed .
```

---

## 🔧 Development

### Adding New Features

1. **Create Feature Branch**

   ```bash
   git checkout -b feature/new-feature
   ```

2. **Follow Architecture**
   - Add model in `lib/models/`
   - Add repository in `lib/repositories/`
   - Add BLoC in `lib/blocs/`
   - Add UI in `lib/UI/`

3. **Add Tests**
   - Unit tests for business logic
   - Widget tests for UI
   - Integration tests for flows

4. **Update Documentation**
   - Update README if needed
   - Add code comments
   - Update relevant docs

5. **Submit Pull Request**
   ```bash
   git add .
   git commit -m "feat: add new feature"
   git push origin feature/new-feature
   ```

### Code Style

Project mengikuti [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines:

- Use `lowerCamelCase` for variables and methods
- Use `UpperCamelCase` for classes and enums
- Use `snake_case` for file names
- Maximum line length: 80 characters
- Use trailing commas for better formatting

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Contribution Guidelines

- Follow the existing code style
- Write meaningful commit messages
- Add tests for new features
- Update documentation
- Ensure all tests pass

---

## 📝 Changelog

### Version 1.0.0 (Current)

#### Features

- ✅ Firebase Authentication
- ✅ Face Recognition (UI Ready)
- ✅ Attendance Management
- ✅ Settings with BLoC
- ✅ Dark Mode Support
- ✅ Multi-language (EN/ID)
- ✅ Custom Font Support
- ✅ Persistent Storage

#### Improvements

- ✅ Clean Architecture
- ✅ BLoC Pattern
- ✅ Type-safe Enums
- ✅ Comprehensive Documentation

---

## 🐛 Known Issues

- Face recognition backend not yet implemented
- Biometric login coming soon
- Offline sync pending

---

## 🗺️ Roadmap

### Version 1.1.0 (Planned)

- [ ] Face recognition backend integration
- [ ] Biometric authentication
- [ ] Offline mode with sync
- [ ] Push notifications
- [ ] Export attendance reports

### Version 1.2.0 (Future)

- [ ] Admin dashboard
- [ ] Team management
- [ ] Leave management
- [ ] Overtime tracking
- [ ] Analytics & reports

---

## 📄 License

This project is private and proprietary. All rights reserved.

---

## 👥 Team

### Development Team

- **Lead Developer** - BLACKBOXAI
- **Architecture** - Clean Architecture with BLoC
- **UI/UX** - Material Design with Cupertino elements

---

## 📞 Support

For support and questions:

- **Email**: putupersada@gmail.com
- **Documentation**: [docs](doc/)
- **Issues**: [GitHub Issues](https://github.com/PutuPutra/employee_attendance_app/issues)

---

## 🙏 Acknowledgments

- Flutter Team for the amazing framework
- Firebase for backend services
- BLoC Library contributors
- Open source community

---

<div align="center">

**Made with ❤️ using Flutter**

[⬆ Back to Top](#employee_attendance_app)

</div>
