import 'package:supabase_flutter/supabase_flutter.dart';

class AdModel {
  final String id;
  final String imageUrl;
  final String title;
  final String linkUrl;
  final int priority;

  AdModel({
    required this.id, 
    required this.imageUrl, 
    required this.title, 
    this.linkUrl = "",
    this.priority = 0,
  });

  factory AdModel.fromMap(Map<String, dynamic> data, String id) {
    return AdModel(
      id: id,
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
  final String contactEmail;

  JobModel({
    required this.id, 
    required this.role, 
    required this.pharmacyName, 
    required this.salary, 
    required this.location,
    required this.contactEmail,
  });

  factory JobModel.fromMap(Map<String, dynamic> data, String id) {
    return JobModel(
      id: id,
      role: data['role'] ?? "Pharmacist",
      pharmacyName: data['pharmacyName'] ?? "Vail Pharmacy",
      salary: data['salaryRange'] ?? data['salary'] ?? "Negotiable",
      location: data['location'] ?? "Lagos",
      contactEmail: data['contactEmail'] ?? "",
    );
  }
}

class PublicService {
  final _supabase = Supabase.instance.client;

  Stream<List<AdModel>> getAds() {
    return _supabase
        .from('advertisements')
        .stream(primaryKey: ['id'])
        .order('priority', ascending: true)
        .map((maps) => maps.map((doc) => AdModel.fromMap(doc, doc['id'].toString())).toList());
  }

  Stream<List<JobModel>> getJobs() {
    return _supabase
        .from('jobs')
        .stream(primaryKey: ['id'])
        .order('createdAt', ascending: false)
        .map((maps) => maps.map((doc) => JobModel.fromMap(doc, doc['id'].toString())).toList());
  }

  Stream<List<Map<String, dynamic>>> searchMedications(String query) {
    if (query.isEmpty) {
      return _supabase.from('products').stream(primaryKey: ['id']).limit(15);
    }
    
    String searchKey = query.toLowerCase().trim();
    
    return _supabase.from('products').stream(primaryKey: ['id']).map((list) {
      return list.where((p) {
        final name = (p['name'] as String? ?? '').toLowerCase();
        return name.contains(searchKey);
      }).toList();
    });
  }
}
