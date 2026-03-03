import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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

  // KONFIGURASI LARAVEL STORAGE
  String get _laravelUploadEndpoint {
    return dotenv.env['LARAVEL_FACE_REGISTER_UPLOAD_ENDPOINT'] ?? '';
  }

  /// Registers face: Generates embedding, uploads to laravel, saves to Firestore.
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

      // 4. Upload to Laravel
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${user.uid}_face_register_$timestamp.jpg';
      String? faceImageUrl;

      try {
        // Konversi ke JPG & perbaiki orientasi sebelum upload agar preview muncul
        final processedFile = await _convertToJpg(file);

        final String safeName = (name ?? 'Unknown').replaceAll(
          RegExp(r'\s+'),
          '_',
        );
        final String folderPath = 'face_register/${employeeId}_$safeName';

        faceImageUrl = await _uploadToLaravel(
          processedFile,
          fileName,
          folderPath,
          employeeId,
          name ?? 'Unknown',
        );

        // Hapus file temporary
        if (await processedFile.exists()) {
          await processedFile.delete();
        }
      } catch (e) {
        debugPrint("Warning: Gagal upload ke Laravel: $e");
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

  Future<String> _uploadToLaravel(
    File file,
    String fileName,
    String folderPath,
    String employeeId,
    String name,
  ) async {
    final uri = Uri.parse(_laravelUploadEndpoint);
    final request = http.MultipartRequest('POST', uri);

    request.headers['Accept'] = 'application/json';

    // Kirim data tambahan
    request.fields['employee_id'] = employeeId;
    request.fields['first_name'] = name;
    request.fields['folder_path'] = folderPath;

    request.files.add(
      await http.MultipartFile.fromPath('image', file.path, filename: fileName),
    );

    final response = await request.send().timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw Exception(
          'Connection Timeout. Cek IP Address Server: $_laravelUploadEndpoint',
        );
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final respStr = await response.stream.bytesToString();
      final json = jsonDecode(respStr);
      return json['url'];
    } else {
      final errorBody = await response.stream.bytesToString();
      throw Exception(
        'Laravel Upload Failed: ${response.statusCode}, Body: $errorBody',
      );
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
