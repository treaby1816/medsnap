import 'package:flutter/material.dart';
import '../../../../core/theme.dart';

class MedicationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> drug;
  const MedicationDetailScreen({super.key, required this.drug});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(drug['name'] ?? 'Medication')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.medication, size: 80, color: AppTheme.primaryColor),
            const SizedBox(height: 20),
            Text(drug['name'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(drug['category'] ?? 'General', style: const TextStyle(color: Colors.grey)),
            // Add more details like price, dosage, etc.
          ],
        ),
      ),
    );
  }
}