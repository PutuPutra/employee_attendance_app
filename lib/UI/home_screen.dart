import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'login_screen.dart';
import 'face_screen.dart';
import 'face_scan.dart';
import 'settings_screen.dart';
import 'account_settings_screen.dart';
import '../auth/auth_service.dart';
import '../l10n/app_localizations.dart';
import '../core/constants/storage_keys.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? startDate;
  DateTime? endDate;
  String? _employeeId;
  String? _region;
  String? _locationName;
  bool _isFaceRegistered = false;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  StreamSubscription<QuerySnapshot>? _faceRegisterSubscription;
  StreamSubscription<QuerySnapshot>? _todayAttendanceSubscription;
  bool _hasCheckedInToday = false;
  String? _breakInTime;
  String? _breakOutTime;
  String? _checkOutTime;

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _faceRegisterSubscription?.cancel();
    _todayAttendanceSubscription?.cancel();
    super.dispose();
  }

  void _setupListeners() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // 1. Listen ke data User untuk mendapatkan employeeId terbaru
      _userSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen(
            (snapshot) async {
              final data = snapshot.data() as Map<String, dynamic>?;
              final newEmployeeId =
                  data?[StorageKeys.employeeId]?.toString() ?? '';
              final newRegion = data?['region']?.toString() ?? '';

              // Ambil location_name dari collection locations berdasarkan location_id
              final companyId = data?['company_id']?.toString();
              String newLocationName = '';
              final locationId = data?['location_id'];

              if (locationId != null && locationId.toString().isNotEmpty) {
                try {
                  final locDoc = await FirebaseFirestore.instance
                      .collection('locations')
                      .doc(locationId.toString())
                      .get();
                  if (locDoc.exists) {
                    newLocationName =
                        locDoc.data()?['location_name']?.toString() ?? '';
                  }
                } catch (e) {
                  debugPrint("Error fetching location name: $e");
                }
              }

              // Fetch settings (Jam Istirahat & Pulang)
              _fetchSettings(companyId, locationId?.toString());

              // Jika employeeId atau region berubah, update state
              if (_employeeId != newEmployeeId ||
                  _region != newRegion ||
                  _locationName != newLocationName) {
                final bool idChanged = _employeeId != newEmployeeId;
                if (mounted) {
                  setState(() {
                    _employeeId = newEmployeeId;
                    _region = newRegion;
                    _locationName = newLocationName;
                  });
                }
                if (idChanged) {
                  _updateFaceRegisterListener(newEmployeeId);
                  _updateTodayAttendanceListener(newEmployeeId);
                }
              }
            },
            onError: (e) {
              debugPrint("Error listening to user data: $e");
            },
          );
    }
  }

  Future<void> _fetchSettings(String? companyId, String? locationId) async {
    try {
      Map<String, dynamic> settings = {};

      // 1. Fetch Company Settings (Base Layer)
      if (companyId != null && companyId.isNotEmpty) {
        final companyDoc = await FirebaseFirestore.instance
            .collection('companies')
            .doc(companyId)
            .get();
        if (companyDoc.exists) {
          final data = companyDoc.data();
          if (data != null && data['settings'] != null) {
            settings.addAll(Map<String, dynamic>.from(data['settings']));
          }
        }
      }

      // 2. Fetch Location Settings (Override Layer)
      // Sesuai briefing: Jika settings di location TIDAK NULL, maka pakai (override)
      if (locationId != null && locationId.isNotEmpty) {
        final locationDoc = await FirebaseFirestore.instance
            .collection('locations')
            .doc(locationId)
            .get();
        if (locationDoc.exists) {
          final data = locationDoc.data();
          // Cek apakah field 'settings' ada dan tidak null
          if (data != null && data['settings'] != null) {
            final locSettings = Map<String, dynamic>.from(data['settings']);
            locSettings.forEach((key, value) {
              // Hanya override jika value valid (tidak null/empty)
              if (value != null && value.toString().isNotEmpty) {
                settings[key] = value;
              }
            });
          }
        }
      }

      if (mounted) {
        setState(() {
          _breakInTime = settings['break_in_time']?.toString();
          _breakOutTime = settings['break_out_time']?.toString();
          _checkOutTime = settings['check_out_time']?.toString();
        });
      }
    } catch (e) {
      debugPrint("Error fetching settings: $e");
    }
  }

  void _updateFaceRegisterListener(String employeeId) {
    // Cancel listener lama jika ada
    _faceRegisterSubscription?.cancel();

    if (employeeId.isNotEmpty) {
      // 2. Listen ke face_register berdasarkan employeeId
      _faceRegisterSubscription = FirebaseFirestore.instance
          .collection('face_register')
          .where(StorageKeys.employeeId, isEqualTo: employeeId)
          .limit(1)
          .snapshots()
          .listen(
            (snapshot) {
              final isRegistered = snapshot.docs.isNotEmpty;
              // Update state hanya jika status berubah
              if (_isFaceRegistered != isRegistered) {
                if (mounted) {
                  setState(() {
                    _isFaceRegistered = isRegistered;
                  });
                }
              }
            },
            onError: (e) {
              debugPrint("Error listening to face register: $e");
            },
          );
    } else {
      // Jika tidak ada employeeId, anggap belum terdaftar
      if (_isFaceRegistered) {
        if (mounted) {
          setState(() {
            _isFaceRegistered = false;
          });
        }
      }
    }
  }

  void _updateTodayAttendanceListener(String employeeId) {
    _todayAttendanceSubscription?.cancel();

    if (employeeId.isNotEmpty) {
      final now = DateTime.now();
      // Format tanggal harus sama persis dengan yang disimpan di database
      // Berdasarkan request: "February 10, 2026" -> MMMM d, yyyy
      final todayStr = DateFormat('MMMM d, yyyy').format(now);

      _todayAttendanceSubscription = FirebaseFirestore.instance
          .collection('user_attendance')
          .where('employeeId', isEqualTo: employeeId)
          .where('date', isEqualTo: todayStr) // Query for all records of today
          .snapshots()
          .listen(
            (snapshot) {
              // Check if any of today's records is a 'checkIn' (status == 1)
              final hasCheckedInToday = snapshot.docs.any(
                (doc) => (doc.data() as Map<String, dynamic>)['status'] == 1,
              );
              if (_hasCheckedInToday != hasCheckedInToday) {
                if (mounted) {
                  setState(() {
                    _hasCheckedInToday = hasCheckedInToday;
                  });
                }
              }
            },
            onError: (e) {
              debugPrint("Error listening to today's attendance: $e");
            },
          );
    }
  }

  void _handleAttendanceAction(String type) {
    final now = DateTime.now();
    final l10n = AppLocalizations.of(context);

    String? targetTimeStr;
    String actionLabel = '';

    switch (type) {
      case 'breakStart':
        targetTimeStr = _breakInTime;
        actionLabel = l10n.break_;
        break;
      case 'breakEnd':
        targetTimeStr = _breakOutTime;
        actionLabel = l10n.return_;
        break;
      case 'checkOut':
        targetTimeStr = _checkOutTime;
        actionLabel = l10n.checkOut;
        break;
      default:
        _go(FaceScanScreen(attendanceType: type));
        return;
    }

    // Jika tidak ada setting jam dari Firebase, langsung lanjut tanpa validasi waktu
    if (targetTimeStr == null || !targetTimeStr.contains(':')) {
      _go(FaceScanScreen(attendanceType: type));
      return;
    }

    int targetHour = 0;
    int targetMinute = 0;

    try {
      final parts = targetTimeStr.split(':');
      targetHour = int.parse(parts[0]);
      targetMinute = int.parse(parts[1]);
    } catch (e) {
      debugPrint("Error parsing time for $type: $e");
      _go(FaceScanScreen(attendanceType: type));
      return;
    }

    final targetDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      targetHour,
      targetMinute,
    );

    // Jika waktu sekarang kurang dari target waktu, tampilkan peringatan
    if (now.isBefore(targetDateTime)) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(l10n.earlyAttendance),
          content: Text(
            '${l10n.notYetTime} $actionLabel. ${l10n.wantToProceed}',
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.pop(ctx),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: Text(l10n.proceed),
              onPressed: () {
                Navigator.pop(ctx);
                _go(FaceScanScreen(attendanceType: type));
              },
            ),
          ],
        ),
      );
    } else {
      // Jika sudah waktunya, langsung lanjut
      _go(FaceScanScreen(attendanceType: type));
    }
  }

  // Helper to get the start of the day
  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Helper to get the end of the day
  DateTime _endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  Stream<QuerySnapshot> _getAttendanceStream() {
    if (_employeeId == null || _employeeId!.isEmpty) {
      return const Stream.empty();
    }

    debugPrint("🔍 Fetching attendance for Employee ID: $_employeeId");

    // UPDATE: Kita hapus orderBy dan limit di server untuk menghindari error "Requires Index".
    // Kita akan ambil semua data user ini, lalu sort dan limit di sisi aplikasi (client-side).
    return FirebaseFirestore.instance
        .collection('user_attendance')
        .where('employeeId', isEqualTo: _employeeId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          /// ================= BLUE GRADIENT BACKGROUND =================
          Container(
            height: 260,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        Colors.blue.shade900,
                        Colors.blue.shade800,
                        Colors.grey.shade900,
                      ]
                    : [
                        Colors.blue.shade900,
                        Colors.blue.shade800,
                        Colors.blue.shade600,
                      ],
              ),
            ),
          ),

          /// ================= MAIN CONTENT =================
          SafeArea(
            child: Column(
              children: [
                /// ================= TOP BAR =================
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: _ProfileHeader()),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          _TopIcon(
                            icon: CupertinoIcons.settings,
                            onTap: () => Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (_) => const SettingsScreen(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _TopIcon(
                            icon: CupertinoIcons.square_arrow_right,
                            onTap: () => _showLogoutDialog(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                /// ================= WHITE CONTENT =================
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey[900]
                          : CupertinoColors.systemGroupedBackground,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      children: [
                        /// ================= ACTION BUTTONS =================
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _employeeId == null
                              ? const Center(
                                  child: CupertinoActivityIndicator(),
                                )
                              : _isFaceRegistered
                              ? GridView.count(
                                  crossAxisCount: 2,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 1.6,
                                  children: [
                                    _IOSActionCard(
                                      title: l10n.checkIn,
                                      icon: CupertinoIcons.arrow_right_circle,
                                      color: _hasCheckedInToday
                                          ? CupertinoColors.systemGrey
                                          : CupertinoColors.systemBlue,
                                      onTap: _hasCheckedInToday
                                          ? () {} // Disable jika sudah check in
                                          : () => _go(
                                              const FaceScanScreen(
                                                attendanceType: 'checkIn',
                                              ),
                                            ),
                                    ),
                                    if (_locationName != 'Head Office') ...[
                                      _IOSActionCard(
                                        title: l10n.break_,
                                        icon: CupertinoIcons.clock,
                                        color: CupertinoColors.systemOrange,
                                        onTap: () => _handleAttendanceAction(
                                          'breakStart',
                                        ),
                                      ),
                                      _IOSActionCard(
                                        title: l10n.return_,
                                        icon:
                                            CupertinoIcons.arrow_turn_down_left,
                                        color: CupertinoColors.systemGreen,
                                        onTap: () =>
                                            _handleAttendanceAction('breakEnd'),
                                      ),
                                    ],
                                    _IOSActionCard(
                                      title: l10n.checkOut,
                                      icon: CupertinoIcons.arrow_right_square,
                                      color: CupertinoColors.systemRed,
                                      onTap: () =>
                                          _handleAttendanceAction('checkOut'),
                                    ),
                                  ],
                                )
                              : SizedBox(
                                  width: double.infinity,
                                  height: 100,
                                  child: _IOSActionCard(
                                    title: l10n.faceRegistration,
                                    icon: CupertinoIcons
                                        .person_crop_circle_badge_plus,
                                    color: CupertinoColors.systemPurple,
                                    onTap: () {
                                      if (_employeeId == null ||
                                          _employeeId!.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              l10n.completeAccountDataFirst,
                                            ),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                        _go(const AccountSettingsScreen());
                                      } else {
                                        _go(const FaceScreen());
                                      }
                                    },
                                  ),
                                ),
                        ),

                        /// ================= HEADER RIWAYAT =================
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.attendanceHistory,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => _showDateRangeDialog(context),
                                    child: Icon(
                                      CupertinoIcons.slider_horizontal_3,
                                      color: isDark
                                          ? CupertinoColors.systemBlue
                                          : CupertinoColors.systemBlue,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        startDate = null;
                                        endDate = null;
                                      });
                                    },
                                    child: Icon(
                                      CupertinoIcons.refresh,
                                      color: isDark
                                          ? CupertinoColors.systemBlue
                                          : CupertinoColors.systemBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        /// ================= FILTER INFO =================
                        if (startDate != null && endDate != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${_fmt(startDate!)} → ${_fmt(endDate!)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ),
                          ),

                        /// ================= SCROLLABLE HISTORY ONLY =================
                        Expanded(
                          child: _employeeId == null
                              ? const Center(
                                  child: CupertinoActivityIndicator(),
                                )
                              : StreamBuilder<QuerySnapshot>(
                                  stream: _getAttendanceStream(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasError) {
                                      debugPrint(
                                        "❌ Stream Error: ${snapshot.error}",
                                      );
                                      return Center(
                                        child: Text(
                                          '${l10n.error}: ${snapshot.error}',
                                        ),
                                      );
                                    }

                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CupertinoActivityIndicator(),
                                      );
                                    }

                                    // Ambil data dan convert ke List yang bisa dimodifikasi
                                    if (snapshot.hasData) {
                                      debugPrint(
                                        "✅ Stream received ${snapshot.data!.docs.length} documents.",
                                      );
                                    }

                                    final rawDocs = snapshot.data?.docs ?? [];
                                    final Map<String, Map<String, dynamic>>
                                    groupedData = {};

                                    // Grouping data berdasarkan tanggal
                                    for (var doc in rawDocs) {
                                      final data =
                                          doc.data() as Map<String, dynamic>;
                                      final dateStr = data['date'] as String?;
                                      if (dateStr == null) continue;

                                      if (!groupedData.containsKey(dateStr)) {
                                        groupedData[dateStr] = {
                                          'date': dateStr,
                                          'timestamp':
                                              data['timestamp'], // Untuk sorting & display tanggal
                                          'checkIn': null,
                                          'breakStart': null,
                                          'breakEnd': null,
                                          'statusCheckIn':
                                              1, // Default to on-time
                                          'checkOut': null,
                                        };
                                      }

                                      final status =
                                          data['status']; // 1, 2, 3, 4
                                      final ts = data['timestamp'];

                                      if (status == 1) {
                                        groupedData[dateStr]!['checkIn'] = ts;
                                        groupedData[dateStr]!['statusCheckIn'] =
                                            data['statusCheckIn'] ?? 1;
                                      } else if (status == 2) {
                                        groupedData[dateStr]!['breakStart'] =
                                            ts;
                                      } else if (status == 3) {
                                        groupedData[dateStr]!['breakEnd'] = ts;
                                      } else if (status == 4) {
                                        groupedData[dateStr]!['checkOut'] = ts;
                                      }
                                    }

                                    var historyList = groupedData.values
                                        .toList();

                                    // 1. SORTING CLIENT-SIDE (Terbaru di atas)
                                    historyList.sort((a, b) {
                                      final t1 = a['timestamp'] as Timestamp?;
                                      final t2 = b['timestamp'] as Timestamp?;
                                      if (t1 == null && t2 == null) return 0;
                                      if (t1 == null) return 1;
                                      if (t2 == null) return -1;
                                      return t2.compareTo(t1);
                                    });

                                    // 2. FILTERING & LIMITING
                                    if (startDate != null && endDate != null) {
                                      // Filter by date range
                                      historyList = historyList.where((data) {
                                        final t =
                                            data['timestamp'] as Timestamp?;
                                        if (t == null) return false;
                                        final date = t.toDate();
                                        return date.isAfter(
                                              _startOfDay(startDate!).subtract(
                                                const Duration(seconds: 1),
                                              ),
                                            ) &&
                                            date.isBefore(
                                              _endOfDay(
                                                endDate!,
                                              ).add(const Duration(seconds: 1)),
                                            );
                                      }).toList();
                                    } else {
                                      // Default: Ambil 7 data terbaru saja
                                      if (historyList.length > 7) {
                                        historyList = historyList.sublist(0, 7);
                                      }
                                    }

                                    if (historyList.isEmpty) {
                                      return Center(
                                        child: Text(
                                          l10n.noHistoryFound,
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.black54,
                                          ),
                                        ),
                                      );
                                    }

                                    return ListView.builder(
                                      physics: const BouncingScrollPhysics(),
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        0,
                                        16,
                                        12,
                                      ),
                                      itemCount: historyList.length,
                                      itemBuilder: (context, index) {
                                        final data = historyList[index];
                                        return _IOSHistoryCard(
                                          data: data,
                                          locationName: _locationName,
                                        );
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ================= DATE FILTER (BOTTOM iOS STYLE) =================
  void _showDateRangeDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? Colors.grey[850] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + bottomPadding + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.selectDateRange,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// START DATE
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => startDate = picked);
                          setModalState(() {});
                        }
                      },
                      child: Text(
                        startDate == null
                            ? l10n.selectStartDate
                            : '${l10n.start}: ${startDate!.toLocal().toString().split(' ')[0]}',
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// END DATE
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: endDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          if (startDate != null &&
                              picked.isBefore(startDate!)) {
                            showCupertinoDialog(
                              context: context,
                              builder: (ctx) => CupertinoAlertDialog(
                                title: Text(l10n.invalidDateRange),
                                content: Text(l10n.endDateBeforeStartDate),
                                actions: [
                                  CupertinoDialogAction(
                                    child: Text(l10n.ok),
                                    onPressed: () => Navigator.pop(ctx),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }
                          setState(() => endDate = picked);
                          setModalState(() {});
                        }
                      },
                      child: Text(
                        endDate == null
                            ? l10n.selectEndDate
                            : '${l10n.end}: ${endDate!.toLocal().toString().split(' ')[0]}',
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.cancel),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (startDate != null && endDate != null) {
                            if (endDate!.isBefore(startDate!)) {
                              showCupertinoDialog(
                                context: context,
                                builder: (ctx) => CupertinoAlertDialog(
                                  title: Text(l10n.invalidDateRange),
                                  content: Text(l10n.endDateBeforeStartDate),
                                  actions: [
                                    CupertinoDialogAction(
                                      child: const Text('OK'),
                                      onPressed: () => Navigator.pop(ctx),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }
                          }
                          // Trigger rebuild with new filters
                          setState(() {});
                          Navigator.pop(context);
                        },
                        child: Text(l10n.ok),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// ================= HELPERS =================
  void _go(Widget page) {
    Navigator.push(context, CupertinoPageRoute(builder: (_) => page));
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  void _showLogoutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirm),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text(l10n.logout),
            onPressed: () async {
              Navigator.pop(context);
              await authService.value.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  CupertinoPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

/// ================= PROFILE HEADER =================
class _ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = authService.value.currentUser;
    final l10n = AppLocalizations.of(context);

    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        // Ambil username dari Firestore, jika null gunakan Auth displayName
        final username = data?['username'] ?? user.displayName ?? 'User Name';

        String employeeId;
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          employeeId = '${l10n.idLabel}: ...';
        } else {
          employeeId = data?[StorageKeys.employeeId] ?? l10n.notAvailable;
        }

        return Row(
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white24,
              child: Icon(CupertinoIcons.person_fill, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    employeeId,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// ================= TOP ICON =================
class _TopIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

/// ================= ACTION CARD =================
class _IOSActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IOSActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : CupertinoColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : const Color(0x11000000),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ================= HISTORY CARD =================
class _IOSHistoryCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String? locationName;

  const _IOSHistoryCard({super.key, required this.data, this.locationName});

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '--:--';
    if (timestamp is Timestamp) {
      return DateFormat('HH:mm').format(timestamp.toDate());
    }
    return '--:--';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    // Extract data
    final timestamp = data['timestamp'] as Timestamp?;
    final date = timestamp?.toDate() ?? DateTime.now();

    final checkIn = data['checkIn'];
    final statusCheckIn = data['statusCheckIn']; // 1: On-time, 2: Late
    final isLate = statusCheckIn == 2;
    final breakStart = data['breakStart'];
    final breakEnd = data['breakEnd'];
    final checkOut = data['checkOut'];

    final localeCode = Localizations.localeOf(context).languageCode;
    final formattedDay = DateFormat('EEEE', localeCode).format(date);
    final formattedDate = DateFormat('d MMM', localeCode).format(date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : CupertinoColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedDay,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  formattedDate,
                  style: const TextStyle(color: CupertinoColors.systemGrey),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Time(
                  label: l10n.entry,
                  time: _formatTime(checkIn),
                  isLate: isLate,
                ),
                if (locationName != 'Head Office') ...[
                  _Time(label: l10n.breakTime, time: _formatTime(breakStart)),
                  _Time(label: l10n.returnTime, time: _formatTime(breakEnd)),
                ],
                _Time(label: l10n.exit, time: _formatTime(checkOut)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ================= TIME =================
class _Time extends StatelessWidget {
  final String label;
  final String time;
  final bool isLate;

  const _Time({required this.label, required this.time, this.isLate = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isLate
                ? CupertinoColors.systemRed
                : (isDark ? Colors.white : Colors.black),
          ),
        ),
      ],
    );
  }
}
