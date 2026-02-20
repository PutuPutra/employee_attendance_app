import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../core/constants/storage_keys.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();
  final _companyController = TextEditingController();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String? _employeeId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.userNotFoundLoginAgain)));
      }
      return;
    }

    try {
      // For new users, start with their login email and an empty username.
      String username = '';
      String email =
          user.email ?? ''; // Directly get email from the logged-in user
      String? employeeId;
      String locationName = '';
      String companyName = '';

      // Then, try to load more specific data from Firestore.
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        // If a document exists, overwrite the defaults with data from Firestore.
        final data = userDoc.data() as Map<String, dynamic>;
        username =
            data['username'] ??
            user.displayName ??
            ''; // Use Firestore username if available
        // email = data['email'] ?? email; // Gunakan email dari Auth saja sebagai source of truth
        email = data['email'] ?? email; // Use Firestore email if available
        employeeId = data[StorageKeys.employeeId];

        final locationId = data['location_id'];
        if (locationId != null && locationId.toString().isNotEmpty) {
          final locDoc = await _firestore
              .collection('locations')
              .doc(locationId.toString())
              .get();
          if (locDoc.exists) {
            final locData = locDoc.data() as Map<String, dynamic>?;
            locationName =
                locData?['location_name']?.toString() ??
                'Location name not available';
          } else {
            locationName = 'Location document not found';
          }
        } else {
          locationName = 'No location ID available';
        }

        final companyId = data['company_id'];
        if (companyId != null && companyId.toString().isNotEmpty) {
          final compDoc = await _firestore
              .collection('companies')
              .doc(companyId.toString())
              .get();
          if (compDoc.exists) {
            final compData = compDoc.data() as Map<String, dynamic>?;
            companyName =
                compData?['company_name']?.toString() ??
                'Company name not available';
          } else {
            companyName = 'Company document not found';
          }
        } else {
          companyName = 'No company ID available';
        }
      }

      // Set the controller values.
      _usernameController.text = username;
      _emailController.text = email;
      _locationController.text = locationName;
      _companyController.text = companyName;

      // Finally, generate an Employee ID if it doesn't exist yet.
      if (employeeId == null || employeeId.isEmpty) {
        final randomId = Random().nextInt(90000000) + 10000000;
        _employeeId = 'EMP-$randomId';
      } else {
        _employeeId = employeeId;
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${l10n.failedToLoad}: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountPersonalization), elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(l10n.employeeIdLabel),
                    const SizedBox(height: 8),
                    _buildReadOnlyTextField(
                      _employeeId ?? l10n.notAvailable,
                      CupertinoIcons.number,
                    ),
                    const SizedBox(height: 24),

                    _buildSectionHeader(l10n.accountData),
                    const SizedBox(height: 16),

                    _buildTextFormField(
                      controller: _usernameController,
                      label: l10n.username,
                      icon: CupertinoIcons.person,
                      enabled: false,
                    ),
                    const SizedBox(height: 16),

                    _buildTextFormField(
                      controller: _emailController,
                      label: l10n.emailAddress,
                      icon: CupertinoIcons.at,
                      enabled: false,
                    ),
                    const SizedBox(height: 16),

                    _buildTextFormField(
                      controller: _locationController,
                      label: l10n.locationLabel,
                      icon: CupertinoIcons.location,
                      enabled: false,
                    ),
                    const SizedBox(height: 16),

                    _buildTextFormField(
                      controller: _companyController,
                      label: 'Company',
                      icon: CupertinoIcons.building_2_fill,
                      enabled: false,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildReadOnlyTextField(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).disabledColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).disabledColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 16),
          Text(text, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      enabled: enabled,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
    );
  }
}
