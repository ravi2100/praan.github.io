import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:panchayat_mitra/widgets/location_selector.dart';

class UploadOsrScreen extends StatefulWidget {
  const UploadOsrScreen({super.key});

  @override
  State<UploadOsrScreen> createState() => _UploadOsrScreenState();
}

class _UploadOsrScreenState extends State<UploadOsrScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _revenueController = TextEditingController();
  List<XFile> _images = [];
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

  Future<void> _pickImage() async {
    if (_images.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only upload up to 3 images.')),
      );
      return;
    }
    final pickedImages = await ImagePicker().pickMultiImage();
    if (pickedImages.isNotEmpty) {
      for (var image in pickedImages) {
        final imageBytes = await image.readAsBytes();
        if (imageBytes.lengthInBytes > 1048576) {
          // 1MB
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${image.name} is larger than 1MB.')),
          );
        } else if (_images.length < 3) {
          setState(() {
            _images.add(image);
          });
        }
      }
    }
  }

  Future<void> _uploadOsr() async {
    if (_nameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _revenueController.text.isEmpty ||
        _images.isEmpty ||
        _selectedBlock == null ||
        _selectedPanchayat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill all fields, select a location, and select at least one image',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final List<String> downloadUrls = [];
      for (var image in _images) {
        final storageRef = FirebaseStorage.instance.ref().child(
          'osr/${DateTime.now().toIso8601String()}_${image.name}',
        );
        String downloadUrl;
        if (kIsWeb) {
          final uploadTask = await storageRef.putData(
            await image.readAsBytes(),
          );
          downloadUrl = await uploadTask.ref.getDownloadURL();
        } else {
          final uploadTask = await storageRef.putFile(File(image.path));
          downloadUrl = await uploadTask.ref.getDownloadURL();
        }
        downloadUrls.add(downloadUrl);
      }

      await FirebaseFirestore.instance.collection('osr').add({
        'name': _nameController.text,
        'description': _descriptionController.text,
        'expectedRevenue': _revenueController.text,
        'imageUrls': downloadUrls,
        'block': _selectedBlock,
        'panchayat': _selectedPanchayat,
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload OSR data: $e')));
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
          child: Text('Upload OSR Data'),
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
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
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _revenueController,
                decoration: const InputDecoration(
                  labelText: 'Expected Revenue in a Year (₹)',
                ),
                keyboardType: TextInputType.number,
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
              const SizedBox(height: 16),
              _images.isEmpty
                  ? const Text('No images selected.')
                  : Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _images.map((image) {
                        return kIsWeb
                            ? Image.network(
                                image.path,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(image.path),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              );
                      }).toList(),
                    ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Select Images'),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _uploadOsr,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 15,
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        )
                      : const Text('Upload Data'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
