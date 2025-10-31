import 'package:flutter/material.dart';
import '../../services/ads/ad_service.dart';
import '../../services/iap/subscription_manager.dart';

/// Navigation observer to track screen changes and show ads accordingly
class AdNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    
    // Don't track ads for Pro users
    if (SubscriptionManager.instance.isProUser) {
      return;
    }
    
    // Only track navigation for detail screens (not settings/search/favorites)
    final routeName = route.settings.name ?? '';
    final isDetailScreen = routeName.isEmpty || 
        route.settings.arguments != null ||
        route.settings.name == null; // Most detail screens use unnamed routes
    
    if (isDetailScreen && previousRoute != null) {
      // Track navigation for interstitial ads
      AdService.instance.onNavigation();
      
      // Also check for time-based ads
      AdService.instance.checkAndShowTimeBasedAd();
    }
  }
}

