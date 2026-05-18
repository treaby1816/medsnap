// Supabase returns timestamps as strings
class UserProfile {
  final String uid;
  final String email;
  final String name; 
  final String? displayName; // Prefer this over 'name'
  final String? photoUrl;
  final String? bio;
  final String? phone;
  final String role; // 'patient' or 'pharmacy'
  final bool isVerified;
  final String? licenseNumber;
  final String? licensePhotoUrl;
  final String? accessToken;
  final DateTime? createdAt;
  
  // Patient specific fields
  final String? insuranceProvider;
  final String? insuranceID;
  final Map<String, dynamic>? healthRecords;
  final List<String>? connectedDevices;

  // Pharmacy specific fields
  final String? storeName;
  final String? storeFrontImageUrl;
  final String? storeInsideImageUrl;
  final String? npiNumber;
  final bool isAdminApproved;
  final String verificationStatus; // 'none', 'pending', 'approved', 'rejected'
  
  // Location Fields
  final double? latitude;
  final double? longitude;

  bool get isVerificationPending => verificationStatus == 'pending';
  bool get isAdmin => role == 'admin';

  UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    this.displayName,
    this.photoUrl,
    this.bio,
    this.phone,
    required this.role,
    this.isVerified = false,
    this.licenseNumber,
    this.licensePhotoUrl,
    this.accessToken,
    this.createdAt,
    this.insuranceProvider,
    this.insuranceID,
    this.healthRecords,
    this.connectedDevices,
    this.storeName,
    this.storeFrontImageUrl,
    this.storeInsideImageUrl,
    this.npiNumber,
    this.isAdminApproved = false,
    this.verificationStatus = 'none',
    this.latitude,
    this.longitude,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, [String? uid]) {
    return UserProfile(
      uid: uid ?? map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? map['displayName'] ?? '',
      displayName: map['displayName'] ?? map['name'],
      photoUrl: map['photoUrl'],
      bio: map['bio'],
      phone: map['phone'],
      role: map['role'] ?? 'patient',
      isVerified: map['isVerified'] ?? false,
      licenseNumber: map['licenseNumber'],
      licensePhotoUrl: map['licensePhotoUrl'],
      accessToken: map['accessToken'],
      createdAt: map['createdAt'] != null ? (map['createdAt'] is String ? DateTime.parse(map['createdAt']) : map['createdAt'] as DateTime?) : null,
      insuranceProvider: map['insuranceProvider'],
      insuranceID: map['insuranceID'],
      healthRecords: map['healthRecords'],
      connectedDevices: map['connectedDevices'] != null 
          ? List<String>.from(map['connectedDevices']) 
          : null,
      storeName: map['storeName'],
      storeFrontImageUrl: map['storeFrontImageUrl'],
      storeInsideImageUrl: map['storeInsideImageUrl'],
      npiNumber: map['npiNumber'],
      isAdminApproved: map['isAdminApproved'] ?? false,
      verificationStatus: map['verificationStatus'] ?? 'none',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'displayName': displayName ?? name,
      'photoUrl': photoUrl,
      'bio': bio,
      'phone': phone,
      'role': role,
      'isVerified': isVerified,
      'licenseNumber': licenseNumber,
      'licensePhotoUrl': licensePhotoUrl,
      'accessToken': accessToken,
      'createdAt': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'insuranceProvider': insuranceProvider,
      'insuranceID': insuranceID,
      'healthRecords': healthRecords,
      'connectedDevices': connectedDevices,
      'storeName': storeName,
      'storeFrontImageUrl': storeFrontImageUrl,
      'storeInsideImageUrl': storeInsideImageUrl,
      'npiNumber': npiNumber,
      'isAdminApproved': isAdminApproved,
      'verificationStatus': verificationStatus,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  UserProfile copyWith({
    String? uid,
    String? email,
    String? name,
    String? displayName,
    String? photoUrl,
    String? bio,
    String? phone,
    String? role,
    bool? isVerified,
    String? licenseNumber,
    String? licensePhotoUrl,
    String? accessToken,
    DateTime? createdAt,
    String? insuranceProvider,
    String? insuranceID,
    Map<String, dynamic>? healthRecords,
    List<String>? connectedDevices,
    String? storeName,
    String? storeFrontImageUrl,
    String? storeInsideImageUrl,
    String? npiNumber,
    bool? isAdminApproved,
    String? verificationStatus,
    double? latitude,
    double? longitude,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licensePhotoUrl: licensePhotoUrl ?? this.licensePhotoUrl,
      accessToken: accessToken ?? this.accessToken,
      createdAt: createdAt ?? this.createdAt,
      insuranceProvider: insuranceProvider ?? this.insuranceProvider,
      insuranceID: insuranceID ?? this.insuranceID,
      healthRecords: healthRecords ?? this.healthRecords,
      connectedDevices: connectedDevices ?? this.connectedDevices,
      storeName: storeName ?? this.storeName,
      storeFrontImageUrl: storeFrontImageUrl ?? this.storeFrontImageUrl,
      storeInsideImageUrl: storeInsideImageUrl ?? this.storeInsideImageUrl,
      npiNumber: npiNumber ?? this.npiNumber,
      isAdminApproved: isAdminApproved ?? this.isAdminApproved,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
