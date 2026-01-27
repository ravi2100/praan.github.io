import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UploadSchemeScreen extends StatefulWidget {
  const UploadSchemeScreen({super.key});

  @override
  State<UploadSchemeScreen> createState() => _UploadSchemeScreenState();
}

class _UploadSchemeScreenState extends State<UploadSchemeScreen> {
  final _nameController = TextEditingController();
  String? _selectedSchemeType;
  PlatformFile? _file;
  List<XFile> _images = [];
  bool _isLoading = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() {
        _file = result.files.first;
      });
    }
  }

  Future<void> _pickImages() async {
    if (_images.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only upload up to 2 images.')),
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
        } else if (_images.length < 2) {
          setState(() {
            _images.add(image);
          });
        }
      }
    }
  }

  Future<void> _uploadScheme() async {
    if (_nameController.text.isEmpty ||
        _selectedSchemeType == null ||
        _file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and select a PDF file'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload PDF
      final pdfStorageRef = FirebaseStorage.instance.ref().child(
        'schemes/${DateTime.now().toIso8601String()}.pdf',
      );
      String pdfDownloadUrl;
      if (kIsWeb) {
        final pdfUploadTask = await pdfStorageRef.putData(_file!.bytes!);
        pdfDownloadUrl = await pdfUploadTask.ref.getDownloadURL();
      } else {
        final pdfUploadTask = await pdfStorageRef.putFile(File(_file!.path!));
        pdfDownloadUrl = await pdfUploadTask.ref.getDownloadURL();
      }

      // Upload Images
      final List<String> imageUrls = [];
      for (var image in _images) {
        final imageStorageRef = FirebaseStorage.instance.ref().child(
          'schemes/${DateTime.now().toIso8601String()}_${image.name}',
        );
        String downloadUrl;
        if (kIsWeb) {
          final uploadTask = await imageStorageRef.putData(
            await image.readAsBytes(),
          );
          downloadUrl = await uploadTask.ref.getDownloadURL();
        } else {
          final uploadTask = await imageStorageRef.putFile(File(image.path));
          downloadUrl = await uploadTask.ref.getDownloadURL();
        }
        imageUrls.add(downloadUrl);
      }

      await FirebaseFirestore.instance.collection('schemes').add({
        'name': _nameController.text,
        'schemeType': _selectedSchemeType,
        'pdfUrl': pdfDownloadUrl,
        'imageUrls': imageUrls,
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload scheme: $e')));
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
          child: Text('Upload Scheme'),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Scheme Name'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedSchemeType,
              hint: const Text('Select Scheme Type'),
              onChanged: (value) {
                setState(() {
                  _selectedSchemeType = value;
                });
              },
              items: ['State Government Scheme', 'Central Government Scheme']
                  .map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  })
                  .toList(),
            ),
            const SizedBox(height: 16),
            _file == null
                ? const Text('No file selected.')
                : Text('File selected: ${_file!.name}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickFile,
              child: const Text('Select PDF'),
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
              onPressed: _pickImages,
              child: const Text('Select Images'),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _uploadScheme,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
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
                    : const Text('Upload Scheme'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
