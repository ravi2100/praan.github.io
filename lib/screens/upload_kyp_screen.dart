import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:panchayat_mitra/widgets/location_selector.dart';

class UploadKypScreen extends StatefulWidget {
  const UploadKypScreen({super.key});

  @override
  State<UploadKypScreen> createState() => _UploadKypScreenState();
}

class _UploadKypScreenState extends State<UploadKypScreen> {
  final _nameController = TextEditingController();
  final _designationController = TextEditingController();
  final _mobileController = TextEditingController();
  bool _isLoading = false;
  String? _selectedBlock;
  String? _selectedPanchayat;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        _userData = userDoc.data();
        _selectedBlock = _userData?['block'];
        _selectedPanchayat = _userData?['panchayat'];
      });
    }
  }

  Future<void> _uploadKyp() async {
    if (_nameController.text.isEmpty ||
        _designationController.text.isEmpty ||
        _mobileController.text.isEmpty ||
        _selectedBlock == null ||
        _selectedPanchayat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and select a location'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('kyp').add({
        'name': _nameController.text,
        'designation': _designationController.text,
        'mobile': _mobileController.text,
        'block': _selectedBlock,
        'panchayat': _selectedPanchayat,
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload contact: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Padding(
          padding: EdgeInsets.only(top: 20.0),
          child: Text('Upload Contact'),
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _designationController,
              decoration: const InputDecoration(labelText: 'Designation'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _mobileController,
              decoration: const InputDecoration(labelText: 'Mobile'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            if (_userData != null)
              LocationSelector(
                initialBlock: _userData!['block'],
                initialPanchayat: _userData!['panchayat'],
                onLocationChanged: (block, panchayat) {
                  setState(() {
                    _selectedBlock = block;
                    _selectedPanchayat = panchayat;
                  });
                },
                isEnabled: false,
              ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _uploadKyp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 15,
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Text('Upload'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
