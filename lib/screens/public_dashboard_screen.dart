import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:panchayat_mitra/screens/assets_screen.dart';
import 'package:panchayat_mitra/screens/finance_screen.dart';
import 'package:panchayat_mitra/screens/activities_screen.dart';
import 'package:panchayat_mitra/screens/grievances_screen.dart';
import 'package:panchayat_mitra/screens/kyp_screen.dart';
import 'package:panchayat_mitra/screens/model_screen.dart';
import 'package:panchayat_mitra/screens/osr_screen.dart';
import 'package:panchayat_mitra/screens/schemes_screen.dart';

class PublicDashboardScreen extends StatefulWidget {
  const PublicDashboardScreen({super.key});

  @override
  State<PublicDashboardScreen> createState() => _PublicDashboardScreenState();
}

class _PublicDashboardScreenState extends State<PublicDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Public Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('grievances')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Something went wrong'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Card(
                  elevation: 4.0,
                  color: Colors.pink[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Grievance Redressal',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16.0),
                        const Text("No grievances found."),
                      ],
                    ),
                  ),
                );
              }

              int pendingCount = 0;
              int actionTakenCount = 0;

              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                if (data.containsKey('status')) {
                  if (doc['status'] == 'Pending') {
                    pendingCount++;
                  } else if (doc['status'] == 'In Progress' ||
                      doc['status'] == 'Closed' ||
                      doc['status'] == 'Rejected') {
                    actionTakenCount++;
                  }
                }
              }

              return Card(
                elevation: 4.0,
                color: Colors.pink[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grievance Redressal',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildCountColumn('Pending', pendingCount),
                          _buildCountColumn('Action Taken', actionTakenCount),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16.0),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
            ),
            itemCount: _getGridItems().length,
            itemBuilder: (context, index) {
              final item = _getGridItems()[index];
              return StreamBuilder<int>(
                stream: _buildCountStream(item['collectionName'] as String),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error'));
                  }
                  return Card(
                    elevation: 4.0,
                    color: item['color'] as Color,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => item['screen'] as Widget,
                          ),
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            snapshot.data.toString(),
                            style: const TextStyle(
                              fontSize: 48.0,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            item['label'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Stream<int> _buildCountStream(String collectionName) {
    Query query = FirebaseFirestore.instance.collection(collectionName);
    if (collectionName == 'model_answers') {
      query = query.where('isApproved', isEqualTo: true);
    }
    return query.snapshots().map((snapshot) => snapshot.docs.length);
  }

  Widget _buildCountColumn(String title, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(title),
      ],
    );
  }

  List<Map<String, dynamic>> _getGridItems() {
    return [
      {
        'icon': Icons.business,
        'label': 'Assets',
        'screen': const AssetsScreen(userData: {}),
        'color': Colors.blue,
        'collectionName': 'assets',
      },
      {
        'text_icon': '₹',
        'label': '15th Finance',
        'screen': const FinanceScreen(userData: {}),
        'color': Colors.green,
        'collectionName': 'finance',
      },
      {
        'icon': Icons.account_balance,
        'label': 'Schemes',
        'screen': const SchemesScreen(userData: {}),
        'color': Colors.orange,
        'collectionName': 'schemes',
      },
      {
        'icon': Icons.receipt,
        'label': 'OSR',
        'screen': const OsrScreen(userData: {}),
        'color': Colors.purple,
        'collectionName': 'osr',
      },
      {
        'icon': Icons.home_work,
        'label': 'MODEL',
        'screen': const ModelScreen(userData: {}, isPublic: true),
        'color': Colors.red,
        'collectionName': 'model_answers',
      },
      {
        'icon': Icons.local_activity,
        'label': 'Activities',
        'screen': const ActivitiesScreen(userData: {}),
        'color': Colors.amber,
        'collectionName': 'activities',
      },
      {
        'icon': Icons.info,
        'label': 'KYP',
        'screen': const KypScreen(userData: {}),
        'color': Colors.indigo,
        'collectionName': 'kyp',
      },
    ];
  }
}
