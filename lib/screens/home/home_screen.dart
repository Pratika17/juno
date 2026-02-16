import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/item_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/item_card.dart';
// screens/home/ -> .. -> screens/ -> auth/ -> login_screen.dart
// So ../auth/login_screen.dart is correct.

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ... (rest of build)
    return Scaffold(
      appBar: AppBar(
        title: const Text('UniFound'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon!')),
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
          Expanded(child: _buildItemGrid(context)),
        ],
      ),
    );
  }
  // ... (drawer and search bar unchanged for now, reusing file content implicitly? NO, must provide full content for safety or valid chunks)
  // I will provide chunks.

  // Chunk 1: Imports

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
              // Navigate to profile
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile screen coming soon!')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('Chats'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to chats
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat List screen coming soon!')),
              );
            },
          ),
          const Divider(),
          // Theme Toggle Placeholder
          SwitchListTile(
            title: const Text('Dark Mode'),
            secondary: const Icon(Icons.dark_mode),
            value: false, // TODO: Connect to ThemeProvider
            onChanged: (val) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Theme toggling coming soon!')),
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
              // AuthWrapper in main.dart will handle navigation to LoginScreen
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search items...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 20,
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        onChanged: (value) {
          // Debounce could be added here
          itemProvider.searchItems(value);
        },
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Consumer<ItemProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildFilterChip(
                context,
                label: 'All',
                isSelected: provider.currentFilter == null,
                onSelected: () => provider.applyFilter(null),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                context,
                label: 'Lost',
                isSelected: provider.currentFilter == ItemType.lost,
                onSelected: () => provider.applyFilter(ItemType.lost),
                color: Colors.red[100],
                selectedColor: Colors.red[200],
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                context,
                label: 'Found',
                isSelected: provider.currentFilter == ItemType.found,
                onSelected: () => provider.applyFilter(ItemType.found),
                color: Colors.green[100],
                selectedColor: Colors.green[200],
              ),
              const SizedBox(width: 16),
              // Category Dropdown wrapped in a container for styling
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ItemCategory>(
                    value: provider.currentCategory,
                    hint: const Text('Category'),
                    icon: const Icon(Icons.arrow_drop_down),
                    isDense: true,
                    onChanged: (ItemCategory? newValue) {
                      provider.applyCategory(newValue);
                    },
                    items: [
                      const DropdownMenuItem<ItemCategory>(
                        value: null,
                        child: Text('All Categories'),
                      ),
                      ...ItemCategory.values.map((ItemCategory category) {
                        return DropdownMenuItem<ItemCategory>(
                          value: category,
                          child: Text(
                            category.toString().split('.').last.toUpperCase(),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    Color? color,
    Color? selectedColor,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: color ?? Colors.grey[200],
      selectedColor:
          selectedColor ??
          Theme.of(context).primaryColor.withValues(alpha: 0.3),
      checkmarkColor: Colors.black87,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
    );
  }

  Widget _buildItemGrid(BuildContext context) {
    return Consumer<ItemProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
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
