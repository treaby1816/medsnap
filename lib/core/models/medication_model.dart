class Medication {
  final String id;
  final String name;
  final String brand;
  final double price;
  final String category;
  final bool isAvailable;
  final String imagePath;
  final int stockCount;
  final bool isUrgent;

  Medication({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.category,
    required this.isAvailable,
    this.imagePath = '',
    this.stockCount = 0,
    this.isUrgent = false,
  });

  // Convert Firestore Document to Medication Object
  factory Medication.fromFirestore(Map<String, dynamic> data, String id) {
    return Medication(
      id: id,
      name: data['name'] ?? '',
      brand: data['brand'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      category: data['category'] ?? 'General',
      isAvailable: data['isAvailable'] ?? false,
      imagePath: data['imagePath'] ?? '',
      stockCount: data['stockCount'] ?? 0,
      isUrgent: data['isUrgent'] ?? false,
    );
  }
}
