import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/auth_provider.dart';
import '../chat/chat_detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  void _markAsRead(String docId) {
    FirebaseFirestore.instance.collection('notifications').doc(docId).update({
      'isRead': true,
    });
  }

  void _deleteNotification(String docId) {
    FirebaseFirestore.instance.collection('notifications').doc(docId).delete();
  }

  void _handleNotificationTap(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
  ) {
    if (data['isRead'] == false) {
      _markAsRead(docId);
    }

    final type = data['type'] as String?;

    if (type == 'new_message' && data['chatId'] != null) {
      // Navigate to chat
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            chatId: data['chatId'],
            otherUserId:
                '', // We might need to fetch this or pass it if available
            otherUserName: 'Chat', // Fallback, could be extracted from title
          ),
        ),
      );
    } else if (type == 'item_status' && data['itemId'] != null) {
      // Navigate to item detail (if implemented)
      // Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: data['itemId'])));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Navigate to item ${data['itemId']}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUserModel?.userId;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Please log in to view notifications')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final isRead = data['isRead'] ?? false;
              final timestamp = data['createdAt'] as Timestamp?;
              final timeString = timestamp != null
                  ? timeago.format(timestamp.toDate())
                  : '';

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => _deleteNotification(doc.id),
                child: Container(
                  color: isRead ? null : Colors.blue.withOpacity(0.05),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isRead
                          ? Colors.grey[200]
                          : Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Icon(
                        data['type'] == 'new_message'
                            ? Icons.chat
                            : Icons.info_outline,
                        color: isRead
                            ? Colors.grey
                            : Theme.of(context).primaryColor,
                      ),
                    ),
                    title: Text(
                      data['title'] ?? 'Notification',
                      style: TextStyle(
                        fontWeight: isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          data['body'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (timeString.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            timeString,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                    onTap: () => _handleNotificationTap(context, data, doc.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
