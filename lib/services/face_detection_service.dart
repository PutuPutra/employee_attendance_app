import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionService {
  late final FaceDetector _faceDetector;

  void initialize() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableContours: false,
        enableClassification: true, // Aktifkan ini untuk deteksi kedipan mata
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
      debugPrint("ML Kit Found: ${faces.length} faces"); // DEBUG LOG
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
    final rotation = _getInputImageRotation(cameraDescription);

    final format = InputImageFormatValue.fromRawValue(image.format.raw);

    // Validasi format diperlonggar untuk Android karena kita melakukan konversi manual.
    // InputImageFormat.yuv_420_888 terkadang bermasalah saat validasi enum equality.
    if (Platform.isIOS && format != InputImageFormat.bgra8888) {
      debugPrint('Image format not supported on this platform: $format');
      return null;
    }

    Uint8List bytes;
    if (Platform.isAndroid && image.planes.length > 1) {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      bytes = allBytes.done().buffer.asUint8List();
    } else {
      bytes = image.planes[0].bytes;
    }

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation:
            rotation ??
            InputImageRotation
                .rotation270deg, // Default ke 270 untuk kamera depan Android
        format: Platform.isAndroid
            ? InputImageFormat.nv21
            : (format ?? InputImageFormat.yuv420),
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  InputImageRotation? _getInputImageRotation(
    CameraDescription cameraDescription,
  ) {
    final sensorOrientation = cameraDescription.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isAndroid) {
      var rotationCompensation =
          0; // orientations[controller!.value.deviceOrientation];
      if (cameraDescription.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    return rotation ?? InputImageRotationValue.fromRawValue(sensorOrientation);
  }

  void dispose() {
    _faceDetector.close();
  }
}
