import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'face_screen.dart';
import 'face_scan.dart';
import 'settings_screen.dart';
import '../auth/auth_service.dart';
import '../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? startDate;
  DateTime? endDate;

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
                      _ProfileHeader(),
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
                          child: GridView.count(
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
                                color: CupertinoColors.systemBlue,
                                onTap: () => _go(const FaceScreen()),
                              ),
                              _IOSActionCard(
                                title: l10n.break_,
                                icon: CupertinoIcons.clock,
                                color: CupertinoColors.systemOrange,
                                onTap: () => _go(const FaceScanScreen()),
                              ),
                              _IOSActionCard(
                                title: l10n.return_,
                                icon: CupertinoIcons.arrow_turn_down_left,
                                color: CupertinoColors.systemGreen,
                                onTap: () => _go(const FaceScreen()),
                              ),
                              _IOSActionCard(
                                title: l10n.checkOut,
                                icon: CupertinoIcons.arrow_right_square,
                                color: CupertinoColors.systemRed,
                                onTap: () => _go(const FaceScreen()),
                              ),
                            ],
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
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            itemCount: 7,
                            itemBuilder: (context, index) {
                              return _IOSHistoryCard(index: index);
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? Colors.grey[850] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
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
                      setState(() => endDate = picked);
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
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.ok),
                  ),
                ],
              ),
            ],
          ),
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

    return Row(
      children: [
        const CircleAvatar(
          radius: 22,
          backgroundColor: Colors.white24,
          child: Icon(CupertinoIcons.person_fill, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user?.displayName ?? 'User Name',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'ID: ${user?.uid.substring(0, 8) ?? '12345678'}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ],
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
                  ? Colors.black.withOpacity(0.3)
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
  final int index;
  const _IOSHistoryCard({required this.index});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final days = [
      l10n.monday,
      l10n.tuesday,
      l10n.wednesday,
      l10n.thursday,
      l10n.friday,
      l10n.saturday,
      l10n.sunday,
    ];
    final dates = [
      '25 Okt',
      '26 Okt',
      '27 Okt',
      '28 Okt',
      '29 Okt',
      '30 Okt',
      '31 Okt',
    ];

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
                  days[index],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  dates[index],
                  style: const TextStyle(color: CupertinoColors.systemGrey),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Time(label: l10n.entry, time: '08:00'),
                _Time(label: l10n.breakTime, time: '12:00'),
                _Time(label: l10n.returnTime, time: '13:00'),
                _Time(label: l10n.exit, time: '17:00'),
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
  const _Time({required this.label, required this.time});

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
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }
}
