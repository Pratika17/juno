import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/database_service.dart';

class ChatProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<ChatModel> _chats = [];
  Map<String, List<MessageModel>> _messagesByChat = {};
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<List<ChatModel>>? _chatsSubscription;
  final Map<String, StreamSubscription<List<MessageModel>>>
  _messageSubscriptions = {};

  List<ChatModel> get chats => _chats;
  Map<String, List<MessageModel>> get messagesByChat => _messagesByChat;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int getUnreadCount(String userId) {
    int total = 0;
    for (var chat in _chats) {
      total += chat.unreadCounts[userId] ?? 0;
    }
    return total;
  }

  // Stream chats for the current user
  void fetchChatsForUser(String userId) {
    _isLoading = true;
    notifyListeners();

    _chatsSubscription?.cancel();
    _chatsSubscription = _databaseService
        .getChatsForUser(userId)
        .listen(
          (chatsData) {
            _chats = chatsData;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = error.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  // Stream messages for a specific chat
  void fetchMessages(String chatId) {
    if (_messageSubscriptions.containsKey(chatId)) return; // Already listening

    _messageSubscriptions[chatId] = _databaseService
        .getMessages(chatId)
        .listen(
          (messagesData) {
            _messagesByChat[chatId] = messagesData;
            notifyListeners();
          },
          onError: (error) {
            print("Error fetching messages for $chatId: $error");
          },
        );
  }

  // Send a message
  Future<void> sendMessage(
    String chatId,
    String senderId,
    String text,
    String otherUserId,
  ) async {
    if (text.trim().isEmpty) return;
    try {
      await _databaseService.sendMessage(chatId, senderId, text, otherUserId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Mark chat as read
  Future<void> markChatAsRead(String chatId, String userId) async {
    try {
      await _databaseService.markChatAsRead(chatId, userId);
    } catch (e) {
      print("Error marking chat as read: $e");
    }
  }

  // Create or get an existing chat
  Future<String?> createOrGetChat(
    String itemId,
    String currentUserId,
    String otherUserId,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      String chatId = await _databaseService.createChat(
        itemId,
        currentUserId,
        otherUserId,
      );
      _isLoading = false;
      notifyListeners();
      return chatId;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  @override
  void dispose() {
    _chatsSubscription?.cancel();
    for (var sub in _messageSubscriptions.values) {
      sub.cancel();
    }
    super.dispose();
  }
}
