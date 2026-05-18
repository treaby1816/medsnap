import 'package:supabase_flutter/supabase_flutter.dart';

class JobService {
  final _supabase = Supabase.instance.client;

  // STREAM: Get all jobs for the Patient Dashboard / Job Board
  Stream<List<Map<String, dynamic>>> getJobsStream() {
    return _supabase.from('jobs')
        .stream(primaryKey: ['id'])
        .order('createdAt', ascending: false);
  }

  // ACTION: Post a new job (For Pharmacy side)
  Future<void> postJob({
    required String pharmacyName,
    required String role,
    required String location,
    required String salaryRange,
    required String contactEmail,
  }) async {
    await _supabase.from('jobs').insert({
      'pharmacyName': pharmacyName,
      'role': role,
      'location': location,
      'salaryRange': salaryRange,
      'contactEmail': contactEmail,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
}
