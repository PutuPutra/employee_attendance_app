part of 'attendance_bloc.dart';

@immutable
sealed class AttendanceEvent {}

class SubmitAttendance extends AttendanceEvent {
  final String employeeId;
  final String name;
  final String imagePath;
  final double latitude;
  final double longitude;

  SubmitAttendance({
    required this.employeeId,
    required this.name,
    required this.imagePath,
    required this.latitude,
    required this.longitude,
  });
}
