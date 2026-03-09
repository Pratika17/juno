import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:unifound/firebase_options.dart';
import 'package:unifound/providers/auth_provider.dart';
import 'package:unifound/providers/item_provider.dart';
import 'package:unifound/providers/my_posts_provider.dart';
import 'package:unifound/providers/chat_provider.dart';
import 'package:unifound/screens/auth/login_screen.dart';
import 'package:unifound/screens/home/home_screen.dart';
import 'package:unifound/screens/posts/add_item_screen.dart';
import 'package:unifound/screens/posts/my_posts_screen.dart';
import 'package:unifound/screens/chat/chat_list_screen.dart';
import 'package:unifound/screens/profile/profile_screen.dart';
import 'package:unifound/utils/constants.dart';
import 'package:unifound/services/notification_service.dart';
import 'package:unifound/widgets/offline_banner.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().initNotifications();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ItemProvider()),
        ChangeNotifierProvider(create: (_) => MyPostsProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'UniFound',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.primary,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            secondary: AppColors.secondary,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 2,
            centerTitle: true,
          ),
          cardTheme: CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        home: const OfflineBanner(child: AuthWrapper()),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return StreamBuilder<User?>(
      stream: authProvider.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;

          if (user == null) {
            return const LoginScreen();
          }

          if (authProvider.currentUserModel == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return const MainScreen();
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    NotificationService().setupInteractedMessage();
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const AddItemScreen(),
    const MyPostsScreen(),
    const ChatListScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Post',
          ),
          const NavigationDestination(
            icon: Icon(Icons.list_alt),
            selectedIcon: Icon(Icons.list),
            label: 'My Posts',
          ),
          NavigationDestination(
            icon: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                final userId = authProvider.currentUserModel?.userId;
                final unreadCount = userId != null
                    ? chatProvider.getUnreadCount(userId)
                    : 0;

                return Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text(unreadCount > 9 ? '9+' : '$unreadCount'),
                  child: const Icon(Icons.chat_bubble_outline),
                );
              },
            ),
            selectedIcon: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                final userId = authProvider.currentUserModel?.userId;
                final unreadCount = userId != null
                    ? chatProvider.getUnreadCount(userId)
                    : 0;

                return Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text(unreadCount > 9 ? '9+' : '$unreadCount'),
                  child: const Icon(Icons.chat_bubble),
                );
              },
            ),
            label: 'Chats',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
