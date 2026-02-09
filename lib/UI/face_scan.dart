import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gunas_employee_attendance/blocs/location/location_bloc.dart';
import 'package:gunas_employee_attendance/services/camera_service.dart';
import 'package:intl/intl.dart';
import 'package:gunas_employee_attendance/auth/auth_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';

class FaceScanScreen extends StatelessWidget {
  const FaceScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LocationBloc()..add(FetchLocation()),
      child: const FaceScanView(),
    );
  }
}

class FaceScanView extends StatefulWidget {
  const FaceScanView({super.key});

  @override
  State<FaceScanView> createState() => _FaceScanViewState();
}

class _FaceScanViewState extends State<FaceScanView> {
  String _currentTime = '';
  String _currentDate = '';
  String _name = '';
  String _id = '';
  final CameraService _cameraService = CameraService();
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadUserData();
    _updateTime();
  }

  Future<void> _initializeCamera() async {
    await _cameraService.initializeCamera();
    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = authService.value.currentUser;
    if (user == null) return;

    setState(() {
      _name = user.displayName ?? 'Unknown';
      _id = 'Memuat ID...';
    });

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (mounted && doc.exists) {
      setState(() {
        _id = doc.data()?['employeeId'] ?? 'N/A';
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
    final lat = position.latitude;
    final long = position.longitude;
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$long',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka peta.')),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
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
                  text: '$_id - $_name',
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
                ElevatedButton(
                  onPressed: () {
                    /* Submit action */
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: Text(
                    l10n.submit,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
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
    return BlocBuilder<LocationBloc, LocationState>(
      builder: (context, state) {
        Widget content;
        Function()? onTap;

        if (state is LocationLoading || state is LocationInitial) {
          content = const Row(
            children: [
              Icon(Icons.location_on, color: Colors.blueAccent, size: 20),
              SizedBox(width: 10),
              Text('Mencari lokasi...'),
              SizedBox(width: 10),
              CupertinoActivityIndicator(radius: 10),
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
            text: 'Status lokasi tidak diketahui.',
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
