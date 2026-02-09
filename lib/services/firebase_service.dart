import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ## METODE INI TELAH DIPERBAIKI ##
  Future<String> uploadImage(File image, String userId) async {
    final storageRef = _storage.ref().child('user_faces').child('$userId.jpg');

    // 1. Dapatkan objek UploadTask dari putFile.
    final UploadTask uploadTask = storageRef.putFile(image);

    // 2. Tunggu hingga tugas unggah selesai sepenuhnya.
    final TaskSnapshot snapshot = await uploadTask;

    // 3. Setelah selesai, baru dapatkan URL unduhan dari referensi snapshot.
    // Ini adalah cara yang paling aman dan dijamin berhasil setelah unggah selesai.
    final String downloadUrl = await snapshot.ref.getDownloadURL();

    return downloadUrl;
  }

  Future<void> saveFaceData({
    required String userId,
    required String imageUrl,
    required Timestamp timestamp,
  }) async {
    await _firestore.collection('face_data').add({
      'userId': userId,
      'imageUrl': imageUrl,
      'timestamp': timestamp,
    });
  }
}
