import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Login gagal: ${e.toString()}')),
              );
            }
          } finally {
            if (mounted) setState(() => _isLoading = false);
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Silakan login manual sekali untuk mengaktifkan fitur ini.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _login() async {
    final l10n = AppLocalizations.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pleaseEnterEmailPassword)));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await authService.value.signIn(email: email, password: password);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StorageKeys.savedEmail, email);
      await prefs.setString(StorageKeys.savedPassword, password);

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
        } else if (e.code == 'invalid-email') {
          message = l10n.invalidEmailFormat;
        } else if (e.code == 'user-disabled') {
          message = l10n.userDisabled;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.loginFailed)));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _iosInput(
    String hint,
    IconData icon,
    bool isDark, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.blue.shade800),
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
          /// 🔵 GRADIENT BACKGROUND (Tetap biru untuk branding)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                colors: [
                  Colors.blue.shade900,
                  Colors.blue.shade800,
                  Colors.blue.shade400,
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
                              color: Colors.blue,
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
                              backgroundColor: Colors.blue.shade900,
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
