import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dio/dio.dart';
import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/themes/app_dimensions.dart';
import '../../../core/utils/debouncer.dart';
import '../../../domain/entities/movie.dart';
import '../../../services/scraping/scraping_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/ad_banner_widget.dart';
import '../home/widgets/wallpaper_grid_item.dart';
import '../detail/movie_detail_screen.dart';

/// Search screen provider
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider.family<List<Movie>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  try {
    final searchUrl = 'https://www.themoviedb.org/search/movie?query=' + Uri.encodeComponent(query);
    final scraper = ScrapingService.instance;
    final response = await Dio().get<String>(searchUrl, options: Options(headers: {'Accept': 'text/html, */*; q=0.01'}));
    final models = scraper.extractSearchResultsFromHtml(response.data ?? '');
    return models.map((m) => m.toEntity()).toList();
  } catch (e) {
    throw Exception('Failed to search: $e');
  }
});

/// Search screen with debouncing
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _debouncer = Debouncer(delay: const Duration(milliseconds: 500));
  
  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debouncer.call(() {
      ref.read(searchQueryProvider.notifier).state = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final searchResults = searchQuery.isNotEmpty
        ? ref.watch(searchResultsProvider(searchQuery))
        : null;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        title: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: AppTextStyles.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Search movies...',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: AppColors.textSecondary),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                      },
                    )
                  : null,
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              ref.read(searchQueryProvider.notifier).state = '';
            },
          ),
        ],
      ),
      body: searchResults == null
          ? _buildEmptyState()
          : searchResults.when(
              data: (movies) => movies.isEmpty
                  ? _buildNoResults()
                  : _buildResults(movies),
              loading: () => const Center(child: LoadingIndicator()),
              error: (error, stackTrace) => AppErrorWidget(
                message: 'Failed to search movies',
                onRetry: () => ref.invalidate(searchResultsProvider(searchQuery)),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget(
      message: 'Search for your favorite movies\nand discover amazing wallpapers',
      icon: Icons.search,
    );
  }

  Widget _buildNoResults() {
    return const EmptyStateWidget(
      message: 'No results found.\nTry a different search term.',
      icon: Icons.search_off,
    );
  }

  Widget _buildResults(List<Movie> movies) {
    return ListView(
      padding: EdgeInsets.all(AppDimensions.space16),
      children: [
        // Banner Ad
        const AdBannerWidget(),
        SizedBox(height: AppDimensions.space16),
        // GridView
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppDimensions.gridSpacing,
            crossAxisSpacing: AppDimensions.gridSpacing,
            childAspectRatio: AppDimensions.posterAspectRatio,
          ),
          itemCount: movies.length,
          itemBuilder: (context, index) {
            final movie = movies[index];
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
        ),
      ],
    );
  }
}

