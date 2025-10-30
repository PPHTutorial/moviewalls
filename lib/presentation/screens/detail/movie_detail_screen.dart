import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/themes/app_dimensions.dart';
import '../../../domain/entities/movie.dart';
import '../../../services/storage/download_service.dart';
import '../../../services/storage/wallpaper_service.dart';
import '../../../services/ads/ad_service.dart';
// Data fetching removed during rebuild
import '../../../services/permissions/permission_service.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/cached_image_widget.dart';
import '../../widgets/loading_indicator.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../../services/scraping/scraping_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/image_processing/image_pipeline_service.dart';
import '../../../services/image_processing/image_optimizer_service.dart';
import '../../../core/constants/tmdb_endpoints.dart';

/// Complete movie detail screen with posters and backdrops gallery
class MovieDetailScreen extends ConsumerStatefulWidget {
  final Movie movie;

  const MovieDetailScreen({
    super.key,
    required this.movie,
  });

  @override
  ConsumerState<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends ConsumerState<MovieDetailScreen> {
  int _selectedTab = 1; // 0: Backdrops, 1: Posters
  bool _isDownloadingAll = false;

  List<String> _allPosters = [];
  List<String> _allBackdrops = [];
  bool _isLoadingImages = false;

  // Movie details from HTML scraping
  String? _overview;
  String? _tagline;
  String? _runtime;
  String? _releaseDate;
  String? _certification;
  List<String> _genres = [];
  String? _userScore;

  static const String _imageBase = 'https://image.tmdb.org/t/p';
  String _imageUrl(String path, {String size = 'w500'}) => '$_imageBase/$size$path';

  @override
  void initState() {
    super.initState();
    _fetchAllImages(); // Stubbed during logic rebuild
    _fetchMovieDetails(); // Stubbed during logic rebuild
  }

  Future<void> _fetchMovieDetails() async {
    try {
      final mediaType = widget.movie.mediaType.isNotEmpty ? widget.movie.mediaType : 'movie';
      final map = await ScrapingService.instance.fetchDetails(
        mediaType: mediaType,
        id: widget.movie.id,
      );
      if (!mounted) return;
      setState(() {
        _overview = map['overview'] as String?;
        _tagline = map['tagline'] as String?;
        _runtime = map['runtime'] as String?;
        _releaseDate = map['releaseDate'] as String?;
        _certification = map['certification'] as String?;
        _genres = (map['genres'] as List?)?.cast<String>() ?? [];
        _userScore = map['userScore'] as String?;
      });
    } catch (e) {
      // keep UI resilient
    }
  }

  Future<void> _fetchAllImages() async {
    setState(() => _isLoadingImages = true);
    try {
      final mediaType = widget.movie.mediaType.isNotEmpty ? widget.movie.mediaType : 'movie';
      final posters = await ScrapingService.instance.fetchImages(
        mediaType: mediaType,
        id: widget.movie.id,
        kind: 'posters',
      );
      final backdrops = await ScrapingService.instance.fetchImages(
        mediaType: mediaType,
        id: widget.movie.id,
        kind: 'backdrops',
      );
      if (!mounted) return;
      setState(() {
        _allPosters = posters;
        _allBackdrops = backdrops;
        _isLoadingImages = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingImages = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final isFavorite = ref.watch(isFavoriteProvider(widget.movie.id));
              return IconButton(
                icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                onPressed: () {
                  ref
                      .read(favoritesProviders.notifier)
                      .toggleFavorite(widget.movie);
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              try {
                await Share.share(
                  'Check out ${widget.movie.title}!\nDownload the MovieWalls app for amazing wallpapers!',
                  subject: widget.movie.title,
                );
              } catch (e) {
                print('Share failed: $e');
              }
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Hero Image (restored) with watermark
          SliverToBoxAdapter(
            child: SizedBox(
              height: 300.h,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.movie.hasBackdrop)
                    CachedImageWidget(
                      imageUrl: TMDBEndpoints.backdropUrl(
                        widget.movie.backdropPath!,
                        size: BackdropSize.w1280,
                      ),
                      fit: BoxFit.cover,
                    )
                  else if (widget.movie.hasPoster)
                    CachedImageWidget(
                      imageUrl: TMDBEndpoints.posterUrl(
                        widget.movie.posterPath!,
                        size: PosterSize.w780,
                      ),
                      fit: BoxFit.cover,
                    )
                  else
                    Container(color: AppColors.darkSurface),
                  // gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                  // Watermark overlay
                  Positioned(
                    right: AppDimensions.space12,
                    bottom: AppDimensions.space12,
                    child: Opacity(
                      opacity: AppConstants.watermarkOpacity,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppDimensions.space8,
                          vertical: AppDimensions.space4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          AppConstants.watermarkText,
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Rating
                Padding(
                  padding: EdgeInsets.all(AppDimensions.space20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.movie.title,
                        style: AppTextStyles.headline3,
                      ),
                      SizedBox(height: AppDimensions.space8),
                      Row(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star,
                                  size: 18.w, color: AppColors.ratingGold),
                              SizedBox(width: 4.w),
                              Text(
                                widget.movie.formattedRating,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (_userScore != null) ...[
                            SizedBox(width: 12.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                borderRadius: BorderRadius.circular(4.w),
                              ),
                              child: Text(
                                '${_userScore}%',
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Overview with Read More
                if (_overview != null && _overview!.isNotEmpty) ...[
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: AppDimensions.space20),
                    child: Container(
                      padding: EdgeInsets.all(AppDimensions.space16),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurface,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMedium),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 20.w, color: AppColors.accentColor),
                              SizedBox(width: 8.w),
                              Text('Overview',
                                  style: AppTextStyles.sectionTitle),
                            ],
                          ),
                          SizedBox(height: AppDimensions.space12),
                          Text(
                            _overview!,
                            style:
                                AppTextStyles.bodyMedium.copyWith(height: 1.5),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: AppDimensions.space8),
                          InkWell(
                            onTap: () => _showFullOverview(context),
                            child: Text(
                              'Read more',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: AppDimensions.space24),
                ],

                // Gallery Tabs
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: AppDimensions.space20),
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                            child: _buildTabButton(
                                'Posters', 1, Icons.aspect_ratio)),
                        Expanded(
                            child:
                                _buildTabButton('Backdrops', 0, Icons.photo)),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: AppDimensions.space20),

                // Gallery
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: AppDimensions.space20),
                  child: _buildGallery(),
                ),

                SizedBox(height: 100.h),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildTabButton(String label, int index, IconData icon) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
        // Fetch images when switching tabs
        if (_allPosters.isEmpty && _allBackdrops.isEmpty) {
          _fetchAllImages();
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: AppDimensions.space12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isSelected ? Colors.white : AppColors.textSecondary),
            SizedBox(width: 4.w),
            Text(
              label,
              style: AppTextStyles.button.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGallery() {
    if (_isLoadingImages) {
      return const LoadingIndicator(size: 48);
    }

    // Use fetched images
    final List<String> images = _selectedTab == 0 ? _allBackdrops : _allPosters;

    if (images.isEmpty) {
      print(
          '🔍 [MOVIE DETAIL] No images available for movie ID: ${widget.movie.id}, Tab: ${_selectedTab == 0 ? "Backdrops" : "Posters"}');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 48.w,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: AppDimensions.space16),
            Text(
              'No images available',
              style: AppTextStyles.bodyMedium,
            ),
            SizedBox(height: AppDimensions.space8),
            Text(
              'Movie ID: ${widget.movie.id}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppDimensions.space12,
          crossAxisSpacing: AppDimensions.space12,
          childAspectRatio:
              _selectedTab == 0 ? 1.78 : 0.67, // Backdrop vs Poster ratio
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          final rawPath = images[index];
          if (_selectedTab == 0) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              child: CachedImageWidget(
                imageUrl: TMDBEndpoints.backdropUrl(rawPath, size: BackdropSize.w1280),
                fit: BoxFit.cover,
              ),
            );
          } else {
            return ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              child: CachedImageWidget(
                imageUrl: TMDBEndpoints.posterUrl(rawPath, size: PosterSize.w780),
                fit: BoxFit.cover,
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildBottomActions() {
    final isPro = ref.read(isProUserProvider);
    final totalImages = _allPosters.length + _allBackdrops.length;

    return Container(
      padding: EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isPro) ...[
            InkWell(
              onTap: () {
                Navigator.pushNamed(context, '/pro-upgrade');
              },
              child: Container(
                padding: EdgeInsets.all(AppDimensions.space12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.proGradientStart,
                      AppColors.proGradientEnd
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMedium),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, color: Colors.white, size: 20.w),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Upgrade to Pro to download all $totalImages images!',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: AppDimensions.space12),
          ],
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isDownloadingAll
                      ? null
                      : () => _handleDownloadAll(context),
                  icon: _isDownloadingAll
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(isPro ? Icons.download : Icons.ads_click),
                  label: Text(isPro
                      ? 'Download All ($totalImages)'
                      : 'Watch Ad to Download'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentColor,
                    padding:
                        EdgeInsets.symmetric(vertical: AppDimensions.space12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleDownloadAll(BuildContext context) async {
    final isPro = ref.read(isProUserProvider);

    // Check if user is Pro
    if (!isPro) {
      // Show dialog to upgrade or watch ads
      final shouldUpgrade = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Download All Images'),
          content: const Text(
              'You need to upgrade to Pro or watch 10 ads to download all images.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Watch Ads'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/pro-upgrade');
              },
              child: const Text('Upgrade to Pro'),
            ),
          ],
        ),
      );

      if (shouldUpgrade == null || !shouldUpgrade) return;

      // Watch 10 ads
      for (int i = 0; i < 10; i++) {
        await AdService.instance.showRewardedAd();
        print('🔍 [DOWNLOAD] Watched ad ${i + 1}/10');
      }
    }

    await _downloadAllImages();
  }

  Future<void> _downloadAllImages() async {
    setState(() => _isDownloadingAll = true);

    try {
      await PermissionService.instance.requestAllPermissions();
      if (!await PermissionService.instance.hasStoragePermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission denied')),
          );
        }
        return;
      }

      final selectedImage = _getCurrentImage();
      print('🔍 Download: Selected image path: $selectedImage');

      if (selectedImage == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No image available')),
          );
        }
        return;
      }

      final url = _imageUrl(
        selectedImage,
        size: 'original',
      );

      print('🔍 Download: URL = $url');

      // Check if user is Pro
      final isProUser = ref.read(isProUserProvider);

      await DownloadService.instance.downloadWallpaper(
        imageUrl: url,
        movieTitle: widget.movie.title,
        isPro: isProUser,
      );

      print('🔍 Download: Download completed');

      // Show interstitial ad after download
      await AdService.instance.showInterstitialAfterDownload();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download completed!')),
        );
      }
    } catch (e, stackTrace) {
      print('❌ Download Error: $e');
      print('❌ Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloadingAll = false);
      }
    }
  }

  String? _getCurrentImage() {
    print('🔍 Current tab: ${_selectedTab == 0 ? "Backdrops" : "Posters"}');
    print('🔍 All backdrops count: ${_allBackdrops.length}');
    print('🔍 All posters count: ${_allPosters.length}');

    // Get images from fetched gallery first
    final images = _selectedTab == 0 ? _allBackdrops : _allPosters;

    if (images.isNotEmpty) {
      print('🔍 Using gallery image: ${images[0]}');
      return images[0];
    }

    // Fallback to movie's default image
    final fallbackImages = _selectedTab == 0
        ? [
            if (widget.movie.backdropPath != null) widget.movie.backdropPath!,
          ]
        : [
            if (widget.movie.posterPath != null) widget.movie.posterPath!,
          ];

    final selected = fallbackImages.isNotEmpty ? fallbackImages[0] : null;
    print('🔍 Selected fallback image: $selected');
    return selected;
  }

  void _showFullOverview(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusLarge),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: AppDimensions.space12),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.textSecondary,
                borderRadius: BorderRadius.circular(2.w),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.space20,
                vertical: AppDimensions.space16,
              ),
              child: Row(
                children: [
                  Container(
                    width: 50.w,
                    height: 50.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accentColor,
                          AppColors.accentColor.withOpacity(0.7),
                        ],
                      ),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                    child: Icon(
                      Icons.movie,
                      color: Colors.white,
                      size: 28.w,
                    ),
                  ),
                  SizedBox(width: AppDimensions.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.movie.title,
                          style: AppTextStyles.headline4,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_tagline != null && _tagline!.isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          Text(
                            _tagline!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding:
                    EdgeInsets.symmetric(horizontal: AppDimensions.space20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Synopsis
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(AppDimensions.space20),
                      decoration: BoxDecoration(
                        color: AppColors.darkBackground,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMedium),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.format_quote,
                                size: 24.w,
                                color: AppColors.accentColor,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Synopsis',
                                style: AppTextStyles.sectionTitle.copyWith(
                                  fontSize: 18.sp,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: AppDimensions.space16),
                          Text(
                            _overview ?? 'No overview available',
                            style: AppTextStyles.bodyMedium.copyWith(
                              height: 1.6,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: AppDimensions.space20),

                    // Additional details
                    if (_certification != null ||
                        _releaseDate != null ||
                        _runtime != null ||
                        _genres.isNotEmpty) ...[
                      Text(
                        'Details',
                        style: AppTextStyles.sectionTitle.copyWith(
                          fontSize: 18.sp,
                        ),
                      ),
                      SizedBox(height: AppDimensions.space16),
                      Wrap(
                        spacing: AppDimensions.space12,
                        runSpacing: AppDimensions.space12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (_certification != null &&
                              _certification!.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 10.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusSmall),
                                border: Border.all(
                                  color: AppColors.accentColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentColor,
                                      borderRadius: BorderRadius.circular(6.w),
                                    ),
                                    child: Text(
                                      _certification!,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'Rating',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_releaseDate != null && _releaseDate!.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 10.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.darkSurface,
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusSmall),
                                border: Border.all(
                                  color:
                                      AppColors.textSecondary.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.calendar_today,
                                      size: 16.w,
                                      color: AppColors.textSecondary),
                                  SizedBox(width: 8.w),
                                  Text(
                                    _releaseDate!,
                                    style: TextStyle(fontSize: 14.sp),
                                  ),
                                ],
                              ),
                            ),
                          if (_runtime != null && _runtime!.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 10.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.darkSurface,
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusSmall),
                                border: Border.all(
                                  color:
                                      AppColors.textSecondary.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time,
                                      size: 16.w,
                                      color: AppColors.textSecondary),
                                  SizedBox(width: 8.w),
                                  Text(
                                    _runtime!,
                                    style: TextStyle(fontSize: 14.sp),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (_genres.isNotEmpty) ...[
                        SizedBox(height: AppDimensions.space12),
                        Wrap(
                          spacing: AppDimensions.space12,
                          runSpacing: AppDimensions.space12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: _genres.map((genre) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 10.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.darkBackground,
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusSmall),
                                border: Border.all(
                                  color:
                                      AppColors.textSecondary.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                genre,
                                style: TextStyle(fontSize: 14.sp),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      SizedBox(height: AppDimensions.space20),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// Full screen image viewer
class _ImageFullScreenView extends StatefulWidget {
  final String imageUrl;
  final String rawPath;
  final bool isBackdrop;
  final String movieTitle;

  const _ImageFullScreenView({
    required this.imageUrl,
    required this.rawPath,
    required this.isBackdrop,
    required this.movieTitle,
  });

  @override
  State<_ImageFullScreenView> createState() => _ImageFullScreenViewState();
}

class _ImageFullScreenViewState extends State<_ImageFullScreenView> {
  bool _isDownloading = false;
  bool _isSettingWallpaper = false;

  Future<void> _download() async {
    setState(() => _isDownloading = true);

    try {
      final status = await PermissionService.instance.hasStoragePermission();
      if (!status) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission denied')),
          );
        }
        return;
      }

      // Ask user for desired size
      final size = await _pickSize(context, widget.isBackdrop);
      if (size == null) {
        return;
      }

      // Generate local variant (with watermark for free) and save locally via DownloadService
      final variant = await ImagePipelineService.instance.getLocalVariant(
        rawPathOrUrl: widget.rawPath,
        size: size,
        isBackdrop: widget.isBackdrop,
        watermark: true,
        isPro: false,
      );

      await DownloadService.instance.saveLocalImageFile(
        sourcePath: variant.path,
        movieTitle: widget.movieTitle,
        isPro: false,
        quality: size == 'original' ? ImageQuality.original : (size == 'w1280' || size == 'w900') ? ImageQuality.fullHd : ImageQuality.hd,
      );

      await AdService.instance.showInterstitialAfterDownload();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download completed!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  Future<String?> _pickSize(BuildContext context, bool isBackdrop) async {
    final sizes = isBackdrop
        ? <String>['w780', 'w900', 'w1280', 'original']
        : <String>['w342', 'w500', 'w780', 'w900', 'original'];
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.darkSurface,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(AppDimensions.space16),
                child: Text(
                  'Select Image Quality',
                  style: AppTextStyles.sectionTitle,
                ),
              ),
              ...sizes.map((s) => ListTile(
                    title: Text(s, style: AppTextStyles.bodyLarge),
                    onTap: () => Navigator.pop(context, s),
                  )),
              SizedBox(height: AppDimensions.space12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _setAsWallpaper() async {
    setState(() => _isSettingWallpaper = true);

    try {
      final granted = await PermissionService.instance.requestAllPermissions();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission denied')),
          );
        }
        return;
      }

      final filePath = await DownloadService.instance.downloadWallpaper(
        imageUrl: widget.imageUrl,
        movieTitle: widget.movieTitle,
        isPro: false,
      );

      if (filePath != null && File(filePath).existsSync()) {
        final success = await WallpaperService.instance.setWallpaperFromFile(
          filePath: filePath,
          location: WallpaperLocation.both,
        );

        await AdService.instance.showInterstitialAfterDownload();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(success
                    ? 'Wallpaper set successfully!'
                    : 'Failed to set wallpaper')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set wallpaper: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSettingWallpaper = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: InteractiveViewer(
        child: CachedImageWidget(
          imageUrl: widget.imageUrl,
          fit: BoxFit.contain,
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(AppDimensions.space16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              offset: const Offset(0, -2),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isDownloading ? null : _download,
                icon: _isDownloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.download, color: Colors.white),
                label: const Text('Download',
                    style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white),
                ),
              ),
            ),
            SizedBox(width: AppDimensions.space12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSettingWallpaper ? null : _setAsWallpaper,
                icon: _isSettingWallpaper
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.wallpaper),
                label: const Text('Set Wallpaper'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
