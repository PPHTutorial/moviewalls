import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../app/themes/app_colors.dart';
import '../../app/themes/app_dimensions.dart';
import '../../services/ads/ad_service.dart';

/// Ad banner widget
class AdBannerWidget extends StatefulWidget {
  final bool showAd;
  
  const AdBannerWidget({
    super.key,
    this.showAd = true,
  });

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.showAd) {
      // Delay ad loading to ensure AdMob is fully initialized
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
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
        print('❌ [BANNER] Banner ad failed to load: ${error.message}, Code: ${error.code}, Domain: ${error.domain}');
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
    if (!widget.showAd || !_isAdLoaded || _bannerAd == null) {
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

