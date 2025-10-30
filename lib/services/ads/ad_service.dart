import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import 'ad_config.dart';

/// Ad service for managing Google AdMob ads
class AdService {
  static AdService? _instance;
  
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  
  bool _isInterstitialReady = false;
  bool _isRewardedReady = false;
  int _downloadsSinceLastAd = 0;
  DateTime? _lastInterstitialTime;
  
  // Retry tracking for ads
  int _interstitialRetryCount = 0;
  int _rewardedRetryCount = 0;
  static const int _maxRetries = 5;
  static const int _initialRetryDelaySeconds = 30;
  
  AdService._();
  
  static AdService get instance {
    _instance ??= AdService._();
    return _instance!;
  }
  
  /// Initialize Mobile Ads SDK
  Future<void> initialize() async {
    try {
      print('🔍 [AD] Initializing AdMob...');
      
      // Set test device IDs for testing
      final configuration = RequestConfiguration(
        testDeviceIds: ['FDB6404EE2DF76ABCA39527BDAFAB242'], // Your test device
      );
      MobileAds.instance.updateRequestConfiguration(configuration);
      print('✅ [AD] Set test device configuration');
      
      await MobileAds.instance.initialize();
      print('✅ [AD] AdMob initialized successfully');
      AppLogger.i('AdMob initialized successfully');
      
      // Load initial ads with delay to ensure SDK is ready
      Future.delayed(const Duration(seconds: 2), () {
        print('🔍 [AD] Loading interstitial ad...');
        _loadInterstitialAd();
        print('🔍 [AD] Loading rewarded ad...');
        _loadRewardedAd();
      });
    } catch (e, stackTrace) {
      print('❌ [AD] Error initializing AdMob: $e');
      AppLogger.e('Error initializing AdMob', e, stackTrace);
    }
  }
  
