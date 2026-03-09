import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/my_posts_provider.dart';
import '../../models/item_model.dart';
import '../../widgets/item_card.dart';
import '../../utils/constants.dart';
import 'edit_item_screen.dart';
import '../../widgets/item_card_skeleton.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Fetch posts after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(
        context,
        listen: false,
      ).currentUserModel;
      final myPostsProvider = Provider.of<MyPostsProvider>(
        context,
        listen: false,
      );

      if (user != null) {
        myPostsProvider.fetchMyPosts(user.userId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Posts'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Lost Items'),
            Tab(text: 'Found Items'),
          ],
        ),
      ),
      body: Consumer<MyPostsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading &&
              provider.lostItems.isEmpty &&
              provider.foundItems.isEmpty) {
            return const ItemFeedSkeleton();
          }

          if (provider.errorMessage != null) {
            final error = provider.errorMessage!;
            if (error.contains('failed-precondition') ||
                error.contains('requires an index')) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.settings_system_daydream,
                        size: 60,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Database Setup Required',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This query requires a Firestore Index. Please check your debug console for a link to create it automatically.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Trigger refresh
                          final user = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          ).currentUserModel;
                          if (user != null) {
                            provider.fetchMyPosts(
                              user.userId,
                              forceRefresh: true,
                            );
                          }
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Center(child: Text('Error: $error'));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildPostList(provider.lostItems, provider),
              _buildPostList(provider.foundItems, provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPostList(List<ItemModel> items, MyPostsProvider provider) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text('No posts yet'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final user = Provider.of<AuthProvider>(
          context,
          listen: false,
        ).currentUserModel;
        if (user != null) {
          await provider.fetchMyPosts(user.userId, forceRefresh: true);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: SizedBox(
              height: 320,
              child: Stack(
                children: [
                  ItemCard(
                    key: ValueKey('${item.itemId}_${item.status}'),
                    item: item,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 16,
                      child: PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          size: 20,
                          color: Colors.black,
                        ),
                        padding: EdgeInsets.zero,
                        onSelected: (value) =>
                            _handleMenuAction(value, item, provider),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'status',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, size: 20),
                                SizedBox(width: 8),
                                Text('Update Status'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleMenuAction(
    String action,
    ItemModel item,
    MyPostsProvider provider,
  ) {
    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EditItemScreen(item: item)),
        );
        break;
      case 'delete':
        _confirmDelete(item, provider);
        break;
      case 'status':
        _showStatusDialog(item, provider);
        break;
    }
  }

  void _confirmDelete(ItemModel item, MyPostsProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await provider.deletePost(item.itemId, item.imageUrl);
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Post deleted')));
                }
              } catch (e) {
                if (mounted) {
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

  void _showStatusDialog(ItemModel item, MyPostsProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Active'),
              leading: Radio<ItemStatus>(
                value: ItemStatus.active,
                groupValue: item.status,
                onChanged: (val) {
                  Navigator.pop(ctx);
                  _updateStatus(item, ItemStatus.active, provider);
                },
              ),
            ),
            ListTile(
              title: const Text('Recovered'),
              leading: Radio<ItemStatus>(
                value: ItemStatus.recovered,
                groupValue: item.status,
                onChanged: (val) {
                  Navigator.pop(ctx);
                  _updateStatus(item, ItemStatus.recovered, provider);
                },
              ),
            ),
            ListTile(
              title: const Text('Returned'),
              leading: Radio<ItemStatus>(
                value: ItemStatus.returned,
                groupValue: item.status,
                onChanged: (val) {
                  Navigator.pop(ctx);
                  _updateStatus(item, ItemStatus.returned, provider);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(
    ItemModel item,
    ItemStatus status,
    MyPostsProvider provider,
  ) async {
    try {
      await provider.updatePostStatus(item.itemId, status);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Status updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
