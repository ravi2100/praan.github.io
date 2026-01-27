import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:panchayat_mitra/data/locations.dart';
import 'package:panchayat_mitra/screens/add_grievance_screen.dart';
import 'package:panchayat_mitra/screens/grievance_detail_screen.dart';
import 'package:rxdart/rxdart.dart';

class GrievancesScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const GrievancesScreen({super.key, required this.userData});

  @override
  State<GrievancesScreen> createState() => _GrievancesScreenState();
}

class _GrievancesScreenState extends State<GrievancesScreen> {
  String? _selectedStatusCategory;
  final _searchController = TextEditingController();
  late final BehaviorSubject<String> _searchQuerySubject;
  String? _selectedBlock;
  String? _selectedPanchayat;
  final List<Map<String, dynamic>> _dashboardItems = [
    {'status': 'Pending', 'color': Colors.orange},
    {'status': 'Action Taken', 'color': Colors.green},
  ];

  @override
  void initState() {
    super.initState();
    _searchQuerySubject = BehaviorSubject<String>.seeded('');
  }

  // TODO: Implement the logic to delete all grievances
  void _deleteAllGrievances() {}

  // TODO: Implement the logic to delete a single grievance
  void _deleteGrievance(String grievanceId) {}

  @override
  void dispose() {
    _searchController.dispose();
    _searchQuerySubject.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bool isPublicView = widget.userData.isEmpty;

    if (user == null && !isPublicView) {
      return const Scaffold(body: Center(child: Text("User not logged in.")));
    }

    if (isPublicView) {
      return _buildGrievancesView(null);
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text("User data not found.")),
          );
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        return _buildGrievancesView(userData);
      },
    );
  }

  Widget _buildGrievancesView(Map<String, dynamic>? userData) {
    final role = (userData?['role'] as String?)?.trim().toLowerCase();
    final isPublicView = userData == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grievances'),
        elevation: 0,
        actions: [
          if (role != 'citizen')
            StreamBuilder<int>(
              stream: _getGrievanceCountStream('Current Owner', userData),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications),
                      onPressed: () {
                        setState(() {
                          _selectedStatusCategory = 'Current Owner';
                        });
                      },
                    ),
                    if (count > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          if (role == 'district admin')
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: _deleteAllGrievances,
            ),
        ],
      ),
      floatingActionButton: !isPublicView && role != 'block admin'
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddGrievanceScreen(),
                  ),
                );
              },
              label: const Text('Add Grievance'),
              icon: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade100, Colors.orange.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _searchQuerySubject.add,
                        decoration: InputDecoration(
                          labelText: 'Search by Complaint ID',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (isPublicView || role == 'district admin')
                    SliverToBoxAdapter(child: _buildLocationFilters()),
                  if (role == 'block admin')
                    SliverToBoxAdapter(child: _buildPanchayatFilter(userData!)),
                  SliverToBoxAdapter(child: _buildDashboard(userData)),
                  if (_selectedStatusCategory != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedStatusCategory = null;
                            });
                          },
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear Filter'),
                        ),
                      ),
                    ),
                  StreamBuilder<QuerySnapshot>(
                    stream: _getGrievancesStream(userData),
                    builder: (context, grievanceSnapshot) {
                      if (grievanceSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const SliverToBoxAdapter(
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (grievanceSnapshot.hasError) {
                        return SliverToBoxAdapter(
                          child: Center(
                            child: Text('Error: ${grievanceSnapshot.error}'),
                          ),
                        );
                      }
                      if (!grievanceSnapshot.hasData ||
                          grievanceSnapshot.data!.docs.isEmpty) {
                        return const SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'No grievances found.',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                        );
                      }

                      final allGrievances = grievanceSnapshot.data!.docs;

                      return StreamBuilder<String>(
                        stream: _searchQuerySubject.stream,
                        builder: (context, searchSnapshot) {
                          final searchQuery = searchSnapshot.data ?? '';
                          final grievances = allGrievances.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final complaintId =
                                data['complaintId']?.toString().toLowerCase() ??
                                '';
                            return complaintId.contains(
                              searchQuery.toLowerCase(),
                            );
                          }).toList();

                          if (grievances.isEmpty) {
                            return const SliverToBoxAdapter(
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    'No grievances found.',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ),
                              ),
                            );
                          }

                          return SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final grievance =
                                  grievances[index].data()
                                      as Map<String, dynamic>;
                              final grievanceId = grievances[index].id;
                              final timestamp =
                                  grievance['timestamp'] as Timestamp?;
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 8.0,
                                ),
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16.0),
                                  title: Text(
                                    grievance['title'] ?? 'No title',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      Text(
                                        'Complaint ID: ${grievance['complaintId'] ?? 'N/A'}',
                                      ),
                                      Text(
                                        'Applicant Name: ${grievance['applicantName'] ?? 'N/A'}',
                                      ),
                                      Text(
                                        'Applicant Mb No: ${grievance['applicantMbNo'] ?? 'N/A'}',
                                      ),
                                      Text(
                                        'Location: ${grievance['block'] ?? 'N/A'}, ${grievance['panchayat'] ?? 'N/A'}',
                                      ),
                                      Text(
                                        'Date: ${timestamp != null ? DateFormat.yMMMd().format(timestamp.toDate()) : 'N/A'}',
                                      ),
                                    ],
                                  ),
                                  trailing: SizedBox(
                                    width: 100,
                                    child: role == 'district admin'
                                        ? IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () =>
                                                _deleteGrievance(grievanceId),
                                          )
                                        : Text(
                                            grievance['status'] ?? 'No status',
                                            style: TextStyle(
                                              color: _getStatusColor(
                                                grievance['status'],
                                              ),
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.end,
                                          ),
                                  ),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            GrievanceDetailScreen(
                                              grievance: grievance,
                                              grievanceId: grievances[index].id,
                                              userData: userData ?? {},
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }, childCount: grievances.length),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(Map<String, dynamic>? userData) {
    final dashboardItems = _dashboardItems;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 2.0,
      ),
      itemCount: dashboardItems.length,
      itemBuilder: (context, index) {
        final item = dashboardItems[index];
        final icon = item['icon'] as IconData?;
        return InkWell(
          onTap: () {
            setState(() {
              _selectedStatusCategory = item['status'];
            });
          },
          child: StreamBuilder<int>(
            stream: _getGrievanceCountStream(item['status'], userData),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: item['color'],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 24),
                      const SizedBox(height: 4.0),
                    ],
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          item['status'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Stream<int> _getGrievanceCountStream(
    String status,
    Map<String, dynamic>? userData,
  ) {
    final user = FirebaseAuth.instance.currentUser;
    final role = (userData?['role'] as String?)?.trim().toLowerCase();
    final isPublicView = userData == null;

    if (user == null && !isPublicView) return Stream.value(0);

    Query query = FirebaseFirestore.instance.collection('grievances');

    if (status == 'Current Owner') {
      String? expectedOwner;
      if (role == 'panchayat admin') {
        expectedOwner = 'Panchayat admin';
      } else if (role == 'block admin') {
        expectedOwner = 'Block admin';
      } else if (role == 'district admin') {
        expectedOwner = 'District admin';
      }
      if (expectedOwner != null) {
        query = query.where('currentOwner', isEqualTo: expectedOwner);
      } else {
        query = query.where('currentOwner', isEqualTo: 'impossible_value');
      }
    } else {
      List<String> statusesToQuery;
      if (status == 'Pending') {
        statusesToQuery = ['Pending'];
      } else if (status == 'Action Taken') {
        statusesToQuery = ['In Progress', 'Closed', 'Rejected'];
      } else {
        statusesToQuery = [status];
      }
      query = query.where('status', whereIn: statusesToQuery);
    }

    if (isPublicView) {
      // No specific user role filters for public view
    } else if (role == 'panchayat admin') {
      query = query
          .where('block', isEqualTo: userData!['block'])
          .where('panchayat', isEqualTo: userData['panchayat']);
    } else if (role == 'block admin') {
      query = query.where(
        'block',
        isEqualTo: (userData!['block'] as String?)?.toUpperCase(),
      );
      if (_selectedPanchayat != null) {
        query = query.where('panchayat', isEqualTo: _selectedPanchayat);
      }
    } else if (role == 'citizen') {
      query = query.where('userId', isEqualTo: user!.uid);
    } else if (role == 'district admin') {
      if (_selectedBlock != null) {
        query = query.where('block', isEqualTo: _selectedBlock);
        if (_selectedPanchayat != null) {
          query = query.where('panchayat', isEqualTo: _selectedPanchayat);
        }
      }
    }

    return query.snapshots().map((snapshot) => snapshot.docs.length);
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

  Stream<QuerySnapshot> _getGrievancesStream(Map<String, dynamic>? userData) {
    final user = FirebaseAuth.instance.currentUser;
    final role = (userData?['role'] as String?)?.trim().toLowerCase();
    final uid = user?.uid;
    final isPublicView = userData == null;

    if (user == null && !isPublicView) {
      return const Stream.empty();
    }

    Query grievancesCollection = FirebaseFirestore.instance.collection(
      'grievances',
    );

    if (_selectedStatusCategory != null) {
      if (_selectedStatusCategory == 'Current Owner') {
        String? expectedOwner;
        if (role == 'panchayat admin') {
          expectedOwner = 'Panchayat admin';
        } else if (role == 'block admin') {
          expectedOwner = 'Block admin';
        } else if (role == 'district admin') {
          expectedOwner = 'District admin';
        }

        if (expectedOwner != null) {
          grievancesCollection = grievancesCollection.where(
            'currentOwner',
            isEqualTo: expectedOwner,
          );
        } else {
          grievancesCollection = grievancesCollection.where(
            'currentOwner',
            isEqualTo: 'impossible_value',
          );
        }
      } else {
        List<String> statusesToQuery;
        if (_selectedStatusCategory == 'Pending') {
          statusesToQuery = ['Pending'];
        } else if (_selectedStatusCategory == 'Action Taken') {
          statusesToQuery = ['In Progress', 'Closed', 'Rejected'];
        } else {
          statusesToQuery = [_selectedStatusCategory!];
        }
        grievancesCollection = grievancesCollection.where(
          'status',
          whereIn: statusesToQuery,
        );
      }
    }

    if (isPublicView) {
      // Public view logic
    } else if (role == 'citizen') {
      return grievancesCollection.where('userId', isEqualTo: uid).snapshots();
    } else if (role == 'panchayat admin') {
      return grievancesCollection
          .where('block', isEqualTo: userData!['block'])
          .where('panchayat', isEqualTo: userData['panchayat'])
          .snapshots();
    } else if (role == 'block admin') {
      var query = grievancesCollection.where(
        'block',
        isEqualTo: (userData!['block'] as String?)?.toUpperCase(),
      );
      if (_selectedPanchayat != null) {
        query = query.where('panchayat', isEqualTo: _selectedPanchayat);
      }
      return query.snapshots();
    } else if (role == 'district admin') {
      if (_selectedBlock != null) {
        grievancesCollection = grievancesCollection.where(
          'block',
          isEqualTo: _selectedBlock,
        );
        if (_selectedPanchayat != null) {
          grievancesCollection = grievancesCollection.where(
            'panchayat',
            isEqualTo: _selectedPanchayat,
          );
        }
      }
      return grievancesCollection.snapshots();
    } else {
      return const Stream.empty();
    }
    return grievancesCollection.snapshots();
  }

  Widget _buildLocationFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedBlock,
              hint: const Text('Select Block'),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedBlock = newValue;
                  _selectedPanchayat = null;
                });
              },
              items: locationData.keys.map<DropdownMenuItem<String>>((
                String value,
              ) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedPanchayat,
              hint: const Text('Select Panchayat'),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedPanchayat = newValue;
                });
              },
              items:
                  (_selectedBlock != null
                          ? locationData[_selectedBlock]
                          : <String>[])
                      ?.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      })
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanchayatFilter(Map<String, dynamic> userData) {
    final block = (userData['block'] as String?)?.toUpperCase();
    final panchayats = block != null ? locationData[block] ?? [] : <String>[];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: _selectedPanchayat,
        hint: const Text('Select Panchayat'),
        onChanged: (String? newValue) {
          setState(() {
            _selectedPanchayat = newValue;
          });
        },
        items: panchayats.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(value: value, child: Text(value));
        }).toList(),
      ),
    );
  }
}
