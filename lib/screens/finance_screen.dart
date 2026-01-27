import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:panchayat_mitra/screens/edit_finance_screen.dart';
import 'package:panchayat_mitra/screens/upload_finance_screen.dart';
import 'package:panchayat_mitra/widgets/location_filter.dart';

class FinanceScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const FinanceScreen({super.key, required this.userData});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  String? _selectedBlock;
  String? _selectedPanchayat;

  Color _getUtilizationColor(double utilization) {
    if (utilization < 25) {
      return Colors.red;
    } else if (utilization < 50) {
      return Colors.orange;
    } else if (utilization < 75) {
      return Colors.yellow;
    } else {
      return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = (widget.userData['role'] as String?)?.trim().toLowerCase();
    final userBlock = (widget.userData['block'] as String?)?.toUpperCase();
    final isPublicView = widget.userData.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Finance')),
      body: Column(
        children: [
          if (isPublicView || role == 'district admin' || role == 'super admin')
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
                      builder: (context) => const UploadFinanceScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 15,
                  ),
                ),
                child: const Text('Upload Finance Data'),
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getFinanceStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No finance data found.'));
                }

                final financeData = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: financeData.length,
                  itemBuilder: (context, index) {
                    final data =
                        financeData[index].data() as Map<String, dynamic>;
                    final tideFund = (data['tideFund'] ?? 0.0).toDouble();
                    final untideFund = (data['untideFund'] ?? 0.0).toDouble();
                    final expenditure = (data['expenditure'] ?? 0.0).toDouble();
                    final totalFund = tideFund + untideFund;
                    final utilization = totalFund > 0
                        ? (expenditure / totalFund) * 100
                        : 0.0;

                    return Card(
                      elevation: 4.0,
                      margin: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 16.0,
                      ),
                      child: ListTile(
                        title: Text(
                          data['financialYear'] ?? 'No Financial Year',
                        ),
                        subtitle: Text(
                          'Tide Fund: ₹$tideFund\nUntide Fund: ₹$untideFund\nExpenditure: ₹$expenditure\nBlock: ${data['block'] ?? 'N/A'}, Panchayat: ${data['panchayat'] ?? 'N/A'}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                              label: Text('${utilization.round()}%'),
                              backgroundColor: _getUtilizationColor(
                                utilization,
                              ),
                            ),
                            if (!isPublicView &&
                                (role == 'panchayat admin' ||
                                    role == 'district admin'))
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => EditFinanceScreen(
                                        financeId: financeData[index].id,
                                        block: data['block'] ?? '',
                                        panchayat: data['panchayat'] ?? '',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            if (!isPublicView &&
                                (role == 'panchayat admin' ||
                                    role == 'district admin'))
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('finance')
                                      .doc(financeData[index].id)
                                      .delete();
                                },
                              ),
                          ],
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

  Stream<QuerySnapshot> _getFinanceStream() {
    final role = (widget.userData['role'] as String?)?.trim().toLowerCase();
    final block = (widget.userData['block'] as String?)?.toUpperCase();
    final panchayat = (widget.userData['panchayat'] as String?)?.toUpperCase();
    final isPublicView = widget.userData.isEmpty;

    Query query = FirebaseFirestore.instance.collection('finance');

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
    } else if (isPublicView ||
        role == 'district admin' ||
        role == 'super admin') {
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
