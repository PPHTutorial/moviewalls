import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import 'ad_config.dart';

/// Ad service for managing Google AdMob ads
class AdService {
  static AdService? _instance;
  
  // Note: Banner ads are created per widget, not stored here
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  RewardedInterstitialAd? _rewardedInterstitialAd;
  
  bool _isInterstitialReady = false;
  bool _isRewardedReady = false;
  bool _isRewardedInterstitialReady = false;
  int _downloadsSinceLastAd = 0;
  DateTime? _lastInterstitialTime;
  // Navigation and time-based tracking
  int _navigationCount = 0;
  DateTime? _lastNavigationAdTime;
  
  // Retry tracking for ads
  int _interstitialRetryCount = 0;
  int _rewardedRetryCount = 0;
  int _rewardedInterstitialRetryCount = 0;
  static const int _maxRetries = 5;
  static const int _initialRetryDelaySeconds = 30;
  static const int _rateLimitBackoffSeconds = 60; // 1 minute for rate limit errors
  
  // Ad frequency settings (user-friendly - not too aggressive)
  static const int _navigationsBeforeInterstitial = 3; // Show ad after 3 screen navigations
  static const int _minutesBetweenTimeBasedAds = 5; // Show time-based ad every 5 minutes
  
  AdService._();
  
  static AdService get instance {
    _instance ??= AdService._();
    return _instance!;
  }
  
