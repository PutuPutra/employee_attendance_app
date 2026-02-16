import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class MLService {
  Interpreter? _interpreter;
  // Threshold (Ambang Batas): Semakin KECIL semakin KETAT/AMAN.
  // 1.0 adalah standar yang seimbang. 1.2 agak longgar.
  double threshold = 1.0;
  static const int inputSize = 112;

  Future<void> initialize() async {
    try {
      final options = InterpreterOptions();
      // options.addDelegate(GpuDelegateV2()); // Uncomment jika ingin pakai GPU (Android)
      _interpreter = await Interpreter.fromAsset(
        'assets/mobilefacenet.tflite',
        options: options,
      );
    } catch (e) {
      debugPrint('Failed to load model: $e');
    }
  }

  /// Mendapatkan embedding dari CameraImage (Real-time)
  Future<List<double>> getEmbeddingFromCamera(
    CameraImage cameraImage,
    Face face,
    CameraDescription cameraDescription,
  ) async {
    // Siapkan data untuk dikirim ke Isolate (Background Thread)
    // Kita kirim bytes raw karena CameraImage tidak bisa dikirim langsung antar thread
    final isolateData = IsolateData(
      width: cameraImage.width,
      height: cameraImage.height,
      yPlane: cameraImage.planes[0].bytes,
      uPlane: cameraImage.planes[1].bytes,
      vPlane: cameraImage.planes[2].bytes,
      yRowStride: cameraImage.planes[0].bytesPerRow,
      uvRowStride: cameraImage.planes[1].bytesPerRow,
      uvPixelStride: cameraImage.planes[1].bytesPerPixel!,
      rotation: cameraDescription.sensorOrientation,
      // Kirim koordinat wajah sebagai List sederhana
      faceBounds: [
        face.boundingBox.left,
        face.boundingBox.top,
        face.boundingBox.width,
        face.boundingBox.height,
      ],
      isAndroid: Platform.isAndroid,
    );

    // Jalankan pemrosesan berat di background thread
    // Hasilnya adalah List input yang sudah siap untuk TFLite
    final List input = await compute(_processCameraImageInIsolate, isolateData);

    // Output array (biasanya 192 atau 128 dimensi)
    List output = List.generate(1, (index) => List.filled(192, 0.0));

    // Run Inference (Ringan, bisa di main thread)
    _interpreter!.run(input, output);

    return List<double>.from(output[0]);
  }

  /// Mendapatkan embedding dari File (Registered Image)
  Future<List<double>> getEmbeddingFromFile(File file, Face face) async {
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception("failed_to_decode_image");

    // FIX: Perbaiki orientasi gambar berdasarkan EXIF agar cropping wajah akurat
    final fixedImage = img.bakeOrientation(image);

    return _processImage(fixedImage, face);
  }

  List<double> _processImage(img.Image image, Face face) {
    // Crop wajah berdasarkan bounding box
    double x = face.boundingBox.left - 10.0;
    double y = face.boundingBox.top - 10.0;
    double w = face.boundingBox.width + 20.0;
    double h = face.boundingBox.height + 20.0;

    // Pastikan crop tidak keluar batas
    if (x < 0) x = 0;
    if (y < 0) y = 0;
    if (x + w > image.width) w = image.width - x;
    if (y + h > image.height) h = image.height - y;

    img.Image croppedImage = img.copyCrop(
      image,
      x: x.toInt(),
      y: y.toInt(),
      width: w.toInt(),
      height: h.toInt(),
    );

    // Resize ke 112x112 (Input standar MobileFaceNet)
    img.Image resizedImage = img.copyResize(
      croppedImage,
      width: inputSize,
      height: inputSize,
    );

    // Normalize & Prepare Input
    // MobileFaceNet biasanya butuh input [1, 112, 112, 3]
    // Nilai pixel dinormalisasi ke -1 s/d 1 atau 0 s/d 1 tergantung training modelnya.
    // Di sini kita pakai standard (pixel - 128) / 128
    List input = _imageToByteListFloat32(resizedImage, inputSize, 128, 128);
    input = input.reshape([1, inputSize, inputSize, 3]);

    // Output array (biasanya 192 atau 128 dimensi)
    List output = List.generate(1, (index) => List.filled(192, 0.0));

    // Run Inference
    _interpreter!.run(input, output);

    return List<double>.from(output[0]);
  }

  List<double> _imageToByteListFloat32(
    img.Image image,
    int inputSize,
    double mean,
    double std,
  ) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (pixel.r - mean) / std;
        buffer[pixelIndex++] = (pixel.g - mean) / std;
        buffer[pixelIndex++] = (pixel.b - mean) / std;
      }
    }
    return convertedBytes.toList();
  }

  /// Menghitung Euclidean Distance
  double euclideanDistance(List<double> e1, List<double> e2) {
    double sum = 0.0;
    for (int i = 0; i < e1.length; i++) {
      sum += pow((e1[i] - e2[i]), 2);
    }
    return sqrt(sum);
  }

  bool isMatch(List<double> e1, List<double> e2) {
    double distance = euclideanDistance(e1, e2);
    bool isMatched = distance < threshold;
    // Log yang lebih jelas untuk memantau akurasi secara realtime
    debugPrint(
      '🔍 Jarak Wajah: ${distance.toStringAsFixed(4)} -> ${isMatched ? "✅ COCOK" : "❌ TIDAK COCOK"}',
    );
    return isMatched;
  }
}

