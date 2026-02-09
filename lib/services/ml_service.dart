import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class MLService {
  Interpreter? _interpreter;
  double threshold =
      1.2; // Ambang batas dinaikkan lagi untuk mempermudah matching awal

  Future<void> initialize() async {
    try {
      final options = InterpreterOptions();
      // options.addDelegate(GpuDelegateV2()); // Uncomment jika ingin pakai GPU (Android)
      _interpreter = await Interpreter.fromAsset(
        'assets/mobilefacenet.tflite',
        options: options,
      );
    } catch (e) {
      print('Failed to load model: $e');
    }
  }

  /// Mendapatkan embedding dari CameraImage (Real-time)
  Future<List<double>> getEmbeddingFromCamera(
    CameraImage cameraImage,
    Face face,
    CameraDescription cameraDescription,
  ) async {
    // 1. Convert YUV420 to RGB Image
    img.Image image = _convertYUV420ToImage(cameraImage);

    // 2. Rotate image based on sensor orientation to match Face coordinates
    if (Platform.isAndroid) {
      image = img.copyRotate(image, angle: cameraDescription.sensorOrientation);
    }

    // 3. Preprocess (Crop & Resize)
    return _processImage(image, face);
  }

  /// Mendapatkan embedding dari File (Registered Image)
  Future<List<double>> getEmbeddingFromFile(File file, Face face) async {
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception("Gagal decode gambar file");

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
      width: 112,
      height: 112,
    );

    // Normalize & Prepare Input
    // MobileFaceNet biasanya butuh input [1, 112, 112, 3]
    // Nilai pixel dinormalisasi ke -1 s/d 1 atau 0 s/d 1 tergantung training modelnya.
    // Di sini kita pakai standard (pixel - 128) / 128
    List input = _imageToByteListFloat32(resizedImage, 112, 128, 128);
    input = input.reshape([1, 112, 112, 3]);

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

  /// Konversi CameraImage (YUV420) ke img.Image (RGB)
  img.Image _convertYUV420ToImage(CameraImage cameraImage) {
    final int width = cameraImage.width;
    final int height = cameraImage.height;
    final int uvRowStride = cameraImage.planes[1].bytesPerRow;
    final int uvPixelStride = cameraImage.planes[1].bytesPerPixel!;

    final img.Image image = img.Image(width: width, height: height);

    for (int w = 0; w < width; w++) {
      for (int h = 0; h < height; h++) {
        final int uvIndex =
            uvPixelStride * (w / 2).floor() + uvRowStride * (h / 2).floor();
        final int index = h * width + w;

        final y = cameraImage.planes[0].bytes[index];
        final u = cameraImage.planes[1].bytes[uvIndex];
        final v = cameraImage.planes[2].bytes[uvIndex];

        image.setPixelRgb(
          w,
          h,
          (y + 1.402 * (v - 128)).toInt().clamp(0, 255),
          (y - 0.344136 * (u - 128) - 0.714136 * (v - 128)).toInt().clamp(
            0,
            255,
          ),
          (y + 1.772 * (u - 128)).toInt().clamp(0, 255),
        );
      }
    }
    return image;
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
    print('Face Distance: $distance'); // Debugging: Cek nilai jarak di console
    return distance < threshold;
  }
}
