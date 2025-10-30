import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../app/themes/app_colors.dart';
import '../../../../app/themes/app_dimensions.dart';
import '../../../../app/themes/app_text_styles.dart';
import 'package:movie_posters/services/image_processing/image_pipeline_service.dart';
import '../../search/search_screen.dart';
import '../../../../domain/entities/movie.dart';

/// Trending movies carousel
class TrendingCarousel extends StatefulWidget {
  final List<Movie> movies;
  final Function(Movie)? onMovieTap;
  
  const TrendingCarousel({
    super.key,
    required this.movies,
    this.onMovieTap,
  });

  @override
  State<TrendingCarousel> createState() => _TrendingCarouselState();
}

class _TrendingCarouselState extends State<TrendingCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.movies.isEmpty) {
      return const SizedBox.shrink();
    }
     
    
    // Take only first 10 for carousel
    final limit = 5;
    final base = widget.movies.take(limit).toList();
    // create a sentinel for see more
    final carouselMovies = base;
    
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: carouselMovies.length + 1,
          itemBuilder: (context, index, realIndex) {
            if (index == carouselMovies.length) {
              return _buildSeeMoreCard(context);
            }
            final movie = carouselMovies[index];
            return _buildCarouselItem(movie);
          },
          options: CarouselOptions(
            height: AppDimensions.carouselHeight,
            viewportFraction: 0.85,
            enlargeCenterPage: true,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
        SizedBox(height: AppDimensions.space12),
        AnimatedSmoothIndicator(
          activeIndex: _currentIndex,
          count: carouselMovies.length,
          effect: ExpandingDotsEffect(
            activeDotColor: AppColors.accentColor,
            dotColor: AppColors.textDisabled,
            dotHeight: 8.h,
            dotWidth: 8.w,
            spacing: 4.w,
          ),
        ),
      ],
    );
  }
  
  Widget _buildCarouselItem(Movie movie) {
    return GestureDetector(
      onTap: () => widget.onMovieTap?.call(movie),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: AppDimensions.space4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          child: Stack(
            fit: StackFit.expand,
            children: [
              FutureBuilder(
                future: movie.hasBackdrop
                    ? ImagePipelineService.instance.getLocalVariant(
                        rawPathOrUrl: movie.backdropPath!,
                        size: 'w1280',
                        isBackdrop: true,
                        watermark: false,
                        isPro: true,
                      )
                    : movie.hasPoster
                        ? ImagePipelineService.instance.getLocalVariant(
                            rawPathOrUrl: movie.posterPath!,
                            size: 'w780',
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
                  if (!movie.hasBackdrop && !movie.hasPoster) {
                    return Container(
                      color: AppColors.darkCard,
                      child: const Center(
                        child: Icon(
                          Icons.movie_outlined,
                          color: AppColors.textDisabled,
                          size: 60,
                        ),
                      ),
                    );
                  }
                  return Container(color: AppColors.darkCard);
                },
              ),
              
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              
              // Movie info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: EdgeInsets.all(AppDimensions.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Trending badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppDimensions.space8,
                          vertical: AppDimensions.space4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentColor,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSmall,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.trending_up,
                              size: 14.w,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'TRENDING',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: AppDimensions.space8),
                      // Title
                      Text(
                        movie.title,
                        style: AppTextStyles.headline5,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: AppDimensions.space4),
                      // Rating
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 18.w,
                            color: AppColors.ratingGold,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            movie.formattedRating,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (movie.releaseYear != null) ...[
                            SizedBox(width: 12.w),
                            Text(
                              '• ${movie.releaseYear}',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeeMoreCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SearchScreen()),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: AppDimensions.space4),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        ),
        child: Center(
          child: Text(
            'See more',
            style: AppTextStyles.headline5,
          ),
        ),
      ),
    );
  }
}

