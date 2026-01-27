import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:panchayat_mitra/screens/edit_osr_screen.dart';
import 'package:panchayat_mitra/screens/gallery_view_screen.dart';
import 'package:panchayat_mitra/screens/upload_osr_screen.dart';
import 'package:panchayat_mitra/widgets/location_filter.dart';

class OsrScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const OsrScreen({super.key, required this.userData});

  @override
  State<OsrScreen> createState() => _OsrScreenState();
}

class _OsrScreenState extends State<OsrScreen> {
  String? _selectedBlock;
  String? _selectedPanchayat;

  @override
  Widget build(BuildContext context) {
    final role = (widget.userData['role'] as String?)?.trim().toLowerCase();
    final userBlock = (widget.userData['block'] as String?)?.toUpperCase();

    return Scaffold(
      appBar: AppBar(title: const Text('OSR')),
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
                      builder: (context) => const UploadOsrScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 15,
                  ),
                ),
                child: const Text('Upload OSR Data'),
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getOsrStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No OSR data found.'));
                }

                final osrData = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: osrData.length,
                  itemBuilder: (context, index) {
                    final osr = osrData[index].data() as Map<String, dynamic>;
                    final imageUrls = osr['imageUrls'] as List<dynamic>?;
                    return Card(
                      elevation: 4.0,
                      margin: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 16.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text(osr['name'] ?? 'No name'),
                            subtitle: Text(
                              '${osr['description'] ?? 'No description'}\nExpected Revenue: ₹${osr['expectedRevenue'] ?? 'N/A'}\nBlock: ${osr['block'] ?? 'N/A'}, Panchayat: ${osr['panchayat'] ?? 'N/A'}',
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
                                              builder: (context) =>
                                                  EditOsrScreen(
                                                    osrId: osrData[index].id,
                                                    name: osr['name'] ?? '',
                                                    description:
                                                        osr['description'] ??
                                                        '',
                                                    imageUrls: imageUrls,
                                                    block: osr['block'] ?? '',
                                                    panchayat:
                                                        osr['panchayat'] ?? '',
                                                    expectedRevenue:
                                                        osr['expectedRevenue'] ??
                                                        '',
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
                                              title: const Text(
                                                'Delete OSR Data',
                                              ),
                                              content: const Text(
                                                'Are you sure you want to delete this data?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(
                                                    context,
                                                  ).pop(),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection('osr')
                                                        .doc(osrData[index].id)
                                                        .delete();
                                                    if (imageUrls != null) {
                                                      for (var url
                                                          in imageUrls) {
                                                        await FirebaseStorage
                                                            .instance
                                                            .refFromURL(url)
                                                            .delete();
                                                      }
                                                    }
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
                          if (imageUrls != null && imageUrls.isNotEmpty)
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: imageUrls.length,
                                itemBuilder: (context, index) {
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              GalleryViewScreen(
                                                imageUrls: imageUrls,
                                                initialIndex: index,
                                              ),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Image.network(
                                        imageUrls[index],
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
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

  Stream<QuerySnapshot> _getOsrStream() {
    final role = (widget.userData['role'] as String?)?.trim().toLowerCase();
    final block = (widget.userData['block'] as String?)?.toUpperCase();
    final panchayat = (widget.userData['panchayat'] as String?)?.toUpperCase();

    Query query = FirebaseFirestore.instance.collection('osr');

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
