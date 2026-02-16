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
  bool _isSubmittingAuto = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadUserData();
    _updateTime();
  }

  Future<void> _initializeCamera() async {
    // Gunakan resolusi rendah (320x240) untuk performa lebih cepat & mencegah crash
    // Opsi lain:
    // - ResolutionPreset.low (320x240)
    // - ResolutionPreset.medium (480p)
    // - ResolutionPreset.high (720p)
    // - ResolutionPreset.veryHigh (1080p)
    // - ResolutionPreset.ultraHigh (2160p)
    // - ResolutionPreset.max (Resolusi tertinggi yang didukung)
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

      // THROTTLING: Hanya proses 1 frame setiap 10ms (sebelumnya 500ms)
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      if (currentTime - _lastFrameTime < 100) return;
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
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: Text(l10n.error),
            content: Text(l10n.cannotOpenMap),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
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

  Future<void> _submitAttendance() async {
    if (_isSubmittingAuto) return;

    final l10n = AppLocalizations.of(context);
    final locationState = context.read<LocationBloc>().state;

    if (locationState is! LocationSuccess) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: Text(l10n.error),
            content: Text(l10n.locationNotFound),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      }
      return;
    }

    setState(() {
      _isSubmittingAuto = true;
    });

    try {
      final XFile? image = await _cameraService.takePicture();
      if (image == null) {
        if (mounted) setState(() => _isSubmittingAuto = false);
        return;
      }

      if (mounted) {
        context.read<AttendanceBloc>().add(
          SubmitAttendance(
            employeeId: _id,
            name: _name,
            imagePath: image.path,
            latitude: locationState.position.latitude,
            longitude: locationState.position.longitude,
            attendanceType: widget.attendanceType,
            region: _region,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmittingAuto = false);
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: Text(l10n.error),
            content: Text('$e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MultiBlocListener(
      listeners: [
        BlocListener<AttendanceBloc, AttendanceState>(
          listener: (context, state) {
            if (state is AttendanceSuccess) {
              showCupertinoDialog(
                context: context,
                builder: (ctx) => CupertinoAlertDialog(
                  title: const Text('Berhasil'),
                  content: Text(l10n.attendanceSuccess),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text('OK'),
                      onPressed: () {
                        Navigator.pop(ctx); // Tutup Dialog
                        Navigator.pop(context); // Kembali ke Home
                      },
                    ),
                  ],
                ),
              );
            } else if (state is AttendanceFailure) {
              setState(() => _isSubmittingAuto = false);
              showCupertinoDialog(
                context: context,
                builder: (ctx) => CupertinoAlertDialog(
                  title: Text(l10n.error),
                  content: Text('${l10n.attendanceFailed}\n${state.error}'),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text('OK'),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              );
            }
          },
        ),
        BlocListener<FaceRecognitionBloc, FaceRecognitionState>(
          listener: (context, state) {
            if (state is FaceMatched && !_isSubmittingAuto) {
              _submitAttendance();
            } else if (state is FaceRecognitionFailure) {
              // Terjemahkan kode error dari Bloc
              String errorMsg = state.error;
              if (errorMsg == 'no_face_in_registered_photo') {
                errorMsg = l10n.noFaceInRegisteredPhoto;
              } else if (errorMsg == 'face_file_not_found') {
                errorMsg = l10n.faceFileNotFound;
              } else if (errorMsg == 'face_not_registered') {
                errorMsg = l10n.faceNotRegistered;
              } else if (errorMsg == 'login_required') {
                errorMsg = l10n.loginRequired;
              }

              showCupertinoDialog(
                context: context,
                builder: (ctx) => CupertinoAlertDialog(
                  title: Text(l10n.error),
                  content: Text(errorMsg),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text('OK'),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ],
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
                    color: Colors.black.withValues(alpha: 0.1),
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
                              attendanceState is AttendanceLoading ||
                              _isSubmittingAuto;

                          // Teks tombol dinamis
                          String buttonText = '';
                          if (isSubmitting) {
                            buttonText = l10n.loading;
                          } else if (isMatched) {
                            buttonText = l10n.submit;
                          } else {
                            // Jika belum match, beri hint untuk berkedip
                            // (Asumsi: jika wajah terdeteksi tapi belum match, mungkin karena belum blink)
                            if (faceState is FaceNotMatched) {
                              // Cek konfigurasi dari Bloc
                              if (FaceRecognitionBloc.isLivenessEnabled) {
                                buttonText = l10n
                                    .faceNotMatchBlink; // "Wajah Tidak Cocok / Silakan Berkedip"
                              } else {
                                buttonText = l10n
                                    .faceNotMatch; // "Wajah Tidak Cocok" (BARU)
                              }
                            } else {
                              // Provide a default text when face is not being processed.
                              // This can be an empty string or a message like "Scan Face"
                              buttonText =
                                  ''; // Or buttonText = l10n.scanFace; with "scanFace" added to AppLocalizations
                            }
                          }

                          return ElevatedButton(
                            onPressed: (isMatched && !isSubmitting)
                                ? _submitAttendance
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
