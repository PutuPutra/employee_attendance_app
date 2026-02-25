import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:gunas_employee_attendance/services/ml_service.dart';
import '../core/constants/storage_keys.dart';
import 'package:image/image.dart' as img;

class FaceDataService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // KONFIGURASI IMAGEKIT
  // ⚠️ PENTING: Masukkan Private Key Anda di sini
  String get _imageKitPrivateKey => dotenv.env['IMAGEKIT_PRIVATE_KEY'] ?? '';
  final String _imageKitUrlEndpoint =
      'https://upload.imagekit.io/api/v1/files/upload';

  /// Registers face: Generates embedding, uploads to ImageKit, saves to Firestore.
  /// Returns the ImageKit URL.
  Future<String?> registerFace(XFile imageFile) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user logged in. Cannot register face.');
    }

    final MLService mlService = MLService();
    final FaceDetector faceDetector = FaceDetector(
      options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
    );

    try {
      // 1. Initialize ML Service
      await mlService.initialize();

      // 2. Detect Face & Generate Embedding
      final File file = File(imageFile.path);
      final inputImage = InputImage.fromFilePath(file.path);
      final faces = await faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        throw Exception('No face detected in the image.');
      }

      // Generate embedding (List<double>)
      final List<double> embedding = await mlService.getEmbeddingFromFile(
        file,
        faces.first,
      );

      // 3. Get the user's employeeId and name from Firestore
      String? employeeId;
      String? name;
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        employeeId = data[StorageKeys.employeeId];
        name = data['username'] ?? user.displayName;
      }

      if (employeeId == null) {
        throw Exception('Employee ID not found for the current user.');
      }

      // 4. Upload to ImageKit
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${user.uid}_face_register_$timestamp.jpg';
      String? faceImageUrl;

      try {
        if (_imageKitPrivateKey.isEmpty) {
          print("Warning: IMAGEKIT_PRIVATE_KEY tidak ditemukan di .env");
        } else {
          // Konversi ke JPG & perbaiki orientasi sebelum upload agar preview muncul
          final processedFile = await _convertToJpg(file);
          faceImageUrl = await _uploadToImageKit(processedFile, fileName);
        }
      } catch (e) {
        print("Warning: Gagal upload ke ImageKit: $e");
        // Opsional: Throw error jika ImageKit wajib
        // throw Exception("Failed to upload image to cloud.");
      }

      // 5. Save Embedding & URL to Firestore
      await _firestore.collection('face_register').doc(user.uid).set({
        StorageKeys.employeeId: employeeId,
        'name': name ?? 'Unknown',
        'faceImageUrl': faceImageUrl, // Simpan URL ImageKit
        'embedding': embedding, // SIMPAN EMBEDDING DI SINI
        'registeredAt': FieldValue.serverTimestamp(),
      });

      return faceImageUrl;
    } on FirebaseException catch (e) {
      // Re-throw with a more specific message
      throw Exception('Firebase error during face registration: ${e.message}');
    } catch (e) {
      // Re-throw any other exceptions
      rethrow;
    } finally {
      faceDetector.close();
      // mlService dispose handled internally or let GC handle it
    }
  }

  Future<String> _uploadToImageKit(File file, String fileName) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(_imageKitUrlEndpoint),
    );

    request.fields['fileName'] = fileName;
    request.fields['folder'] = '/face_registration/';
    request.fields['useUniqueFileName'] = 'false';

    // Basic Auth menggunakan Private Key
    final auth = 'Basic ' + base64Encode(utf8.encode('$_imageKitPrivateKey:'));
    request.headers['Authorization'] = auth;

    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();

    if (response.statusCode == 200 || response.statusCode == 201) {
      final respStr = await response.stream.bytesToString();
      final json = jsonDecode(respStr);
      return json['url']; // URL gambar dari ImageKit
    } else {
      throw Exception('ImageKit Upload Failed: ${response.statusCode}');
    }
  }

  Future<File> _convertToJpg(File originalFile) async {
    final bytes = await originalFile.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception("Gagal membaca gambar untuk konversi");
    }

    // Fix orientation (EXIF) - Penting agar gambar tidak miring di web/preview
    final fixedImage = img.bakeOrientation(image);

    // Encode to JPG dengan kualitas 85
    final jpgBytes = img.encodeJpg(fixedImage, quality: 85);

    // Buat file temporary baru untuk memastikan tidak ada konflik path
    // dan nama file memiliki ekstensi .jpg yang valid.
    final tempDir = await getTemporaryDirectory();
    final newPath =
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_processed.jpg';

    final newFile = File(newPath);
    await newFile.writeAsBytes(jpgBytes);

    return newFile;
  }
}