  /// Load banner ad
  BannerAd? loadBannerAd({
    required Function(Ad ad) onAdLoaded,
    required Function(Ad ad, LoadAdError error) onAdFailedToLoad,
  }) {
    _bannerAd = BannerAd(
      adUnitId: AdConfig.getBannerAdUnitId(),
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          AppLogger.i('Banner ad loaded');
          onAdLoaded(ad);
        },
        onAdFailedToLoad: (ad, error) {
          AppLogger.e('Banner ad failed to load: ${error.message}');
          ad.dispose();
          onAdFailedToLoad(ad, error);
        },
      ),
    );
    
    _bannerAd!.load();
    return _bannerAd;
  }
  
  /// Load interstitial ad
  void _loadInterstitialAd() {
    final adUnitId = AdConfig.getInterstitialAdUnitId();
    print('🔍 [AD] Loading interstitial ad with unit ID: $adUnitId');
    
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          print('✅ [AD] Interstitial ad loaded successfully');
          _interstitialAd = ad;
          _isInterstitialReady = true;
          _interstitialRetryCount = 0; // Reset retry count on success
          AppLogger.i('Interstitial ad loaded');
          
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              print('🔍 [AD] Interstitial ad dismissed');
              ad.dispose();
              _isInterstitialReady = false;
              _loadInterstitialAd(); // Reload for next time
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('❌ [AD] Interstitial ad failed to show: ${error.message}');
              AppLogger.e('Interstitial ad failed to show: ${error.message}');
              ad.dispose();
              _isInterstitialReady = false;
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('❌ [AD] Interstitial ad failed to load: ${error.message}, Code: ${error.code}, Domain: ${error.domain}');
          AppLogger.e('Interstitial ad failed to load: ${error.message}');
          _isInterstitialReady = false;
          
          // Check for "too many failed requests" error
          if (error.message.toLowerCase().contains('too many recently failed requests')) {
            print('⚠️ [AD] Too many failed requests - backing off significantly');
            _interstitialRetryCount = _maxRetries; // Treat as max retries reached
          }
          
          // Only retry if under max retries
          if (_interstitialRetryCount < _maxRetries) {
            _interstitialRetryCount++;
            // Exponential backoff: 30s, 60s, 120s, 240s, 480s
            final delaySeconds = _initialRetryDelaySeconds * (1 << (_interstitialRetryCount - 1));
            print('🔍 [AD] Retrying interstitial ad in ${delaySeconds}s (attempt $_interstitialRetryCount/$_maxRetries)');
            
            Future.delayed(Duration(seconds: delaySeconds), () {
              if (_interstitialRetryCount <= _maxRetries) {
                _loadInterstitialAd();
              }
            });
          } else {
            print('⚠️ [AD] Max retries reached for interstitial ad. Stopping retries.');
          }
        },
      ),
    );
  }
  
  /// Load rewarded ad
  void _loadRewardedAd() {
    final adUnitId = AdConfig.getRewardedAdUnitId();
    print('🔍 [AD] Loading rewarded ad with unit ID: $adUnitId');
    
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          print('✅ [AD] Rewarded ad loaded successfully');
          _rewardedAd = ad;
          _isRewardedReady = true;
          _rewardedRetryCount = 0; // Reset retry count on success
          AppLogger.i('Rewarded ad loaded');
          
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              print('🔍 [AD] Rewarded ad dismissed');
              ad.dispose();
              _isRewardedReady = false;
              _loadRewardedAd(); // Reload for next time
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('❌ [AD] Rewarded ad failed to show: ${error.message}');
              AppLogger.e('Rewarded ad failed to show: ${error.message}');
              ad.dispose();
              _isRewardedReady = false;
              _loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('❌ [AD] Rewarded ad failed to load: ${error.message}, Code: ${error.code}, Domain: ${error.domain}');
          AppLogger.e('Rewarded ad failed to load: ${error.message}');
          _isRewardedReady = false;
          
          // Check for "too many failed requests" error
          if (error.message.toLowerCase().contains('too many recently failed requests')) {
            print('⚠️ [AD] Too many failed requests - backing off significantly');
            _rewardedRetryCount = _maxRetries; // Treat as max retries reached
          }
          
          // Only retry if under max retries
          if (_rewardedRetryCount < _maxRetries) {
            _rewardedRetryCount++;
            // Exponential backoff: 30s, 60s, 120s, 240s, 480s
            final delaySeconds = _initialRetryDelaySeconds * (1 << (_rewardedRetryCount - 1));
            print('🔍 [AD] Retrying rewarded ad in ${delaySeconds}s (attempt $_rewardedRetryCount/$_maxRetries)');
            
            Future.delayed(Duration(seconds: delaySeconds), () {
              if (_rewardedRetryCount <= _maxRetries) {
                _loadRewardedAd();
              }
            });
          } else {
            print('⚠️ [AD] Max retries reached for rewarded ad. Stopping retries.');
          }
        },
      ),
    );
  }
  
  /// Show interstitial ad after downloads
  Future<void> showInterstitialAfterDownload() async {
    _downloadsSinceLastAd++;
    
    if (_downloadsSinceLastAd >= AppConstants.downloadsBeforeInterstitial) {
      await showInterstitialAd();
      _downloadsSinceLastAd = 0;
    }
  }
  
  /// Show interstitial ad with frequency cap
  Future<void> showInterstitialAd() async {
    print('🔍 [AD] Attempting to show interstitial ad. Ready: $_isInterstitialReady');
    
    // Check frequency cap
    if (_lastInterstitialTime != null) {
      final timeSinceLastAd = DateTime.now().difference(_lastInterstitialTime!);
      if (timeSinceLastAd.inMinutes < AppConstants.minutesBetweenInterstitials) {
        AppLogger.i('Interstitial ad frequency cap - too soon');
        print('🔍 [AD] Frequency cap - ${timeSinceLastAd.inMinutes} minutes since last ad');
        return;
      }
    }
    
    if (_isInterstitialReady && _interstitialAd != null) {
      print('✅ [AD] Showing interstitial ad...');
      try {
        await _interstitialAd!.show();
        _lastInterstitialTime = DateTime.now();
        _isInterstitialReady = false;
        print('✅ [AD] Interstitial ad shown successfully');
      } catch (e) {
        print('❌ [AD] Failed to show interstitial ad: $e');
      }
    } else {
      print('⚠️ [AD] Interstitial ad not ready. Loading...');
      AppLogger.w('Interstitial ad not ready');
      _loadInterstitialAd(); // Try to load for next time
    }
  }
  
  /// Show rewarded ad
  Future<bool> showRewardedAd() async {
    if (_isRewardedReady && _rewardedAd != null) {
      bool rewardEarned = false;
      
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          AppLogger.i('User earned reward: ${reward.amount} ${reward.type}');
          rewardEarned = true;
        },
      );
      
      _isRewardedReady = false;
      return rewardEarned;
    } else {
      AppLogger.w('Rewarded ad not ready');
      _loadRewardedAd(); // Try to load for next time
      return false;
    }
  }
  
  /// Dispose banner ad
  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }
  
  /// Dispose all ads
  void disposeAll() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    
    _bannerAd = null;
    _interstitialAd = null;
    _rewardedAd = null;
    _isInterstitialReady = false;
    _isRewardedReady = false;
    _interstitialRetryCount = 0;
    _rewardedRetryCount = 0;
  }
  
  /// Reset retry counts (useful for manual retry)
  void resetRetryCounts() {
    _interstitialRetryCount = 0;
    _rewardedRetryCount = 0;
  }
}

