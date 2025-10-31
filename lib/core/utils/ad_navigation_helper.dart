import 'package:flutter/material.dart';
import '../../services/ads/ad_service.dart';
import '../../services/iap/subscription_manager.dart';

/// Helper utility for showing ads during navigation
class AdNavigationHelper {
  /// Navigate and show interstitial ad if needed (only for free users)
  static Future<T?> navigateWithAd<T extends Object?>(
    BuildContext context,
    Widget Function() routeBuilder, {
    bool showInterstitial = true,
  }) async {
    // Don't show ads for Pro users
    if (SubscriptionManager.instance.isProUser) {
      return Navigator.push<T>(
        context,
        MaterialPageRoute(builder: (_) => routeBuilder()),
      );
    }
    
    // Show interstitial ad before navigation if enabled
    if (showInterstitial) {
      await AdService.instance.showInterstitialAdOnNavigation();
    }
    
    // Navigate after ad
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => routeBuilder()),
    );
  }
  
  /// Navigate with rewarded interstitial (for premium content access)
  static Future<T?> navigateWithRewardedInterstitial<T extends Object?>(
    BuildContext context,
    Widget Function() routeBuilder,
    Function() onRewardEarned,
  ) async {
    // Don't show ads for Pro users
    if (SubscriptionManager.instance.isProUser) {
      return Navigator.push<T>(
        context,
        MaterialPageRoute(builder: (_) => routeBuilder()),
      );
    }
    
    // Show rewarded interstitial
    await AdService.instance.showRewardedInterstitialAd(
      onRewardEarned: onRewardEarned,
    );
    
    // Navigate after ad
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => routeBuilder()),
    );
  }
}

