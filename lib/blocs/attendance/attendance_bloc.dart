import 'dart:convert';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import './attendance_calculator.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
part 'attendance_event.dart';
part 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // KONFIGURASI IMAGEKIT
  // ⚠️ PENTING: Masukkan Private Key Anda di sini
  String get _imageKitPrivateKey => dotenv.env['IMAGEKIT_PRIVATE_KEY'] ?? '';
  final String _imageKitUrlEndpoint =
      'https://upload.imagekit.io/api/v1/files/upload';

  AttendanceBloc() : super(AttendanceInitial()) {
    on<SubmitAttendance>(_onSubmitAttendance);
  }

  // Helper untuk parse string waktu "HH:mm" ke DateTime pada tanggal tertentu
  DateTime? _parseTime(String? timeStr, DateTime date) {
    if (timeStr == null || !timeStr.contains(':')) return null;
    try {
      final parts = timeStr.split(':');
      return DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    } catch (e) {
      return null;
    }
  }

  // Helper untuk mengambil jadwal attendance (CheckIn, CheckOut, Break)
  Future<Map<String, DateTime>> _getAttendanceSchedule(
    String employeeId,
    DateTime now,
  ) async {
    String? companyId;
    String? locationId;

    // 1. Ambil Data User
    try {
      final userQuery = await _firestore
          .collection('users')
          .where('id_karyawan', isEqualTo: employeeId)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final userData = userQuery.docs.first.data();
        companyId = userData['company_id']?.toString();
        final locId = userData['location_id']?.toString();
        if (locId != null && locId.trim().isNotEmpty) {
          locationId = locId.trim();
        }
      }
    } catch (e) {
      debugPrint("Error fetching user data for settings: $e");
    }

    // 2. Ambil Settings
    String? scheduledCheckInTime;
    String? scheduledCheckOutTime;
    String? scheduledBreakInTime;
    String? scheduledBreakOutTime;

    if (companyId != null) {
      try {
        final futures = <Future<DocumentSnapshot>>[
          _firestore.collection('companies').doc(companyId).get(),
        ];
        if (locationId != null) {
          futures.add(_firestore.collection('locations').doc(locationId).get());
        }

        final results = await Future.wait(futures);
        final companyDoc = results[0];
        final locationDoc = (results.length > 1) ? results[1] : null;

        Map<String, dynamic>? companySettings;
        if (companyDoc.exists) {
          final data = companyDoc.data() as Map<String, dynamic>?;
          if (data != null && data['settings'] != null) {
            companySettings = Map<String, dynamic>.from(data['settings']);
          }
        }

        Map<String, dynamic>? locationSettings;
        if (locationDoc != null && locationDoc.exists) {
          final data = locationDoc.data() as Map<String, dynamic>?;
          if (data != null && data['settings'] != null) {
            locationSettings = Map<String, dynamic>.from(data['settings']);
          }
        }

        String? getSetting(String key) {
          if (locationSettings != null &&
              locationSettings[key]?.toString().isNotEmpty == true) {
            return locationSettings[key].toString();
          }
          if (companySettings != null &&
              companySettings[key]?.toString().isNotEmpty == true) {
            return companySettings[key].toString();
          }
          return null;
        }

        scheduledCheckInTime = getSetting('check_in_time');
        scheduledCheckOutTime = getSetting('check_out_time');
        scheduledBreakInTime = getSetting('break_in_time');
        scheduledBreakOutTime = getSetting('break_out_time');
      } catch (e) {
        debugPrint("Error fetching settings: $e");
      }
    }

    // 3. Parse Times
    return {
      'checkIn':
          _parseTime(scheduledCheckInTime, now) ??
          DateTime(now.year, now.month, now.day, 8, 0),
      'checkOut':
          _parseTime(scheduledCheckOutTime, now) ??
          DateTime(now.year, now.month, now.day, 17, 0),
      'breakIn':
          _parseTime(scheduledBreakInTime, now) ??
          DateTime(now.year, now.month, now.day, 12, 0),
      'breakOut':
          _parseTime(scheduledBreakOutTime, now) ??
          DateTime(now.year, now.month, now.day, 13, 0),
    };
  }

  Future<void> _onSubmitAttendance(
    SubmitAttendance event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());
    try {
      final now = DateTime.now();
      // Tetap simpan date string untuk keperluan query di HomeScreen (cek sudah absen hari ini)
      final dateStr = DateFormat('MMMM d, yyyy').format(now);
      final docIdDatePart = DateFormat('yyyy-MM-dd').format(now);
      final dailyLogDocId = '${event.employeeId}_$docIdDatePart';

      // Mapping attendanceType ke status code
      int status = 0;
      switch (event.attendanceType) {
        case 'checkIn':
          status = 1;
          break;
        case 'breakStart':
          status = 2;
          break;
        case 'breakEnd':
          status = 3;
          break;
        case 'checkOut':
          status = 4;
          break;
      }

      // --- LOGIC PENENTUAN JAM MASUK (CASCADING SETTINGS) ---
      final schedule = await _getAttendanceSchedule(event.employeeId, now);
      final defaultCheckIn = schedule['checkIn']!;
      final defaultCheckOut = schedule['checkOut']!;
      final defaultBreakIn = schedule['breakIn']!;
      final defaultBreakOut = schedule['breakOut']!;

      // Upload to ImageKit (Backup Cloud)
      String? imageUrl;
      try {
        final fileName =
            '${event.employeeId}_attendance_${DateFormat('yyyyMMdd_HHmmss').format(now)}.jpg';
        if (_imageKitPrivateKey.isEmpty) {
          debugPrint("Warning: IMAGEKIT_PRIVATE_KEY tidak ditemukan di .env");
        } else {
          // Konversi gambar ke JPG valid & fix orientation sebelum upload
          // Ini memastikan preview di ImageKit dashboard bisa muncul dengan benar
          // Ini adalah GAMBAR ASLI (Real Image), bukan embedding.
          final File processedImage = await _convertToJpg(
            File(event.imagePath),
          );
          imageUrl = await _uploadToImageKit(processedImage, fileName);

          // Hapus file temporary hasil proses agar tidak menumpuk di cache
          if (await processedImage.exists()) {
            await processedImage.delete();
          }
        }
      } catch (e) {
        debugPrint("Warning: Gagal upload attendance ke ImageKit: $e");
      }

      // 4. Save to user_attendance (Raw Log)
      // Calculate statusCheckIn for the log entry itself (useful for UI)
      int statusCheckIn = 1;
      if (status == 1) {
        final lateThreshold = defaultCheckIn.add(const Duration(minutes: 5));
        if (now.isAfter(lateThreshold)) {
          statusCheckIn = 2;
        }
      }

      final Map<String, dynamic> attendanceData = {
        'id_karyawan': event.employeeId,
        'name': event.name,
        'imagePath': event.imagePath,
        'imageUrl': imageUrl,
        'latitude': event.latitude,
        'longitude': event.longitude,
        'status': status, // 1=CheckIn, 2=Break, 3=Return, 4=CheckOut
        'timestamp': FieldValue.serverTimestamp(),
        'date': dateStr, // Disimpan untuk memudahkan query per hari
        'is_synced':
            false, // Flag bantu: Laravel akan query data yang is_synced == false
      };

      if (status == 1) {
        attendanceData['statusCheckIn'] = statusCheckIn;
      }

      await _firestore.collection('user_attendance').add(attendanceData);

      // 5. Calculate Metrics & Save (Delegated to Helper which fetches realtime data)
      await AttendanceCalculator.updateDailyLog(
        firestore: _firestore,
        employeeId: event.employeeId,
        employeeName: event.name,
        defaultCheckIn: defaultCheckIn,
        defaultCheckOut: defaultCheckOut,
        defaultBreakIn: defaultBreakIn,
        defaultBreakOut: defaultBreakOut,
        now: now,
      );

      // Hapus file lokal jika upload berhasil untuk menghemat storage
      if (imageUrl != null) {
        try {
          final file = File(event.imagePath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          debugPrint("Warning: Gagal menghapus file lokal: $e");
        }
      }

      emit(AttendanceSuccess());
    } catch (e) {
      emit(AttendanceFailure(error: e.toString()));
    }
  }

  Future<String> _uploadToImageKit(File file, String fileName) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(_imageKitUrlEndpoint),
    );

    request.fields['fileName'] = fileName;
    request.fields['folder'] = '/face_attendance/';
    request.fields['useUniqueFileName'] = 'false';

    // Basic Auth menggunakan Private Key
    final auth = 'Basic ' + base64Encode(utf8.encode('$_imageKitPrivateKey:'));
    request.headers['Authorization'] = auth;

    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();

    if (response.statusCode == 200 || response.statusCode == 201) {
      final respStr = await response.stream.bytesToString();
      final json = jsonDecode(respStr);
      return json['url']; // URL gambar dari ImageKit
    } else {
      throw Exception('ImageKit Upload Failed: ${response.statusCode}');
    }
  }

  Future<File> _convertToJpg(File originalFile) async {
    // 1. Baca file gambar asli
    final bytes = await originalFile.readAsBytes();

    // 2. Decode gambar menggunakan package 'image'
    final image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception("Gagal membaca gambar");
    }

    // 3. Perbaiki orientasi (penting untuk hasil kamera HP agar tidak miring)
    // Fungsi bakeOrientation sudah kamu pakai juga di ml_service.dart
    final fixedImage = img.bakeOrientation(image);

    // 4. Encode (ubah) menjadi format JPG
    // quality: 85 adalah standar yang bagus (seimbang antara size dan kualitas)
    final jpgBytes = img.encodeJpg(fixedImage, quality: 85);

    // 5. Buat file temporary baru untuk memastikan tidak ada konflik path
    // dan nama file memiliki ekstensi .jpg yang valid.
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newPath = '${tempDir.path}/${timestamp}_attendance_processed.jpg';

    // 6. Tulis bytes ke file baru
    final newFile = File(newPath);
    await newFile.writeAsBytes(jpgBytes);

    return newFile; // File ini siap di-upload ke ImageKit
  }
}
