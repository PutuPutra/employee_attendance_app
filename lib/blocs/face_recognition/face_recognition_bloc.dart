import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:gunas_employee_attendance/services/face_detection_service.dart';
import 'package:gunas_employee_attendance/services/ml_service.dart';
import 'package:path_provider/path_provider.dart';

part 'face_recognition_event.dart';
part 'face_recognition_state.dart';

class FaceRecognitionBloc
    extends Bloc<FaceRecognitionEvent, FaceRecognitionState> {
  final FaceDetectionService _detectionService = FaceDetectionService();
  final MLService _mlService = MLService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<double>? _registeredEmbedding;
  bool _isProcessing = false;

  // --- KONFIGURASI LIVENESS DETECTION ---
  // Ubah ke true untuk mengaktifkan fitur kedip, false untuk mematikan (langsung scan)
  static const bool isLivenessEnabled = false;

  // Variabel untuk Liveness Detection (Kedipan)
  int? _currentTrackingId;
  bool _hasBlinked = false;

  FaceRecognitionBloc() : super(FaceRecognitionInitial()) {
    _detectionService.initialize();
    on<LoadRegisteredFace>(_onLoadRegisteredFace);
    on<ProcessCameraImage>(_onProcessCameraImage);
  }

  Future<void> _onLoadRegisteredFace(
    LoadRegisteredFace event,
    Emitter<FaceRecognitionState> emit,
  ) async {
    emit(FaceRecognitionLoading());
    try {
      // Pastikan ML Service siap sebelum loading data
      await _mlService.initialize();

      final user = _auth.currentUser;
      if (user == null) {
        emit(FaceRecognitionFailure("User tidak login"));
        return;
      }

      // 1. Ambil nama file gambar dari Firestore
      final doc = await _firestore
          .collection('face_register')
          .doc(user.uid)
          .get();
      if (!doc.exists || doc.data()?['faceImagePath'] == null) {
        emit(FaceRecognitionFailure("Wajah belum didaftarkan"));
        return;
      }

      final fileName = doc.data()!['faceImagePath'];
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');

      if (!await file.exists()) {
        emit(FaceRecognitionFailure("File wajah tidak ditemukan di lokal"));
        return;
      }

      // 2. Deteksi wajah pada gambar file
      // Kita perlu InputImage dari file untuk ML Kit
      final inputImage = InputImage.fromFilePath(file.path);
      // Note: FaceDetectionService perlu method untuk handle InputImage langsung atau kita buat instance detector lokal
      final faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.accurate,
        ),
      );

      try {
        final faces = await faceDetector.processImage(inputImage);

        if (faces.isEmpty) {
          emit(FaceRecognitionFailure("Tidak ada wajah di foto terdaftar"));
          return;
        }

        // 3. Generate Embedding untuk wajah terdaftar
        _registeredEmbedding = await _mlService.getEmbeddingFromFile(
          file,
          faces.first,
        );

        emit(FaceNotMatched()); // Siap untuk scan
      } finally {
        faceDetector.close();
      }
    } catch (e) {
      String message = e.toString();
      if (message.startsWith("Exception: ")) {
        message = message.replaceFirst("Exception: ", "");
      }
      emit(FaceRecognitionFailure(message));
    }
  }

  Future<void> _onProcessCameraImage(
    ProcessCameraImage event,
    Emitter<FaceRecognitionState> emit,
  ) async {
    if (_isProcessing || _registeredEmbedding == null) return;
    _isProcessing = true;

    try {
      // 1. Deteksi wajah (ML Kit)
      final face = await _detectionService.processImage(
        event.image,
        event.cameraDescription,
      );

      if (face != null) {
        // --- LIVENESS DETECTION (BLINK CHECK) ---
        if (isLivenessEnabled) {
          // Reset status jika wajah berganti (trackingId berubah)
          if (face.trackingId != _currentTrackingId) {
            _currentTrackingId = face.trackingId;
            _hasBlinked = false;
          }

          // Deteksi mata tertutup (Probabilitas < 0.1 atau 10%)
          if ((face.leftEyeOpenProbability ?? 1.0) < 0.1 &&
              (face.rightEyeOpenProbability ?? 1.0) < 0.1) {
            _hasBlinked = true;
            debugPrint("Liveness: Blink Detected! (Eyes Closed)");
          }
        }
        // ----------------------------------------

        debugPrint("Face detected! Generating embedding..."); // DEBUG LOG

        // 2. Generate Embedding dari kamera (TFLite)
        final currentEmbedding = await _mlService.getEmbeddingFromCamera(
          event.image,
          face,
          event.cameraDescription,
        );

        // 3. Bandingkan dengan registered embedding
        final isMatch = _mlService.isMatch(
          currentEmbedding,
          _registeredEmbedding!,
        );

        if (isMatch) {
          if (isLivenessEnabled) {
            // HANYA valid jika sudah berkedip DAN mata sekarang terbuka
            if (_hasBlinked && (face.leftEyeOpenProbability ?? 0.0) > 0.5) {
              if (state is! FaceMatched) emit(FaceMatched(0.95));
            } else {
              // Wajah cocok tapi belum berkedip -> Tetap NotMatched
              debugPrint("Liveness: Face matched but waiting for blink...");
              if (state is! FaceNotMatched) emit(FaceNotMatched());
            }
          } else {
            // Jika liveness mati, langsung match tanpa syarat kedip
            if (state is! FaceMatched) emit(FaceMatched(0.95));
          }
        } else {
          if (state is! FaceNotMatched) emit(FaceNotMatched());
        }
      } else {
        if (state is! FaceNotMatched) emit(FaceNotMatched());
      }
    } catch (e) {
      debugPrint("Error processing face: $e");
    } finally {
      _isProcessing = false;
    }
  }

  @override
  Future<void> close() {
    _detectionService.dispose();
    return super.close();
  }
}
