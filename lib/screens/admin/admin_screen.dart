import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/item_model.dart';
import '../../services/database_service.dart';
import '../../utils/constants.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final DatabaseService _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All Items'),
              Tab(text: 'Reported (>2)'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: TabBarView(
          children: [
            _buildItemsList(false),
            _buildItemsList(true),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(bool reportedOnly) {
    return StreamBuilder<List<ItemModel>>(
      stream: _databaseService.getItems(isAdmin: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading items: ${snapshot.error}'),
          );
        }

        var items = snapshot.data ?? [];

        if (reportedOnly) {
          items = items.where((item) => item.reportedBy.length >= 2).toList();
        }

        if (items.isEmpty) {
          return Center(
            child: Text(
              reportedOnly ? 'No highly reported items.' : 'No items found.',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildAdminItemCard(context, item);
          },
        );
      },
    );
  }

  Widget _buildAdminItemCard(BuildContext context, ItemModel item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: item.imageUrl,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (context, url, error) => Container(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              child: const Icon(Icons.image_not_supported),
            ),
          ),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('By: ${item.userName}'),
            const SizedBox(height: 2),
            Text(
              'Reports: ${item.reportedBy.length}',
              style: TextStyle(
                color: item.reportedBy.length >= 2 ? Colors.red : Colors.grey,
                fontWeight: item.reportedBy.length >= 2
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Posted: ${timeago.format(item.createdAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _confirmDelete(context, item),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ItemModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _databaseService.deleteItem(item.itemId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Item deleted successfully')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
