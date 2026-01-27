import 'package:flutter/material.dart';
import 'package:panchayat_mitra/data/locations.dart';

class LocationSelector extends StatefulWidget {
  final Function(String, String) onLocationChanged;
  final String? initialBlock;
  final String? initialPanchayat;
  final bool isEnabled;

  const LocationSelector({
    super.key,
    required this.onLocationChanged,
    this.initialBlock,
    this.initialPanchayat,
    this.isEnabled = true,
  });

  @override
  State<LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  String? _selectedBlock;
  String? _selectedPanchayat;

  @override
  void initState() {
    super.initState();
    _selectedBlock = widget.initialBlock;
    _selectedPanchayat = widget.initialPanchayat;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _selectedBlock,
          hint: const Text('Select Block'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a block';
            }
            return null;
          },
          onChanged: widget.isEnabled
              ? (value) {
                  setState(() {
                    _selectedBlock = value;
                    _selectedPanchayat = null;
                  });
                }
              : null,
          items: locationData.keys.map((block) {
            return DropdownMenuItem(value: block, child: Text(block));
          }).toList(),
        ),
        const SizedBox(height: 16),
        if (_selectedBlock != null)
          DropdownButtonFormField<String>(
            value: _selectedPanchayat,
            hint: const Text('Select Panchayat'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a panchayat';
              }
              return null;
            },
            onChanged: widget.isEnabled
                ? (value) {
                    setState(() {
                      _selectedPanchayat = value;
                      if (_selectedBlock != null &&
                          _selectedPanchayat != null) {
                        widget.onLocationChanged(
                          _selectedBlock!,
                          _selectedPanchayat!,
                        );
                      }
                    });
                  }
                : null,
            items: locationData[_selectedBlock]!.map((panchayat) {
              return DropdownMenuItem(value: panchayat, child: Text(panchayat));
            }).toList(),
          ),
      ],
    );
  }
}
