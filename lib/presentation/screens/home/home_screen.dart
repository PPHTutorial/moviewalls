import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/themes/app_dimensions.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/permissions/permission_service.dart';
import '../../providers/movie_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_widget.dart';
import 'widgets/trending_carousel.dart';
import 'widgets/wallpaper_grid_item.dart';
import '../detail/movie_detail_screen.dart';
import '../search/search_screen.dart';
import '../favorites/favorites_screen.dart';
import '../settings/settings_screen.dart';
import '../../widgets/ad_banner_widget.dart';
import '../../widgets/cached_image_widget.dart';
import '../../../core/constants/tmdb_endpoints.dart';

/// Home screen with real data - Complete implementation
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _checkPermissionsOnLaunch();
  }

  Future<void> _checkPermissionsOnLaunch() async {
    // Check storage permission on app launch
    final hasStorage = await PermissionService.instance.hasStoragePermission();
    
    if (!hasStorage && mounted) {
      // Request permission with dialog
      await PermissionService.instance.requestAllPermissions(context: context);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      ref.read(popularMoviesProvider.notifier).loadNextPage();
      ref.read(trendingMoviesProvider.notifier).refresh();
      ref.read(topRatedProvider.notifier).loadNextPage();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.8);
  }

  @override
  Widget build(BuildContext context) {
    final trendingMoviesState = ref.watch(trendingMoviesProvider);
    final popularMoviesState = ref.watch(popularMoviesProvider);
    final topRatedState = ref.watch(topRatedProvider);
    // Get provider states for new sections
    final trailersState = ref.watch(trailersProvider);
    final freeToWatchState = ref.watch(freeToWatchProvider);
    final discoverState = ref.watch(discoverProvider);
    final upcomingState = ref.watch(upcomingProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(
          AppConstants.appName,
          style: AppTextStyles.headline4,
        ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FavoritesScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(trendingMoviesProvider.notifier).refresh();
          await ref.read(popularMoviesProvider.notifier).refresh();
          await ref.read(topRatedProvider.notifier).refresh();
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Trending Section
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(AppDimensions.space16),
                child: Text(
                  'Trending Now',
                  style: AppTextStyles.sectionTitle,
                ),
              ),
            ),

            // Trending Carousel
            if (trendingMoviesState.isLoading)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: AppDimensions.carouselHeight,
                  child: const LoadingIndicator(),
                ),
              )
            else if (trendingMoviesState.error != null)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: AppDimensions.carouselHeight,
                  child: AppErrorWidget(
                    message: 'Failed to load trending movies',
                    onRetry: () => ref.read(trendingMoviesProvider.notifier).refresh(),
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: TrendingCarousel(
                  movies: trendingMoviesState.items,
                  onMovieTap: (movie) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MovieDetailScreen(movie: movie),
                      ),
                    );
                  },
                ),
              ),

            SliverToBoxAdapter(child: SizedBox(height: AppDimensions.space24)),
            
            // Banner Ad
            const SliverToBoxAdapter(
              child: AdBannerWidget(),
            ),
            
            SliverToBoxAdapter(child: SizedBox(height: AppDimensions.space16)),

            // Popular Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppDimensions.space16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Popular Wallpapers', style: AppTextStyles.sectionTitle),
                    TextButton(
                      onPressed: () {
                        // Navigate to Search with popularity sort
                        ref.read(searchQueryProvider.notifier).state = '';
                        ref.read(sortByProvider.notifier).state = 'popularity.desc';
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SearchScreen()),
                        );
                      },
                      child: const Text('See more'),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: AppDimensions.space12)),

            // Top Rated Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppDimensions.space16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Top Rated', style: AppTextStyles.sectionTitle),
                    TextButton(
                      onPressed: () {
                        ref.read(searchQueryProvider.notifier).state = '';
                        ref.read(sortByProvider.notifier).state = 'vote_average.desc';
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SearchScreen()),
                        );
                      },
                      child: const Text('See more'),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: AppDimensions.space12)),

            // Top Rated Horizontal List
            if (topRatedState.items.isEmpty && topRatedState.isLoading)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 220,
                  child: Center(child: LoadingIndicator()),
                ),
              )
            else if (topRatedState.items.isEmpty && topRatedState.error != null)
              SliverToBoxAdapter(
                child: AppErrorWidget(
                  message: topRatedState.error!,
                  onRetry: () => ref.read(topRatedProvider.notifier).loadInitial(),
                ),
              )
            else
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 240,
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: AppDimensions.space16),
                    scrollDirection: Axis.horizontal,
                    itemCount: topRatedState.items.length,
                    separatorBuilder: (_, __) => SizedBox(width: AppDimensions.space12),
                    itemBuilder: (context, index) {
                      final movie = topRatedState.items[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MovieDetailScreen(movie: movie),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                          child: SizedBox(
                            width: 140,
                            child: movie.hasPoster
                                ? CachedImageWidget(
                                    imageUrl: TMDBEndpoints.posterUrl(movie.posterPath!, size: PosterSize.w500),
                                    fit: BoxFit.cover,
                                  )
                                : Container(color: AppColors.darkCard),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            SliverToBoxAdapter(child: SizedBox(height: AppDimensions.space24)),

            // Trailers Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppDimensions.space16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Latest Trailers', style: AppTextStyles.sectionTitle),
                    TextButton(
                      onPressed: () {
                        ref.read(searchQueryProvider.notifier).state = '';
                        // Use popularity for trailers discover as proxy
                        ref.read(sortByProvider.notifier).state = 'popularity.desc';
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SearchScreen()),
                        );
                      },
                      child: const Text('See more'),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: AppDimensions.space12)),

            // Trailers Horizontal List
            if (trailersState.items.isEmpty && trailersState.isLoading)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 240,
                  child: Center(child: LoadingIndicator()),
                ),
              )
            else if (trailersState.items.isEmpty && trailersState.error != null)
              SliverToBoxAdapter(
                child: AppErrorWidget(
                  message: trailersState.error!,
                  onRetry: () => ref.read(trailersProvider.notifier).loadTrailers(),
                ),
              )
            else
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 240,
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: AppDimensions.space16),
                    scrollDirection: Axis.horizontal,
                    itemCount: trailersState.items.length,
                    separatorBuilder: (_, __) => SizedBox(width: AppDimensions.space12),
                    itemBuilder: (context, index) {
                      final movie = trailersState.items[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MovieDetailScreen(movie: movie),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                          child: SizedBox(
                            width: 140,
                            child: movie.hasPoster
                                ? CachedImageWidget(
                                    imageUrl: TMDBEndpoints.posterUrl(movie.posterPath!, size: PosterSize.w500),
                                    fit: BoxFit.cover,
                                  )
                                : Container(color: AppColors.darkCard),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            SliverToBoxAdapter(child: SizedBox(height: AppDimensions.space24)),

            // Free To Watch Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppDimensions.space16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Free to Watch', style: AppTextStyles.sectionTitle),
                    TextButton(
                      onPressed: () {
                        ref.read(searchQueryProvider.notifier).state = '';
                        // Default discover without region/date filters
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SearchScreen()),
                        );
                      },
                      child: const Text('See more'),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: AppDimensions.space12)),

            // Free To Watch Horizontal List
            if (freeToWatchState.items.isEmpty && freeToWatchState.isLoading)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 240,
                  child: Center(child: LoadingIndicator()),
                ),
              )
            else if (freeToWatchState.items.isEmpty && freeToWatchState.error != null)
              SliverToBoxAdapter(
                child: AppErrorWidget(
                  message: freeToWatchState.error!,
                  onRetry: () => ref.read(freeToWatchProvider.notifier).loadFreeToWatch(),
                ),
              )
            else
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 240,
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: AppDimensions.space16),
                    scrollDirection: Axis.horizontal,
                    itemCount: freeToWatchState.items.length,
                    separatorBuilder: (_, __) => SizedBox(width: AppDimensions.space12),
                    itemBuilder: (context, index) {
                      final movie = freeToWatchState.items[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MovieDetailScreen(movie: movie),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                          child: SizedBox(
                            width: 140,
                            child: movie.hasPoster
                                ? CachedImageWidget(
                                    imageUrl: TMDBEndpoints.posterUrl(movie.posterPath!, size: PosterSize.w500),
                                    fit: BoxFit.cover,
                                  )
                                : Container(color: AppColors.darkCard),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Popular Movies Grid
            if (popularMoviesState.items.isEmpty && popularMoviesState.isLoading)
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: AppDimensions.space16),
                sliver: SliverToBoxAdapter(
                  child: GridShimmerLoading(
                    itemCount: 6,
                    aspectRatio: AppDimensions.posterAspectRatio,
                  ),
                ),
              )
            else if (popularMoviesState.items.isEmpty && popularMoviesState.error != null)
              SliverToBoxAdapter(
                child: AppErrorWidget(
                  message: popularMoviesState.error!,
                  onRetry: () => ref.read(popularMoviesProvider.notifier).loadInitial(),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.all(AppDimensions.space16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppDimensions.gridSpacing,
                    crossAxisSpacing: AppDimensions.gridSpacing,
                    childAspectRatio: AppDimensions.posterAspectRatio,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final movie = popularMoviesState.items[index];
                      return WallpaperGridItem(
                        movie: movie,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MovieDetailScreen(movie: movie),
                            ),
                          );
                        },
                      );
                    },
                    childCount: popularMoviesState.items.length,
                  ),
                ),
              ),

            // Loading indicator for pagination
            if (popularMoviesState.isLoading && popularMoviesState.items.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppDimensions.space16),
                  child: const LoadingIndicator(size: 32),
                ),
              ),

            SliverToBoxAdapter(child: SizedBox(height: AppDimensions.space24)),
            // Trailers Section
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(AppDimensions.space16),
                child: Text(
                  'Latest Trailers',
                  style: AppTextStyles.sectionTitle,
                ),
              ),
            ),
            if (trailersState.isLoading)
              SliverToBoxAdapter(child: SizedBox(height: 220, child: Center(child: LoadingIndicator())))
            else if (trailersState.error != null)
              SliverToBoxAdapter(child: AppErrorWidget(message: trailersState.error!, onRetry: () => ref.read(trailersProvider.notifier).loadTrailers()))
            else
              SliverToBoxAdapter(
                child: TrendingCarousel(
                  movies: trailersState.items,
                ),
              ),
            SliverToBoxAdapter(child: SizedBox(height: AppDimensions.space24)),
            // Free to Watch Section
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppDimensions.space16),
                child: Text('Free to Watch', style: AppTextStyles.sectionTitle),
              ),
            ),
            if (freeToWatchState.isLoading)
              SliverToBoxAdapter(child: SizedBox(height: 220, child: Center(child: LoadingIndicator())))
            else if (freeToWatchState.error != null)
              SliverToBoxAdapter(child: AppErrorWidget(message: freeToWatchState.error!, onRetry: () => ref.read(freeToWatchProvider.notifier).loadFreeToWatch()))
            else
              SliverPadding(
                padding: EdgeInsets.all(AppDimensions.space16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppDimensions.gridSpacing,
                    crossAxisSpacing: AppDimensions.gridSpacing,
                    childAspectRatio: AppDimensions.posterAspectRatio,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => WallpaperGridItem(movie: freeToWatchState.items[index]),
                    childCount: freeToWatchState.items.length,
                  ),
                ),
              ),
            SliverToBoxAdapter(child: SizedBox(height: AppDimensions.space24)),
            // Discover Section
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppDimensions.space16),
                child: Text('Discover', style: AppTextStyles.sectionTitle),
              ),
            ),
            if (discoverState.isLoading && discoverState.items.isEmpty)
              SliverToBoxAdapter(child: SizedBox(height: 220, child: Center(child: LoadingIndicator())))
            else if (discoverState.error != null && discoverState.items.isEmpty)
              SliverToBoxAdapter(child: AppErrorWidget(message: discoverState.error!, onRetry: () => ref.read(discoverProvider.notifier).loadInitial()))
            else
              SliverPadding(
                padding: EdgeInsets.all(AppDimensions.space16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppDimensions.gridSpacing,
                    crossAxisSpacing: AppDimensions.gridSpacing,
                    childAspectRatio: AppDimensions.posterAspectRatio,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => WallpaperGridItem(movie: discoverState.items[index]),
                    childCount: discoverState.items.length,
                  ),
                ),
              ),
            // Show loading at bottom for infinite scroll
            if (discoverState.isLoading && discoverState.items.isNotEmpty)
              SliverToBoxAdapter(child: Padding(
                padding: EdgeInsets.all(AppDimensions.space16),
                child: LoadingIndicator(size: 32),
              )),
            SliverToBoxAdapter(child: SizedBox(height: AppDimensions.space24)),
            // Upcoming Section
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppDimensions.space16),
                child: Text('Upcoming', style: AppTextStyles.sectionTitle),
              ),
            ),
            if (upcomingState.isLoading && upcomingState.items.isEmpty)
              SliverToBoxAdapter(child: SizedBox(height: 220, child: Center(child: LoadingIndicator())))
            else if (upcomingState.error != null && upcomingState.items.isEmpty)
              SliverToBoxAdapter(child: AppErrorWidget(message: upcomingState.error!, onRetry: () => ref.read(upcomingProvider.notifier).loadInitial()))
            else
              SliverPadding(
                padding: EdgeInsets.all(AppDimensions.space16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppDimensions.gridSpacing,
                    crossAxisSpacing: AppDimensions.gridSpacing,
                    childAspectRatio: AppDimensions.posterAspectRatio,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => WallpaperGridItem(movie: upcomingState.items[index]),
                    childCount: upcomingState.items.length,
                  ),
                ),
              ),
            // Show loading at bottom for upcoming
            if (upcomingState.isLoading && upcomingState.items.isNotEmpty)
              SliverToBoxAdapter(child: Padding(
                padding: EdgeInsets.all(AppDimensions.space16),
                child: LoadingIndicator(size: 32),
              )),
            SliverToBoxAdapter(child: SizedBox(height: AppDimensions.space32)),
          ],
        ),
      ),
    );
  }
}

