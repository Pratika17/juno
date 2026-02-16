import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/item_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';

import 'package:unifound/screens/posts/edit_item_screen.dart';
import 'package:unifound/screens/chat/chat_detail_screen.dart';
import '../../providers/item_provider.dart';
import '../../providers/my_posts_provider.dart';
import '../../providers/chat_provider.dart';

class ItemDetailScreen extends StatefulWidget {
  final ItemModel item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late ItemModel _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isOwner = authProvider.currentUserModel?.userId == _item.userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditItemScreen(item: _item),
                  ),
                );

                if (result != null && result is ItemModel) {
                  setState(() {
                    _item = result;
                  });
                }
              },
            ),
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                _confirmDelete(
                  context,
                  _item.itemId,
                  _item.imageUrl,
                  _item.userId,
                );
              },
            ),
          if (!isOwner)
            IconButton(
              icon: const Icon(Icons.flag),
              onPressed: () {
                _confirmReport(
                  context,
                  _item.itemId,
                  authProvider.currentUserModel?.userId,
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (_item.imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: _item.imageUrl,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 300,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 300,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 50),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.image, size: 60, color: Colors.grey),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _item.title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      _buildStatusBadge(_item.status),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Date & Location
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(_item.date),
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _item.location,
                          style: const TextStyle(color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _item.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  // Category & Type
                  Row(
                    children: [
                      _buildInfoChip(
                        Icons.category,
                        _item.category.toString().split('.').last.toUpperCase(),
                      ),
                      const SizedBox(width: 12),
                      _buildInfoChip(
                        _item.itemType == ItemType.lost
                            ? Icons.search
                            : Icons.check_circle,
                        _item.itemType.toString().split('.').last.toUpperCase(),
                        color: _item.itemType == ItemType.lost
                            ? Colors.red[100]
                            : Colors.green[100],
                        textColor: _item.itemType == ItemType.lost
                            ? Colors.red
                            : Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // owner info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Text(
                            _item.userName.isNotEmpty
                                ? _item.userName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _item.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Contact: ${_item.userContact}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  if (!isOwner)
                    CustomButton(
                      text:
                          'Contact ${_item.itemType == ItemType.lost ? "Owner" : "Finder"}',
                      onPressed: () {
                        // Navigate to chat
                        _contactUser(
                          context,
                          _item,
                          authProvider.currentUserModel?.userId,
                        );
                      },
                      backgroundColor: AppColors.primary,
                    ),

                  if (isOwner && _item.status == ItemStatus.active)
                    Column(
                      children: [
                        const SizedBox(height: 12),
                        CustomButton(
                          text:
                              'Mark as ${_item.itemType == ItemType.lost ? "Recovered" : "Returned"}',
                          onPressed: () {
                            _updateStatus(
                              context,
                              _item.itemId,
                              _item.itemType == ItemType.lost
                                  ? ItemStatus.recovered
                                  : ItemStatus.returned,
                            );
                          },
                          backgroundColor: Colors.green,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ItemStatus status) {
    Color color = Colors.grey;
    String text = 'Unknown';
    switch (status) {
      case ItemStatus.active:
        color = Colors.green;
        text = 'Active';
        break;
      case ItemStatus.recovered:
        color = Colors.orange;
        text = 'Recovered';
        break;
      case ItemStatus.returned:
        color = Colors.blue;
        text = 'Returned';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String label, {
    Color? color,
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color ?? Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor ?? Colors.black87),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  void _confirmDelete(
    BuildContext context,
    String itemId,
    String imageUrl,
    String userId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                // Use MyPostsProvider to delete if available, or DatabaseService directly
                // Using MyPostsProvider ensures local list is updated if we are supposedly viewing from there
                // But ItemDetailScreen can be reached from Home too.
                // Best to use DatabaseService and then refresh providers.

                // Actually, MyPostsProvider.deletePost also handles Storage deletion if we pass the provider.
                // But here we might not have MyPostsProvider in context if we came from Home?
                // We have access to it via Provider.of.

                await Provider.of<MyPostsProvider>(
                  context,
                  listen: false,
                ).deletePost(itemId, imageUrl);

                if (context.mounted) {
                  Provider.of<ItemProvider>(
                    context,
                    listen: false,
                  ).refreshItems();
                  Navigator.pop(context); // Go back to home
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Item deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmReport(BuildContext context, String itemId, String? userId) {
    if (userId == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Item'),
        content: const Text('Is this item spam or inappropriate?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await DatabaseService().reportItem(itemId, userId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Item reported. Thank you.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Report', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _updateStatus(
    BuildContext context,
    String itemId,
    ItemStatus status,
  ) async {
    try {
      // Use MyPostsProvider to update state if we are the owner!
      // Even if not using MyPostsProvider for display, we should notify it.
      await Provider.of<MyPostsProvider>(
        context,
        listen: false,
      ).updatePostStatus(itemId, status);

      // We also need to update our local state to reflect the change immediately
      if (mounted) {
        setState(() {
          _item = _item.copyWith(status: status);
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Status updated!')));
        // We do NOT pop here anymore, we just update the UI.
        // User can pop manually.
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _contactUser(
    BuildContext context,
    ItemModel item,
    String? currentUserId,
  ) async {
    if (currentUserId == null) return;

    // Check if chatting with self
    if (currentUserId == item.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot chat with yourself')),
      );
      return;
    }

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    try {
      String? chatId = await chatProvider.createOrGetChat(
        item.itemId,
        currentUserId,
        item.userId,
      );

      if (chatId != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              chatId: chatId,
              otherUserId: item.userId,
              otherUserName: item.userName,
              contextItem: item, // Pass item for context banner
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error starting chat: $e')));
      }
    }
  }
}
