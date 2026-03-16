import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  Future<ItemModel?> getItem(String itemId) async {
    try {
      DocumentSnapshot doc = await _itemsCollection.doc(itemId).get();
      if (doc.exists) {
        return ItemModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get item: $e');
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      // Find all chats associated with this item
      QuerySnapshot associatedChats = await _chatsCollection
          .where('itemId', isEqualTo: itemId)
          .get();
          
      // Delete each associated chat
      for (var doc in associatedChats.docs) {
        await deleteChat(doc.id);
      }

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

  Stream<List<ItemModel>> getItems({
    ItemType? filter,
    ItemCategory? category,
    bool isAdmin = false,
  }) {
    Query query = _itemsCollection
        .orderBy('createdAt', descending: true)
        .limit(20);

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
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      var items = snapshot.docs
          .map((doc) => ItemModel.fromFirestore(doc))
          .toList();
      if (!isAdmin) {
        // Filter out items that have 3 or more reports OR were reported by the current user
        items = items.where((item) {
          if (item.reportedBy.length >= 3) return false;
          if (currentUserId != null && item.reportedBy.contains(currentUserId))
            return false;
          return true;
        }).toList();
      }
      return items;
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
        unreadCounts: {userId1: 0, userId2: 0},
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

  Future<void> sendMessage(
    String chatId,
    String senderId,
    String text,
    String otherUserId,
  ) async {
    try {
      final message = MessageModel(
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

      // Update last message and increment unread count for the other user
      await _chatsCollection.doc(chatId).update({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCounts.$otherUserId': FieldValue.increment(1),
      });
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

  Future<void> markChatAsRead(String chatId, String userId) async {
    try {
      // Reset unread count for this user
      await _chatsCollection.doc(chatId).update({'unreadCounts.$userId': 0});

      // Also mark all messages received by this user as updated?
      // Ideally we should mark messages as isRead = true where sender != userId
      // But that requires a batch update which might be expensive if many messages.
      // For now, let's just reset the counter as that drives the badge.
      // The 'isRead' on individual messages is harder to maintain without a backend trigger.
      // We can do a client side batch for recent messages.

      final unreadMessagesQuery = await _chatsCollection
          .doc(chatId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .where('senderId', isNotEqualTo: userId)
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in unreadMessagesQuery.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark chat as read: $e');
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      // First delete all messages in the subcollection
      final messagesQuery = await _chatsCollection.doc(chatId).collection('messages').get();
      WriteBatch batch = _firestore.batch();
      for (var doc in messagesQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Then delete the chat document itself
      await _chatsCollection.doc(chatId).delete();
    } catch (e) {
      throw Exception('Failed to delete chat: $e');
    }
  }
}
