import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:panchayat_mitra/widgets/location_selector.dart';

class EditOsrScreen extends StatefulWidget {
  final String osrId;
  final String name;
  final String description;
  final List<dynamic>? imageUrls;
  final String block;
  final String panchayat;
  final String expectedRevenue;

  const EditOsrScreen({
    super.key,
    required this.osrId,
    required this.name,
    required this.description,
    this.imageUrls,
    required this.block,
    required this.panchayat,
    required this.expectedRevenue,
  });

  @override
  State<EditOsrScreen> createState() => _EditOsrScreenState();
}

class _EditOsrScreenState extends State<EditOsrScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _revenueController;
  List<XFile> _images = [];
  List<dynamic>? _imageUrls;
  bool _isLoading = false;
  String? _selectedBlock;
  String? _selectedPanchayat;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _descriptionController = TextEditingController(text: widget.description);
    _revenueController = TextEditingController(text: widget.expectedRevenue);
    _imageUrls = widget.imageUrls;
    _selectedBlock = widget.block;
    _selectedPanchayat = widget.panchayat;
  }

  Future<void> _pickImage() async {
    if ((_images.length + (_imageUrls?.length ?? 0)) >= 3) {
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
        } else if ((_images.length + (_imageUrls?.length ?? 0)) < 3) {
          setState(() {
            _images.add(image);
          });
        }
      }
    }
  }

  Future<void> _updateOsr() async {
    if (_nameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _revenueController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<String> downloadUrls = _imageUrls?.cast<String>() ?? [];
      if (_images.isNotEmpty) {
        for (var image in _images) {
          final storageRef = FirebaseStorage.instance.ref().child(
            'osr/${DateTime.now().toIso8601String()}_${image.name}',
          );
          if (kIsWeb) {
            final uploadTask = await storageRef.putData(
              await image.readAsBytes(),
            );
            final downloadUrl = await uploadTask.ref.getDownloadURL();
            downloadUrls.add(downloadUrl);
          } else {
            final uploadTask = await storageRef.putFile(File(image.path));
            final downloadUrl = await uploadTask.ref.getDownloadURL();
            downloadUrls.add(downloadUrl);
          }
        }
      }

      await FirebaseFirestore.instance
          .collection('osr')
          .doc(widget.osrId)
          .update({
            'name': _nameController.text,
            'description': _descriptionController.text,
            'imageUrls': downloadUrls,
            'block': _selectedBlock,
            'panchayat': _selectedPanchayat,
            'expectedRevenue': _revenueController.text,
          });

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update OSR data: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit OSR Data')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
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
              Text('Block: $_selectedBlock'),
              const SizedBox(height: 8),
              Text('Panchayat: $_selectedPanchayat'),
              const SizedBox(height: 16),
              _images.isEmpty && (_imageUrls == null || _imageUrls!.isEmpty)
                  ? const Text('No images selected.')
                  : Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                        if (_images.isNotEmpty)
                          ..._images.map((image) {
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
                          }),
                        if (_images.isEmpty && _imageUrls != null)
                          ..._imageUrls!.map((url) {
                            return Image.network(
                              url,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            );
                          }),
                      ],
                    ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Select Images'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateOsr,
                child: _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Text('Update Data'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
