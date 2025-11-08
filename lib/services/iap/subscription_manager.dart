import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';

/// Subscription manager for tracking Pro status
class SubscriptionManager {
  static SubscriptionManager? _instance;
  SharedPreferences? _prefs;
  
  bool _isProUser = false;
  String? _activeProductId;
  DateTime? _subscriptionExpiry;
  
  SubscriptionManager._();
  
  static SubscriptionManager get instance {
    _instance ??= SubscriptionManager._();
    return _instance!;
  }
  
  /// Initialize subscription manager
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadSubscriptionStatus();
      AppLogger.i('Subscription manager initialized - Pro: $_isProUser');
    } catch (e, stackTrace) {
      AppLogger.e('Error initializing subscription manager', e, stackTrace);
    }
  }
  
  /// Load subscription status from local storage
  Future<void> _loadSubscriptionStatus() async {
    try {
      _isProUser = _prefs?.getBool(AppConstants.keyProStatus) ?? false;
      _activeProductId = _prefs?.getString('active_product_id');
      
      final expiryTimestamp = _prefs?.getInt('subscription_expiry');
      if (expiryTimestamp != null) {
        _subscriptionExpiry = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
        
        // Check if subscription has expired
        if (_subscriptionExpiry != null && DateTime.now().isAfter(_subscriptionExpiry!)) {
          AppLogger.w('Subscription expired');
          await _setProStatus(false);
        }
      }
    } catch (e, stackTrace) {
      AppLogger.e('Error loading subscription status', e, stackTrace);
    }
  }
  
  /// Update subscription status
  Future<void> updateSubscriptionStatus({
    required String productId,
    required bool isActive,
  }) async {
    try {
      await _setProStatus(isActive);
      
      if (isActive) {
        _activeProductId = productId;
        await _prefs?.setString('active_product_id', productId);
        
        // Set expiry based on product type
        if (productId == AppConstants.iapMonthly) {
          _subscriptionExpiry = DateTime.now().add(const Duration(days: 30));
        } else if (productId == AppConstants.iapSixMonths) {
          _subscriptionExpiry = DateTime.now().add(const Duration(days: 180)); // 6 months
        } else if (productId == AppConstants.iapYearly) {
          _subscriptionExpiry = DateTime.now().add(const Duration(days: 365)); // 1 year
        }
        
        if (_subscriptionExpiry != null) {
          await _prefs?.setInt(
            'subscription_expiry',
            _subscriptionExpiry!.millisecondsSinceEpoch,
          );
        }
        
        AppLogger.i('Subscription activated: $productId');
      } else {
        _activeProductId = null;
        _subscriptionExpiry = null;
        await _prefs?.remove('active_product_id');
        await _prefs?.remove('subscription_expiry');
        AppLogger.i('Subscription deactivated');
      }
    } catch (e, stackTrace) {
      AppLogger.e('Error updating subscription status', e, stackTrace);
    }
  }
  
  /// Set Pro status
  Future<void> _setProStatus(bool isPro) async {
    _isProUser = isPro;
    await _prefs?.setBool(AppConstants.keyProStatus, isPro);
  }
  
  /// Check if user is Pro
  bool get isProUser => _isProUser;
  
  /// Get active product ID
  String? get activeProductId => _activeProductId;
  
  /// Get subscription expiry
  DateTime? get subscriptionExpiry => _subscriptionExpiry;
  
  /// Check if subscription is active
  bool get isSubscriptionActive {
    if (!_isProUser) return false;
    
    if (_subscriptionExpiry == null) return false;
    
    return DateTime.now().isBefore(_subscriptionExpiry!);
  }
  
  /// Get days until expiry
  int? get daysUntilExpiry {
    if (_subscriptionExpiry == null) return null;
    
    final difference = _subscriptionExpiry!.difference(DateTime.now());
    return difference.inDays;
  }
  
  /// Get subscription type display name
  String get subscriptionType {
    if (!_isProUser) return 'Free';
    
    switch (_activeProductId) {
      case AppConstants.iapMonthly:
        return 'Pro Monthly';
      case AppConstants.iapSixMonths:
        return 'Pro 6 Months';
      case AppConstants.iapYearly:
        return 'Pro Yearly';
      default:
        return 'Pro';
    }
  }
}

