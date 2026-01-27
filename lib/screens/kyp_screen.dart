import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:panchayat_mitra/screens/edit_kyp_screen.dart';
import 'package:panchayat_mitra/screens/upload_kyp_screen.dart';
import 'package:panchayat_mitra/widgets/location_filter.dart';

class KypScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const KypScreen({super.key, required this.userData});

  @override
  State<KypScreen> createState() => _KypScreenState();
}

class _KypScreenState extends State<KypScreen> {
  String? _selectedBlock;
  String? _selectedPanchayat;

  @override
  Widget build(BuildContext context) {
    final role = (widget.userData['role'] as String?)?.trim().toLowerCase();
    final userBlock = (widget.userData['block'] as String?)?.toUpperCase();

    return Scaffold(
      appBar: AppBar(title: const Text('Know Your Panchayat')),
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
          if (role == 'panchayat admin' || role == 'district admin')
            Padding(
              padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const UploadKypScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 15,
                  ),
                ),
                child: const Text('Upload Contact'),
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getKypStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No contact data found.'));
                }

                final kypData = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: kypData.length,
                  itemBuilder: (context, index) {
                    final kyp = kypData[index].data() as Map<String, dynamic>;
                    return Card(
                      elevation: 4.0,
                      margin: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 16.0,
                      ),
                      child: ListTile(
                        title: Text(kyp['name'] ?? 'No name'),
                        subtitle: Text(
                          '${kyp['designation'] ?? 'No designation'}\n${kyp['mobile'] ?? 'No mobile'}\nBlock: ${kyp['block'] ?? 'N/A'}, Panchayat: ${kyp['panchayat'] ?? 'N/A'}',
                        ),
                        trailing:
                            (role == 'panchayat admin' ||
                                role == 'district admin')
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => EditKypScreen(
                                            kypId: kypData[index].id,
                                            name: kyp['name'] ?? '',
                                            designation:
                                                kyp['designation'] ?? '',
                                            mobile: kyp['mobile'] ?? '',
                                            block: kyp['block'] ?? '',
                                            panchayat: kyp['panchayat'] ?? '',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Contact'),
                                          content: const Text(
                                            'Are you sure you want to delete this contact?',
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
                                                    .collection('kyp')
                                                    .doc(kypData[index].id)
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
                              )
                            : null,
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

  Stream<QuerySnapshot> _getKypStream() {
    final role = (widget.userData['role'] as String?)?.trim().toLowerCase();
    final block = (widget.userData['block'] as String?)?.toUpperCase();
    final panchayat = (widget.userData['panchayat'] as String?)?.toUpperCase();

    Query query = FirebaseFirestore.instance.collection('kyp');

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
          .where('panchayat', isEqualTo: panchayat);
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
