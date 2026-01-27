import 'package:flutter/material.dart';
import 'package:panchayat_mitra/data/locations.dart';

class LocationFilter extends StatelessWidget {
  final String? selectedBlock;
  final String? selectedPanchayat;
  final ValueChanged<String?> onBlockChanged;
  final ValueChanged<String?> onPanchayatChanged;
  final bool showBlockDropdown;

  const LocationFilter({
    super.key,
    this.selectedBlock,
    this.selectedPanchayat,
    required this.onBlockChanged,
    required this.onPanchayatChanged,
    this.showBlockDropdown = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          if (showBlockDropdown) ...[
            Expanded(
              child: DropdownButtonFormField<String>(
                value: selectedBlock,
                hint: const Text('Select Block'),
                onChanged: onBlockChanged,
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
          ],
          Expanded(
            child: DropdownButtonFormField<String>(
              value: selectedPanchayat,
              hint: const Text('Select Panchayat'),
              onChanged: onPanchayatChanged,
              items:
                  (selectedBlock != null
                          ? locationData[selectedBlock]
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
}
