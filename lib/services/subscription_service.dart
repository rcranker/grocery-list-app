import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/foundation.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  // Initialize RevenueCat
  Future<void> initialize() async {
    await Purchases.setLogLevel(LogLevel.debug);
    
    PurchasesConfiguration configuration;
    
    // TODO:Using test API keys - replace with production keys before Play Store release
    if (defaultTargetPlatform == TargetPlatform.android) {
      configuration = PurchasesConfiguration('test_KSvAgNhtkBvAalyuUFnACWEvsxi');
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      configuration = PurchasesConfiguration('test_KSvAgNhtkBvAalyuUFnACWEvsxi');
    } else {
      return;
    }
    
    await Purchases.configure(configuration);
    
    // Check current subscription status
    //await checkSubscriptionStatus();
  }

  // Check if user has active subscription
  Future<void> checkSubscriptionStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _isPremium = customerInfo.entitlements.active.isNotEmpty;
      debugPrint('Premium status: $_isPremium');
    } catch (e) {
      debugPrint('Error checking subscription: $e');
      _isPremium = false;
    }
  }

  // Get available offerings
  Future<Offerings?> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      return offerings;
    } catch (e) {
      debugPrint('Error getting offerings: $e');
      return null;
    }
  }

  // Purchase a package
  Future<bool> purchasePackage(Package package) async {
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      _isPremium = customerInfo.entitlements.active.isNotEmpty;
      return _isPremium;
    } catch (e) {
      debugPrint('Error purchasing: $e');
      return false;
    }
  }

  // Restore purchases
  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      _isPremium = customerInfo.entitlements.active.isNotEmpty;
      return _isPremium;
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      return false;
    }
  }

  // Login user (links subscription to account)
  Future<void> loginUser(String userId) async {
    try {
      await Purchases.logIn(userId);
      await checkSubscriptionStatus();
    } catch (e) {
      debugPrint('Error logging in user: $e');
    }
  }

  // Logout user
  Future<void> logoutUser() async {
    try {
      await Purchases.logOut();
      _isPremium = false;
    } catch (e) {
      debugPrint('Error logging out: $e');
    }
  }
}