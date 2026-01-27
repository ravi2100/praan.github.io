import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:panchayat_mitra/screens/edit_activity_screen.dart';
import 'package:panchayat_mitra/screens/gallery_view_screen.dart';
import 'package:panchayat_mitra/screens/upload_activity_screen.dart';
import 'package:panchayat_mitra/widgets/location_filter.dart';

class ActivitiesScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ActivitiesScreen({super.key, required this.userData});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  String? _selectedBlock;
  String? _selectedPanchayat;

  @override
  Widget build(BuildContext context) {
    final role = (widget.userData['role'] as String?)?.trim().toLowerCase();
    final userBlock = (widget.userData['block'] as String?)?.toUpperCase();

    return Scaffold(
      appBar: AppBar(title: const Text('Activities')),
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
                      builder: (context) => const UploadActivityScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 15,
                  ),
                ),
                child: const Text('Upload Activity'),
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getActivitiesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No activities found.'));
                }

                final activities = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final activity =
                        activities[index].data() as Map<String, dynamic>;
                    final imageUrls = activity['imageUrls'] as List<dynamic>?;
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
                            title: Text(activity['title'] ?? 'No title'),
                            subtitle: Text(
                              '${activity['description'] ?? 'No description'}\nBlock: ${activity['block'] ?? 'N/A'}, Panchayat: ${activity['panchayat'] ?? 'N/A'}',
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
                                                  EditActivityScreen(
                                                    activityId:
                                                        activities[index].id,
                                                    title:
                                                        activity['title'] ?? '',
                                                    description:
                                                        activity['description'] ??
                                                        '',
                                                    imageUrls: imageUrls,
                                                    block:
                                                        activity['block'] ?? '',
                                                    panchayat:
                                                        activity['panchayat'] ??
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
                                                'Delete Activity',
                                              ),
                                              content: const Text(
                                                'Are you sure you want to delete this activity?',
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
                                                        .collection(
                                                          'activities',
                                                        )
                                                        .doc(
                                                          activities[index].id,
                                                        )
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

  Stream<QuerySnapshot> _getActivitiesStream() {
    final role = (widget.userData['role'] as String?)?.trim().toLowerCase();
    final block = (widget.userData['block'] as String?)?.toUpperCase();
    final panchayat = (widget.userData['panchayat'] as String?)?.toUpperCase();

    Query query = FirebaseFirestore.instance.collection('activities');

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
