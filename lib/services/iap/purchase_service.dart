import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import 'subscription_manager.dart';

/// Purchase service for handling in-app purchases
class PurchaseService {
  static PurchaseService? _instance;
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final SubscriptionManager _subscriptionManager = SubscriptionManager.instance;
  
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  
  PurchaseService._();
  
  static PurchaseService get instance {
    _instance ??= PurchaseService._();
    return _instance!;
  }
  
  /// Initialize IAP
  Future<void> initialize() async {
    try {
      // Check if IAP is available
      _isAvailable = await _inAppPurchase.isAvailable();
      
      if (!_isAvailable) {
        AppLogger.w('In-app purchases not available');
        return;
      }
      
      AppLogger.i('In-app purchases available');
      
      // Listen to purchase updates
      _subscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdates,
        onError: (error) {
          AppLogger.e('Purchase stream error', error);
        },
      );
      
      // Load products
      await _loadProducts();
      
      // Restore previous purchases
      await restorePurchases();
    } catch (e, stackTrace) {
      AppLogger.e('Error initializing IAP', e, stackTrace);
    }
  }
  
  /// Load available products
  Future<void> _loadProducts() async {
    try {
      final productIds = {
        AppConstants.iapMonthly,
        AppConstants.iapYearly,
        AppConstants.iapLifetime,
      };
      
      final response = await _inAppPurchase.queryProductDetails(productIds);
      
      if (response.error != null) {
        AppLogger.e('Error loading products: ${response.error}');
        return;
      }
      
      if (response.productDetails.isEmpty) {
        AppLogger.w('No products found');
        return;
      }
      
      _products = response.productDetails;
      AppLogger.i('Loaded ${_products.length} products');
      
      for (final product in _products) {
        AppLogger.d('Product: ${product.id} - ${product.title} - ${product.price}');
      }
    } catch (e, stackTrace) {
      AppLogger.e('Error loading products', e, stackTrace);
    }
  }
  
  /// Handle purchase updates
  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      AppLogger.i('Purchase update: ${purchase.productID} - ${purchase.status}');
      
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // Verify purchase
        _verifyPurchase(purchase);
        
        // Update subscription status
        _subscriptionManager.updateSubscriptionStatus(
          productId: purchase.productID,
          isActive: true,
        );
      } else if (purchase.status == PurchaseStatus.error) {
        AppLogger.e('Purchase error: ${purchase.error}');
      }
      
      // Complete purchase
      if (purchase.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchase);
      }
    }
  }
  
  /// Verify purchase (implement server-side verification in production)
  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    // TODO: Implement server-side purchase verification
    AppLogger.i('Verifying purchase: ${purchase.productID}');
    
    // For now, just return true
    // In production, send to your backend for verification
    return true;
  }
  
  /// Purchase product
  Future<bool> purchaseProduct(String productId) async {
    if (!_isAvailable) {
      AppLogger.w('IAP not available');
      return false;
    }
    
    try {
      final product = _products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('Product not found'),
      );
      
      final purchaseParam = PurchaseParam(productDetails: product);
      
      // Purchase
      final result = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
      
      AppLogger.i('Purchase initiated: ${product.id}');
      return result;
    } catch (e, stackTrace) {
      AppLogger.e('Error purchasing product', e, stackTrace);
      return false;
    }
  }
  
  /// Restore purchases
  Future<void> restorePurchases() async {
    if (!_isAvailable) {
      AppLogger.w('IAP not available');
      return;
    }
    
    try {
      AppLogger.i('Restoring purchases...');
      await _inAppPurchase.restorePurchases();
    } catch (e, stackTrace) {
      AppLogger.e('Error restoring purchases', e, stackTrace);
    }
  }
  
  /// Get available products
  List<ProductDetails> get products => _products;
  
  /// Check if IAP is available
  bool get isAvailable => _isAvailable;
  
  /// Dispose
  void dispose() {
    _subscription?.cancel();
  }
}

