import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:freerasp/freerasp.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  /// Inisialisasi keamanan aplikasi
  Future<void> initialize() async {
    // Konfigurasi Talsec (FreeRASP)
    final config = TalsecConfig(
      /// Untuk Android:
      /// 1. Package Name: Harus sama persis dengan di AndroidManifest.xml / build.gradle
      /// 2. Signing Cert Hashes: SHA-256 dari Keystore release Anda (bukan debug key).
      // /    Cara dapat hash: keytool -list -v -keystore your-release-key.jks
      // /    Lalu konversi Hex SHA-256 ke Base64.
      // /    Jika hash tidak cocok, aplikasi akan mendeteksi sebagai "Tampering" (Mod).
      androidConfig: AndroidConfig(
        packageName:
            'com.gunas.employee_attendance', // TODO: Ganti dengan package name asli
        signingCertHashes: [dotenv.env['SIGNING_CERT_HASH'] ?? ''],
      ),

      /// Untuk iOS:
      /// Bundle ID dan Team ID dari Apple Developer Account
      iosConfig: IOSConfig(
        bundleIds: [
          'com.gunas.employeeAttendance',
        ], // TODO: Ganti dengan Bundle ID asli
        teamId: 'M852XXXXXX', // TODO: Ganti dengan Team ID Apple Anda
      ),

      watcherMail:
          'kalbargunas@gmail.com', // Email untuk laporan alert (opsional)
      isProd: kReleaseMode, // Hanya aktifkan mode ketat di Release
    );

    // Callback ketika ancaman terdeteksi
    final callback = ThreatCallback(
      onAppIntegrity: () => _handleThreat("App Integrity (Modded/Tampered)"),
      onObfuscationIssues: () => _handleThreat("Obfuscation Issues"),
      onDebug: () => _handleThreat("Debugging Detected"),
      onDeviceBinding: () => _handleThreat("Device Binding Issue"),
      onDeviceID: () => _handleThreat("Device ID Hooking"),
      onHooks: () => _handleThreat("Hooking Framework (Frida/Xposed)"),
      onPrivilegedAccess: () => _handleThreat("Root/Jailbreak Detected"),
      onSecureHardwareNotAvailable: () =>
          _handleThreat("Secure Hardware Missing"),
      onSimulator: () => _handleThreat("Emulator Detected"),
      // PENTING: Kosongkan ini agar karyawan bisa install APK manual tanpa dianggap ancaman
      onUnofficialStore: () {},
    );

    // Mulai monitoring
    await Talsec.instance.start(config);
    Talsec.instance.attachListener(callback);
  }

  Future<void> _handleThreat(String threatType) async {
    // Log ancaman
    if (kDebugMode) {
      print("🚨 SECURITY THREAT DETECTED: $threatType");
    } else {
      // AKSI TEGAS: Tutup aplikasi jika terdeteksi ancaman di mode Release
      // Ini mencegah user menggunakan aplikasi modifikasi atau HP Root

      // 1. Hapus Sesi (Hukuman bagi penyerang)
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Logout paksa

      // 2. Matikan Aplikasi
      _killApp();
    }
  }

  void _killApp() {
    if (Platform.isAndroid) {
      SystemNavigator.pop();
    } else if (Platform.isIOS) {
      exit(0);
    }
  }
}
