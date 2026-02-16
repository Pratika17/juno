import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String chatId;
  final String itemId;
  final List<String> participants;
  final Map<String, String> participantNames;
  final String lastMessage;
  final DateTime lastMessageTime;
  final DateTime createdAt;

  ChatModel({
    required this.chatId,
    required this.itemId,
    required this.participants,
    required this.participantNames,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.createdAt,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      chatId: doc.id,
      itemId: data['itemId'] ?? '',
      participants: List<String>.from(data['participants'] ?? []),
      participantNames: Map<String, String>.from(
        data['participantNames'] ?? {},
      ),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'itemId': itemId,
      'participants': participants,
      'participantNames': participantNames,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
