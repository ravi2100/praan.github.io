import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:panchayat_mitra/screens/upload_model_screen.dart';
import 'package:intl/intl.dart';
import 'package:panchayat_mitra/screens/edit_model_questionnaire_screen.dart';
import 'package:panchayat_mitra/screens/model_questionnaire_detail_screen.dart';
import 'package:panchayat_mitra/widgets/location_filter.dart';

class ModelScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final bool isPublic;
  const ModelScreen({super.key, required this.userData, this.isPublic = false});

  @override
  State<ModelScreen> createState() => _ModelScreenState();
}

class _ModelScreenState extends State<ModelScreen> {
  String? _selectedBlock;
  String? _selectedPanchayat;

  Color _getPercentageColor(double percentage) {
    if (percentage < 25) {
      return Colors.red;
    } else if (percentage < 50) {
      return Colors.orange;
    } else if (percentage < 75) {
      return Colors.yellow;
    } else {
      return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = (widget.userData['role'] as String?)?.trim().toLowerCase();
    final userBlock = (widget.userData['block'] as String?)?.toUpperCase();

    return Scaffold(
      appBar: AppBar(title: const Text('Model Questionnaire')),
      body: Column(
        children: [
          if (role == 'district admin' ||
              role == 'super admin' ||
              role == null ||
              role.isEmpty)
            LocationFilter(
              selectedBlock: _selectedBlock,
              selectedPanchayat: _selectedPanchayat,
              onBlockChanged: (value) {
                setState(() {
                  _selectedBlock = value;
                  _selectedPanchayat = null;
                });
              },
              onPanchayatChanged: (value) {
                setState(() {
                  _selectedPanchayat = value;
                });
              },
            ),
          if (role == 'block admin')
            LocationFilter(
              selectedBlock: userBlock,
              selectedPanchayat: _selectedPanchayat,
              showBlockDropdown: false,
              onBlockChanged: (_) {},
              onPanchayatChanged: (value) {
                setState(() {
                  _selectedPanchayat = value;
                });
              },
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getModelStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (role == 'panchayat admin' ||
                            role == 'district admin')
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 20.0,
                              bottom: 8.0,
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const UploadModelScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 50,
                                  vertical: 15,
                                ),
                              ),
                              child: const Text('Add Questionnaire'),
                            ),
                          ),
                        const Text('No questionnaire data found.'),
                      ],
                    ),
                  );
                }

                final modelData = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: modelData.length,
                  itemBuilder: (context, index) {
                    final model =
                        modelData[index].data() as Map<String, dynamic>;
                    final timestamp = model['timestamp'] as Timestamp?;
                    final percentage = model['percentage'] as double?;
                    final isApproved = model['isApproved'] as bool? ?? false;

                    return Card(
                      elevation: 4.0,
                      margin: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 16.0,
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  ModelQuestionnaireDetailScreen(
                                    documentId: modelData[index].id,
                                  ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 16.0,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Block: ${model['block'] ?? 'N/A'}, Panchayat: ${model['panchayat'] ?? 'N/A'}',
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Score: ${percentage?.toStringAsFixed(2) ?? 'N/A'}%',
                                    ),
                                    if (role == 'district admin')
                                      Text(
                                        isApproved
                                            ? 'Approved'
                                            : 'Not Approved',
                                        style: TextStyle(
                                          color: isApproved
                                              ? Colors.green
                                              : Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (percentage != null)
                                Chip(
                                  label: Text(
                                    '${percentage.toStringAsFixed(2)}%',
                                  ),
                                  backgroundColor: _getPercentageColor(
                                    percentage,
                                  ),
                                ),
                              if (role == 'district admin')
                                IconButton(
                                  icon: Icon(
                                    isApproved
                                        ? Icons.cancel
                                        : Icons.check_circle,
                                    color: isApproved
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                  onPressed: () {
                                    FirebaseFirestore.instance
                                        .collection('model_answers')
                                        .doc(modelData[index].id)
                                        .update({'isApproved': !isApproved});
                                  },
                                ),
                              if (role == 'panchayat admin' ||
                                  role == 'district admin')
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EditModelQuestionnaireScreen(
                                              documentId: modelData[index].id,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              if (role == 'panchayat admin' ||
                                  role == 'district admin')
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text(
                                          'Delete Questionnaire',
                                        ),
                                        content: const Text(
                                          'Are you sure you want to delete this entry?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              await FirebaseFirestore.instance
                                                  .collection('model_answers')
                                                  .doc(modelData[index].id)
                                                  .delete();
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getModelStream() {
    final role = (widget.userData['role'] as String?)?.trim().toLowerCase();
    final block = (widget.userData['block'] as String?)?.toUpperCase();
    final panchayat = (widget.userData['panchayat'] as String?)?.toUpperCase();

    Query query = FirebaseFirestore.instance.collection('model_answers');

    if (widget.isPublic) {
      query = query.where('isApproved', isEqualTo: true);
    }

    if (role == 'panchayat admin') {
      query = query.where('panchayat', isEqualTo: panchayat);
    } else if (role == 'block admin') {
      query = query.where('block', isEqualTo: block);
      if (_selectedPanchayat != null) {
        query = query.where('panchayat', isEqualTo: _selectedPanchayat);
      }
    } else if (role == 'citizen') {
      query = query
          .where('block', isEqualTo: block)
          .where('panchayat', isEqualTo: panchayat)
          .where('isApproved', isEqualTo: true);
    } else if (role == 'district admin' ||
        role == 'super admin' ||
        role == null ||
        role.isEmpty) {
      if (_selectedBlock != null) {
        query = query.where('block', isEqualTo: _selectedBlock);
      }
      if (_selectedPanchayat != null) {
        query = query.where('panchayat', isEqualTo: _selectedPanchayat);
      }
    }

    return query.snapshots();
  }
}
