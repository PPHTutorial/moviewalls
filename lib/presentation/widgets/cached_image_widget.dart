import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../app/themes/app_colors.dart';
import 'loading_indicator.dart';

/// Cached image widget with consistent loading and error states
class CachedImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  
  const CachedImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) =>
            placeholder ?? const LoadingShimmer(),
        errorWidget: (context, url, error) =>
            errorWidget ??
            Container(
              color: AppColors.darkCard,
              child: const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.textDisabled,
                  size: 40,
                ),
              ),
            ),
      ),
    );
  }
}

