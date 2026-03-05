import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'reset_password.dart';
import '../auth/auth_service.dart';
import '../l10n/app_localizations.dart';
import '../core/constants/storage_keys.dart';
import '../services/biometric_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _showBiometricLogin = false;
  final BiometricService _biometricService = BiometricService();

  @override
  void initState() {
    super.initState();
    _checkBiometricSettings();
    _emailController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
  }

  Future<void> _checkBiometricSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(StorageKeys.isBiometricEnabled) ?? false;

    if (isEnabled) {
      final isAvailable = await _biometricService.isBiometricAvailable();
      if (mounted) {
        setState(() => _showBiometricLogin = isAvailable);
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    final l10n = AppLocalizations.of(context);
    try {
      final authenticated = await _biometricService.authenticate(
        localizedReason: l10n.biometricReason,
      );
      if (authenticated) {
        final prefs = await SharedPreferences.getInstance();
        final email = prefs.getString(StorageKeys.savedEmail);
        final password = prefs.getString(StorageKeys.savedPassword);

        if (email != null && password != null) {
          if (mounted) setState(() => _isLoading = true);
          try {
            await authService.value.signIn(email: email, password: password);
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            }
          } on FirebaseAuthException catch (e) {
            if (mounted) {
              String message = l10n.loginFailed;
              if (e.code == 'user-not-found') {
                message = l10n.userNotFound;
              } else if (e.code == 'wrong-password') {
                message = l10n.wrongPassword;
              } else if (e.code == 'user-disabled') {
                message = l10n.userDisabled;
              } else if (e.code == 'invalid-email') {
                message = l10n.invalidEmailFormat;
              } else if (e.code == 'invalid-credential') {
                message = l10n.invalidCredentials;
              } else if (e.code == 'too-many-requests') {
                message = l10n.tooManyRequests;
              }
              _showTopNotification(context, message, isError: true);
            }
          } catch (e) {
            if (mounted) {
              _showTopNotification(
                context,
                '${l10n.loginFailed}: ${e.toString()}',
                isError: true,
              );
            }
          } finally {
            if (mounted) setState(() => _isLoading = false);
          }
        } else if (mounted) {
          _showTopNotification(
            context,
            l10n.loginManualRequired,
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showTopNotification(
          context,
          e.toString().replaceAll('Exception: ', ''),
          isError: true,
        );
      }
    }
  }

  Future<void> _login() async {
    final l10n = AppLocalizations.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showTopNotification(
        context,
        l10n.pleaseEnterEmailPassword,
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await authService.value.signIn(email: email, password: password);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StorageKeys.savedEmail, email);
      await prefs.setString(StorageKeys.savedPassword, password);

      if (mounted) {
        final isBiometricAvailable = await _biometricService
            .isBiometricAvailable();
        final isBiometricEnabled =
            prefs.getBool(StorageKeys.isBiometricEnabled) ?? false;

        if (isBiometricAvailable && !isBiometricEnabled) {
          final enable = await _showBiometricOfferDialog();
          if (enable == true) {
            await prefs.setBool(StorageKeys.isBiometricEnabled, true);
          }
        }
        _navigateToHome();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message = l10n.loginFailed;
        if (e.code == 'user-not-found') {
          message = l10n.userNotFound;
        } else if (e.code == 'wrong-password') {
          message = l10n.wrongPassword;
        } else if (e.code == 'invalid-email') {
          message = l10n.invalidEmailFormat;
        } else if (e.code == 'user-disabled') {
          message = l10n.userDisabled;
        } else if (e.code == 'invalid-credential') {
          message = l10n.invalidCredentials;
        } else if (e.code == 'too-many-requests') {
          message = l10n.tooManyRequests;
        }
        _showTopNotification(context, message, isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showTopNotification(context, l10n.loginFailed, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<bool?> _showBiometricOfferDialog() async {
    final l10n = AppLocalizations.of(context);
    return showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.enableBiometricTitle),
        content: Text(l10n.enableBiometricMessage),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.later),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(l10n.enable),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }

  void _showTopNotification(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: FadeInDown(
            duration: const Duration(milliseconds: 500),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isError ? Colors.redAccent : Colors.green,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    isError ? Icons.error_outline : Icons.check_circle_outline,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        try {
          overlayEntry.remove();
        } catch (_) {}
      }
    });
  }

  InputDecoration _iosInput(
    String hint,
    IconData icon,
    bool isDark, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.green.shade800),
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.9)
          : Colors.white.withValues(alpha: 0.75),
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bool isBiometricActive =
        _showBiometricLogin &&
        _emailController.text.isEmpty &&
        _passwordController.text.isEmpty;

    return Scaffold(
      body: Stack(
        children: [
          ///  GRADIENT BACKGROUND
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                colors: [
                  Colors.green.shade900,
                  Colors.green.shade800,
                  Colors.lightGreen.shade400,
                ],
              ),
            ),
          ),

          /// HEADER
          Positioned(
            top: 90,
            left: 20,
            right: 20,
            child: Column(
              children: [
                FadeInUp(
                  duration: const Duration(milliseconds: 900),
                  child: Text(
                    l10n.login,
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FadeInUp(
                  duration: const Duration(milliseconds: 1200),
                  child: Text(
                    l10n.welcomeBack,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// GLASS CARD
          Positioned(
            top: screenHeight * 0.35,
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(50),
                topRight: Radius.circular(50),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.grey[900]!.withValues(alpha: 0.95)
                        : Colors.white.withValues(alpha: 0.85),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        const SizedBox(height: 50),

                        FadeInUp(
                          duration: const Duration(milliseconds: 1400),
                          child: Column(
                            children: [
                              TextField(
                                controller: _emailController,
                                decoration: _iosInput(
                                  l10n.email,
                                  Icons.mail,
                                  isDark,
                                ),
                                style: TextStyle(
                                  color: isDark ? Colors.black : null,
                                ),
                              ),
                              const SizedBox(height: 18),
                              TextField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                decoration: _iosInput(
                                  l10n.password,
                                  Icons.lock,
                                  isDark,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(
                                        () => _isPasswordVisible =
                                            !_isPasswordVisible,
                                      );
                                    },
                                  ),
                                ),
                                style: TextStyle(
                                  color: isDark ? Colors.black : null,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ResetPasswordScreen(),
                              ),
                            );
                          },
                          child: Text(
                            l10n.forgotPassword,
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const SizedBox(height: 35),

                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : (isBiometricActive
                                      ? _handleBiometricLogin
                                      : _login),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade900,
                              elevation: 6,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  )
                                : Text(
                                    isBiometricActive
                                        ? l10n.biometricLogin
                                        : l10n.login,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
