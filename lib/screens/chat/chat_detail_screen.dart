import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/message_model.dart';
import '../../models/item_model.dart';
import '../../models/chat_model.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/item_chat_banner.dart';
import '../../services/database_service.dart';

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
      appBar: AppBar(title: Text(widget.otherUserName)),
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
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send),
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
