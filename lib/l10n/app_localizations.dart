import 'package:flutter/material.dart';

/// Class untuk mengelola localization/internationalization
///
/// Mendukung bahasa:
/// - English (en)
/// - Indonesian (id)
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  /// Helper method untuk mendapatkan instance dari context
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  /// Delegate untuk AppLocalizations
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('id'), // Indonesian
  ];

  // ===== Translations =====

  // Common
  String get cancel => _localizedValues[locale.languageCode]!['cancel']!;
  String get ok => _localizedValues[locale.languageCode]!['ok']!;
  String get yes => _localizedValues[locale.languageCode]!['yes']!;
  String get no => _localizedValues[locale.languageCode]!['no']!;

  // Login Screen
  String get login => _localizedValues[locale.languageCode]!['login']!;
  String get welcomeBack =>
      _localizedValues[locale.languageCode]!['welcome_back']!;
  String get email => _localizedValues[locale.languageCode]!['email']!;
  String get password => _localizedValues[locale.languageCode]!['password']!;
  String get forgotPassword =>
      _localizedValues[locale.languageCode]!['forgot_password']!;
  String get pleaseEnterEmailPassword =>
      _localizedValues[locale.languageCode]!['please_enter_email_password']!;
  String get loginFailed =>
      _localizedValues[locale.languageCode]!['login_failed']!;
  String get userNotFound =>
      _localizedValues[locale.languageCode]!['user_not_found']!;
  String get wrongPassword =>
      _localizedValues[locale.languageCode]!['wrong_password']!;
  String get userDisabled =>
      _localizedValues[locale.languageCode]!['user_disabled']!;

  // Home Screen
  String get home => _localizedValues[locale.languageCode]!['home']!;
  String get checkIn => _localizedValues[locale.languageCode]!['check_in']!;
  String get break_ => _localizedValues[locale.languageCode]!['break']!;
  String get return_ => _localizedValues[locale.languageCode]!['return']!;
  String get checkOut => _localizedValues[locale.languageCode]!['check_out']!;
  String get attendanceHistory =>
      _localizedValues[locale.languageCode]!['attendance_history']!;
  String get selectDateRange =>
      _localizedValues[locale.languageCode]!['select_date_range']!;
  String get selectStartDate =>
      _localizedValues[locale.languageCode]!['select_start_date']!;
  String get selectEndDate =>
      _localizedValues[locale.languageCode]!['select_end_date']!;
  String get start => _localizedValues[locale.languageCode]!['start']!;
  String get end => _localizedValues[locale.languageCode]!['end']!;
  String get logout => _localizedValues[locale.languageCode]!['logout']!;
  String get logoutConfirm =>
      _localizedValues[locale.languageCode]!['logout_confirm']!;
  String get invalidDateRange =>
      _localizedValues[locale.languageCode]!['invalid_date_range']!;
  String get endDateBeforeStartDate =>
      _localizedValues[locale.languageCode]!['end_date_before_start_date']!;

  // Days
  String get monday => _localizedValues[locale.languageCode]!['monday']!;
  String get tuesday => _localizedValues[locale.languageCode]!['tuesday']!;
  String get wednesday => _localizedValues[locale.languageCode]!['wednesday']!;
  String get thursday => _localizedValues[locale.languageCode]!['thursday']!;
  String get friday => _localizedValues[locale.languageCode]!['friday']!;
  String get saturday => _localizedValues[locale.languageCode]!['saturday']!;
  String get sunday => _localizedValues[locale.languageCode]!['sunday']!;

  // Time labels
  String get entry => _localizedValues[locale.languageCode]!['entry']!;
  String get breakTime => _localizedValues[locale.languageCode]!['break_time']!;
  String get returnTime =>
      _localizedValues[locale.languageCode]!['return_time']!;
  String get exit => _localizedValues[locale.languageCode]!['exit']!;

  // Reset Password Screen
  String get resetPassword =>
      _localizedValues[locale.languageCode]!['reset_password']!;
  String get enterEmailToReset =>
      _localizedValues[locale.languageCode]!['enter_email_to_reset']!;
  String get sendResetLink =>
      _localizedValues[locale.languageCode]!['send_reset_link']!;
  String get pleaseEnterEmail =>
      _localizedValues[locale.languageCode]!['please_enter_email']!;
  String get resetLinkSent =>
      _localizedValues[locale.languageCode]!['reset_link_sent']!;
  String get resetFailed =>
      _localizedValues[locale.languageCode]!['reset_failed']!;
  String get backToLogin =>
      _localizedValues[locale.languageCode]!['back_to_login']!;
  String get invalidEmailFormat =>
      _localizedValues[locale.languageCode]!['invalid_email_format']!;
  String get accessRestricted =>
      _localizedValues[locale.languageCode]!['access_restricted']!;
  String get resetCooldownMessage =>
      _localizedValues[locale.languageCode]!['reset_cooldown_message']!;
  String get newPassword =>
      _localizedValues[locale.languageCode]!['new_password']!;
  String get confirmNewPassword =>
      _localizedValues[locale.languageCode]!['confirm_new_password']!;
  String get updatePassword =>
      _localizedValues[locale.languageCode]!['update_password']!;
  String get attention => _localizedValues[locale.languageCode]!['attention']!;
  String get fillAllFields =>
      _localizedValues[locale.languageCode]!['fill_all_fields']!;
  String get passwordMismatch =>
      _localizedValues[locale.languageCode]!['password_mismatch']!;
  String get emailNotRegistered =>
      _localizedValues[locale.languageCode]!['email_not_registered']!;
  String get success => _localizedValues[locale.languageCode]!['success']!;
  String get passwordChangedSuccess =>
      _localizedValues[locale.languageCode]!['password_changed_success']!;
  String get occurredError =>
      _localizedValues[locale.languageCode]!['occurred_error']!;
  String get failed => _localizedValues[locale.languageCode]!['failed']!;

  // Settings Screen
  String get settings => _localizedValues[locale.languageCode]!['settings']!;
  String get faceRecognition =>
      _localizedValues[locale.languageCode]!['face_recognition']!;
  String get savedFaces =>
      _localizedValues[locale.languageCode]!['saved_faces']!;
  String get manageFaceData =>
      _localizedValues[locale.languageCode]!['manage_face_data']!;
  String get personalization =>
      _localizedValues[locale.languageCode]!['personalization']!;
  String get theme => _localizedValues[locale.languageCode]!['theme']!;
  String get language => _localizedValues[locale.languageCode]!['language']!;
  String get font => _localizedValues[locale.languageCode]!['font']!;
  String get security => _localizedValues[locale.languageCode]!['security']!;
  String get biometricLogin =>
      _localizedValues[locale.languageCode]!['biometric_login']!;
  String get biometricLoginDesc =>
      _localizedValues[locale.languageCode]!['biometric_login_desc']!;
  String get changePassword =>
      _localizedValues[locale.languageCode]!['change_password']!;
  String get account => _localizedValues[locale.languageCode]!['account']!;
  String get editProfile =>
      _localizedValues[locale.languageCode]!['edit_profile']!;
  String get editProfileDesc =>
      _localizedValues[locale.languageCode]!['edit_profile_desc']!;

  // Theme options
  String get themeSystem =>
      _localizedValues[locale.languageCode]!['theme_system']!;
  String get themeLight =>
      _localizedValues[locale.languageCode]!['theme_light']!;
  String get themeDark => _localizedValues[locale.languageCode]!['theme_dark']!;

  // Language options
  String get languageSystem =>
      _localizedValues[locale.languageCode]!['language_system']!;
  String get languageEnglish =>
      _localizedValues[locale.languageCode]!['language_english']!;
  String get languageIndonesian =>
      _localizedValues[locale.languageCode]!['language_indonesian']!;

  // Font options
  String get fontSystem =>
      _localizedValues[locale.languageCode]!['font_system']!;
  String get fontAppDefault =>
      _localizedValues[locale.languageCode]!['font_app_default']!;

  // Face Screen
  String get faceRegistration =>
      _localizedValues[locale.languageCode]!['face_registration']!;
  String get positionYourFace =>
      _localizedValues[locale.languageCode]!['position_your_face']!;
  String get capture => _localizedValues[locale.languageCode]!['capture']!;
  String get skipForNow =>
      _localizedValues[locale.languageCode]!['skip_for_now']!;
  String get faceRecognitionNotImplemented =>
      _localizedValues[locale
          .languageCode]!['face_recognition_not_implemented']!;
  String get imageSaved =>
      _localizedValues[locale.languageCode]!['image_saved']!;
  String get error => _localizedValues[locale.languageCode]!['error']!;
  String get savingImage =>
      _localizedValues[locale.languageCode]!['saving_image']!;
  String get positionFaceInstruction =>
      _localizedValues[locale.languageCode]!['position_face_instruction']!;
  String get captureFace =>
      _localizedValues[locale.languageCode]!['capture_face']!;
  String get preparingCamera =>
      _localizedValues[locale.languageCode]!['preparing_camera']!;

  // Saved Face Screen
  String get nameNotAvailable =>
      _localizedValues[locale.languageCode]!['name_not_available']!;
  String get idNotAvailable =>
      _localizedValues[locale.languageCode]!['id_not_available']!;
  String get failedToLoad =>
      _localizedValues[locale.languageCode]!['failed_to_load']!;
  String get faceDataDeleted =>
      _localizedValues[locale.languageCode]!['face_data_deleted']!;
  String get failedToDelete =>
      _localizedValues[locale.languageCode]!['failed_to_delete']!;
  String get deleteFaceData =>
      _localizedValues[locale.languageCode]!['delete_face_data']!;
  String get deleteFaceDataConfirm =>
      _localizedValues[locale.languageCode]!['delete_face_data_confirm']!;
  String get delete => _localizedValues[locale.languageCode]!['delete']!;
  String get pleaseLoginToViewFaceData =>
      _localizedValues[locale.languageCode]!['please_login_to_view_face_data']!;
  String get faceProfile =>
      _localizedValues[locale.languageCode]!['face_profile']!;
  String get noFaceData =>
      _localizedValues[locale.languageCode]!['no_face_data']!;
  String get faceNotRegistered =>
      _localizedValues[locale.languageCode]!['face_not_registered']!;
  String get loading => _localizedValues[locale.languageCode]!['loading']!;

  // Face Scan Screen
  String get submit => _localizedValues[locale.languageCode]!['submit']!;
  String get cannotOpenMap =>
      _localizedValues[locale.languageCode]!['cannot_open_map']!;
  String get attendanceSuccess =>
      _localizedValues[locale.languageCode]!['attendance_success']!;
  String get attendanceFailed =>
      _localizedValues[locale.languageCode]!['attendance_failed']!;
  String get loadingId => _localizedValues[locale.languageCode]!['loading_id']!;
  String get notAvailable =>
      _localizedValues[locale.languageCode]!['not_available']!;
  String get unknown => _localizedValues[locale.languageCode]!['unknown']!;
  String get faceNotMatchBlink =>
      _localizedValues[locale.languageCode]!['face_not_match_blink']!;
  String get locationNotFound =>
      _localizedValues[locale.languageCode]!['location_not_found']!;
  String get searchingLocation =>
      _localizedValues[locale.languageCode]!['searching_location']!;
  String get locationUnknown =>
      _localizedValues[locale.languageCode]!['location_unknown']!;

  // Attendance Warning
  String get earlyAttendance =>
      _localizedValues[locale.languageCode]!['early_attendance']!;
  String get notYetTime =>
      _localizedValues[locale.languageCode]!['not_yet_time']!;
  String get wantToProceed =>
      _localizedValues[locale.languageCode]!['want_to_proceed']!;
  String get proceed => _localizedValues[locale.languageCode]!['proceed']!;

  // ===== Localized Values Map =====
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Common
      'cancel': 'Cancel',
      'ok': 'OK',
      'yes': 'Yes',
      'no': 'No',

      // Login Screen
      'login': 'Login',
      'welcome_back': 'Welcome back 👋',
      'email': 'Email',
      'password': 'Password',
      'forgot_password': 'Forgot Password?',
      'please_enter_email_password': 'Please enter email and password',
      'login_failed': 'Login failed',
      'user_not_found': 'No user found for that email',
      'wrong_password': 'Wrong password provided',
      'user_disabled': 'User account is disabled',

      // Home Screen
      'home': 'Home',
      'check_in': 'Check In',
      'break': 'Break',
      'return': 'Return',
      'check_out': 'Check Out',
      'attendance_history': 'Attendance History',
      'select_date_range': 'Select Date Range',
      'select_start_date': 'Select Start Date',
      'select_end_date': 'Select End Date',
      'start': 'Start',
      'end': 'End',
      'logout': 'Logout',
      'logout_confirm': 'Are you sure you want to logout?',
      'invalid_date_range': 'Invalid Date Range',
      'end_date_before_start_date':
          'End date cannot be earlier than start date',

      // Days
      'monday': 'Monday',
      'tuesday': 'Tuesday',
      'wednesday': 'Wednesday',
      'thursday': 'Thursday',
      'friday': 'Friday',
      'saturday': 'Saturday',
      'sunday': 'Sunday',

      // Time labels
      'entry': 'Check In',
      'break_time': 'Break',
      'return_time': 'Return',
      'exit': 'Check Out',

      // Reset Password
      'reset_password': 'Reset Password',
      'enter_email_to_reset': 'Enter your email to reset password',
      'send_reset_link': 'Send Reset Link',
      'please_enter_email': 'Please enter your email',
      'reset_link_sent': 'Reset link sent to your email',
      'reset_failed': 'Failed to send reset link',
      'back_to_login': 'Back to Login',
      'invalid_email_format': 'The email address is badly formatted',
      'access_restricted': 'Access Restricted',
      'reset_cooldown_message':
          'You have already reset your password. Please try again in:',
      'new_password': 'New Password',
      'confirm_new_password': 'Confirm New Password',
      'update_password': 'Update Password',
      'attention': 'Attention',
      'fill_all_fields': 'Please fill all fields',
      'password_mismatch': 'Passwords do not match',
      'email_not_registered': 'Email address not found',
      'success': 'Success',
      'password_changed_success': 'Password changed successfully.',
      'occurred_error': 'An error occurred',
      'failed': 'Failed',

      // Settings
      'settings': 'Settings',
      'face_recognition': 'FACE RECOGNITION',
      'saved_faces': 'Saved Faces',
      'manage_face_data': 'Manage your saved face data',
      'personalization': 'PERSONALIZATION',
      'theme': 'Theme',
      'language': 'Language',
      'font': 'Font',
      'security': 'SECURITY',
      'biometric_login': 'Biometric Login',
      'biometric_login_desc': 'Use fingerprint or face unlock',
      'change_password': 'Change Password',
      'account': 'Account',
      'edit_profile': 'Edit Profile',
      'edit_profile_desc': 'Change your username and email',

      // Theme options
      'theme_system': 'System',
      'theme_light': 'Light',
      'theme_dark': 'Dark',

      // Language options
      'language_system': 'System',
      'language_english': 'English',
      'language_indonesian': 'Indonesia',

      // Font options
      'font_system': 'System',
      'font_app_default': 'App Default',

      // Face Screen
      'face_registration': 'Face Registration',
      'position_your_face': 'Position your face in the circle',
      'capture': 'Capture',
      'skip_for_now': 'Skip for now',
      'face_recognition_not_implemented':
          'Face recognition not implemented yet',
      'image_saved': 'Image saved successfully',
      'error': 'Error',
      'saving_image': 'Saving image locally...',
      'position_face_instruction':
          'Position your face in the center and press the button.',
      'capture_face': 'Capture Face',
      'preparing_camera': 'Preparing camera...',

      // Saved Face Screen
      'name_not_available': 'Name not available',
      'id_not_available': 'ID not available',
      'failed_to_load': 'Failed to load',
      'face_data_deleted': 'Face data deleted successfully.',
      'failed_to_delete': 'Failed to delete data',
      'delete_face_data': 'Delete Face Data',
      'delete_face_data_confirm':
          'Are you sure you want to delete this face data? This action cannot be undone.',
      'delete': 'Delete',
      'please_login_to_view_face_data': 'Please login to view face data.',
      'face_profile': 'Face Profile',
      'no_face_data': 'No Face Data',
      'face_not_registered': 'Your face is not registered yet.',
      'loading': 'Loading...',

      // Face Scan Screen
      'submit': 'Submit',
      'cannot_open_map': 'Cannot open map.',
      'attendance_success': 'Attendance submitted successfully!',
      'attendance_failed': 'Failed to submit attendance:',
      'loading_id': 'Loading ID...',
      'not_available': 'N/A',
      'unknown': 'Unknown',
      'face_not_match_blink': 'Face Not Matched / Please Blink 😉',
      'location_not_found': 'Location not found',
      'searching_location': 'Searching location...',
      'location_unknown': 'Location status unknown.',

      // Attendance Warning
      'early_attendance': 'Early Attendance',
      'not_yet_time': 'It is not yet time for',
      'want_to_proceed': 'Do you want to proceed?',
      'proceed': 'Proceed',
    },
    'id': {
      // Common
      'cancel': 'Batal',
      'ok': 'OK',
      'yes': 'Ya',
      'no': 'Tidak',

      // Login Screen
      'login': 'Masuk',
      'welcome_back': 'Selamat datang kembali 👋',
      'email': 'Email',
      'password': 'Kata Sandi',
      'forgot_password': 'Lupa Kata Sandi?',
      'please_enter_email_password': 'Silakan masukkan email dan kata sandi',
      'login_failed': 'Login gagal',
      'user_not_found': 'Pengguna tidak ditemukan',
      'wrong_password': 'Kata sandi salah',
      'user_disabled': 'Akun dinonaktifkan',

      // Home Screen
      'home': 'Beranda',
      'check_in': 'Masuk',
      'break': 'Istirahat',
      'return': 'Kembali',
      'check_out': 'Pulang',
      'attendance_history': 'Riwayat Kehadiran',
      'select_date_range': 'Pilih Rentang Tanggal',
      'select_start_date': 'Pilih Tanggal Mulai',
      'select_end_date': 'Pilih Tanggal Akhir',
      'start': 'Mulai',
      'end': 'Akhir',
      'logout': 'Keluar',
      'logout_confirm': 'Yakin ingin keluar?',
      'invalid_date_range': 'Rentang Tanggal Salah',
      'end_date_before_start_date':
          'Tanggal akhir tidak boleh lebih awal dari tanggal mulai',

      // Days
      'monday': 'Senin',
      'tuesday': 'Selasa',
      'wednesday': 'Rabu',
      'thursday': 'Kamis',
      'friday': 'Jumat',
      'saturday': 'Sabtu',
      'sunday': 'Minggu',

      // Time labels
      'entry': 'Masuk',
      'break_time': 'Istirahat',
      'return_time': 'Kembali',
      'exit': 'Pulang',

      // Reset Password
      'reset_password': 'Reset Kata Sandi',
      'enter_email_to_reset': 'Masukkan email Anda untuk reset kata sandi',
      'send_reset_link': 'Kirim Link Reset',
      'please_enter_email': 'Silakan masukkan email Anda',
      'reset_link_sent': 'Link reset telah dikirim ke email Anda',
      'reset_failed': 'Gagal mengirim link reset',
      'back_to_login': 'Kembali ke Login',
      'invalid_email_format': 'Format email tidak valid',
      'access_restricted': 'Akses Dibatasi',
      'reset_cooldown_message':
          'Anda sudah melakukan reset password. Silakan coba lagi dalam:',
      'new_password': 'Password Baru',
      'confirm_new_password': 'Konfirmasi Password Baru',
      'update_password': 'Update Password',
      'attention': 'Perhatian',
      'fill_all_fields': 'Mohon isi semua kolom',
      'password_mismatch': 'Password tidak cocok',
      'email_not_registered': 'Email tidak terdaftar di database.',
      'success': 'Sukses',
      'password_changed_success': 'Password berhasil diubah.',
      'occurred_error': 'Terjadi kesalahan',
      'failed': 'Gagal',

      // Settings
      'settings': 'Pengaturan',
      'face_recognition': 'PENGENALAN WAJAH',
      'saved_faces': 'Wajah Tersimpan',
      'manage_face_data': 'Kelola data wajah tersimpan Anda',
      'personalization': 'PERSONALISASI',
      'theme': 'Tema',
      'language': 'Bahasa',
      'font': 'Font',
      'security': 'KEAMANAN',
      'biometric_login': 'Login Biometrik',
      'biometric_login_desc': 'Gunakan sidik jari atau pengenalan wajah',
      'change_password': 'Ubah Kata Sandi',
      'account': 'Akun',
      'edit_profile': 'Edit Profil',
      'edit_profile_desc': 'Ubah username dan email Anda',

      // Theme options
      'theme_system': 'Sistem',
      'theme_light': 'Terang',
      'theme_dark': 'Gelap',

      // Language options
      'language_system': 'Sistem',
      'language_english': 'English',
      'language_indonesian': 'Indonesia',

      // Font options
      'font_system': 'Sistem',
      'font_app_default': 'Default Aplikasi',

      // Face Screen
      'face_registration': 'Registrasi Wajah',
      'position_your_face': 'Posisikan wajah Anda di dalam lingkaran',
      'capture': 'Ambil Foto',
      'skip_for_now': 'Lewati untuk sekarang',
      'face_recognition_not_implemented':
          'Pengenalan wajah belum diimplementasikan',
      'image_saved': 'Gambar berhasil disimpan',
      'error': 'Error',
      'saving_image': 'Menyimpan gambar secara lokal...',
      'position_face_instruction':
          'Posisikan wajah Anda di tengah dan tekan tombol.',
      'capture_face': 'Ambil Gambar Wajah',
      'preparing_camera': 'Mempersiapkan kamera...',

      // Saved Face Screen
      'name_not_available': 'Nama tidak tersedia',
      'id_not_available': 'ID tidak tersedia',
      'failed_to_load': 'Gagal memuat',
      'face_data_deleted': 'Data wajah berhasil dihapus.',
      'failed_to_delete': 'Gagal menghapus data',
      'delete_face_data': 'Hapus Data Wajah',
      'delete_face_data_confirm':
          'Anda yakin ingin menghapus data wajah ini? Tindakan ini tidak dapat dibatalkan.',
      'delete': 'Hapus',
      'please_login_to_view_face_data':
          'Silakan login untuk melihat data wajah.',
      'face_profile': 'Profil Wajah',
      'no_face_data': 'Tidak Ada Data Wajah',
      'face_not_registered': 'Wajah Anda belum terdaftar.',
      'loading': 'Memuat...',

      // Face Scan Screen
      'submit': 'Kirim',
      'cannot_open_map': 'Tidak dapat membuka peta.',
      'attendance_success': 'Absensi berhasil dikirim!',
      'attendance_failed': 'Gagal mengirim absensi:',
      'loading_id': 'Memuat ID...',
      'not_available': 'T/A',
      'unknown': 'Tidak Diketahui',
      'face_not_match_blink': 'Wajah Tidak Cocok / Silakan Berkedip 😉',
      'location_not_found': 'Lokasi belum ditemukan',
      'searching_location': 'Mencari lokasi...',
      'location_unknown': 'Status lokasi tidak diketahui.',

      // Attendance Warning
      'early_attendance': 'Absensi Lebih Awal',
      'not_yet_time': 'Belum waktunya untuk',
      'want_to_proceed': 'Apakah Anda ingin melanjutkan?',
      'proceed': 'Lanjutkan',
    },
  };
}

/// Delegate untuk AppLocalizations
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'id'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
