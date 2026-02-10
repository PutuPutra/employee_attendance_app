import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gunas_employee_attendance/blocs/attendance/attendance_bloc.dart';
import 'package:gunas_employee_attendance/blocs/face_recognition/face_recognition_bloc.dart';
import 'package:gunas_employee_attendance/blocs/location/location_bloc.dart';
import 'package:gunas_employee_attendance/services/camera_service.dart';
import 'package:intl/intl.dart';
import 'package:gunas_employee_attendance/auth/auth_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';

class FaceScanScreen extends StatelessWidget {
  final String
  attendanceType; // 'checkIn', 'breakStart', 'breakEnd', 'checkOut'

  const FaceScanScreen({super.key, required this.attendanceType});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => LocationBloc()..add(FetchLocation())),
        BlocProvider(
          create: (context) => FaceRecognitionBloc()..add(LoadRegisteredFace()),
        ),
        BlocProvider(
          create: (context) => AttendanceBloc(),
        ), // Pastikan AttendanceBloc bisa handle logic baru
      ],
      child: FaceScanView(attendanceType: attendanceType),
    );
  }
}

class FaceScanView extends StatefulWidget {
  final String attendanceType;

  const FaceScanView({super.key, required this.attendanceType});

  @override
  State<FaceScanView> createState() => _FaceScanViewState();
}

