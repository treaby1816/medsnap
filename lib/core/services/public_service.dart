import 'package:cloud_firestore/cloud_firestore.dart';

class AdModel {
  final String id;
  final String imageUrl;
  final String title;
  final String linkUrl;
  final int priority; // Added for sorting

  AdModel({
    required this.id, 
    required this.imageUrl, 
    required this.title, 
    this.linkUrl = "",
    this.priority = 0,
  });

  factory AdModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdModel(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? "",
      title: data['title'] ?? "Special Offer",
      linkUrl: data['linkUrl'] ?? "",
      priority: data['priority'] ?? 0,
    );
  }
}

class JobModel {
  final String id;
  final String role;
  final String pharmacyName;
  final String salary;
  final String location;
  final String contactEmail; // Crucial for the Apply button

  JobModel({
    required this.id, 
    required this.role, 
    required this.pharmacyName, 
    required this.salary, 
    required this.location,
    required this.contactEmail,
  });

  factory JobModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JobModel(
      id: doc.id,
      role: data['role'] ?? "Pharmacist",
      pharmacyName: data['pharmacyName'] ?? "Vail Pharmacy",
      salary: data['salaryRange'] ?? data['salary'] ?? "Negotiable", // Handles both field names
      location: data['location'] ?? "Lagos",
      contactEmail: data['contactEmail'] ?? "",
    );
  }
}

class PublicService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream for Ads - Now sorted by Priority
  Stream<List<AdModel>> getAds() {
    return _db
        .collection('advertisements') // Matching your collection name
        .orderBy('priority', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AdModel.fromFirestore(doc)).toList());
  }

  // Stream for Jobs - Sorted by newest first
  Stream<List<JobModel>> getJobs() {
    return _db
        .collection('jobs')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => JobModel.fromFirestore(doc)).toList());
  }

  // Global Med Search (Connects Pharmacy Data to Patients)
  Stream<QuerySnapshot> searchMedications(String query) {
    if (query.isEmpty) {
      return _db.collection('products').limit(15).snapshots();
    }
    
    String searchKey = query.toLowerCase().trim();
    
    return _db.collection('products')
        .where('nameLower', isGreaterThanOrEqualTo: searchKey)
        .where('nameLower', isLessThanOrEqualTo: '$searchKey\uf8ff')
        .snapshots();
  }
}
