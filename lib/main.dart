import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:unifound/firebase_options.dart';
import 'package:unifound/providers/auth_provider.dart';
import 'package:unifound/providers/item_provider.dart';
import 'package:unifound/providers/my_posts_provider.dart';
import 'package:unifound/screens/auth/login_screen.dart';
import 'package:unifound/screens/home/home_screen.dart';
import 'package:unifound/screens/posts/add_item_screen.dart';
import 'package:unifound/screens/posts/my_posts_screen.dart';
import 'package:unifound/utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
      ],
      child: MaterialApp(
        title: 'UniFound',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.primary,
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // If we're already listening in AuthProvider, we just check the state here.
    // AuthProvider.authStateChanges is available but AuthProvider itself
    // exposes currentUserModel and auth state.

    // Actually, we should probably stick to the StreamBuilder for the raw auth state
    // if we want to be super responsive to FirebaseAuth changes,
    // OR just rely on AuthProvider notifications if it notifies on auth state change.

    // The current AuthProvider implementation DOES notifyListeners() when user model changes.
    // But it doesn't automatically notify on just auth state change unless we added that.
    // We added _initAuthListener which calls fetchCurrentUserModel which calls notifyListeners.
    // So for "Loading" -> "User Loaded" transition, it works.
    // transitions:
    // 1. App Start (User null) -> Listener fires -> User not null -> fetch flows -> notify -> UI updates.

    return StreamBuilder<User?>(
      stream: authProvider.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;

          if (user == null) {
            return const LoginScreen();
          }

          // User is logged in.
          // Check if we have the user model loaded.

          if (authProvider.currentUserModel == null) {
            // We are waiting for the user model to be fetched by AuthProvider.
            // AuthProvider should be in a loading state or just hasn't finished fetching yet.
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

  final List<Widget> _screens = [
    const HomeScreen(),
    const AddItemScreen(),
    const MyPostsScreen(),
    const Center(child: Text('Profile Screen (Coming Soon)')),
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Post',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt),
            selectedIcon: Icon(Icons.list),
            label: 'My Posts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