class _FaceScanViewState extends State<FaceScanView> {
  String _currentTime = '';
  String _currentDate = '';
  String _name = '';
  String _id = '';
  String _region = '';
  bool _isLoadingId = true;
  final CameraService _cameraService = CameraService();
  bool _isCameraInitialized = false;
  int _lastFrameTime = 0; // Untuk throttling

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadUserData();
    _updateTime();
  }

  Future<void> _initializeCamera() async {
    // Gunakan resolusi rendah (320x240) untuk performa lebih cepat & mencegah crash
    await _cameraService.initializeCamera(
      resolutionPreset: ResolutionPreset.low,
    );
    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
      });
    }

    // Give camera a moment to settle before starting stream
    await Future.delayed(const Duration(milliseconds: 500));

    // Mulai stream gambar untuk face recognition
    _cameraService.startImageStream((CameraImage image) {
      if (!mounted) return;

      // THROTTLING: Hanya proses 1 frame setiap 500ms
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      if (currentTime - _lastFrameTime < 500) return;
      _lastFrameTime = currentTime;

      context.read<FaceRecognitionBloc>().add(
        ProcessCameraImage(image, _cameraService.cameraDescription!),
      );
    });
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = authService.value.currentUser;
    if (user == null) return;

    // Jangan set text hardcode di sini, gunakan flag loading
    setState(() {
      _name = user.displayName ?? 'Unknown';
      _isLoadingId = true;
    });

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (mounted) {
      setState(() {
        final data = doc.data();
        _id = data?['employeeId']?.toString() ?? '';
        _region = data?['region']?.toString() ?? '';
        _isLoadingId = false;
      });
    }
  }

  void _updateTime() {
    if (!mounted) return;
    setState(() {
      _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
      _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    });
    Future.delayed(const Duration(seconds: 1), _updateTime);
  }

  Future<void> _openMap(Position position) async {
    final l10n = AppLocalizations.of(context);
    final lat = position.latitude;
    final long = position.longitude;
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$long',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.cannotOpenMap)));
      }
    }
  }

  String _getLocalizedDay(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dayIndex = DateTime.now().weekday - 1;
    final days = [
      l10n.monday,
      l10n.tuesday,
      l10n.wednesday,
      l10n.thursday,
      l10n.friday,
      l10n.saturday,
      l10n.sunday,
    ];
    return days[dayIndex];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<AttendanceBloc, AttendanceState>(
      listener: (context, state) {
        if (state is AttendanceSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.attendanceSuccess),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else if (state is AttendanceFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.attendanceFailed} ${state.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            if (_isCameraInitialized)
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.62,
                width: double.infinity,
                child: CameraPreview(_cameraService.controller!),
              )
            else
              Container(
                height: MediaQuery.of(context).size.height * 0.62,
                width: double.infinity,
                color: Colors.black,
                child: const Center(
                  child: CupertinoActivityIndicator(color: Colors.white),
                ),
              ),
            Container(
              height: MediaQuery.of(context).size.height * 0.38,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.blueAccent,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        _currentTime,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildInfoRow(
                    context,
                    icon: Icons.person,
                    text:
                        '${_isLoadingId ? l10n.loadingId : (_id.isEmpty ? l10n.notAvailable : _id)} - ${_name == 'Unknown' ? l10n.unknown : _name}',
                  ),
                  const SizedBox(height: 10),
                  _buildInfoRow(
                    context,
                    icon: Icons.calendar_today,
                    text: '${_getLocalizedDay(context)}, $_currentDate',
                  ),
                  const SizedBox(height: 10),
                  _buildLocationSection(),
                  const Spacer(),
                  BlocBuilder<FaceRecognitionBloc, FaceRecognitionState>(
                    builder: (context, faceState) {
                      final isMatched = faceState is FaceMatched;

                      return BlocBuilder<AttendanceBloc, AttendanceState>(
                        builder: (context, attendanceState) {
                          final isSubmitting =
                              attendanceState is AttendanceLoading;

                          // Teks tombol dinamis
                          String buttonText;
                          if (isMatched) {
                            buttonText = l10n.submit;
                          } else {
                            // Jika belum match, beri hint untuk berkedip
                            // (Asumsi: jika wajah terdeteksi tapi belum match, mungkin karena belum blink)
                            buttonText = l10n.faceNotMatchBlink;
                          }

                          return ElevatedButton(
                            onPressed: (isMatched && !isSubmitting)
                                ? () async {
                                    // 1. Ambil lokasi dari LocationBloc
                                    final locationState = context
                                        .read<LocationBloc>()
                                        .state;
                                    if (locationState is! LocationSuccess) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(l10n.locationNotFound),
                                        ),
                                      );
                                      return;
                                    }

                                    // 2. Ambil foto (capture) untuk bukti
                                    final XFile? image = await _cameraService
                                        .takePicture();
                                    if (image == null) return;

                                    // 3. Dispatch Submit Event
                                    if (context.mounted) {
                                      context.read<AttendanceBloc>().add(
                                        SubmitAttendance(
                                          employeeId: _id,
                                          name: _name,
                                          imagePath: image
                                              .name, // Simpan nama file saja
                                          latitude:
                                              locationState.position.latitude,
                                          longitude:
                                              locationState.position.longitude,
                                          attendanceType: widget
                                              .attendanceType, // Kirim tipe absensi
                                          region: _region,
                                        ),
                                      );
                                    }
                                  }
                                : null, // Disable jika wajah tidak match
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isMatched
                                  ? Colors.green
                                  : Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: isSubmitting
                                ? const CupertinoActivityIndicator(
                                    color: Colors.white,
                                  )
                                : Text(
                                    buttonText,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blueAccent, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<LocationBloc, LocationState>(
      builder: (context, state) {
        Widget content;
        Function()? onTap;

        if (state is LocationLoading || state is LocationInitial) {
          content = Row(
            children: [
              const Icon(Icons.location_on, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 10),
              Text(l10n.searchingLocation),
              const SizedBox(width: 10),
              const CupertinoActivityIndicator(radius: 10),
            ],
          );
        } else if (state is LocationSuccess) {
          content = _buildInfoRow(
            context,
            icon: Icons.location_on,
            text: state.address,
          );
          onTap = () => _openMap(state.position);
        } else if (state is LocationFailure) {
          content = _buildInfoRow(
            context,
            icon: Icons.location_off,
            text: state.error,
          );
        } else {
          content = _buildInfoRow(
            context,
            icon: Icons.location_off,
            text: l10n.locationUnknown,
          );
        }

        return InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: content,
          ),
        );
      },
    );
  }
}
