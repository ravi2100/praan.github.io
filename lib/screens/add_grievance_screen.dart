import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:panchayat_mitra/data/grievance_categories.dart';
import 'package:panchayat_mitra/widgets/location_selector.dart';

class AddGrievanceScreen extends StatefulWidget {
  const AddGrievanceScreen({super.key});

  @override
  State<AddGrievanceScreen> createState() => _AddGrievanceScreenState();
}

class _AddGrievanceScreenState extends State<AddGrievanceScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _nameController = TextEditingController();
  final _mbNoController = TextEditingController();
  String? _selectedCategory;
  String? _selectedSubCategory;
  List<String> _subCategories = [];
  List<PlatformFile> _attachments = [];
  String? _selectedBlock;
  String? _selectedPanchayat;
  bool _isLoading = false;
  Map<String, dynamic>? _userData;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        _userData = doc.data();
        final role = (_userData?['role'] as String?)?.trim();
        if (role == 'Citizen' || role == 'Panchayat Admin') {
          _selectedBlock = _userData?['block'];
          _selectedPanchayat = _userData?['panchayat'];
        }
      });
    }
  }

  Future<void> _pickAttachments() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (result != null) {
      List<PlatformFile> newAttachments = [];
      for (var file in result.files) {
        if (file.size > 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${file.name} exceeds the 1 MB size limit.'),
            ),
          );
        } else {
          newAttachments.add(file);
        }
      }
      setState(() {
        _attachments.addAll(newAttachments);
      });
    }
  }

  Future<void> _submitGrievance() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _mbNoController.text.isEmpty ||
        _selectedCategory == null ||
        _selectedSubCategory == null ||
        _selectedBlock == null ||
        _selectedPanchayat == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a date')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final imageUrls = <String>[];
      final fileUrls = <String>[];

      // Atomically increment the complaint ID
      final complaintIdRef = FirebaseFirestore.instance
          .collection('counters')
          .doc('complaintId');
      final newComplaintId = await FirebaseFirestore.instance.runTransaction((
        transaction,
      ) async {
        final snapshot = await transaction.get(complaintIdRef);
        if (!snapshot.exists) {
          transaction.set(complaintIdRef, {'lastId': 100000});
          return 100000;
        }
        final lastId = snapshot.data()!['lastId'] as int;
        final newId = lastId + 1;
        transaction.update(complaintIdRef, {'lastId': newId});
        return newId;
      });

      final complaintId = newComplaintId.toString();

      for (var attachment in _attachments) {
        final storageRef = FirebaseStorage.instance.ref().child(
          'grievances/${DateTime.now().toIso8601String()}-${attachment.name}',
        );

        UploadTask uploadTask;
        if (kIsWeb) {
          uploadTask = storageRef.putData(attachment.bytes!);
        } else {
          uploadTask = storageRef.putFile(File(attachment.path!));
        }

        final downloadUrl = await (await uploadTask).ref.getDownloadURL();
        final extension = attachment.extension?.toLowerCase();

        if (extension == 'jpg' || extension == 'jpeg' || extension == 'png') {
          imageUrls.add(downloadUrl);
        } else if (extension == 'pdf') {
          fileUrls.add(downloadUrl);
        }
      }

      await FirebaseFirestore.instance.collection('grievances').add({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'applicantName': _nameController.text,
        'applicantMbNo': _mbNoController.text,
        'category': _selectedCategory,
        'subCategory': _selectedSubCategory,
        'imageUrls': imageUrls,
        'fileUrls': fileUrls,
        'status': 'Pending',
        'currentOwner': 'Panchayat admin',
        'userId': user!.uid,
        'timestamp': _selectedDate,
        'complaintId': complaintId,
        'block': _selectedBlock,
        'panchayat': _selectedPanchayat,
        'history': [
          {
            'status': 'Pending',
            'timestamp': _selectedDate,
            'actionBy': user.uid,
            'currentOwner': 'Panchayat admin',
          },
        ],
      });

      Navigator.of(context).pop();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Grievance Submitted'),
          content: Text(
            'Your complaint has been submitted successfully. Your complaint ID is $complaintId',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to submit grievance: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildAttachmentPreview() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _attachments.length,
      itemBuilder: (context, index) {
        final file = _attachments[index];
        final isImage = [
          'jpg',
          'jpeg',
          'png',
        ].contains(file.extension?.toLowerCase());

        return Card(
          child: ListTile(
            leading: isImage
                ? (kIsWeb
                      ? Image.memory(
                          file.bytes!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(file.path!),
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ))
                : const Icon(Icons.insert_drive_file),
            title: Text(file.name),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _attachments.removeAt(index);
                });
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = (_userData?['role'] as String?)?.trim();
    return Scaffold(
      appBar: AppBar(title: const Text('Add Grievance'), elevation: 0),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade100, Colors.orange.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Submit a New Grievance',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        prefixIcon: Icon(Icons.subject),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name of the Applicant',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _mbNoController,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Select Date',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            _selectedDate = pickedDate;
                          });
                        }
                      },
                      controller: TextEditingController(
                        text: _selectedDate == null
                            ? ''
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (role == 'Citizen' || role == 'Panchayat Admin') ...[
                      Text('Block: ${_selectedBlock ?? ''}'),
                      const SizedBox(height: 8),
                      Text('Panchayat: ${_selectedPanchayat ?? ''}'),
                    ] else
                      LocationSelector(
                        onLocationChanged: (block, panchayat) {
                          setState(() {
                            _selectedBlock = block;
                            _selectedPanchayat = panchayat;
                          });
                        },
                      ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      hint: const Text('Select Category'),
                      isExpanded: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCategory = newValue;
                          _selectedSubCategory = null;
                          _subCategories = grievanceCategories[newValue!] ?? [];
                        });
                      },
                      items: grievanceCategories.keys
                          .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          })
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    if (_selectedCategory != null)
                      DropdownButtonFormField<String>(
                        value: _selectedSubCategory,
                        hint: const Text('Select Sub-Category'),
                        isExpanded: true,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.subdirectory_arrow_right),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedSubCategory = newValue;
                          });
                        },
                        items: _subCategories.map<DropdownMenuItem<String>>((
                          String value,
                        ) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _pickAttachments,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Add Attachments (Max 1MB)'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_attachments.isNotEmpty) _buildAttachmentPreview(),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitGrievance,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            )
                          : const Text('Submit Grievance'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
