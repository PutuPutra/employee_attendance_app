import 'dart:io';
import 'dart:ui'; // <--- IMPORT YANG HILANG

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionService {
  late final FaceDetector _faceDetector;

  void initialize() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableContours: true,
        enableClassification: true,
      ),
    );
  }

  Future<Face?> processImage(
    CameraImage image,
    CameraDescription cameraDescription,
  ) async {
    final inputImage = _inputImageFromCameraImage(image, cameraDescription);
    if (inputImage == null) return null;

    try {
      final faces = await _faceDetector.processImage(inputImage);
      if (faces.isNotEmpty) {
        return faces.first;
      }
    } catch (e) {
      debugPrint("Error processing image with ML Kit: $e");
    }
    return null;
  }

  InputImage? _inputImageFromCameraImage(
    CameraImage image,
    CameraDescription cameraDescription,
  ) {
    final rotation = InputImageRotationValue.fromRawValue(
      cameraDescription.sensorOrientation,
    );
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      debugPrint('Image format not supported on this platform.');
      return null;
    }

    // ## INI BAGIAN YANG DIPERBAIKI SECARA TOTAL ##
    return InputImage.fromBytes(
      bytes: image.planes[0].bytes,
      metadata: InputImageMetadata(
        size: Size(
          image.width.toDouble(),
          image.height.toDouble(),
        ), // 'Size' sekarang terdefinisi
        rotation: rotation,
        format: format,
        // Menggunakan parameter 'bytesPerRow' yang benar dan menghapus 'planes'
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  void dispose() {
    _faceDetector.close();
  }
}
