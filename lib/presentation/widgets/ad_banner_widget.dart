import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../app/themes/app_colors.dart';
import '../../app/themes/app_dimensions.dart';
import '../../services/ads/ad_service.dart';
import '../../services/iap/subscription_manager.dart';
import '../../presentation/providers/subscription_provider.dart';

/// Ad banner widget (respects Pro status - no ads for Pro users)
class AdBannerWidget extends ConsumerStatefulWidget {
  final bool showAd;
  
  const AdBannerWidget({
    super.key,
    this.showAd = true,
  });

  @override
  ConsumerState<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends ConsumerState<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _maybeLoadAd();
  }

  void _maybeLoadAd() {
    // Check Pro status before loading ads
    final isPro = SubscriptionManager.instance.isProUser;
    if (widget.showAd && !isPro) {
      // Delay ad loading to ensure AdMob is fully initialized
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && !SubscriptionManager.instance.isProUser) {
          _loadAd();
        }
      });
    }
  }

  void _loadAd() {
    print('🔍 [BANNER] Loading banner ad...');
    _bannerAd = AdService.instance.loadBannerAd(
      onAdLoaded: (ad) {
        print('✅ [BANNER] Banner ad loaded successfully');
        if (mounted) {
          setState(() {
            _isAdLoaded = true;
          });
        }
      },
      onAdFailedToLoad: (ad, error) {
        // Code 3 is "No fill" - normal occurrence, log as info not error
        if (error.code == 3) {
          // No fill is normal - AdMob doesn't always have ads available
          // Silently handle this - widget will just not show an ad
        } else {
          print('❌ [BANNER] Banner ad failed to load: ${error.message}, Code: ${error.code}, Domain: ${error.domain}');
        }
        if (mounted) {
          setState(() {
            _isAdLoaded = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch Pro status - dispose ad if user becomes Pro
    final isPro = ref.watch(isProUserProvider);
    
    // Dispose ad if user becomes Pro
    if (isPro && _bannerAd != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _bannerAd?.dispose();
        _bannerAd = null;
        if (mounted) {
          setState(() {
            _isAdLoaded = false;
          });
        }
      });
    }
    
    // Don't show ads for Pro users or if ad not loaded
    if (isPro || !widget.showAd || !_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      margin: EdgeInsets.symmetric(vertical: AppDimensions.space8),
      decoration: BoxDecoration(
        color: AppColors.adBackground,
        border: Border.all(color: AppColors.adBorder),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

