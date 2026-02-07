import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class FaceScreen extends StatelessWidget {
  const FaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              colors: isDark
                  ? [Colors.grey[700]!, Colors.grey.shade800, Colors.grey[900]!]
                  : [
                      Colors.blue.shade900,
                      Colors.blue.shade800,
                      Colors.blue.shade400,
                    ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Text(
                l10n.faceRegistration,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.positionYourFace,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 50),
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 80,
                ),
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement face recognition
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.faceRecognitionNotImplemented)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue.shade900,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  l10n.capture,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(20),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    l10n.skipForNow,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
