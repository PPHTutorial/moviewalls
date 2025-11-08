import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../app/themes/app_colors.dart';
import '../../app/themes/app_dimensions.dart';
import '../../services/ads/ad_service.dart';
import '../../services/iap/subscription_manager.dart';
import '../providers/subscription_provider.dart';

/// Native ad widget (respects Pro status - no ads for Pro users)
class NativeAdWidget extends ConsumerStatefulWidget {
  const NativeAdWidget({super.key});

  @override
  ConsumerState<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends ConsumerState<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _maybeLoadAd();
  }

  void _maybeLoadAd() {
    // Check Pro status before loading ads
    final isPro = SubscriptionManager.instance.isProUser;
    if (!isPro) {
      // Delay ad loading to ensure AdMob is fully initialized
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && !SubscriptionManager.instance.isProUser) {
          _loadAd();
        }
      });
    }
  }

  void _loadAd() {
    print('🔍 [NATIVE] Loading native ad...');
    _nativeAd = AdService.instance.loadNativeAd(
      onAdLoaded: (ad) {
        print('✅ [NATIVE] Native ad loaded successfully');
        if (mounted) {
          setState(() {
            _isAdLoaded = true;
          });
        }
      },
      onAdFailedToLoad: (ad, error) {
        if (error.code == 3) {
          // No fill is normal - AdMob doesn't always have ads available
        } else {
          print('❌ [NATIVE] Native ad failed to load: ${error.message}, Code: ${error.code}');
        }
        if (mounted) {
          setState(() {
            _isAdLoaded = false;
          });
        }
        ad.dispose();
      },
    );
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch Pro status - dispose ad if user becomes Pro
    final isPro = ref.watch(isProUserProvider);
    
    // Dispose ad if user becomes Pro
    if (isPro && _nativeAd != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _nativeAd?.dispose();
        _nativeAd = null;
        if (mounted) {
          setState(() {
            _isAdLoaded = false;
          });
        }
      });
    }
    
    // Don't show ads for Pro users or if ad not loaded
    if (isPro || !_isAdLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(
        vertical: AppDimensions.space8,
        horizontal: AppDimensions.space4,
      ),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: AppColors.textSecondary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: AdWidget(ad: _nativeAd!),
      ),
    );
  }
}

