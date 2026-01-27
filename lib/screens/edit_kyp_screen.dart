import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:panchayat_mitra/widgets/location_selector.dart';

class EditKypScreen extends StatefulWidget {
  final String kypId;
  final String name;
  final String designation;
  final String mobile;
  final String block;
  final String panchayat;

  const EditKypScreen({
    super.key,
    required this.kypId,
    required this.name,
    required this.designation,
    required this.mobile,
    required this.block,
    required this.panchayat,
  });

  @override
  State<EditKypScreen> createState() => _EditKypScreenState();
}

class _EditKypScreenState extends State<EditKypScreen> {
  late TextEditingController _nameController;
  late TextEditingController _designationController;
  late TextEditingController _mobileController;
  bool _isLoading = false;
  String? _selectedBlock;
  String? _selectedPanchayat;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _designationController = TextEditingController(text: widget.designation);
    _mobileController = TextEditingController(text: widget.mobile);
    _selectedBlock = widget.block;
    _selectedPanchayat = widget.panchayat;
  }

  Future<void> _updateKyp() async {
    if (_nameController.text.isEmpty ||
        _designationController.text.isEmpty ||
        _mobileController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('kyp')
          .doc(widget.kypId)
          .update({
            'name': _nameController.text,
            'designation': _designationController.text,
            'mobile': _mobileController.text,
            'block': _selectedBlock,
            'panchayat': _selectedPanchayat,
          });

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update contact: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Contact')),
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
              Text('Block: $_selectedBlock'),
              const SizedBox(height: 8),
              Text('Panchayat: $_selectedPanchayat'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateKyp,
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
