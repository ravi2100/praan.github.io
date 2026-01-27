import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:panchayat_mitra/screens/add_grievance_screen.dart';
import 'package:panchayat_mitra/screens/assets_screen.dart';
import 'package:panchayat_mitra/screens/finance_screen.dart';
import 'package:panchayat_mitra/screens/activities_screen.dart';
import 'package:panchayat_mitra/screens/grievances_screen.dart';
import 'package:panchayat_mitra/screens/kyp_screen.dart';
import 'package:panchayat_mitra/screens/model_screen.dart';
import 'package:panchayat_mitra/screens/osr_screen.dart';
import 'package:panchayat_mitra/screens/schemes_screen.dart';
import 'package:panchayat_mitra/screens/register_screen.dart';
import 'package:panchayat_mitra/auth_gate.dart';
import 'package:panchayat_mitra/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('User data not found.'));
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>;
                final role = userData['role'] ?? 'No role';
                final email = user.email ?? 'No email';
                final block = userData['block'] ?? '';
                final panchayat = userData['panchayat'] ?? '';

                return Scaffold(
                  appBar: AppBar(
                    title: Text('PRAANPAKUR', style: GoogleFonts.notoSans()),
                    actions: [
                      if (role == 'District admin')
                        IconButton(
                          icon: const Icon(Icons.person_add),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(
                                  userRole: 'District admin',
                                ),
                              ),
                            );
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.account_circle),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProfileScreen(userData: userData),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const AuthGate(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  body: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Text('Welcome, $email ($role)'),
                            if (role == 'Panchayat Admin' ||
                                role == 'Citizen') ...[
                              const SizedBox(height: 8.0),
                              Text('Block: $block'),
                              Text('Panchayat: $panchayat'),
                            ],
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(16.0),
                          children: [
                            Card(
                              elevation: 4.0,
                              color: Colors.pink[50],
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Grievance Redressal',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 8.0),
                                    Text(
                                      'Submit your complaints and track their status.',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 16.0),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    GrievancesScreen(
                                                      userData: userData,
                                                    ),
                                              ),
                                            );
                                          },
                                          child: const Text('View Grievances'),
                                        ),
                                        const SizedBox(width: 8.0),
                                        if (role != 'Block Admin')
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const AddGrievanceScreen(),
                                                ),
                                              );
                                            },
                                            child: const Text('Add Grievance'),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 16.0,
                                    mainAxisSpacing: 16.0,
                                  ),
                              itemCount: _getGridItems(userData).length,
                              itemBuilder: (context, index) {
                                final item = _getGridItems(userData)[index];
                                return Card(
                                  elevation: 4.0,
                                  color: item['color'] as Color,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              item['screen'] as Widget,
                                        ),
                                      );
                                    },
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (item.containsKey('icon'))
                                          Icon(
                                            item['icon'] as IconData,
                                            size: 48.0,
                                            color: Colors.white,
                                          )
                                        else if (item.containsKey('text_icon'))
                                          Text(
                                            item['text_icon'] as String,
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
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  List<Map<String, dynamic>> _getGridItems(Map<String, dynamic> userData) {
    return [
      {
        'icon': Icons.business,
        'label': 'Assets',
        'screen': AssetsScreen(userData: userData),
        'color': Colors.blue,
      },
      {
        'text_icon': '₹',
        'label': '15th Finance',
        'screen': FinanceScreen(userData: userData),
        'color': Colors.green,
      },
      {
        'icon': Icons.account_balance,
        'label': 'Schemes',
        'screen': SchemesScreen(userData: userData),
        'color': Colors.orange,
      },
      {
        'icon': Icons.receipt,
        'label': 'OSR',
        'screen': OsrScreen(userData: userData),
        'color': Colors.purple,
      },
      {
        'icon': Icons.home_work,
        'label': 'MODEL',
        'screen': ModelScreen(userData: userData),
        'color': Colors.red,
      },
      {
        'icon': Icons.local_activity,
        'label': 'Activities',
        'screen': ActivitiesScreen(userData: userData),
        'color': Colors.amber,
      },
      {
        'icon': Icons.info,
        'label': 'KYP',
        'screen': KypScreen(userData: userData),
        'color': Colors.indigo,
      },
    ];
  }
}