// --- ISOLATE LOGIC (Berjalan di background thread) ---

class IsolateData {
  final int width;
  final int height;
  final Uint8List yPlane;
  final Uint8List uPlane;
  final Uint8List vPlane;
  final int yRowStride;
  final int uvRowStride;
  final int uvPixelStride;
  final int rotation;
  final List<double> faceBounds; // [left, top, width, height]
  final bool isAndroid;

  IsolateData({
    required this.width,
    required this.height,
    required this.yPlane,
    required this.uPlane,
    required this.vPlane,
    required this.yRowStride,
    required this.uvRowStride,
    required this.uvPixelStride,
    required this.rotation,
    required this.faceBounds,
    required this.isAndroid,
  });
}

// Fungsi Top-Level untuk dijalankan oleh compute()
List _processCameraImageInIsolate(IsolateData data) {
  // 1. Convert YUV420 to RGB (Berat!)
  img.Image image = _convertYUV420ToImageInIsolate(data);

  // 2. Rotate (Berat!)
  if (data.isAndroid) {
    image = img.copyRotate(image, angle: data.rotation);
  }

  // 3. Crop Face
  double x = data.faceBounds[0] - 10.0;
  double y = data.faceBounds[1] - 10.0;
  double w = data.faceBounds[2] + 20.0;
  double h = data.faceBounds[3] + 20.0;

  if (x < 0) x = 0;
  if (y < 0) y = 0;
  if (x + w > image.width) w = image.width - x;
  if (y + h > image.height) h = image.height - y;

  img.Image croppedImage = img.copyCrop(
    image,
    x: x.toInt(),
    y: y.toInt(),
    width: w.toInt(),
    height: h.toInt(),
  );

  // 4. Resize (Berat!)
  img.Image resizedImage = img.copyResize(
    croppedImage,
    width: 112,
    height: 112,
  );

  // 5. Normalize
  var convertedBytes = Float32List(1 * 112 * 112 * 3);
  var buffer = Float32List.view(convertedBytes.buffer);
  int pixelIndex = 0;
  for (var i = 0; i < 112; i++) {
    for (var j = 0; j < 112; j++) {
      var pixel = resizedImage.getPixel(j, i);
      buffer[pixelIndex++] = (pixel.r - 128) / 128;
      buffer[pixelIndex++] = (pixel.g - 128) / 128;
      buffer[pixelIndex++] = (pixel.b - 128) / 128;
    }
  }

  // Reshape input untuk TFLite [1, 112, 112, 3]
  return convertedBytes.reshape([1, 112, 112, 3]);
}

img.Image _convertYUV420ToImageInIsolate(IsolateData data) {
  final int width = data.width;
  final int height = data.height;
  final int uvRowStride = data.uvRowStride;
  final int uvPixelStride = data.uvPixelStride;

  final img.Image image = img.Image(width: width, height: height);

  for (int w = 0; w < width; w++) {
    for (int h = 0; h < height; h++) {
      final int uvIndex =
          uvPixelStride * (w / 2).floor() + uvRowStride * (h / 2).floor();
      final int index = h * width + w;

      final y = data.yPlane[index];
      final u = data.uPlane[uvIndex];
      final v = data.vPlane[uvIndex];

      image.setPixelRgb(
        w,
        h,
        (y + 1.402 * (v - 128)).toInt().clamp(0, 255),
        (y - 0.344136 * (u - 128) - 0.714136 * (v - 128)).toInt().clamp(0, 255),
        (y + 1.772 * (u - 128)).toInt().clamp(0, 255),
      );
    }
  }
  return image;
}
