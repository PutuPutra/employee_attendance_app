import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String? _employeeId;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _selectedRegion;
  String? _selectedLokasi;

  final List<String> _regionOptions = [
    'Cilegon',
    'Head Office',
    'Sanggau',
    'Sintang',
    'Palangkaraya',
  ];

  final List<String> _lokasiOptions = [
    'PT. ASL TIMUR',
    'PT. ACP',
    'PT. MSP TIMUR',
    'PT. MSP BARAT',
    'PT. APN',
    'PT. Arvena Sepakat',
    'PT. MJP 1',
    'PT. SJAL TAYAN',
    'PT. SJAL TAYAN POM',
    'PT. SJAL TOBA POM',
    'PT. SJAL MELIAU',
    'PT. SJAL BARAT',
    'PT. SJAL TIMUR',
    'PT. MJP 2',
    'PT. MJP 3',
    'PT. MJP POM',
    'PT. SURYA DELI 1',
    'PT. SURYA DELI 2',
    'PT. SML BARAT',
    'PT. SML TIMUR',
    'PT. SML POM',
    'PT. ASL BARAT',
    'PT. ASL POM',
    'PT. BSL',
    'PT. BTN',
    'PT. BTN POM',
    'PT. MAL',
    'PT. MSP SINTANG',
    'PT. SML SINTANG',
    'PT. SML TIMUR UNIT APD',
    'PT. SJAL TAYAN PROJECT',
  ];

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengguna tidak ditemukan. Silakan login kembali.'),
          ),
        );
      }
      return;
    }

    try {
      // For new users, start with their login email and an empty username.
      String username = '';
      String email =
          user.email ?? ''; // Directly get email from the logged-in user
      String? employeeId;
      String region = '';
      String lokasi = '';

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
        email = data['email'] ?? email; // Use Firestore email if available
        employeeId = data['employeeId'];
        region = data['region'] ?? '';
        lokasi = data['lokasi'] ?? '';
      }

      // Set the controller values.
      _usernameController.text = username;
      _emailController.text = email;
      if (_regionOptions.contains(region)) {
        _selectedRegion = region;
      }
      if (_lokasiOptions.contains(lokasi)) {
        _selectedLokasi = lokasi;
      }

      // Finally, generate an Employee ID if it doesn't exist yet.
      if (employeeId == null || employeeId.isEmpty) {
        final randomId = Random().nextInt(90000000) + 10000000;
        _employeeId = 'EMP-$randomId';
      } else {
        _employeeId = employeeId;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate() || _isSaving) {
      return;
    }

    setState(() => _isSaving = true);

    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi berakhir. Silakan login kembali.'),
          ),
        );
      }
      return;
    }

    try {
      final userData = {
        'username': _usernameController.text,
        'email': _emailController.text,
        'employeeId': _employeeId,
        'region': _selectedRegion,
        'lokasi': _selectedLokasi,
      };

      // Save data to Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));

      // Update FirebaseAuth display name
      if (user.displayName != _usernameController.text) {
        await user.updateDisplayName(_usernameController.text);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perubahan berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan perubahan: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personalisasi Akun'), elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('ID Karyawan'),
                    const SizedBox(height: 8),
                    _buildReadOnlyTextField(
                      _employeeId ?? 'Membuat ID...',
                      CupertinoIcons.number,
                    ),
                    const SizedBox(height: 24),

                    _buildSectionHeader('Data Akun'),
                    const SizedBox(height: 16),

                    _buildTextFormField(
                      controller: _usernameController,
                      label: 'Username',
                      icon: CupertinoIcons.person,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Username tidak boleh kosong'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    _buildTextFormField(
                      controller: _emailController,
                      label: 'Alamat Email',
                      icon: CupertinoIcons.at,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                          value == null || !value.contains('@')
                          ? 'Masukkan alamat email yang valid'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _selectedRegion,
                      decoration: InputDecoration(
                        labelText: 'Region / Wilayah',
                        prefixIcon: const Icon(
                          CupertinoIcons.location,
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                      ),
                      items: _regionOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) =>
                          setState(() => _selectedRegion = newValue),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Region tidak boleh kosong'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _selectedLokasi,
                      decoration: InputDecoration(
                        labelText: 'Lokasi / PT',
                        prefixIcon: const Icon(
                          CupertinoIcons.building_2_fill,
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                      ),
                      items: _lokasiOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) =>
                          setState(() => _selectedLokasi = newValue),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Lokasi tidak boleh kosong'
                          : null,
                    ),
                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const CupertinoActivityIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Simpan Perubahan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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
