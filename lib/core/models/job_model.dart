// Supabase returns timestamps as strings
class JobModel {
  final String id;
  final String pharmacyId;
  final String pharmacyName;
  final String title;
  final String description;
  final String location;
  final double salary;
  final DateTime createdAt;

  JobModel({
    required this.id,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.title,
    required this.description,
    required this.location,
    required this.salary,
    required this.createdAt,
  });

  factory JobModel.fromMap(Map<String, dynamic> map, String documentId) {
    return JobModel(
      id: documentId,
      pharmacyId: map['pharmacyId'] ?? '',
      pharmacyName: map['pharmacyName'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      salary: (map['salary'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['createdAt'] != null ? (map['createdAt'] is String ? DateTime.parse(map['createdAt']) : map['createdAt'] as DateTime) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'title': title,
      'description': description,
      'location': location,
      'salary': salary,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
