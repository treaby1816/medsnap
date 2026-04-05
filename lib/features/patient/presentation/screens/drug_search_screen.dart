import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'drug_details_screen.dart'; // Ensure this import matches your file path
import '../../../../widgets/hover_card.dart';

class DrugSearchScreen extends StatefulWidget {
  const DrugSearchScreen({super.key});

  @override
  State<DrugSearchScreen> createState() => _DrugSearchScreenState();
}

class _DrugSearchScreenState extends State<DrugSearchScreen> {
  final TextEditingController _searchController = TextEditingController(text: "Amoxicillin");
  final Color primaryColor = const Color(0xFFEC5B13);
  bool _showSuggestions = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              _buildSearchHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildSectionHeader("Categories", "See All"),
                      const SizedBox(height: 12),
                      _buildCategoryRow(),
                      const SizedBox(height: 32),
                      _buildSectionHeader("Search Results (12)", "Sort", icon: Icons.filter_list),
                      const SizedBox(height: 16),
                      
                      // Updated calls to pass data to the card
                      _buildDrugCard("GSK PHARMA", "Amoxicillin 500mg", "15 Capsules • Antibiotic", "14,500", true),
                      _buildDrugCard("AUROBINDO", "Amoxicillin Oral Susp.", "100ml • Mixed Berry", "22,900", true),
                      _buildDrugCard("SANDOZ", "Amox-Clav 875/125", "20 Tablets • Dual Action", "31,000", false),
                      
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_showSuggestions) _buildSuggestionsOverlay(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.menu, color: primaryColor),
        onPressed: () {},
      ),
      centerTitle: true,
      title: Text('VailMeds', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold)),
      actions: [
        IconButton(
          icon: const Icon(Icons.account_circle, color: Colors.black, size: 30),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [primaryColor.withValues(alpha: 0.05), Colors.white],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Find your medication', 
            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildSearchField(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      child: TextField(
        controller: _searchController,
        onTap: () => setState(() => _showSuggestions = true),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          hintText: "Search by drug name or brand...",
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildSuggestionsOverlay() {
    return Positioned(
      top: 135, left: 20, right: 20,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              _suggestionTile("Amoxicillin 500mg", "Antibiotic • Capsules"),
              _suggestionTile("Amoxicillin/Clavulanate", "Antibiotic • Tablets"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _suggestionTile(String title, String sub) {
    return ListTile(
      leading: Icon(Icons.medication, color: primaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
      onTap: () => setState(() => _showSuggestions = false),
    );
  }

  Widget _buildDrugCard(String brand, String name, String info, String price, bool inStock) {
    return HoverCard(
      onTap: inStock ? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DrugDetailsScreen(
              brand: brand,
              name: name,
              info: info,
              price: price,
              imageUrl: 'https://via.placeholder.com/300', // Placeholder
            ),
          ),
        );
      } : null,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(12),
      child: Opacity(
        opacity: inStock ? 1.0 : 0.6,
        child: Row(
          children: [
            _buildProductImage(inStock),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(brand, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 10)),
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(info, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("₦$price", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      _buildStatusChip(inStock),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool inStock) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: inStock ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        inStock ? 'IN STOCK' : 'OUT OF STOCK',
        style: TextStyle(
          color: inStock ? Colors.green : Colors.grey,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProductImage(bool inStock) {
    return Container(
      width: 85, height: 85,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          const Center(child: Icon(Icons.medication_outlined, color: Colors.grey)),
          Positioned(
            top: 4, left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: inStock ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(inStock ? 'IN STOCK' : 'OUT OF STOCK', 
                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action, {IconData? icon}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        TextButton.icon(
          onPressed: () {},
          icon: icon != null ? Icon(icon, size: 16, color: Colors.grey) : const SizedBox.shrink(),
          label: Text(action, style: TextStyle(color: icon != null ? Colors.grey : primaryColor)),
        )
      ],
    );
  }

  Widget _buildCategoryRow() {
    return const SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          CategoryChip(label: "All", selected: true),
          CategoryChip(label: "Pain Relief", selected: false, icon: Icons.medical_services),
          CategoryChip(label: "Antibiotics", selected: false, icon: Icons.coronavirus),
        ],
      ),
    );
  }
}

class CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;

  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFEC5B13);
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? primary : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? primary : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          if (icon != null) Icon(icon, size: 16, color: selected ? Colors.white : primary),
          if (icon != null) const SizedBox(width: 8),
          Text(label, style: TextStyle(color: selected ? Colors.white : Colors.black, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
