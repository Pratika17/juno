import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class ItemModel {
  final String itemId;
  final String userId;
  final String userName;
  final String userContact;
  final String title;
  final String description;
  final ItemCategory category;
  final ItemType itemType;
  final String imageUrl;
  final String location;
  final DateTime date;
  final ItemStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> reportedBy;
  final double? latitude;
  final double? longitude;

  ItemModel({
    required this.itemId,
    required this.userId,
    required this.userName,
    required this.userContact,
    required this.title,
    required this.description,
    required this.category,
    required this.itemType,
    required this.imageUrl,
    required this.location,
    required this.date,
    this.status = ItemStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.reportedBy = const [],
    this.latitude,
    this.longitude,
  });

  factory ItemModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ItemModel(
      itemId: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userContact: data['userContact'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: ItemCategory.values.firstWhere(
        (e) => e.toString() == 'ItemCategory.${data['category']}',
        orElse: () => ItemCategory.other,
      ),
      itemType: ItemType.values.firstWhere(
        (e) => e.toString() == 'ItemType.${data['itemType']}',
        orElse: () => ItemType.lost,
      ),
      imageUrl: data['imageUrl'] ?? '',
      location: data['location'] ?? '',
      date: data['date'] is Timestamp
          ? (data['date'] as Timestamp).toDate()
          : DateTime.now(),
      status: ItemStatus.values.firstWhere(
        (e) => e.toString() == 'ItemStatus.${data['status']}',
        orElse: () => ItemStatus.active,
      ),
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      reportedBy: List<String>.from(data['reportedBy'] ?? []),
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userContact': userContact,
      'title': title,
      'description': description,
      'category': category.toString().split('.').last,
      'itemType': itemType.toString().split('.').last,
      'imageUrl': imageUrl,
      'location': location,
      'date': Timestamp.fromDate(date),
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'reportedBy': reportedBy,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  ItemModel copyWith({
    String? title,
    String? description,
    ItemCategory? category,
    ItemType? itemType,
    String? imageUrl,
    String? location,
    DateTime? date,
    ItemStatus? status,
    List<String>? reportedBy,
    double? latitude,
    double? longitude,
  }) {
    return ItemModel(
      itemId: itemId,
      userId: userId,
      userName: userName,
      userContact: userContact,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      itemType: itemType ?? this.itemType,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      date: date ?? this.date,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      reportedBy: reportedBy ?? this.reportedBy,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
