import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:panchayat_mitra/screens/image_view_screen.dart';
import 'package:panchayat_mitra/screens/pdf_view_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class GrievanceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> grievance;
  final String grievanceId;
  final Map<String, dynamic> userData;

  const GrievanceDetailScreen({
    super.key,
    required this.grievance,
    required this.grievanceId,
    required this.userData,
  });

  @override
  State<GrievanceDetailScreen> createState() => _GrievanceDetailScreenState();
}

class _GrievanceDetailScreenState extends State<GrievanceDetailScreen> {
  bool _isUploading = false;
  late Map<String, dynamic> _grievance;

  @override
  void initState() {
    super.initState();
    _grievance = widget.grievance;
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'In Progress':
        return Colors.blue;
      case 'Closed':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrls = _grievance['imageUrls'] as List<dynamic>? ?? [];
    final fileUrls = _grievance['fileUrls'] as List<dynamic>? ?? [];
    final history = _grievance['history'] as List<dynamic>? ?? [];
    final timestamp = _grievance['timestamp'] as Timestamp?;

    return Scaffold(
      appBar: AppBar(
        title: Text(_grievance['title'] ?? 'Grievance Details'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade100, Colors.orange.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildDetailCard(timestamp),
            const SizedBox(height: 16),
            _buildDescriptionCard(),
            if (imageUrls.isNotEmpty || fileUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildAttachmentCard(imageUrls, fileUrls),
            ],
            const SizedBox(height: 16),
            _buildHistoryCard(history),
            const SizedBox(height: 16),
            _buildActionButtons(),
            const SizedBox(height: 32.0),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(Timestamp? timestamp) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Details', style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 20, thickness: 1),
            _buildDetailRow(
              'Complaint ID:',
              _grievance['complaintId'] ?? 'N/A',
            ),
            _buildDetailRow(
              'Applicant Name:',
              _grievance['applicantName'] ?? 'N/A',
            ),
            _buildDetailRow(
              'Applicant Mb No:',
              _grievance['applicantMbNo'] ?? 'N/A',
            ),
            _buildDetailRow(
              'Status:',
              _grievance['status'] ?? 'N/A',
              valueColor: _getStatusColor(_grievance['status']),
            ),
            _buildDetailRow(
              'Current Owner:',
              _grievance['currentOwner'] ?? 'N/A',
            ),
            _buildDetailRow(
              'Date:',
              timestamp != null
                  ? DateFormat.yMMMd().format(timestamp.toDate())
                  : 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description', style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 20, thickness: 1),
            Text(
              _grievance['description'] ?? 'No description provided.',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentCard(List<dynamic> imageUrls, List<dynamic> fileUrls) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Attachments', style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 20, thickness: 1),
            if (imageUrls.isNotEmpty) ...[
              const Text(
                'Images:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: imageUrls.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              ImageViewScreen(imageUrl: imageUrls[index]),
                        ),
                      );
                    },
                    child: Image.network(imageUrls[index], fit: BoxFit.cover),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
            if (fileUrls.isNotEmpty) ...[
              const Text(
                'Files:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ...fileUrls.map((url) {
                return ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: Text('View PDF ${fileUrls.indexOf(url) + 1}'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PdfViewScreen(pdfUrl: url),
                      ),
                    );
                  },
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(List<dynamic> history) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('History', style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 20, thickness: 1),
            ...history.map((entry) {
              final timestamp = entry['timestamp'] as Timestamp?;
              final comments = entry['comments'] as String?;
              final actionBy = entry['actionBy'] as String?;
              final currentOwner = entry['currentOwner'] as String?;
              final imageUrls = entry['imageUrls'] as List<dynamic>? ?? [];
              final fileUrls = entry['fileUrls'] as List<dynamic>? ?? [];
              return FutureBuilder<DocumentSnapshot>(
                future: actionBy != null
                    ? FirebaseFirestore.instance
                          .collection('users')
                          .doc(actionBy)
                          .get()
                    : null,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final userData =
                      snapshot.data?.data() as Map<String, dynamic>?;
                  final actionByUsername =
                      userData?['name'] ??
                      userData?['email'] ??
                      actionBy ??
                      'N/A';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry['status'] ?? 'No status',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          timestamp != null
                              ? 'on ${DateFormat.yMMMd().format(timestamp.toDate())} by $actionByUsername'
                              : 'No date',
                        ),
                        if (currentOwner != null && currentOwner.isNotEmpty)
                          Text('Owner: $currentOwner'),
                        if (comments != null && comments.isNotEmpty)
                          Text('Comments: $comments'),
                        if (imageUrls.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children: imageUrls
                                  .map(
                                    (url) => GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ImageViewScreen(imageUrl: url),
                                          ),
                                        );
                                      },
                                      child: Image.network(
                                        url,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        if (fileUrls.isNotEmpty)
                          ...fileUrls.map(
                            (url) => InkWell(
                              onTap: () => launchUrl(Uri.parse(url)),
                              child: Text(
                                'View File',
                                style: TextStyle(color: Colors.blue),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(value, style: TextStyle(fontSize: 16, color: valueColor)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final role = (widget.userData['role'] as String?)?.trim().toLowerCase();
    final currentOwner = _grievance['currentOwner'];
    final isPublicView = widget.userData.isEmpty;

    if (isPublicView) {
      return Container();
    }

    if (role == 'panchayat admin' && currentOwner == 'Panchayat admin') {
      return _buildAdminActions(role: role ?? '', forwardTo: 'Block admin');
    } else if (role == 'block admin' && currentOwner == 'Block admin') {
      return _buildAdminActions(role: role ?? '', forwardTo: 'District admin');
    } else if (role == 'district admin' && currentOwner == 'District admin') {
      return _buildAdminActions(
        role: role ?? '',
        forwardTo: 'Panchayat or Block admin',
      );
    }

    return Container();
  }

  Widget _buildAdminActions({required String role, required String forwardTo}) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => _showStatusUpdateDialog(role: role),
          child: const Text('Update Status'),
        ),
      ],
    );
  }

  void _showStatusUpdateDialog({required String role}) {
    final commentsController = TextEditingController();
    String? _selectedAction;
    List<PlatformFile> _pickedFiles = [];
    DateTime? _selectedDate;

    List<String> actionOptions = ['In Progress', 'Close', 'Reject'];
    List<String> forwardOptions = [];
    if (role.toLowerCase() == 'panchayat admin') {
      forwardOptions = ['Forward to Block admin', 'Forward to District admin'];
    } else if (role.toLowerCase() == 'block admin') {
      forwardOptions = [
        'Forward to Panchayat admin',
        'Forward to District admin',
      ];
    } else if (role.toLowerCase() == 'district admin') {
      forwardOptions = ['Forward to Panchayat admin', 'Forward to Block admin'];
    }
    actionOptions.addAll(forwardOptions);

    bool isDialogUploading = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Update Status'),
              content: isDialogUploading
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Please wait...'),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedAction,
                            hint: const Text('Select Action'),
                            onChanged: (String? newValue) {
                              _selectedAction = newValue;
                            },
                            items: actionOptions.map<DropdownMenuItem<String>>((
                              String value,
                            ) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
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
                          TextField(
                            controller: commentsController,
                            decoration: const InputDecoration(
                              labelText: 'Comments',
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result = await FilePicker.platform
                                  .pickFiles(
                                    allowMultiple: true,
                                    type: FileType.custom,
                                    allowedExtensions: [
                                      'jpg',
                                      'jpeg',
                                      'png',
                                      'pdf',
                                    ],
                                  );
                              if (result != null) {
                                int currentCount = _pickedFiles.length;
                                int remainingSlots = 3 - currentCount;
                                if (result.files.length > remainingSlots) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'You can only select up to $remainingSlots more file(s).',
                                      ),
                                    ),
                                  );
                                }
                                final validFiles = result.files
                                    .where((file) => file.size <= 1024 * 1024)
                                    .take(remainingSlots);
                                final oversizedFiles = result.files.where(
                                  (file) => file.size > 1024 * 1024,
                                );

                                if (oversizedFiles.isNotEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Some files were not added because they exceed 1 MB.',
                                      ),
                                    ),
                                  );
                                }
                                setState(() {
                                  _pickedFiles.addAll(validFiles);
                                });
                              }
                            },
                            icon: const Icon(Icons.attach_file),
                            label: const Text('Attach Files'),
                          ),
                          if (_pickedFiles.isNotEmpty)
                            Column(
                              children: _pickedFiles.map((file) {
                                final index = _pickedFiles.indexOf(file);
                                return ListTile(
                                  title: Text(file.name),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      setState(() {
                                        _pickedFiles.removeAt(index);
                                      });
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
              actions: isDialogUploading
                  ? []
                  : [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          if (_selectedAction != null) {
                            if (_selectedDate == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please select a date'),
                                ),
                              );
                              return;
                            }
                            setState(() {
                              isDialogUploading = true;
                            });
                            _updateStatus(
                              _selectedAction!,
                              comments: commentsController.text,
                              role: role,
                              files: _pickedFiles,
                              selectedDate: _selectedDate!,
                            );
                          }
                        },
                        child: const Text('Update'),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateStatus(
    String action, {
    String? comments,
    required String role,
    List<PlatformFile>? files,
    required DateTime selectedDate,
  }) async {
    setState(() {
      _isUploading = true;
    });

    final grievanceRef = FirebaseFirestore.instance
        .collection('grievances')
        .doc(widget.grievanceId);

    List<String> imageUrls = [];
    List<String> fileUrls = [];

    if (files != null && files.isNotEmpty) {
      for (final file in files) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        final ref = FirebaseStorage.instance
            .ref()
            .child('grievance_attachments')
            .child(fileName);

        UploadTask uploadTask;
        if (kIsWeb) {
          uploadTask = ref.putData(file.bytes!);
        } else {
          uploadTask = ref.putFile(File(file.path!));
        }

        final url = await (await uploadTask).ref.getDownloadURL();
        final extension = file.extension?.toLowerCase();

        if (['jpg', 'jpeg', 'png'].contains(extension)) {
          imageUrls.add(url);
        } else {
          fileUrls.add(url);
        }
      }
    }

    String newStatus = '';
    String newCurrentOwner = '';

    if (action.startsWith('Forward to')) {
      newStatus = 'Pending';
      newCurrentOwner = action.substring('Forward to '.length);
    } else if (action == 'In Progress') {
      newStatus = 'In Progress';
      newCurrentOwner = _grievance['currentOwner'];
    } else if (action == 'Close') {
      newStatus = 'Closed';
      newCurrentOwner = _grievance['currentOwner'];
    } else if (action == 'Reject') {
      newStatus = 'Rejected';
      newCurrentOwner = _grievance['currentOwner'];
    }

    final newHistoryEntry = {
      'status': newStatus,
      'timestamp': selectedDate,
      'actionBy': FirebaseAuth.instance.currentUser!.uid,
      'comments': comments,
      'currentOwner': newCurrentOwner,
      'imageUrls': imageUrls,
      'fileUrls': fileUrls,
    };

    await grievanceRef.update({
      'status': newStatus,
      'currentOwner': newCurrentOwner,
      'history': FieldValue.arrayUnion([newHistoryEntry]),
      'imageUrls': FieldValue.arrayUnion(imageUrls),
      'fileUrls': FieldValue.arrayUnion(fileUrls),
    });

    setState(() {
      _isUploading = false;
    });

    if (mounted) {
      Navigator.of(context).pop();
      _refreshGrievanceData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status updated successfully')),
      );
    }
  }

  Future<void> _refreshGrievanceData() async {
    final doc = await FirebaseFirestore.instance
        .collection('grievances')
        .doc(widget.grievanceId)
        .get();
    if (doc.exists && mounted) {
      setState(() {
        _grievance = doc.data()!;
      });
    }
  }
}
