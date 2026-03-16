import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/item_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/item_card_skeleton.dart';
import '../../widgets/item_card.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../chat/chat_list_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// screens/home/ -> .. -> screens/ -> auth/ -> login_screen.dart
// So ../auth/login_screen.dart is correct.

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ... (rest of build)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where(
                  'userId',
                  isEqualTo: Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  ).currentUserModel?.userId,
                )
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.hasData
                  ? snapshot.data!.docs.length
                  : 0;
              return IconButton(
                icon: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text(unreadCount > 9 ? '9+' : '$unreadCount'),
                  child: const Icon(Icons.notifications_outlined),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Column(
        children: [
          _buildSearchBar(context),
          _buildFilters(context),
          const SizedBox(height: 8),
          Expanded(child: _buildItemGrid(context)),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUserModel;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.name ?? 'Guest'),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage:
                  user?.profileImageUrl != null &&
                      user!.profileImageUrl!.isNotEmpty
                  ? NetworkImage(user.profileImageUrl!)
                  : null,
              child:
                  (user?.profileImageUrl == null ||
                      user!.profileImageUrl!.isEmpty)
                  ? Text(
                      user?.name.isNotEmpty == true
                          ? user!.name[0].toUpperCase()
                          : 'G',
                      style: const TextStyle(
                        fontSize: 40.0,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            decoration: const BoxDecoration(color: AppColors.primary),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('Chats'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatListScreen()),
              );
            },
          ),
          const Divider(),
          // Theme Toggle
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return SwitchListTile(
                title: const Text('Dark Mode'),
                secondary: const Icon(Icons.dark_mode),
                value: themeProvider.isDarkMode,
                onChanged: (val) {
                  themeProvider.toggleTheme(val);
                },
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              Navigator.pop(context); // close drawer
              await authProvider.signOut();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search...',
            hintStyle: TextStyle(
                color: isDark ? Colors.white54 : Colors.grey, fontSize: 14),
            prefixIcon: Icon(Icons.search,
                color: isDark ? Colors.white54 : Colors.grey),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            fillColor: Colors.transparent,
            filled: true,
          ),
          onChanged: (value) {
            itemProvider.searchItems(value);
          },
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<ItemProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // Type Filters (All, Lost, Found)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildTypeChip(
                    context,
                    label: 'All Types',
                    isSelected: provider.currentFilter == null,
                    onSelected: () => provider.applyFilter(null),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildTypeChip(
                    context,
                    label: 'Lost',
                    isSelected: provider.currentFilter == ItemType.lost,
                    onSelected: () => provider.applyFilter(ItemType.lost),
                    activeColor: AppColors.primary,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildTypeChip(
                    context,
                    label: 'Found',
                    isSelected: provider.currentFilter == ItemType.found,
                    onSelected: () => provider.applyFilter(ItemType.found),
                    activeColor: AppColors.secondary,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Category Filters (Horizontal Text List)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildCategoryTextTab(
                    context,
                    label: 'All',
                    isSelected: provider.currentCategory == null,
                    onSelected: () => provider.applyCategory(null),
                    isDark: isDark,
                  ),
                  ...ItemCategory.values.map((category) {
                    return _buildCategoryTextTab(
                      context,
                      label: category.toString().split('.').last.toUpperCase(),
                      isSelected: provider.currentCategory == category,
                      onSelected: () => provider.applyCategory(category),
                      isDark: isDark,
                    );
                  }),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTypeChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    required bool isDark,
    Color? activeColor,
  }) {
    // If no active color is provided, default to yellow
    final color = activeColor ?? AppColors.secondary;
    
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (isDark ? AppColors.darkSurface : Colors.grey[200]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTextTab(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onSelected,
      child: Padding(
        padding: const EdgeInsets.only(right: 24.0),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.secondary
                    : (isDark ? Colors.white54 : Colors.grey),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 14,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 3,
                width: 20,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemGrid(BuildContext context) {
    return Consumer<ItemProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.items.isEmpty) {
          return const ItemFeedSkeleton();
        }

        if (provider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${provider.errorMessage}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.refreshItems(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (provider.items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No items found',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                TextButton(
                  onPressed: () {
                    provider.applyFilter(null);
                    provider.applyCategory(null);
                    provider.searchItems('');
                  },
                  child: const Text('Clear Filters'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: provider.refreshItems,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75, // Adjust card aspect ratio
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: provider.items.length,
            itemBuilder: (context, index) {
              return ItemCard(item: provider.items[index]);
            },
          ),
        );
      },
    );
  }
}
