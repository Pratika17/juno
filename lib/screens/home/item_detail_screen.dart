import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/item_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';

import 'package:unifound/screens/posts/edit_item_screen.dart';
import '../../providers/item_provider.dart';
import '../../providers/my_posts_provider.dart';

class ItemDetailScreen extends StatelessWidget {
  final ItemModel item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isOwner = authProvider.currentUserModel?.userId == item.userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditItemScreen(item: item),
                  ),
                );
              },
            ),
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                _confirmDelete(
                  context,
                  item.itemId,
                  item.imageUrl,
                  item.userId,
                );
              },
            ),
          if (!isOwner)
            IconButton(
              icon: const Icon(Icons.flag),
              onPressed: () {
                _confirmReport(
                  context,
                  item.itemId,
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
            if (item.imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: item.imageUrl,
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
                          item.title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      _buildStatusBadge(item.status),
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
                        _formatDate(item.date),
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
                          item.location,
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
                    item.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  // Category & Type
                  Row(
                    children: [
                      _buildInfoChip(
                        Icons.category,
                        item.category.toString().split('.').last.toUpperCase(),
                      ),
                      const SizedBox(width: 12),
                      _buildInfoChip(
                        item.itemType == ItemType.lost
                            ? Icons.search
                            : Icons.check_circle,
                        item.itemType.toString().split('.').last.toUpperCase(),
                        color: item.itemType == ItemType.lost
                            ? Colors.red[100]
                            : Colors.green[100],
                        textColor: item.itemType == ItemType.lost
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
                            item.userName.isNotEmpty
                                ? item.userName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Contact: ${item.userContact}',
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
                          'Contact ${item.itemType == ItemType.lost ? "Owner" : "Finder"}',
                      onPressed: () {
                        // Navigate to chat
                        _contactUser(
                          context,
                          item,
                          authProvider.currentUserModel?.userId,
                        );
                      },
                      backgroundColor: AppColors.primary,
                    ),

                  if (isOwner && item.status == ItemStatus.active)
                    Column(
                      children: [
                        const SizedBox(height: 12),
                        CustomButton(
                          text:
                              'Mark as ${item.itemType == ItemType.lost ? "Recovered" : "Returned"}',
                          onPressed: () {
                            _updateStatus(
                              context,
                              item.itemId,
                              item.itemType == ItemType.lost
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
      await DatabaseService().updateItemStatus(itemId, status);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Status updated!')));
        Navigator.pop(context); // simple refresh by going back
      }
    } catch (e) {
      if (context.mounted) {
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
    try {
      // Create chat or get existing
      String chatId = await DatabaseService().createChat(
        item.itemId,
        currentUserId,
        item.userId,
      );
      // Navigate to Chat Detail (Placeholder for now)
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chat created: $chatId. Chat screen coming soon!'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
