import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DrugDetailsScreen extends StatelessWidget {
  final String brand;
  final String name;
  final String info;
  final String price;
  final String imageUrl;

  const DrugDetailsScreen({
    super.key,
    required this.brand,
    required this.name,
    required this.info,
    required this.price,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFEC5B13);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  Center(
                    child: Container(
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: Icon(Icons.medication, size: 100, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Title and Price
                  Text(brand, style: GoogleFonts.inter(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(name, style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold)),
                      ),
                      Text("₦$price", style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor)),
                    ],
                  ),
                  Text(info, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                  
                  const SizedBox(height: 32),
                  
                  // Description Section
                  const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    "This medication is a penicillin-type antibiotic used to treat a wide variety of bacterial infections. It works by stopping the growth of bacteria.",
                    style: TextStyle(color: Colors.grey.shade700, height: 1.5),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Dosage Info
                  _buildInfoTile(Icons.info_outline, "Dosage", "Take one capsule twice daily after meals."),
                  _buildInfoTile(Icons.warning_amber_rounded, "Side Effects", "May cause drowsiness or mild nausea."),
                ],
              ),
            ),
          ),
          
          // Bottom Bar (Add to Cart)
          _buildBottomAction(primaryColor),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(sub, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBottomAction(Color primary) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shopping_bag_outlined),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Add to Cart', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}