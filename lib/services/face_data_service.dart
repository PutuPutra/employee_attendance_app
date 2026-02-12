import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FaceDataService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // KONFIGURASI IMAGEKIT
  // ⚠️ PENTING: Masukkan Private Key Anda di sini
  String get _imageKitPrivateKey => dotenv.env['IMAGEKIT_PRIVATE_KEY'] ?? '';
  final String _imageKitUrlEndpoint =
      'https://upload.imagekit.io/api/v1/files/upload';

  /// Saves the captured face image locally and updates the user's document in Firestore.
  ///
  /// Returns the local path of the saved image.
  Future<String> registerFace(XFile imageFile) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user logged in. Cannot register face.');
    }

    try {
      // 1. Save image to local storage with a random unique name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${user.uid}_face_register_$timestamp.jpg';
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/$fileName';
      await imageFile.saveTo(imagePath);

      // 2. Get the user's employeeId and name from Firestore
      String? employeeId;
      String? name;
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        employeeId = data['employeeId'];
        name = data['username'] ?? user.displayName;
      }

      if (employeeId == null) {
        throw Exception('Employee ID not found for the current user.');
      }

      // 3. Upload to ImageKit (Backup Cloud)
      String? faceImageUrl;
      try {
        faceImageUrl = await _uploadToImageKit(File(imagePath), fileName);
      } catch (e) {
        // Jika upload gagal, kita log errornya tapi tetap lanjut simpan data lokal
        print("Warning: Gagal upload ke ImageKit: $e");
      }

      // 4. Save to face_register collection
      await _firestore.collection('face_register').doc(user.uid).set({
        'employeeId': employeeId,
        'name': name ?? 'Unknown',
        'faceImagePath': fileName,
        'faceImageUrl': faceImageUrl, // Simpan URL ImageKit
        'registeredAt': FieldValue.serverTimestamp(),
      });

      return imagePath; // Return the local path on success
    } on FirebaseException catch (e) {
      // Re-throw with a more specific message
      throw Exception('Firebase error during face registration: ${e.message}');
    } catch (e) {
      // Re-throw any other exceptions
      rethrow;
    }
  }

  Future<String> _uploadToImageKit(File file, String fileName) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(_imageKitUrlEndpoint),
    );

    request.fields['fileName'] = fileName;
    request.fields['folder'] = '/attendance/'; // Sesuai request folder Anda
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
}