  /// Initialize Mobile Ads SDK
  Future<void> initialize() async {
    try {
      print('🔍 [AD] Initializing AdMob...');
      
      // Configure test device for test ads
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: ['FDB6404EE2DF76ABCA39527BDAFAB242'],
        ),
      );
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
        print('🔍 [AD] Loading rewarded interstitial ad...');
        _loadRewardedInterstitialAd();
        print('🔍 [AD] Loading open app ad...');
        loadAppOpenAd();
      });
    } catch (e, stackTrace) {
      print('❌ [AD] Error initializing AdMob: $e');
      AppLogger.e('Error initializing AdMob', e, stackTrace);
    }
  }
  
  /// Load banner ad (creates new instance each time for multiple banners)
  BannerAd loadBannerAd({
    required Function(Ad ad) onAdLoaded,
    required Function(Ad ad, LoadAdError error) onAdFailedToLoad,
  }) {
    final bannerAd = BannerAd(
      adUnitId: AdConfig.getBannerAdUnitId(),
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          AppLogger.i('Banner ad loaded');
          onAdLoaded(ad);
        },
        onAdFailedToLoad: (ad, error) {
          // Code 3 is "No fill" - normal occurrence, not an error
          if (error.code == 3) {
            AppLogger.d('Banner ad: No fill (no ad available)');
          } else {
            AppLogger.e('Banner ad failed to load: ${error.message}', error);
          }
          ad.dispose();
          onAdFailedToLoad(ad, error);
        },
      ),
    );
    
    bannerAd.load();
    return bannerAd;
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
          // Code 3 is "No fill" - normal occurrence, don't log as error or retry aggressively
          if (error.code == 3) {
            AppLogger.d('Interstitial ad: No fill (no ad available)');
            // Still retry but with longer delay for "No fill"
            if (_interstitialRetryCount < _maxRetries) {
              _interstitialRetryCount++;
              final delaySeconds = _initialRetryDelaySeconds * (1 << (_interstitialRetryCount - 1));
              Future.delayed(Duration(seconds: delaySeconds), () {
                if (_interstitialRetryCount <= _maxRetries) {
                  _loadInterstitialAd();
                }
              });
            }
          } else {
            // Check for rate limit error first
            final isRateLimited = error.message.toLowerCase().contains('too many recently failed requests') ||
                                 error.message.toLowerCase().contains('must wait');
            
            if (isRateLimited) {
              // Rate limit - wait much longer (10 minutes) before retrying
              AppLogger.w('Interstitial ad rate limited - waiting ${_rateLimitBackoffSeconds}s before retry');
              print('⚠️ [AD] Rate limit detected for interstitial ad - waiting ${_rateLimitBackoffSeconds}s');
              Future.delayed(Duration(seconds: _rateLimitBackoffSeconds), () {
                _interstitialRetryCount = 0; // Reset counter after rate limit wait
                _loadInterstitialAd();
              });
            } else {
          print('❌ [AD] Interstitial ad failed to load: ${error.message}, Code: ${error.code}, Domain: ${error.domain}');
              AppLogger.e('Interstitial ad failed to load: ${error.message}', error);
          
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
            }
          }
          _isInterstitialReady = false;
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
          // Code 3 is "No fill" - normal occurrence, don't log as error or retry aggressively
          if (error.code == 3) {
            AppLogger.d('Rewarded ad: No fill (no ad available)');
            // Still retry but with longer delay for "No fill"
            if (_rewardedRetryCount < _maxRetries) {
              _rewardedRetryCount++;
              final delaySeconds = _initialRetryDelaySeconds * (1 << (_rewardedRetryCount - 1));
              Future.delayed(Duration(seconds: delaySeconds), () {
                if (_rewardedRetryCount <= _maxRetries) {
                  _loadRewardedAd();
                }
              });
            }
          } else {
          print('❌ [AD] Rewarded ad failed to load: ${error.message}, Code: ${error.code}, Domain: ${error.domain}');
            AppLogger.e('Rewarded ad failed to load: ${error.message}', error);
            
            // Check for rate limit error first
            final isRateLimited = error.message.toLowerCase().contains('too many recently failed requests') ||
                                 error.message.toLowerCase().contains('must wait');
            
            if (isRateLimited) {
              // Rate limit - wait much longer (10 minutes) before retrying
              AppLogger.w('Rewarded ad rate limited - waiting ${_rateLimitBackoffSeconds}s before retry');
              print('⚠️ [AD] Rate limit detected for rewarded ad - waiting ${_rateLimitBackoffSeconds}s');
              Future.delayed(Duration(seconds: _rateLimitBackoffSeconds), () {
                _rewardedRetryCount = 0; // Reset counter after rate limit wait
                _loadRewardedAd();
              });
            } else {
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
            }
          }
          _isRewardedReady = false;
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
      _loadRewardedAd(); // Reload for next time
      return rewardEarned;
    } else {
      AppLogger.w('Rewarded ad not ready');
      _loadRewardedAd(); // Try to load for next time
      return false;
    }
  }
  
  /// Load rewarded interstitial ad
  void _loadRewardedInterstitialAd() {
    final adUnitId = AdConfig.getRewardedInterstitialAdUnitId();
    print('🔍 [AD] Loading rewarded interstitial ad with unit ID: $adUnitId');
    
    RewardedInterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          print('✅ [AD] Rewarded interstitial ad loaded successfully');
          _rewardedInterstitialAd = ad;
          _isRewardedInterstitialReady = true;
          _rewardedInterstitialRetryCount = 0;
          AppLogger.i('Rewarded interstitial ad loaded');
          
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              print('🔍 [AD] Rewarded interstitial ad dismissed');
              ad.dispose();
              _isRewardedInterstitialReady = false;
              _loadRewardedInterstitialAd(); // Reload for next time
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('❌ [AD] Rewarded interstitial ad failed to show: ${error.message}');
              AppLogger.e('Rewarded interstitial ad failed to show: ${error.message}');
              ad.dispose();
              _isRewardedInterstitialReady = false;
              _loadRewardedInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          if (error.code == 3) {
            AppLogger.d('Rewarded interstitial ad: No fill');
            if (_rewardedInterstitialRetryCount < _maxRetries) {
              _rewardedInterstitialRetryCount++;
              final delaySeconds = _initialRetryDelaySeconds * (1 << (_rewardedInterstitialRetryCount - 1));
              Future.delayed(Duration(seconds: delaySeconds), () {
                if (_rewardedInterstitialRetryCount <= _maxRetries) {
                  _loadRewardedInterstitialAd();
                }
              });
            }
          } else {
            print('❌ [AD] Rewarded interstitial ad failed to load: ${error.message}');
            AppLogger.e('Rewarded interstitial ad failed to load: ${error.message}', error);
            
            final isRateLimited = error.message.toLowerCase().contains('too many recently failed requests');
            if (isRateLimited) {
              AppLogger.w('Rewarded interstitial ad rate limited - waiting ${_rateLimitBackoffSeconds}s');
              Future.delayed(Duration(seconds: _rateLimitBackoffSeconds), () {
                _rewardedInterstitialRetryCount = 0;
                _loadRewardedInterstitialAd();
              });
            } else if (_rewardedInterstitialRetryCount < _maxRetries) {
              _rewardedInterstitialRetryCount++;
              final delaySeconds = _initialRetryDelaySeconds * (1 << (_rewardedInterstitialRetryCount - 1));
              Future.delayed(Duration(seconds: delaySeconds), () {
                if (_rewardedInterstitialRetryCount <= _maxRetries) {
                  _loadRewardedInterstitialAd();
                }
              });
            }
          }
          _isRewardedInterstitialReady = false;
        },
      ),
    );
  }

  /// Show rewarded interstitial ad
  Future<bool> showRewardedInterstitialAd({
    required Function() onRewardEarned,
  }) async {
    if (_isRewardedInterstitialReady && _rewardedInterstitialAd != null) {
      bool rewardEarned = false;
      
      await _rewardedInterstitialAd!.show(
        onUserEarnedReward: (ad, reward) {
          AppLogger.i('User earned reward from rewarded interstitial: ${reward.amount} ${reward.type}');
          rewardEarned = true;
          onRewardEarned();
        },
      );
      
      _isRewardedInterstitialReady = false;
      _loadRewardedInterstitialAd(); // Reload for next time
      return rewardEarned;
    } else {
      AppLogger.w('Rewarded interstitial ad not ready');
      _loadRewardedInterstitialAd(); // Try to load for next time
      return false;
    }
  }

  /// Track navigation and show ad if needed
  Future<void> onNavigation() async {
    _navigationCount++;
    
    // Check if we should show ad based on navigation count
    if (_navigationCount >= _navigationsBeforeInterstitial) {
      // Also check time-based frequency cap
      if (_lastNavigationAdTime == null || 
          DateTime.now().difference(_lastNavigationAdTime!) >= Duration(minutes: _minutesBetweenTimeBasedAds)) {
        await showInterstitialAdOnNavigation();
        _navigationCount = 0;
        _lastNavigationAdTime = DateTime.now();
      }
    }
  }

  /// Show interstitial ad on navigation (with frequency cap check)
  Future<void> showInterstitialAdOnNavigation() async {
    // Check frequency cap
    if (_lastInterstitialTime != null) {
      final timeSinceLastAd = DateTime.now().difference(_lastInterstitialTime!);
      if (timeSinceLastAd.inMinutes < AppConstants.minutesBetweenInterstitials) {
        AppLogger.i('Interstitial ad frequency cap - too soon since last ad');
        return;
      }
    }
    
    await showInterstitialAd();
  }

  /// Check and show time-based interstitial ad (every X minutes)
  Future<void> checkAndShowTimeBasedAd() async {
    if (_lastInterstitialTime == null) {
      _lastInterstitialTime = DateTime.now();
      return;
    }
    
    final timeSinceLastAd = DateTime.now().difference(_lastInterstitialTime!);
    if (timeSinceLastAd.inMinutes >= _minutesBetweenTimeBasedAds) {
      await showInterstitialAd();
    }
  }

  /// Load native ad
  NativeAd loadNativeAd({
    required Function(NativeAd ad) onAdLoaded,
    required Function(NativeAd ad, LoadAdError error) onAdFailedToLoad,
  }) {
    final nativeAd = NativeAd(
      adUnitId: AdConfig.getNativeAdUnitId(),
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          AppLogger.i('Native ad loaded');
          if (ad is NativeAd) {
            onAdLoaded(ad);
          }
        },
        onAdFailedToLoad: (ad, error) {
          if (error.code == 3) {
            AppLogger.d('Native ad: No fill (no ad available)');
          } else {
            AppLogger.e('Native ad failed to load: ${error.message}', error);
          }
          if (ad is NativeAd) {
            onAdFailedToLoad(ad, error);
          }
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: const Color(0xFF1A1A1A),
        cornerRadius: 8.0,
      ),
    );

    nativeAd.load();
    return nativeAd;
  }

  /// Load and show open app ad
  AppOpenAd? _appOpenAd;
  bool _isAppOpenAdReady = false;
  int _appOpenAdRetryCount = 0;

  void loadAppOpenAd() {
    final adUnitId = AdConfig.getOpenAppAdUnitId();
    print('🔍 [AD] Loading open app ad with unit ID: $adUnitId');

    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          print('✅ [AD] Open app ad loaded successfully');
          _appOpenAd = ad;
          _isAppOpenAdReady = true;
          _appOpenAdRetryCount = 0;
          AppLogger.i('Open app ad loaded');

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              print('🔍 [AD] Open app ad dismissed');
              ad.dispose();
              _isAppOpenAdReady = false;
              _appOpenAd = null;
              loadAppOpenAd(); // Reload for next time
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('❌ [AD] Open app ad failed to show: ${error.message}');
              AppLogger.e('Open app ad failed to show: ${error.message}');
              ad.dispose();
              _isAppOpenAdReady = false;
              _appOpenAd = null;
              loadAppOpenAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          if (error.code == 3) {
            AppLogger.d('Open app ad: No fill (no ad available)');
            if (_appOpenAdRetryCount < _maxRetries) {
              _appOpenAdRetryCount++;
              final delaySeconds = _initialRetryDelaySeconds * (1 << (_appOpenAdRetryCount - 1));
              Future.delayed(Duration(seconds: delaySeconds), () {
                if (_appOpenAdRetryCount <= _maxRetries) {
                  loadAppOpenAd();
                }
              });
            }
          } else {
            print('❌ [AD] Open app ad failed to load: ${error.message}, Code: ${error.code}');
            AppLogger.e('Open app ad failed to load: ${error.message}', error);
            if (_appOpenAdRetryCount < _maxRetries) {
              _appOpenAdRetryCount++;
              final delaySeconds = _initialRetryDelaySeconds * (1 << (_appOpenAdRetryCount - 1));
              Future.delayed(Duration(seconds: delaySeconds), () {
                if (_appOpenAdRetryCount <= _maxRetries) {
                  loadAppOpenAd();
                }
              });
            }
          }
          _isAppOpenAdReady = false;
        },
      ),
    );
  }

  /// Show open app ad
  Future<void> showAppOpenAd() async {
    print('🔍 [AD] Attempting to show open app ad. Ready: $_isAppOpenAdReady');
    
    if (_isAppOpenAdReady && _appOpenAd != null) {
      try {
        await _appOpenAd!.show();
        print('✅ [AD] Open app ad shown successfully');
      } catch (e) {
        print('❌ [AD] Error showing open app ad: $e');
        AppLogger.e('Error showing open app ad', e);
        _isAppOpenAdReady = false;
        _appOpenAd = null;
        loadAppOpenAd();
      }
    } else {
      print('⚠️ [AD] Open app ad not ready');
      loadAppOpenAd(); // Try to load for next time
    }
  }
  
  /// Dispose all ads
  void disposeAll() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _rewardedInterstitialAd?.dispose();
    _appOpenAd?.dispose();
    
    _interstitialAd = null;
    _rewardedAd = null;
    _rewardedInterstitialAd = null;
    _appOpenAd = null;
    _isInterstitialReady = false;
    _isRewardedReady = false;
    _isRewardedInterstitialReady = false;
    _isAppOpenAdReady = false;
    _interstitialRetryCount = 0;
    _rewardedRetryCount = 0;
    _rewardedInterstitialRetryCount = 0;
    _appOpenAdRetryCount = 0;
  }
  
  /// Reset retry counts (useful for manual retry)
  void resetRetryCounts() {
    _interstitialRetryCount = 0;
    _rewardedRetryCount = 0;
    _rewardedInterstitialRetryCount = 0;
  }
  
  /// Reset navigation counter (useful when user becomes Pro)
  void resetNavigationCounter() {
    _navigationCount = 0;
  }
}

