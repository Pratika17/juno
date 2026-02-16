import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/item_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../utils/constants.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection References
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _itemsCollection => _firestore.collection('items');
  CollectionReference get _chatsCollection => _firestore.collection('chats');

  // ==================== USER METHODS ====================

  Future<void> createUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.userId).set(user.toFirestore());
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  Future<UserModel?> getUserById(String userId) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      await _usersCollection.doc(userId).update(updates);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // ==================== ITEM METHODS ====================

  Future<void> createItem(ItemModel item) async {
    try {
      await _itemsCollection.doc(item.itemId).set(item.toFirestore());
    } catch (e) {
      throw Exception('Failed to create item: $e');
    }
  }

  Future<void> updateItem(String itemId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _itemsCollection.doc(itemId).update(updates);
    } catch (e) {
      throw Exception('Failed to update item: $e');
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      await _itemsCollection.doc(itemId).delete();
    } catch (e) {
      throw Exception('Failed to delete item: $e');
    }
  }

  Future<void> updateItemStatus(String itemId, ItemStatus status) async {
    try {
      await updateItem(itemId, {'status': status.toString().split('.').last});
    } catch (e) {
      throw Exception('Failed to update item status: $e');
    }
  }

  Stream<List<ItemModel>> getItems({ItemType? filter, ItemCategory? category}) {
    Query query = _itemsCollection.orderBy('createdAt', descending: true);

    if (filter != null) {
      query = query.where(
        'itemType',
        isEqualTo: filter.toString().split('.').last,
      );
    }

    if (category != null) {
      query = query.where(
        'category',
        isEqualTo: category.toString().split('.').last,
      );
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ItemModel.fromFirestore(doc)).toList();
    });
  }

  Stream<List<ItemModel>> getUserItems(String userId) {
    return _itemsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ItemModel.fromFirestore(doc))
              .toList();
        });
  }

  Future<List<ItemModel>> searchItems(String query) async {
    try {
      // Basic search implementation.
      // Firestore doesn't support full-text search natively.
      // This is a simple prefix search on the title.
      // For better search, consider using Algolia or similar services.
      QuerySnapshot snapshot = await _itemsCollection
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: '${query}z')
          .get();

      return snapshot.docs.map((doc) => ItemModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to search items: $e');
    }
  }

  Future<void> reportItem(String itemId, String reporterUserId) async {
    try {
      await _itemsCollection.doc(itemId).update({
        'reportedBy': FieldValue.arrayUnion([reporterUserId]),
      });
    } catch (e) {
      throw Exception('Failed to report item: $e');
    }
  }

  // ==================== CHAT METHODS ====================

  Future<String> createChat(
    String itemId,
    String userId1,
    String userId2,
  ) async {
    try {
      // Check if chat already exists for this item between these users
      QuerySnapshot existingChats = await _chatsCollection
          .where('itemId', isEqualTo: itemId)
          .where('participants', arrayContains: userId1)
          .get();

      for (var doc in existingChats.docs) {
        List<dynamic> participants = doc.get('participants');
        if (participants.contains(userId2)) {
          return doc.id; // Chat already exists
        }
      }

      // Create new chat
      // Need to fetch user names for participantNames map
      UserModel? user1 = await getUserById(userId1);
      UserModel? user2 = await getUserById(userId2);

      Map<String, String> participantNames = {
        userId1: user1?.name ?? 'User 1',
        userId2: user2?.name ?? 'User 2',
      };

      ChatModel newChat = ChatModel(
        chatId: '', // Will be set by Firestore
        itemId: itemId,
        participants: [userId1, userId2],
        participantNames: participantNames,
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        createdAt: DateTime.now(),
      );

      DocumentReference docRef = await _chatsCollection.add(
        newChat.toFirestore(),
      );
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create chat: $e');
    }
  }

  Stream<List<ChatModel>> getChatsForUser(String userId) {
    return _chatsCollection
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatModel.fromFirestore(doc))
              .toList();
        });
  }

  Future<void> sendMessage(String chatId, String senderId, String text) async {
    try {
      MessageModel message = MessageModel(
        messageId: '', // Will be set by Firestore
        senderId: senderId,
        text: text,
        timestamp: DateTime.now(),
        isRead: false,
      );

      // Add message to subcollection
      await _chatsCollection
          .doc(chatId)
          .collection('messages')
          .add(message.toFirestore());

      // Update last message in chat document
      await updateLastMessage(chatId, text);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Stream<List<MessageModel>> getMessages(String chatId) {
    return _chatsCollection
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MessageModel.fromFirestore(doc))
              .toList();
        });
  }

  Future<void> updateLastMessage(String chatId, String message) async {
    try {
      await _chatsCollection.doc(chatId).update({
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update last message: $e');
    }
  }
}
