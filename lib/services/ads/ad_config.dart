import 'dart:io';
import '../../core/constants/app_constants.dart';

/// Ad configuration for AdMob
class AdConfig {
  // Test Ad Unit IDs (for development)
  static const String _testBannerAdUnitIdAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerAdUnitIdIOS = 'ca-app-pub-3940256099942544/2934735716';
  
  static const String _testInterstitialAdUnitIdAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialAdUnitIdIOS = 'ca-app-pub-3940256099942544/4411468910';
  
  static const String _testRewardedAdUnitIdAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const String _testRewardedAdUnitIdIOS = 'ca-app-pub-3940256099942544/1712485313';
  
  static const String _testRewardedInterstitialAdUnitIdAndroid = 'ca-app-pub-3940256099942544/5354046379';
  static const String _testRewardedInterstitialAdUnitIdIOS = 'ca-app-pub-3940256099942544/6978759866';

  static const String _testNativeAdUnitIdAndroid = 'ca-app-pub-3940256099942544/2247696110';
  static const String _testNativeAdUnitIdIOS = 'ca-app-pub-3940256099942544/2247696110';

  static const String _testOpenAppAdUnitIdAndroid = 'ca-app-pub-3940256099942544/3205752111';
  static const String _testOpenAppAdUnitIdIOS = 'ca-app-pub-3940256099942544/3205752111';
  
  // Production Ad Unit IDs
  static const String _prodBannerAdUnitIdAndroid = 'ca-app-pub-9043208558525567/5885621652';
  static const String _prodBannerAdUnitIdIOS = 'ca-app-pub-9043208558525567/5885621652';
  
  static const String _prodInterstitialAdUnitIdAndroid = 'ca-app-pub-9043208558525567/8320213302';
  static const String _prodInterstitialAdUnitIdIOS = 'ca-app-pub-9043208558525567/8320213302';
  
  static const String _prodRewardedAdUnitIdAndroid = 'ca-app-pub-9043208558525567/5502478278';
  static const String _prodRewardedAdUnitIdIOS = 'ca-app-pub-9043208558525567/5502478278';

  static const String _prodRewardedInterstitialAdUnitIdAndroid = 'ca-app-pub-9043208558525567/3067886625';
  static const String _prodRewardedInterstitialAdUnitIdIOS = 'ca-app-pub-9043208558525567/3067886625';

  static const String _prodNativeAdUnitIdAndroid = 'ca-app-pub-9043208558525567/7388938416';
  static const String _prodNativeAdUnitIdIOS = 'ca-app-pub-9043208558525567/7388938416';

  static const String _prodOpenAppAdUnitIdAndroid = 'ca-app-pub-9043208558525567/2019517077';
  static const String _prodOpenAppAdUnitIdIOS = 'ca-app-pub-9043208558525567/2019517077';
  
  // Use test ads for now (change to false for production)
  static const bool _useTestAds = false;
  
  /// Get banner ad unit ID
  static String getBannerAdUnitId() {
    if (_useTestAds) {
      return Platform.isAndroid
          ? _testBannerAdUnitIdAndroid
          : _testBannerAdUnitIdIOS;
    } else {
      return Platform.isAndroid
          ? _prodBannerAdUnitIdAndroid
          : _prodBannerAdUnitIdIOS;
    }
  }
  
  /// Get interstitial ad unit ID
  static String getInterstitialAdUnitId() {
    if (_useTestAds) {
      return Platform.isAndroid
          ? _testInterstitialAdUnitIdAndroid
          : _testInterstitialAdUnitIdIOS;
    } else {
      return Platform.isAndroid
          ? _prodInterstitialAdUnitIdAndroid
          : _prodInterstitialAdUnitIdIOS;
    }
  }
  
  /// Get rewarded ad unit ID
  static String getRewardedAdUnitId() {
    if (_useTestAds) {
      return Platform.isAndroid
          ? _testRewardedAdUnitIdAndroid
          : _testRewardedAdUnitIdIOS;
    } else {
      return Platform.isAndroid
          ? _prodRewardedAdUnitIdAndroid
          : _prodRewardedAdUnitIdIOS;
    }
  }
  
  /// Get rewarded interstitial ad unit ID
  static String getRewardedInterstitialAdUnitId() {
    if (_useTestAds) {
      return Platform.isAndroid
          ? _testRewardedInterstitialAdUnitIdAndroid
          : _testRewardedInterstitialAdUnitIdIOS;
    } else {
      return Platform.isAndroid
          ? _prodRewardedInterstitialAdUnitIdAndroid
          : _prodRewardedInterstitialAdUnitIdIOS;
    }
  }
  
  /// Get native ad unit ID
  static String getNativeAdUnitId() {
    if (_useTestAds) {
      return Platform.isAndroid
          ? _testNativeAdUnitIdAndroid
          : _testNativeAdUnitIdIOS;
    } else {
      return Platform.isAndroid
          ? _prodNativeAdUnitIdAndroid
          : _prodNativeAdUnitIdIOS;
    }
  }

  /// Get open app ad unit ID
  static String getOpenAppAdUnitId() {
    if (_useTestAds) {
      return Platform.isAndroid
          ? _testOpenAppAdUnitIdAndroid
          : _testOpenAppAdUnitIdIOS;
    } else {
      return Platform.isAndroid
          ? _prodOpenAppAdUnitIdAndroid
          : _prodOpenAppAdUnitIdIOS;
    }
  }

  // Ad frequency settings
  static int get downloadsBeforeInterstitial => AppConstants.downloadsBeforeInterstitial;
  static int get minutesBetweenInterstitials => AppConstants.minutesBetweenInterstitials;
  static int get hoursForRewardedBenefit => AppConstants.hoursForRewardedBenefit;
}

