import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AttendanceMetrics {
  final String timeLate;
  final String earlyLeaving;
  final String overtime;
  final String totalWork;
  final String totalRest;

  const AttendanceMetrics({
    this.timeLate = "00:00",
    this.earlyLeaving = "00:00",
    this.overtime = "00:00",
    this.totalWork = "00:00",
    this.totalRest = "00:00",
  });
}

class AttendanceCalculator {
  static String _formatDuration(Duration d) {
    if (d.isNegative) return "00:00";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitHours = twoDigits(d.inHours);
    return "$twoDigitHours:$twoDigitMinutes";
  }

  static AttendanceMetrics calculate({
    required List<QueryDocumentSnapshot<Object?>> logs,
    required DateTime defaultCheckIn,
    required DateTime defaultCheckOut,
    required DateTime defaultBreakIn,
    required DateTime defaultBreakOut,
    required DateTime now,
  }) {
    DateTime? checkInTime;
    DateTime? checkOutTime;
    List<DateTime> breakStarts = [];
    List<DateTime> breakEnds = [];

    // 1. Parse Logs
    for (var doc in logs) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = data['timestamp'] as Timestamp?;
      final s = data['status'] as int?;
      final DateTime time = ts?.toDate() ?? now;

      if (s == 1) {
        // Check In (ambil yang paling awal jika ada duplikat)
        if (checkInTime == null || time.isBefore(checkInTime)) {
          checkInTime = time;
        }
      } else if (s == 2) {
        breakStarts.add(time);
      } else if (s == 3) {
        breakEnds.add(time);
      } else if (s == 4) {
        // Check Out (ambil yang paling akhir)
        if (checkOutTime == null || time.isAfter(checkOutTime)) {
          checkOutTime = time;
        }
      }
    }

    String timeLate = "00:00";
    String earlyLeaving = "00:00";
    String overtime = "00:00";
    String totalRest = "00:00";
    String totalWork = "00:00";

    // A. Time Late
    if (checkInTime != null) {
      // Toleransi keterlambatan 5 menit
      final lateThreshold = defaultCheckIn.add(const Duration(minutes: 5));
      if (checkInTime.isAfter(lateThreshold)) {
        timeLate = _formatDuration(checkInTime.difference(defaultCheckIn));
      }
    }

    // B. Total Rest
    Duration restDuration = Duration.zero;
    breakStarts.sort();
    breakEnds.sort();
    int pairs = min(breakStarts.length, breakEnds.length);
    for (int i = 0; i < pairs; i++) {
      if (breakEnds[i].isAfter(breakStarts[i])) {
        restDuration += breakEnds[i].difference(breakStarts[i]);
      }
    }
    // Fallback: Jika tidak ada log istirahat tapi sudah checkout,
    // dan jam kerja melewati jam istirahat, asumsikan istirahat diambil penuh.
    if (breakStarts.isEmpty && breakEnds.isEmpty && checkOutTime != null) {
      if (checkInTime != null &&
          checkInTime.isBefore(defaultBreakIn) &&
          checkOutTime.isAfter(defaultBreakOut)) {
        restDuration = defaultBreakOut.difference(defaultBreakIn);
      }
    }
    totalRest = _formatDuration(restDuration);

    // C. Early Leaving & Overtime
    if (checkOutTime != null) {
      if (checkOutTime.isBefore(defaultCheckOut)) {
        earlyLeaving = _formatDuration(
          defaultCheckOut.difference(checkOutTime),
        );
      }
      if (checkOutTime.isAfter(defaultCheckOut)) {
        overtime = _formatDuration(checkOutTime.difference(defaultCheckOut));
      }
    }

    // D. Total Work
    if (checkInTime != null) {
      DateTime effectiveEndTime = checkOutTime ?? now;
      Duration workDuration =
          effectiveEndTime.difference(checkInTime) - restDuration;
      if (workDuration.isNegative) workDuration = Duration.zero;
      totalWork = _formatDuration(workDuration);
    }

    return AttendanceMetrics(
      timeLate: timeLate,
      earlyLeaving: earlyLeaving,
      overtime: overtime,
      totalWork: totalWork,
      totalRest: totalRest,
    );
  }

  static Future<void> updateDailyLog({
    required FirebaseFirestore firestore,
    required String employeeId,
    required String employeeName,
    required DateTime defaultCheckIn,
    required DateTime defaultCheckOut,
    required DateTime defaultBreakIn,
    required DateTime defaultBreakOut,
    required DateTime now,
  }) async {
    // 1. Fetch Realtime Data (Always fetch fresh data from user_attendance)
    final dateStr = DateFormat('MMMM d, yyyy').format(now);
    final logsQuery = await firestore
        .collection('user_attendance')
        .where('id_karyawan', isEqualTo: employeeId)
        .where('date', isEqualTo: dateStr)
        // .orderBy('timestamp', descending: false) // Dihapus agar tidak memerlukan Composite Index
        .get(const GetOptions(source: Source.server));

    // 2. Hitung Metrics
    final metrics = calculate(
      logs: logsQuery.docs.cast<QueryDocumentSnapshot<Object?>>(),
      defaultCheckIn: defaultCheckIn,
      defaultCheckOut: defaultCheckOut,
      defaultBreakIn: defaultBreakIn,
      defaultBreakOut: defaultBreakOut,
      now: now,
    );

    // 3. Format Tanggal & Simpan ke Firestore
    final docIdDatePart = DateFormat('yyyy-MM-dd').format(now);
    final dailyLogDocId = '${employeeId}_$docIdDatePart';

    await firestore.collection('daily_work_logs').doc(dailyLogDocId).set({
      'id_karyawan': employeeId,
      'name': employeeName,
      'date': dateStr,
      ...{
        'time_late': metrics.timeLate,
        'early_leaving': metrics.earlyLeaving,
        'overtime': metrics.overtime,
        'total_work': metrics.totalWork,
        'total_rest': metrics.totalRest,
      },
      'last_updated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
