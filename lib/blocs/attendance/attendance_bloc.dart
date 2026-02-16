import 'dart:convert';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
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

      // Tentukan batas waktu check-in berdasarkan region
      int hour = 8;
      int minute = 0;

      switch (event.region) {
        case 'Cilegon':
          hour = 7;
          minute = 0;
          break;
        case 'Head Office':
          hour = 8;
          minute = 0;
          break;
        case 'Sanggau':
          hour = 9;
          minute = 0;
          break;
        case 'Sintang':
          hour = 8;
          minute = 0;
          break;
        case 'Palangkaraya':
          hour = 7;
          minute = 30;
          break;
        default:
          hour = 8; // Default
          minute = 0;
      }

      // Tentukan statusCheckIn (1: Tepat Waktu, 2: Terlambat)
      final limitTime = DateTime(now.year, now.month, now.day, hour, minute, 0);

      // Toleransi 5 menit. Jika lebih dari 5 menit, maka terlambat.
      final lateThreshold = limitTime.add(const Duration(minutes: 5));
      final statusCheckIn = now.isAfter(lateThreshold) ? 2 : 1;

      // Upload to ImageKit (Backup Cloud)
      String? imageUrl;
      try {
        final fileName =
            '${event.employeeId}_attendance_${DateFormat('yyyyMMdd_HHmmss').format(now)}.jpg';
        imageUrl = await _uploadToImageKit(File(event.imagePath), fileName);
      } catch (e) {
        print("Warning: Gagal upload attendance ke ImageKit: $e");
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
          print("Warning: Gagal menghapus file lokal: $e");
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
