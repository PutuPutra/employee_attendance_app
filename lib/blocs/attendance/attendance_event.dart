part of 'attendance_bloc.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object> get props => [];
}

class SubmitAttendance extends AttendanceEvent {
  final String employeeId;
  final String name;
  final String imagePath;
  final double latitude;
  final double longitude;
  final String
  attendanceType; // 'checkIn', 'breakStart', 'breakEnd', 'checkOut'
  final String region;

  const SubmitAttendance({
    required this.employeeId,
    required this.name,
    required this.imagePath,
    required this.latitude,
    required this.longitude,
    required this.attendanceType,
    required this.region,
  });

  @override
  List<Object> get props => [
    employeeId,
    name,
    imagePath,
    latitude,
    longitude,
    attendanceType,
    region,
  ];
}
