import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String department;
  final String? profileImageUrl;
  final DateTime createdAt;
  final bool isAdmin;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.department,
    this.profileImageUrl,
    required this.createdAt,
    this.isAdmin = false,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      userId: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      department: data['department'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isAdmin: data['isAdmin'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'department': department,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'isAdmin': isAdmin,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? department,
    String? profileImageUrl,
    bool? isAdmin,
  }) {
    return UserModel(
      userId: userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
