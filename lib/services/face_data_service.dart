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
      // 1. Save image to local storage with a unique name
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/${user.uid}_face_register.jpg';
      await imageFile.saveTo(imagePath);

      // 2. Get the user's employeeId from Firestore
      String? employeeId;
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        employeeId = (userDoc.data() as Map<String, dynamic>)['employeeId'];
      }

      if (employeeId == null) {
        throw Exception('Employee ID not found for the current user.');
      }

      // 3. Update the user document in Firestore with the image file name
      await _firestore.collection('users').doc(user.uid).update({
        'faceImagePath': '${user.uid}_face_register.jpg', // Save the file name
        // The employeeId is already there, but this ensures the document is consistent
        'employeeId': employeeId,
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
