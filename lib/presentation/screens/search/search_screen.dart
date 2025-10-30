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
final sortByProvider = StateProvider<String>((ref) => 'popularity.desc');
final regionProvider = StateProvider<String>((ref) => '');
final fromDateProvider = StateProvider<String>((ref) => '');
final toDateProvider = StateProvider<String>((ref) => '');
final genresProvider = StateProvider<String>((ref) => ''); // comma-separated genre ids

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

/// Search screen with discover listing + search
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _debouncer = Debouncer(delay: const Duration(milliseconds: 500));
  final ScrollController _scrollController = ScrollController();

  List<Movie> _discoverItems = [];
  bool _isLoadingDiscover = false;
  int _currentPage = 1;
  bool _hasMore = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadDiscover(reset: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debouncer.call(() {
      ref.read(searchQueryProvider.notifier).state = query;
      if (query.isEmpty) {
        _loadDiscover(reset: true);
      }
    });
  }

  Future<void> _loadDiscover({bool reset = false}) async {
    if (_isLoadingDiscover) return;
    if (reset) {
      setState(() {
        _discoverItems = [];
        _currentPage = 1;
        _hasMore = true;
        _error = '';
      });
    }
    if (!_hasMore) return;

    setState(() {
      _isLoadingDiscover = true;
      _error = '';
    });

    try {
      final sortBy = ref.read(sortByProvider);
      final region = ref.read(regionProvider);
      final fromDate = ref.read(fromDateProvider);
      final toDate = ref.read(toDateProvider);
      final genres = ref.read(genresProvider);
      final bodyParams = [
        'page=$_currentPage',
        if (sortBy.isNotEmpty) 'sort_by=$sortBy',
        if (region.isNotEmpty) 'watch_region=$region',
        if (fromDate.isNotEmpty) 'release_date.gte=$fromDate',
        if (toDate.isNotEmpty) 'release_date.lte=$toDate',
        if (genres.isNotEmpty) 'with_genres=$genres',
      ].join('&');
      final movies = await ScrapingService.instance.fetchAndCacheMoviesHtmlPaged(
        endpointKey: 'discover_${sortBy}',
        url: 'https://www.themoviedb.org/discover/movie',
        page: _currentPage,
        extraHeaders: {
          'x-requested-with': 'XMLHttpRequest',
          'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
        },
        body: bodyParams,
        post: true,
        uniqueComposite: 'discover_${sortBy}',
      );
      final items = movies.map((m) => m.toEntity()).toList();
      setState(() {
        _discoverItems = [..._discoverItems, ...items];
        _hasMore = items.length >= 20;
        _currentPage += 1;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) setState(() => _isLoadingDiscover = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      final q = ref.read(searchQueryProvider);
      if (q.isEmpty) _loadDiscover();
    }
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
        title: _buildSearchBar(),
        actions: [
          if (searchQuery.isEmpty)
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'Filters',
              onPressed: _openFiltersSheet,
            ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              ref.read(searchQueryProvider.notifier).state = '';
              _loadDiscover(reset: true);
            },
          ),
        ],
      ),
      body: searchResults == null
          ? _buildDiscoverBody()
          : searchResults.when(
              data: (movies) => movies.isEmpty
                  ? _buildNoResults()
                  : _buildSearchResults(movies),
              loading: () => const Center(child: LoadingIndicator()),
              error: (error, stackTrace) => AppErrorWidget(
                message: 'Failed to search movies',
                onRetry: () => ref.invalidate(searchResultsProvider(searchQuery)),
              ),
            ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: false,
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
                    _loadDiscover(reset: true);
                  },
                )
              : null,
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildDiscoverBody() {
    if (_error.isNotEmpty && _discoverItems.isEmpty) {
      return AppErrorWidget(
        message: _error,
        onRetry: () => _loadDiscover(reset: true),
      );
    }
    return NotificationListener<OverscrollIndicatorNotification>(
      onNotification: (_) {
        return false;
      },
      child: ListView(
        controller: _scrollController,
        padding: EdgeInsets.all(AppDimensions.space16),
        children: [
          const AdBannerWidget(),
          SizedBox(height: AppDimensions.space16),
          _buildGrid(_discoverItems),
          if (_isLoadingDiscover && _discoverItems.isNotEmpty) ...[
            SizedBox(height: AppDimensions.space16),
            const Center(child: LoadingIndicator()),
          ],
          SizedBox(height: AppDimensions.space16),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return const EmptyStateWidget(
      message: 'No results found.\nTry a different search term.',
      icon: Icons.search_off,
    );
  }

  Widget _buildSearchResults(List<Movie> movies) {
    return ListView(
      padding: EdgeInsets.all(AppDimensions.space16),
      children: [
        const AdBannerWidget(),
        SizedBox(height: AppDimensions.space16),
        _buildGrid(movies),
      ],
    );
  }

  Widget _buildGrid(List<Movie> movies) {
    return GridView.builder(
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
    );
  }

  void _openFiltersSheet() {
    final sortBy = ref.read(sortByProvider);
    final region = ref.read(regionProvider);
    final genres = ref.read(genresProvider);
    final from = ref.read(fromDateProvider);
    final to = ref.read(toDateProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      isScrollControlled: true,
      builder: (context) {
        String localSort = sortBy;
        String localRegion = region;
        String localGenres = genres;
        String localFrom = from;
        String localTo = to;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (context, setModal) {
              return SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(AppDimensions.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Filters', style: AppTextStyles.sectionTitle),
                      SizedBox(height: AppDimensions.space12),
                      // Sort
                      DropdownButton<String>(
                        value: localSort,
                        items: const [
                          DropdownMenuItem(value: 'popularity.desc', child: Text('Popularity ↓')),
                          DropdownMenuItem(value: 'vote_average.desc', child: Text('Rating ↓')),
                          DropdownMenuItem(value: 'primary_release_date.desc', child: Text('Release date ↓')),
                          DropdownMenuItem(value: 'title.asc', child: Text('Title A→Z')),
                        ],
                        onChanged: (v) => setModal(() => localSort = v ?? localSort),
                        isExpanded: true,
                      ),
                      SizedBox(height: AppDimensions.space12),
                      // Region
                      DropdownButton<String>(
                        value: localRegion.isEmpty ? '' : localRegion,
                        items: const [
                          DropdownMenuItem(value: '', child: Text('Any Region')),
                          DropdownMenuItem(value: 'US', child: Text('US')),
                          DropdownMenuItem(value: 'GB', child: Text('UK')),
                          DropdownMenuItem(value: 'GH', child: Text('Ghana')),
                          DropdownMenuItem(value: 'IN', child: Text('India')),
                        ],
                        onChanged: (v) => setModal(() => localRegion = v ?? localRegion),
                        isExpanded: true,
                      ),
                      SizedBox(height: AppDimensions.space12),
                      // Genres
                      TextField(
                        controller: TextEditingController(text: localGenres),
                        decoration: const InputDecoration(hintText: 'Genres (comma-separated IDs)'),
                        onChanged: (v) => localGenres = v.trim(),
                      ),
                      SizedBox(height: AppDimensions.space12),
                      // Dates
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.date_range),
                              label: Text(localFrom.isEmpty ? 'From' : localFrom),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(1970),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  final y = picked.year.toString().padLeft(4, '0');
                                  final m = picked.month.toString().padLeft(2, '0');
                                  final d = picked.day.toString().padLeft(2, '0');
                                  setModal(() => localFrom = '$y-$m-$d');
                                }
                              },
                            ),
                          ),
                          SizedBox(width: AppDimensions.space12),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.event),
                              label: Text(localTo.isEmpty ? 'To' : localTo),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(1970),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  final y = picked.year.toString().padLeft(4, '0');
                                  final m = picked.month.toString().padLeft(2, '0');
                                  final d = picked.day.toString().padLeft(2, '0');
                                  setModal(() => localTo = '$y-$m-$d');
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppDimensions.space16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          SizedBox(width: AppDimensions.space12),
                          ElevatedButton(
                            onPressed: () {
                              ref.read(sortByProvider.notifier).state = localSort;
                              ref.read(regionProvider.notifier).state = localRegion;
                              ref.read(genresProvider.notifier).state = localGenres;
                              ref.read(fromDateProvider.notifier).state = localFrom;
                              ref.read(toDateProvider.notifier).state = localTo;
                              Navigator.pop(context);
                              _loadDiscover(reset: true);
                            },
                            child: const Text('Apply'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

