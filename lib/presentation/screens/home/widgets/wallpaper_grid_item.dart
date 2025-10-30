import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/themes/app_colors.dart';
import '../../../../app/themes/app_dimensions.dart';
import '../../../../app/themes/app_text_styles.dart';
import '../../../../domain/entities/movie.dart';
import '../../../providers/favorites_provider.dart';
import '../../../../services/image_processing/image_pipeline_service.dart';

/// Wallpaper grid item widget
class WallpaperGridItem extends ConsumerWidget {
  final Movie movie;
  final VoidCallback? onTap;
  final bool showFavoriteButton;
  
  const WallpaperGridItem({
    super.key,
    required this.movie,
    this.onTap,
    this.showFavoriteButton = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(isFavoriteProvider(movie.id));
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Poster image
              FutureBuilder(
                future: movie.hasPoster
                    ? ImagePipelineService.instance.getLocalVariant(
                        rawPathOrUrl: movie.posterPath!,
                        size: 'w500',
                        isBackdrop: false,
                        watermark: false,
                        isPro: true,
                      )
                    : null,
                builder: (context, snap) {
                  final file = snap.data;
                  if (file != null && file.existsSync()) {
                    return Image.file(file, fit: BoxFit.cover);
                  }
                  if (!movie.hasPoster) {
                    return Container(
                      color: AppColors.darkCard,
                      child: const Center(
                        child: Icon(
                          Icons.movie_outlined,
                          color: AppColors.textDisabled,
                          size: 40,
                        ),
                      ),
                    );
                  }
                  return Container(color: AppColors.darkCard);
                },
              ),
              
              // Gradient overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 100.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Movie info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: EdgeInsets.all(AppDimensions.space8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        movie.title,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      // Rating and year
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 14.w,
                            color: AppColors.ratingGold,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            movie.formattedRating,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (movie.releaseYear != null) ...[
                            SizedBox(width: 8.w),
                            Text(
                              '• ${movie.releaseYear}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Favorite button
              if (showFavoriteButton)
                Positioned(
                  top: AppDimensions.space8,
                  right: AppDimensions.space8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? AppColors.error : Colors.white,
                      ),
                      iconSize: 20.w,
                      padding: EdgeInsets.all(AppDimensions.space8),
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        ref.read(favoritesProviders.notifier).toggleFavorite(movie);
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

