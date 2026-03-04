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
      File? processedFile;

      try {
        // Konversi ke JPG & perbaiki orientasi sebelum upload agar preview muncul
        processedFile = await _convertToJpg(file);

        // Sanitasi nama agar aman untuk nama folder (Hanya Alphanumeric & Underscore)
        final String safeName = (name ?? 'Unknown')
            .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
            .replaceAll(RegExp(r'_+'), '_');
        final String folderPath = 'face_register/${employeeId}_$safeName';

        faceImageUrl = await _uploadToLaravel(
          processedFile!,
          fileName,
          folderPath,
          employeeId,
          name ?? 'Unknown',
        );
      } catch (e) {
        debugPrint("Warning: Gagal upload ke Laravel: $e");
        // PENTING: Throw error agar proses berhenti dan TIDAK lanjut simpan ke Firestore
        // Gunakan pesan error asli agar user tahu jika itu 404 atau Timeout
        throw Exception(
          "Gagal upload: ${e.toString().replaceAll('Exception: ', '')}",
        );
      } finally {
        // Hapus file temporary
        if (processedFile != null && await processedFile.exists()) {
          await processedFile.delete();
        }
      }

      // 5. Save Embedding & URL to Firestore
      await _firestore.collection('face_register').doc(user.uid).set({
        StorageKeys.employeeId: employeeId,
        'name': name ?? 'Unknown',
        'faceImageUrl': faceImageUrl, // Simpan URL gambar yang diupload
        'embedding': embedding, // SIMPAN EMBEDDING
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

    // VALIDASI IP
    if (uri.host == '0.0.0.0' ||
        uri.host == '127.0.0.1' ||
        uri.host == 'localhost') {
      throw Exception(
        "Konfigurasi Salah: Jangan gunakan '${uri.host}' di .env Flutter. Gunakan IP Laptop (contoh: 192.168.1.x)",
      );
    }

    debugPrint("🚀 Memulai upload ke: $uri");

    final request = http.MultipartRequest('POST', uri);

    request.headers['Accept'] = 'application/json';

    // --- SECURITY FIX: Authentication Headers ---
    // 1. User Auth: Mengirim Firebase ID Token (JWT)
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        debugPrint("🔐 Token Firebase didapatkan (Length: ${token?.length})");
        request.headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      debugPrint("⚠️ Gagal mengambil token auth: $e");
    }

    // 2. App Auth: Mengirim API Key (dari .env)
    final apiKey = dotenv.env['API_KEY'];
    if (apiKey != null && apiKey.isNotEmpty) {
      request.headers['X-API-KEY'] = apiKey;
    }

    // Kirim data tambahan
    request.fields['employee_id'] = employeeId;
    request.fields['first_name'] = name;
    request.fields['folder_path'] = folderPath;

    request.files.add(
      await http.MultipartFile.fromPath('image', file.path, filename: fileName),
    );

    http.StreamedResponse response;
    try {
      response = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception(
            'Connection Timeout (60s). Server tidak merespon. Pastikan "php artisan serve --host=0.0.0.0" berjalan & Cek Firewall.',
          );
        },
      );
    } on SocketException catch (e) {
      throw Exception(
        'Gagal Terhubung: $e. Pastikan Server jalan (host=0.0.0.0) & IP benar.',
      );
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      final respStr = await response.stream.bytesToString();
      final json = jsonDecode(respStr);
      return json['url'];
    } else {
      final errorBody = await response.stream.bytesToString();
      if (response.statusCode == 404) {
        // Cek apakah respon berupa HTML (Tanda salah port Ngrok)
        if (errorBody.contains('<!DOCTYPE HTML') ||
            errorBody.contains('<html')) {
          throw Exception(
            'Salah Port Ngrok (404).\n'
            'Server merespon dengan HTML Apache, bukan Laravel.\n'
            'PENYEBAB: Ngrok jalan di port 80, tapi Laravel di port 8000.\n'
            'SOLUSI: Stop ngrok, lalu jalankan: "ngrok http 8000"',
          );
        }
        throw Exception(
          'Laravel Route Not Found (404). Pastikan URL di .env berakhiran /api/face-register/upload. Body: $errorBody',
        );
      }
      if (response.statusCode == 500) {
        throw Exception(
          'Server Error (500). Cek logs Laravel (storage/logs/laravel.log). Kemungkinan: Permission folder atau File terlalu besar. Body: $errorBody',
        );
      }
      throw Exception(
        'Laravel Upload Failed: ${response.statusCode}, Body: $errorBody',
      );
    }
  }

  Future<File> _convertToJpg(File originalFile) async {
    final bytes = await originalFile.readAsBytes();

    // Gunakan compute agar UI tidak freeze
    final jpgBytes = await compute(_processImageInIsolate, bytes);

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

// Fungsi Top-Level untuk Isolate
Uint8List _processImageInIsolate(Uint8List bytes) {
  final image = img.decodeImage(bytes);
  if (image == null) throw Exception("Gagal decode gambar");
  final fixedImage = img.bakeOrientation(image);

  // Resize jika terlalu besar (max width 1024) untuk mencegah error upload size & hemat kuota
  img.Image finalImage = fixedImage;
  if (fixedImage.width > 1024) {
    finalImage = img.copyResize(fixedImage, width: 1024);
  }

  return Uint8List.fromList(img.encodeJpg(finalImage, quality: 85));
}
