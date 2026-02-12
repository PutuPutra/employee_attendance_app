import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../l10n/app_localizations.dart';

class SavedFaceScreen extends StatefulWidget {
  const SavedFaceScreen({super.key});

  @override
  State<SavedFaceScreen> createState() => _SavedFaceScreenState();
}

class _SavedFaceScreenState extends State<SavedFaceScreen> {
  Future<File?>? _faceImageFuture;

  String? _employeeName;
  String? _employeeId;
  bool _isUserDataLoading = true;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    if (_auth.currentUser != null) {
      _loadImage();
      _loadUserData();
    }
  }

  void _loadImage() {
    setState(() {
      _faceImageFuture = _getSavedImage();
    });
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isUserDataLoading = false);
      return;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists && mounted) {
        final data = userDoc.data() as Map<String, dynamic>;
        final l10n = AppLocalizations.of(context);
        setState(() {
          _employeeName = data['username'] ?? l10n.nameNotAvailable;
          _employeeId = data['employeeId'] ?? l10n.idNotAvailable;
          _isUserDataLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() {
          _employeeName = l10n.failedToLoad;
          _employeeId = l10n.failedToLoad;
          _isUserDataLoading = false;
        });
      }
    }
  }

  Future<File?> _getSavedImage() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore
          .collection('face_register')
          .doc(user.uid)
          .get();
      if (!doc.exists) return null;

      final data = doc.data();
      final faceImageUrl = data?['faceImageUrl'] as String?;
      // Gunakan nama file dari Firestore atau default jika null (Cloud First Strategy)
      final fileName =
          data?['faceImagePath'] as String? ?? '${user.uid}_face.jpg';

      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/$fileName';
      final file = File(path);

      if (await file.exists()) {
        return file;
      } else if (faceImageUrl != null) {
        // Restore: Download image from ImageKit if local file is missing
        try {
          final request = await HttpClient().getUrl(Uri.parse(faceImageUrl));
          final response = await request.close();
          if (response.statusCode == 200) {
            final bytes = await consolidateHttpClientResponseBytes(response);
            await file.writeAsBytes(bytes);
            return file;
          }
        } catch (e) {
          debugPrint('Error restoring face image: $e');
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error getting saved image: $e');
      return null;
    }
  }

  Future<void> _deleteFaceData() async {
    final l10n = AppLocalizations.of(context);
    final user = _auth.currentUser;
    if (user == null) {
      // ... (user not logged in handling)
      return;
    }

    try {
      // 1. Delete the local image file
      final doc = await _firestore
          .collection('face_register')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data();
        final fileName =
            data?['faceImagePath'] as String? ?? '${user.uid}_face.jpg';

        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/$fileName';
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // 2. Delete the document from face_register collection
      await _firestore.collection('face_register').doc(user.uid).delete();

      // 3. Refresh UI and show success message
      _loadImage(); // This will now correctly find no image

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.faceDataDeleted),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.failedToDelete}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.deleteFaceData),
        content: Text(l10n.deleteFaceDataConfirm),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text(l10n.delete),
            onPressed: () {
              Navigator.of(context).pop();
              _deleteFaceData();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_auth.currentUser == null) {
      return Center(child: Text(l10n.pleaseLoginToViewFaceData));
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.faceProfile), elevation: 0),
      body: FutureBuilder<File?>(
        future: _faceImageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return _buildNoDataView();
          }
          return _buildProfileCard(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildNoDataView() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.person_badge_minus,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            l10n.noFaceData,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.faceNotRegistered,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(File imageFile) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(radius: 80, backgroundImage: FileImage(imageFile)),
              const SizedBox(height: 24),
              _isUserDataLoading
                  ? const CupertinoActivityIndicator()
                  : Text(
                      _employeeName ?? l10n.loading,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              const SizedBox(height: 8),
              _isUserDataLoading
                  ? const SizedBox.shrink()
                  : Text(
                      _employeeId ?? l10n.loading,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(CupertinoIcons.trash, color: Colors.white),
                  label: Text(
                    l10n.deleteFaceData,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onPressed: _showDeleteConfirmation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
