import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gunas_employee_attendance/auth/auth_service.dart';
import '../l10n/app_localizations.dart';

class FaceScanScreen extends StatefulWidget {
  const FaceScanScreen({super.key});

  @override
  State<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen> {
  String _currentTime = '';
  String _currentDate = '';
  final String _location =
      'Gedung Putih Jalan Perjuangan No57, Jakarta Pusat, Jakarta, Indonesia (-6.2088, 106.8456)';
  String _name = '';
  String _id = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _updateTime();
  }

  void _loadUserData() {
    final user = authService.value.currentUser;
    setState(() {
      _name = user?.displayName ?? 'Unknown';
      _id = user?.email ?? 'N/A';
    });
  }

  void _updateTime() {
    setState(() {
      _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
      _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    });
    Future.delayed(const Duration(seconds: 1), _updateTime);
  }

  String _getLocalizedDay(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dayIndex = DateTime.now().weekday - 1; // Monday = 0
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
      body: Stack(
        children: [
          // Camera background placeholder
          Container(
            color: isDark ? Colors.black : Colors.black,
            child: Align(
              alignment: const Alignment(0.0, -0.36),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.grey[850] : Colors.grey[800],
                  border: Border.all(color: Colors.blueAccent, width: 5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.camera_alt, color: Colors.white, size: 50),
                ),
              ),
            ),
          ),
          // Gradient overlay around camera
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.6,
                  colors: [
                    Colors.blue.withValues(alpha: 0.4),
                    Colors.blue.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          // Bottom card
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.36,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
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
                    Row(
                      children: [
                        const Icon(Icons.person, color: Colors.blueAccent),
                        const SizedBox(width: 10),
                        Text(
                          '$_name - $_id',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.timelapse, color: Colors.blueAccent),
                        const SizedBox(width: 10),
                        Text(
                          '${_getLocalizedDay(context)}, $_currentDate',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white60 : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.blueAccent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _location,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white60 : Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Submit action
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
