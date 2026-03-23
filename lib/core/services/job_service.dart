import 'package:cloud_firestore/cloud_firestore.dart';

class JobService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // STREAM: Get all jobs for the Patient Dashboard / Job Board
  Stream<QuerySnapshot> getJobsStream() {
    return _db.collection('jobs')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ACTION: Post a new job (For Pharmacy side)
  Future<void> postJob({
    required String pharmacyName,
    required String role,
    required String location,
    required String salaryRange,
    required String contactEmail,
  }) async {
    await _db.collection('jobs').add({
      'pharmacyName': pharmacyName,
      'role': role,
      'location': location,
      'salaryRange': salaryRange,
      'contactEmail': contactEmail,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}