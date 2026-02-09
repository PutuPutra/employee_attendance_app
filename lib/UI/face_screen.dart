import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gunas_employee_attendance/blocs/face_detection/face_detection_bloc.dart';
import 'package:gunas_employee_attendance/services/camera_service.dart';
import 'package:gunas_employee_attendance/services/face_data_service.dart';
import '../l10n/app_localizations.dart';

class FaceScreen extends StatelessWidget {
  const FaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          FaceDetectionBloc(CameraService(), FaceDataService())
            ..add(InitializeCamera()),
      child: const FaceScreenView(),
    );
  }
}

class FaceScreenView extends StatelessWidget {
  const FaceScreenView({super.key});

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
          child: BlocConsumer<FaceDetectionBloc, FaceDetectionState>(
            listener: (context, state) {
              if (state is FaceCaptureSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.imageSaved), // Menampilkan path lokal
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.of(context).pop();
              } else if (state is FaceCaptureFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${l10n.error}: ${state.error}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, state) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      l10n.faceRegistration,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(
                    width: 280,
                    height: 380,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child:
                          (state is CameraInitializing ||
                              state is FaceDetectionInitial)
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : CameraPreview(
                              context
                                  .read<FaceDetectionBloc>()
                                  .cameraService
                                  .controller!,
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: _buildInstructionAndAction(context, state),
                    ),
                  ),
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
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionAndAction(
    BuildContext context,
    FaceDetectionState state,
  ) {
    final l10n = AppLocalizations.of(context);

    if (state is FaceCaptureInProgress) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 20),
            Text(
              l10n.savingImage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (state is CameraReady) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.positionFaceInstruction,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              context.read<FaceDetectionBloc>().add(CaptureAndRegisterFace());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: Text(
              l10n.captureFace,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      );
    }

    return Center(
      child: Text(
        l10n.preparingCamera,
        style: const TextStyle(color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }
}
