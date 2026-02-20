import 'dart:convert';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  Future<void> _onSubmitAttendance(
    SubmitAttendance event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());
    try {
      final now = DateTime.now();
      // Tetap simpan date string untuk keperluan query di HomeScreen (cek sudah absen hari ini)
      final dateStr = DateFormat('MMMM d, yyyy').format(now);

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

      // 1. Ambil Data User untuk mendapatkan company_id dan location_id
      String? companyId;
      String? locationId;

      try {
        final userQuery = await _firestore
            .collection('users')
            .where('id_karyawan', isEqualTo: event.employeeId)
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          final userData = userQuery.docs.first.data();
          companyId = userData['company_id']?.toString();
          locationId = userData['location_id']?.toString();
        }
      } catch (e) {
        debugPrint("Error fetching user data for settings: $e");
      }

      // 2. Ambil Settings dari Company dan Location
      String? scheduledCheckInTime;

      if (companyId != null) {
        try {
          final futures = <Future<DocumentSnapshot>>[
            _firestore.collection('companies').doc(companyId).get(),
          ];

          if (locationId != null) {
            futures.add(
              _firestore.collection('locations').doc(locationId).get(),
            );
          }

          final results = await Future.wait(futures);
          final companyDoc = results[0];
          final locationDoc = (results.length > 1) ? results[1] : null;

          Map<String, dynamic>? companySettings;
          if (companyDoc.exists) {
            final data = companyDoc.data() as Map<String, dynamic>?;
            if (data != null && data['settings'] != null) {
              companySettings = data['settings'] as Map<String, dynamic>;
            }
          }

          Map<String, dynamic>? locationSettings;
          if (locationDoc != null && locationDoc.exists) {
            final data = locationDoc.data() as Map<String, dynamic>?;
            if (data != null && data['settings'] != null) {
              locationSettings = data['settings'] as Map<String, dynamic>;
            }
          }

          // Logic: Location > Company
          if (locationSettings != null &&
              locationSettings['check_in_time'] != null) {
            scheduledCheckInTime = locationSettings['check_in_time']
                ?.toString();
          } else if (companySettings != null &&
              companySettings['check_in_time'] != null) {
            scheduledCheckInTime = companySettings['check_in_time']?.toString();
          }
        } catch (e) {
          debugPrint("Error fetching settings: $e");
        }
      }

      // 3. Tentukan Status CheckIn
      // Default status adalah 1 (Tepat Waktu) jika tidak ada setting jam masuk di Firebase
      int statusCheckIn = 1;

      if (scheduledCheckInTime != null) {
        try {
          final parts = scheduledCheckInTime.split(':');
          if (parts.length == 2) {
            final int hour = int.parse(parts[0]);
            final int minute = int.parse(parts[1]);

            final limitTime = DateTime(
              now.year,
              now.month,
              now.day,
              hour,
              minute,
              0,
            );

            // Toleransi 5 menit. Jika lebih dari 5 menit, maka terlambat.
            final lateThreshold = limitTime.add(const Duration(minutes: 5));

            if (now.isAfter(lateThreshold)) {
              statusCheckIn = 2;
            }
          }
        } catch (e) {
          debugPrint("Error parsing check_in_time: $e");
        }
      }

      // Upload to ImageKit (Backup Cloud)
      String? imageUrl;
      try {
        final fileName =
            '${event.employeeId}_attendance_${DateFormat('yyyyMMdd_HHmmss').format(now)}.jpg';
        if (_imageKitPrivateKey.isEmpty) {
          debugPrint("Warning: IMAGEKIT_PRIVATE_KEY tidak ditemukan di .env");
        } else {
          imageUrl = await _uploadToImageKit(File(event.imagePath), fileName);
        }
      } catch (e) {
        debugPrint("Warning: Gagal upload attendance ke ImageKit: $e");
      }

      // Selalu simpan data baru (Add Document)
      await _firestore.collection('user_attendance').add({
        'employeeId': event.employeeId,
        'name': event.name,
        'imagePath': event.imagePath,
        'imageUrl': imageUrl,
        'latitude': event.latitude,
        'longitude': event.longitude,
        'status': status, // 1=CheckIn, 2=Break, 3=Return, 4=CheckOut
        'statusCheckIn': statusCheckIn, // 1=Tepat Waktu, 2=Terlambat
        'timestamp': FieldValue.serverTimestamp(),
        'date': dateStr, // Disimpan untuk memudahkan query per hari
      });

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
    request.fields['folder'] = '/attendance/';
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
}
