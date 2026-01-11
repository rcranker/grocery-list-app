import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/sync_service.dart';
import 'services/subscription_service.dart';
import 'services/storage_service.dart';  // Add this line
import 'models/grocery_item.dart';
import 'models/store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  Hive.registerAdapter(GroceryItemAdapter());
  Hive.registerAdapter(StoreAdapter());
  
  // Open boxes
  final itemsBox = await Hive.openBox<GroceryItem>('items');
  final storesBox = await Hive.openBox<Store>('stores');
  
  // Initialize StorageService with opened boxes
  StorageService.initialize(itemsBox, storesBox);
  
  // Create default store if none exist
  if (storesBox.isEmpty) {
    final defaultStore = Store(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'My Store',
      createdAt: DateTime.now(),
      isDefault: true,
      colorValue: 0xFF4CAF50, // Green
      notes: '',
    );
    await storesBox.add(defaultStore);
  }
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize RevenueCat
  await SubscriptionService().initialize();
  
  runApp(const FamilyCartApp());
}

class FamilyCartApp extends StatelessWidget {
  const FamilyCartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FamilyCart',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final SyncService _syncService = SyncService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          // User is logged in - initialize sync before showing HomeScreen
          return FutureBuilder(
            future: _syncService.initializeSync(),
            builder: (context, syncSnapshot) {
              if (syncSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading your data...'),
                      ],
                    ),
                  ),
                );
              }
              
              return const HomeScreen();
            },
          );
        }

        // User is NOT logged in - show login screen
        return const LoginScreen();
      },
    );
  }
}