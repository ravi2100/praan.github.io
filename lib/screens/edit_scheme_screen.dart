import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class EditSchemeScreen extends StatefulWidget {
  final String schemeId;

  const EditSchemeScreen({super.key, required this.schemeId});

  @override
  State<EditSchemeScreen> createState() => _EditSchemeScreenState();
}

class _EditSchemeScreenState extends State<EditSchemeScreen> {
  late TextEditingController _nameController;
  String? _selectedSchemeType;
  PlatformFile? _file;
  String? _pdfUrl;
  List<XFile> _images = [];
  List<dynamic>? _imageUrls;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _fetchSchemeData();
  }

  Future<void> _fetchSchemeData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('schemes')
          .doc(widget.schemeId)
          .get();
      final data = doc.data();
      if (data != null) {
        setState(() {
          _nameController.text = data['name'] ?? '';
          _selectedSchemeType = data['schemeType'] as String?;
          _pdfUrl = data['pdfUrl'] as String?;
          _imageUrls = data['imageUrls'] as List<dynamic>?;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to fetch data: $e')));
    }
  }

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
    if ((_images.length + (_imageUrls?.length ?? 0)) >= 2) {
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
        } else if ((_images.length + (_imageUrls?.length ?? 0)) < 2) {
          setState(() {
            _images.add(image);
          });
        }
      }
    }
  }

  Future<void> _updateScheme() async {
    if (_nameController.text.isEmpty || _selectedSchemeType == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? pdfDownloadUrl = _pdfUrl;
      if (_file != null) {
        if (_pdfUrl != null) {
          await FirebaseStorage.instance.refFromURL(_pdfUrl!).delete();
        }
        final pdfStorageRef = FirebaseStorage.instance.ref().child(
          'schemes/${DateTime.now().toIso8601String()}.pdf',
        );
        if (kIsWeb) {
          final pdfUploadTask = await pdfStorageRef.putData(_file!.bytes!);
          pdfDownloadUrl = await pdfUploadTask.ref.getDownloadURL();
        } else {
          final pdfUploadTask = await pdfStorageRef.putFile(File(_file!.path!));
          pdfDownloadUrl = await pdfUploadTask.ref.getDownloadURL();
        }
      }

      List<String> downloadUrls = _imageUrls?.cast<String>() ?? [];
      if (_images.isNotEmpty) {
        for (var image in _images) {
          final storageRef = FirebaseStorage.instance.ref().child(
            'schemes/${DateTime.now().toIso8601String()}_${image.name}',
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
          .collection('schemes')
          .doc(widget.schemeId)
          .update({
            'name': _nameController.text,
            'schemeType': _selectedSchemeType,
            'pdfUrl': pdfDownloadUrl,
            'imageUrls': downloadUrls,
          });

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update scheme: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Scheme')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
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
                  ? Text(_pdfUrl ?? 'No file selected.')
                  : Text('File selected: ${_file!.name}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickFile,
                child: const Text('Select PDF'),
              ),
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
                onPressed: _pickImages,
                child: const Text('Select Images'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateScheme,
                child: _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Text('Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
