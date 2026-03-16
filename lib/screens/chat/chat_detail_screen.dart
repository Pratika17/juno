import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/item_model.dart';
import '../../models/chat_model.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/item_chat_banner.dart';
import '../../services/database_service.dart';
import '../../utils/constants.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final ItemModel? contextItem;

  const ChatDetailScreen({
    Key? key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.contextItem,
  }) : super(key: key);

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ItemModel? _item;
  bool _isLoadingItem = false;

  @override
  void initState() {
    super.initState();
    // Fetch messages when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(
        context,
        listen: false,
      ).fetchMessages(widget.chatId);
      _fetchItemContext();
      _markAsRead();
    });
  }

  Future<void> _fetchItemContext() async {
    if (widget.contextItem != null) {
      setState(() {
        _item = widget.contextItem;
      });
      return;
    }

    setState(() => _isLoadingItem = true);
    try {
      // We need to find the chat model to get the itemId
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      // Try to find the chat in the provider's list first
      ChatModel? chat = chatProvider.chats.firstWhere(
        (c) => c.chatId == widget.chatId,
        orElse: () => ChatModel(
          chatId: '',
          itemId: '',
          participants: [],
          participantNames: {},
          lastMessage: '',
          lastMessageTime: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      );

      String itemId = chat.itemId;

      // If not successful or empty (unlikely if opened from list), we might need to fetch chat content?
      // Since ChatListScreen populates the provider, this should be fine.
      // If opened via deep link (future), we might need to fetch chat by ID first.

      if (itemId.isNotEmpty) {
        final item = await DatabaseService().getItem(itemId);
        if (mounted) {
          setState(() {
            _item = item;
          });
        }
      }
    } catch (e) {
      print('Error fetching item context: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingItem = false);
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final currentUser = authProvider.currentUserModel;

    if (currentUser != null) {
      chatProvider.sendMessage(
        widget.chatId,
        currentUser.userId,
        text,
        widget.otherUserId,
        senderName: currentUser.name,
      );
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _markAsRead() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final currentUser = authProvider.currentUserModel;

    if (currentUser != null) {
      chatProvider.markChatAsRead(widget.chatId, currentUser.userId);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0, // Reverse list view, 0 is bottom
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUserModel?.userId ?? '';
    final messages = chatProvider.messagesByChat[widget.chatId] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            color: Colors.red,
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Delete Chat"),
                    content: const Text("Are you sure you want to delete this chat permanently?"),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          final chatProvider = Provider.of<ChatProvider>(context, listen: false);
                          await chatProvider.deleteChat(widget.chatId);
                          if (context.mounted) {
                            Navigator.of(context).pop(); // Go back to chat list
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Chat deleted successfully')),
                            );
                          }
                        },
                        child: const Text(
                          "Delete",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Item Context Banner
          if (_item != null)
            ItemChatBanner(item: _item!)
          else if (_isLoadingItem)
            const LinearProgressIndicator(minHeight: 2),

          Expanded(
            child: messages.isEmpty
                ? const Center(child: Text('No messages yet.'))
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isSent = message.senderId == currentUserId;
                      return MessageBubble(message: message, isSent: isSent);
                    },
                  ),
          ),
          _buildMessageInput(Theme.of(context).brightness == Brightness.dark),
        ],
      ),
    );
  }

  Widget _buildMessageInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      color: isDark ? AppColors.darkBackground : Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurface : Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send, size: 20),
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
