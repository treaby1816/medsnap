import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';

class PharmacyInventoryScreen extends StatefulWidget {
  const PharmacyInventoryScreen({super.key});

  @override
  State<PharmacyInventoryScreen> createState() => _PharmacyInventoryScreenState();
}

class _PharmacyInventoryScreenState extends State<PharmacyInventoryScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();

  void _addMedication() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Add Medication", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Medication Name", hintText: "e.g. Paracetamol"),
            ),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: "Price (₦)"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _stockController,
              decoration: const InputDecoration(labelText: "Stock Quantity"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            onPressed: () async {
              if (_nameController.text.isNotEmpty) {
                // P1 Fix: Ensuring data consistency with nameLower for searching
                await FirebaseFirestore.instance.collection('inventory').add({
                  'name': _nameController.text,
                  'nameLower': _nameController.text.toLowerCase(),
                  'price': double.tryParse(_priceController.text) ?? 0.0,
                  'stock': int.tryParse(_stockController.text) ?? 0,
                  'lastUpdated': FieldValue.serverTimestamp(),
                });

                _nameController.clear();
                _priceController.clear();
                _stockController.clear();

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              }
            },
            child: const Text("Add Product", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editStock(String docId, String currentName, int currentStock) {
    final TextEditingController editController = TextEditingController(text: currentStock.toString());
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text("Update Stock: $currentName"),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(labelText: "New Stock Quantity"),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('inventory').doc(docId).update({
                'stock': int.tryParse(editController.text) ?? currentStock,
                'lastUpdated': FieldValue.serverTimestamp(),
              });

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text("Update", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text("Inventory Management", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor, size: 28),
            onPressed: _addMedication,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('inventory').orderBy('name').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error loading inventory"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text("No items in inventory", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String name = data['name'] ?? 'Unknown';
              final int stock = (data['stock'] ?? 0).toInt();
              final double price = (data['price'] ?? 0.0).toDouble();
              final bool lowStock = stock < 5;

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: lowStock 
                          ? Colors.red.withValues(alpha: 0.1) 
                          : AppTheme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.medication_liquid, 
                      color: lowStock ? Colors.red : AppTheme.primaryColor
                    ),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Text("₦${price.toStringAsFixed(2)}", 
                          style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: lowStock ? Colors.red[50] : Colors.green[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "Stock: $stock",
                            style: TextStyle(
                              fontSize: 12,
                              color: lowStock ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_note, color: Colors.blueGrey),
                    onPressed: () => _editStock(docs[index].id, name, stock),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
