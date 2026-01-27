import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditFinanceScreen extends StatefulWidget {
  final String financeId;
  final String block;
  final String panchayat;

  const EditFinanceScreen({
    super.key,
    required this.financeId,
    required this.block,
    required this.panchayat,
  });

  @override
  State<EditFinanceScreen> createState() => _EditFinanceScreenState();
}

class _EditFinanceScreenState extends State<EditFinanceScreen> {
  late TextEditingController _financialYearController;
  late TextEditingController _tideFundController;
  late TextEditingController _untideFundController;
  late TextEditingController _expenditureController;
  bool _isLoading = false;
  String? _selectedBlock;
  String? _selectedPanchayat;

  @override
  void initState() {
    super.initState();
    _financialYearController = TextEditingController();
    _tideFundController = TextEditingController();
    _untideFundController = TextEditingController();
    _expenditureController = TextEditingController();
    _selectedBlock = widget.block;
    _selectedPanchayat = widget.panchayat;
    _fetchFinanceData();
  }

  Future<void> _fetchFinanceData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('finance')
          .doc(widget.financeId)
          .get();
      final data = doc.data();
      if (data != null) {
        setState(() {
          _financialYearController.text = data['financialYear'] ?? '';
          _tideFundController.text = data['tideFund']?.toString() ?? '';
          _untideFundController.text = data['untideFund']?.toString() ?? '';
          _expenditureController.text = data['expenditure']?.toString() ?? '';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to fetch data: $e')));
    }
  }

  Future<void> _updateFinanceData() async {
    if (_financialYearController.text.isEmpty ||
        _tideFundController.text.isEmpty ||
        _untideFundController.text.isEmpty ||
        _expenditureController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
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
      await FirebaseFirestore.instance
          .collection('finance')
          .doc(widget.financeId)
          .update({
            'financialYear': _financialYearController.text,
            'tideFund': double.parse(_tideFundController.text),
            'untideFund': double.parse(_untideFundController.text),
            'expenditure': double.parse(_expenditureController.text),
          });

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update finance data: $e')),
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
      appBar: AppBar(title: const Text('Edit 15th Finance Data')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
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
              Text('Block: $_selectedBlock'),
              const SizedBox(height: 8),
              Text('Panchayat: $_selectedPanchayat'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateFinanceData,
                child: _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Text('Update Data'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
