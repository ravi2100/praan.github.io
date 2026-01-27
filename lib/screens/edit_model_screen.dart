import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:panchayat_mitra/widgets/location_selector.dart';

class EditModelScreen extends StatefulWidget {
  final String modelId;
  final String villageName;
  final String description;
  final String? imageUrl;
  final String block;
  final String panchayat;

  const EditModelScreen({
    super.key,
    required this.modelId,
    required this.villageName,
    required this.description,
    this.imageUrl,
    required this.block,
    required this.panchayat,
  });

  @override
  State<EditModelScreen> createState() => _EditModelScreenState();
}

class _EditModelScreenState extends State<EditModelScreen> {
  late TextEditingController _villageNameController;
  late TextEditingController _descriptionController;
  XFile? _image;
  bool _isLoading = false;
  String? _selectedBlock;
  String? _selectedPanchayat;

  @override
  void initState() {
    super.initState();
    _villageNameController = TextEditingController(text: widget.villageName);
    _descriptionController = TextEditingController(text: widget.description);
    _selectedBlock = widget.block;
    _selectedPanchayat = widget.panchayat;
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {
      _image = image;
    });
  }

  Future<void> _updateModel() async {
    if (_villageNameController.text.isEmpty ||
        _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? downloadUrl = widget.imageUrl;
      if (_image != null) {
        if (widget.imageUrl != null) {
          await FirebaseStorage.instance.refFromURL(widget.imageUrl!).delete();
        }
        final storageRef = FirebaseStorage.instance.ref().child(
          'model/${DateTime.now().toIso8601String()}',
        );
        if (kIsWeb) {
          final uploadTask = await storageRef.putData(
            await _image!.readAsBytes(),
          );
          downloadUrl = await uploadTask.ref.getDownloadURL();
        } else {
          final uploadTask = await storageRef.putFile(File(_image!.path));
          downloadUrl = await uploadTask.ref.getDownloadURL();
        }
      }

      await FirebaseFirestore.instance
          .collection('model')
          .doc(widget.modelId)
          .update({
            'villageName': _villageNameController.text,
            'description': _descriptionController.text,
            'imageUrl': downloadUrl,
            'block': _selectedBlock,
            'panchayat': _selectedPanchayat,
          });

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update village data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Village Data')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _villageNameController,
                decoration: const InputDecoration(labelText: 'Village Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 16),
              Text('Block: $_selectedBlock'),
              const SizedBox(height: 8),
              Text('Panchayat: $_selectedPanchayat'),
              const SizedBox(height: 16),
              _image == null
                  ? (widget.imageUrl != null
                        ? Image.network(widget.imageUrl!)
                        : const Text('No image selected.'))
                  : (kIsWeb
                        ? Image.network(_image!.path)
                        : Image.file(File(_image!.path))),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Select Image'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateModel,
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
