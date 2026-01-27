import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:panchayat_mitra/widgets/location_selector.dart';

class UploadFinanceScreen extends StatefulWidget {
  const UploadFinanceScreen({super.key});

  @override
  State<UploadFinanceScreen> createState() => _UploadFinanceScreenState();
}

class _UploadFinanceScreenState extends State<UploadFinanceScreen> {
  final _financialYearController = TextEditingController();
  final _tideFundController = TextEditingController();
  final _untideFundController = TextEditingController();
  final _expenditureController = TextEditingController();
  bool _isLoading = false;
  String? _selectedBlock;
  String? _selectedPenditureController;
  Map<String, dynamic>? _userData;
  String? _selectedPanchayat;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        _userData = userDoc.data();
        _selectedBlock = _userData?['block'];
        _selectedPanchayat = _userData?['panchayat'];
      });
    }
  }

  Future<void> _uploadFinanceData() async {
    if (_financialYearController.text.isEmpty ||
        _tideFundController.text.isEmpty ||
        _untideFundController.text.isEmpty ||
        _expenditureController.text.isEmpty ||
        _selectedBlock == null ||
        _selectedPanchayat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and select a location'),
        ),
      );
      return;
    }

    final tideFund = double.tryParse(_tideFundController.text) ?? 0.0;
    final untideFund = double.tryParse(_untideFundController.text) ?? 0.0;
    final expenditure = double.tryParse(_expenditureController.text) ?? 0.0;

    if (expenditure > (tideFund + untideFund)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Expenditure cannot be greater than the sum of Tide and Untide funds.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('finance').add({
        'financialYear': _financialYearController.text,
        'tideFund': double.parse(_tideFundController.text),
        'untideFund': double.parse(_untideFundController.text),
        'expenditure': double.parse(_expenditureController.text),
        'block': _selectedBlock,
        'panchayat': _selectedPanchayat,
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload finance data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Padding(
          padding: EdgeInsets.only(top: 20.0),
          child: Text('Upload 15th Finance Data'),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              TextField(
                controller: _financialYearController,
                decoration: const InputDecoration(labelText: 'Financial Year'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _tideFundController,
                decoration: const InputDecoration(labelText: 'Tide Fund (₹)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _untideFundController,
                decoration: const InputDecoration(labelText: 'Untide Fund (₹)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _expenditureController,
                decoration: const InputDecoration(labelText: 'Expenditure (₹)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              if (_userData != null)
                LocationSelector(
                  initialBlock: _userData!['block'],
                  initialPanchayat: _userData!['panchayat'],
                  onLocationChanged: (block, panchayat) {
                    setState(() {
                      _selectedBlock = block;
                      _selectedPanchayat = panchayat;
                    });
                  },
                  isEnabled: false,
                ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _uploadFinanceData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 15,
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        )
                      : const Text('Upload Data'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
