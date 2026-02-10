import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

part 'attendance_event.dart';
part 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

      // Toleransi 1 menit. Jika lebih dari 1 menit (misal 07:01:01), maka terlambat.
      final lateThreshold = limitTime.add(const Duration(minutes: 1));
      final statusCheckIn = now.isAfter(lateThreshold) ? 2 : 1;

      // Selalu simpan data baru (Add Document)
      await _firestore.collection('user_attendance').add({
        'employeeId': event.employeeId,
        'name': event.name,
        'imagePath': event.imagePath,
        'latitude': event.latitude,
        'longitude': event.longitude,
        'status': status, // 1=CheckIn, 2=Break, 3=Return, 4=CheckOut
        'statusCheckIn': statusCheckIn, // 1=Tepat Waktu, 2=Terlambat
        'timestamp': FieldValue.serverTimestamp(),
        'date': dateStr, // Disimpan untuk memudahkan query per hari
      });

      emit(AttendanceSuccess());
    } catch (e) {
      emit(AttendanceFailure(error: e.toString()));
    }
  }
}
