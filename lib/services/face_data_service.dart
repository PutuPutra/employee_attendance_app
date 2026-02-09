import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';

class FaceDataService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

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

      // 3. Save to face_register collection
      await _firestore.collection('face_register').doc(user.uid).set({
        'employeeId': employeeId,
        'name': name ?? 'Unknown',
        'faceImagePath': fileName,
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
}
