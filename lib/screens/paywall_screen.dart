import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;
import '../services/subscription_service.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  rc.Offerings? _offerings;
  bool _isLoading = true;
  rc.Package? _selectedPackage;

  @override
  void initState() {
    super.initState();
    _loadOfferings().then((_) {
      // Show debug dialog after loading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Debug Info'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Offerings: ${_offerings != null ? "Loaded" : "NULL"}'),
                  Text('Current: ${_offerings?.current?.identifier ?? "none"}'),
                  Text('Packages: ${_offerings?.current?.availablePackages.length ?? 0}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
      });
    });
  }

  Future<void> _loadOfferings() async {
    setState(() => _isLoading = true);
  
    debugPrint('=== LOADING OFFERINGS ===');
    final offerings = await _subscriptionService.getOfferings();
    debugPrint('Offerings object: ${offerings != null ? "exists" : "null"}');
    debugPrint('Current offering: ${offerings?.current?.identifier}');
    debugPrint('All offerings: ${offerings?.all.keys.toList()}');
  
    if (mounted) {
      setState(() {
        _offerings = offerings;
      
        // Get packages from current offering or default offering
        final packages = offerings?.current?.availablePackages ?? 
                      offerings?.getOffering('default')?.availablePackages ?? 
                      [];
      
        debugPrint('Packages from current: ${offerings?.current?.availablePackages.length ?? 0}');
        debugPrint('Packages from default: ${offerings?.getOffering('default')?.availablePackages.length ?? 0}');
        debugPrint('Final packages count: ${packages.length}');

        for (var pkg in packages) {
          debugPrint('Package found: ${pkg.identifier} - ${pkg.storeProduct.title}');
        }
      
        if (packages.isNotEmpty) {
          // Try to find annual package, otherwise use first package
          try {
            _selectedPackage = packages.firstWhere(
              (pkg) => pkg.identifier.contains('annual'),
            );
          } catch (e) {
            _selectedPackage = packages.first;
          }
          debugPrint('Selected package: ${_selectedPackage?.identifier}');
        } else {
          debugPrint('ERROR: No packages available!');
        }

        _isLoading = false;
      });
    }
  }
  

  Future<void> _purchase() async {
    if (_selectedPackage == null) return;

    setState(() => _isLoading = true);

    final success = await _subscriptionService.purchasePackage(_selectedPackage!);

    if (mounted) {
      setState(() => _isLoading = false);
      
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome to Premium! 🎉')),
        );
      }
    }
  }


  Future<void> _restore() async {  // Fix: added space before ()
    setState(() => _isLoading = true);
  
    try {  // Add try block
      // Make sure we're logged into RevenueCat first
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        try {
          await rc.Purchases.logIn(uid);
        } catch (e) {
          debugPrint('RevenueCat login error: $e');
        }
      }
    
      final success = await _subscriptionService.restorePurchases();
    
      if (!mounted) return;
    
      setState(() => _isLoading = false);
    
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchases restored!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No purchases found')),
        );
      }
    } catch (e) {
      debugPrint('Error restoring: $e');
      if (!mounted) return;
    
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error restoring purchases: $e')),
      );
    }
  }



  // Calculate savings percentage
  String _calculateSavings(List<rc.Package> packages) {
    if (packages.length < 2) return '0';
    
    try {
      final monthly = packages.firstWhere(
        (p) => !p.identifier.contains('annual') && !p.identifier.contains('year'),
        orElse: () => packages.first,
      );
      final annual = packages.firstWhere(
        (p) => p.identifier.contains('annual') || p.identifier.contains('year'),
        orElse: () => packages.last,
      );
      
      final monthlyYearlyCost = monthly.storeProduct.price * 12;
      final annualCost = annual.storeProduct.price;
      final savings = ((monthlyYearlyCost - annualCost) / monthlyYearlyCost * 100);
      
      return savings.toStringAsFixed(0);
    } catch (e) {
      return '0';
    }
  }

  // Get monthly equivalent price for annual plan
  String _getMonthlyPrice(double annualPrice) {
    final monthlyEquivalent = annualPrice / 12;
    return '\$${monthlyEquivalent.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Upgrade to Premium')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final packages = _offerings?.current?.availablePackages ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade to Premium'),
        actions: [
          TextButton(
            onPressed: _restore,
            child: const Text('Restore', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.workspace_premium, size: 80, color: Colors.amber),
            const SizedBox(height: 24),
            const Text(
              'Go Premium',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unlock cloud sync and household sharing',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Features
            _buildFeature(Icons.cloud_sync, 'Cloud Sync', 'Access your lists on all devices'),
            _buildFeature(Icons.people, 'Household Sharing', 'Share lists with family in real-time'),
            _buildFeature(Icons.backup, 'Automatic Backup', 'Never lose your grocery lists'),
            _buildFeature(Icons.devices, 'Multi-Device', 'Use on phone, tablet, and web'),
            
            const SizedBox(height: 32),

            
            // Package selection
            if (packages.isNotEmpty) ...[
              ...packages.map((package) {
                final isSelected = _selectedPackage == package;
                final product = package.storeProduct;

                // Determine if monthly or annual
                final isAnnual = package.identifier.contains('annual') || 
                                package.identifier.contains('year') ||
                                product.identifier.contains('annual');

                final displayTitle = isAnnual ? 'Annual Plan' : 'Monthly Plan';
                final displayDescription = isAnnual 
                    ? 'Billed once per year' 
                    : 'Billed monthly';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => setState(() => _selectedPackage = package),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? Colors.green : Colors.grey,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: isSelected ? Colors.green.withValues(alpha:0.1) : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: isSelected ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayTitle,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  displayDescription,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                if (isAnnual) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Save ${_calculateSavings(packages)}%',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                product.priceString,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              if (isAnnual) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '~${_getMonthlyPrice(product.price)} /mo',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
            
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _selectedPackage != null ? _purchase : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              child: const Text('Start Premium'),
            ),

            const SizedBox(height: 16),
              TextButton(
                onPressed: _restore,
                child: const Text('Restore Purchases'),
              ),
            
            
            const Text(
              'Cancel anytime. Terms apply.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}