import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc hide Store;
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
    
    // Production keys for Play Store release
    if (defaultTargetPlatform == TargetPlatform.android) {
      configuration = PurchasesConfiguration('goog_RYLUAsSjndChBcdKeRRnPXqHLOB');
    } else {
      return;
    }
    
    await Purchases.configure(configuration);
    
  }

  // Check if user has active subscription
  Future<void> checkSubscriptionStatus() async {
    debugPrint('=== CHECKING SUBSCRIPTION STATUS ===');
    try {
      final customerInfo = await Purchases.getCustomerInfo();
    
      debugPrint('Customer ID: ${customerInfo.originalAppUserId}');
      debugPrint('All entitlements: ${customerInfo.entitlements.all.keys}');
    
      final premiumEntitlement = customerInfo.entitlements.all['premium'];
      debugPrint('Premium entitlement: $premiumEntitlement');
      debugPrint('Is active: ${premiumEntitlement?.isActive}');
    
      _isPremium = premiumEntitlement?.isActive ?? false;
    
      debugPrint('Final _isPremium value: $_isPremium');
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR checking subscription: $e');
      debugPrint('Stack trace: $stackTrace');
      _isPremium = false;
    }
    debugPrint('=== SUBSCRIPTION CHECK COMPLETE ===');
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
      debugPrint('🔐 Logging into RevenueCat with user: $userId');
        await rc.Purchases.logIn(userId);
        debugPrint('✅ RevenueCat login successful');
    
        await checkSubscriptionStatus();
        debugPrint('Premium status after login: $_isPremium');
    } catch (e) {
      debugPrint('❌ Error logging in user to RevenueCat: $e');
    }
  }

  // Logout user
  Future<void> logoutUser() async {
    try {
      await rc.Purchases.logOut();
      _isPremium = false;
    } catch (e) {
      debugPrint('Error logging out: $e');
    }
  }
}