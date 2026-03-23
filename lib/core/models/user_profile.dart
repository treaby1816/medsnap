import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String name;
  final String role; // 'patient' or 'pharmacy'
  final bool isVerified;
  final String? licenseNumber;
  final String? accessToken;
  final DateTime? createdAt;
  
  // Patient specific fields
  final String? insuranceProvider;
  final String? insuranceID;
  final Map<String, dynamic>? healthRecords;
  final List<String>? connectedDevices;

  UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.isVerified = false,
    this.licenseNumber,
    this.accessToken,
    this.createdAt,
    this.insuranceProvider,
    this.insuranceID,
    this.healthRecords,
    this.connectedDevices,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'patient',
      isVerified: map['isVerified'] ?? false,
      licenseNumber: map['licenseNumber'],
      accessToken: map['accessToken'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      insuranceProvider: map['insuranceProvider'],
      insuranceID: map['insuranceID'],
      healthRecords: map['healthRecords'],
      connectedDevices: map['connectedDevices'] != null 
          ? List<String>.from(map['connectedDevices']) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'isVerified': isVerified,
      'licenseNumber': licenseNumber,
      'accessToken': accessToken,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'insuranceProvider': insuranceProvider,
      'insuranceID': insuranceID,
      'healthRecords': healthRecords,
      'connectedDevices': connectedDevices,
    };
  }

  UserProfile copyWith({
    String? uid,
    String? email,
    String? name,
    String? role,
    bool? isVerified,
    String? licenseNumber,
    String? accessToken,
    DateTime? createdAt,
    String? insuranceProvider,
    String? insuranceID,
    Map<String, dynamic>? healthRecords,
    List<String>? connectedDevices,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      accessToken: accessToken ?? this.accessToken,
      createdAt: createdAt ?? this.createdAt,
      insuranceProvider: insuranceProvider ?? this.insuranceProvider,
      insuranceID: insuranceID ?? this.insuranceID,
      healthRecords: healthRecords ?? this.healthRecords,
      connectedDevices: connectedDevices ?? this.connectedDevices,
    );
  }
}
