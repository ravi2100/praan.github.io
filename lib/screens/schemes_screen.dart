import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:panchayat_mitra/screens/edit_scheme_screen.dart';
import 'package:panchayat_mitra/screens/gallery_view_screen.dart';
import 'package:panchayat_mitra/screens/upload_scheme_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SchemesScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const SchemesScreen({super.key, required this.userData});

  @override
  State<SchemesScreen> createState() => _SchemesScreenState();
}

class _SchemesScreenState extends State<SchemesScreen> {
  @override
  Widget build(BuildContext context) {
    final role = (widget.userData['role'] as String?)?.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(title: const Text('Schemes')),
      body: Column(
        children: [
          if (role == 'district admin' || role == 'district admin')
            Padding(
              padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const UploadSchemeScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 15,
                  ),
                ),
                child: const Text('Upload Scheme'),
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('schemes')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No schemes found.'));
                }

                final schemes = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: schemes.length,
                  itemBuilder: (context, index) {
                    final scheme =
                        schemes[index].data() as Map<String, dynamic>;
                    final imageUrls = scheme['imageUrls'] as List<dynamic>?;
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
                            title: Text(scheme['name'] ?? 'No name'),
                            subtitle: Text(
                              '${scheme['schemeType'] ?? 'No scheme type'}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.download),
                                  onPressed: () async {
                                    if (scheme['pdfUrl'] != null) {
                                      if (await canLaunchUrl(
                                        Uri.parse(scheme['pdfUrl']),
                                      )) {
                                        await launchUrl(
                                          Uri.parse(scheme['pdfUrl']),
                                        );
                                      }
                                    }
                                  },
                                ),
                                if (role == 'district admin' ||
                                    role == 'district admin')
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EditSchemeScreen(
                                                schemeId: schemes[index].id,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                if (role == 'district admin' ||
                                    role == 'district admin')
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('schemes')
                                          .doc(schemes[index].id)
                                          .delete();
                                    },
                                  ),
                              ],
                            ),
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
}
