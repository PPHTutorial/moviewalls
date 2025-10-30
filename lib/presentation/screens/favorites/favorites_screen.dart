import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/themes/app_dimensions.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/ad_banner_widget.dart';
import '../detail/movie_detail_screen.dart';
import '../home/widgets/wallpaper_grid_item.dart';

/// Favorites screen showing all favorited wallpapers
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProviders);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(
          'Favorites',
          style: AppTextStyles.headline4,
        ),
        actions: [
          if (favorites.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                _showClearConfirmation(context, ref);
              },
              tooltip: 'Clear all favorites',
            ),
        ],
      ),
      body: favorites.isEmpty
          ? EmptyStateWidget(
              message: 'No favorites yet.\nStart adding wallpapers you love!',
              icon: Icons.favorite_border,
              action: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Explore Wallpapers'),
              ),
            )
          : ListView(
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
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final movie = favorites[index];
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
            ),
    );
  }
  
  void _showClearConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Favorites?'),
        content: const Text(
          'This will remove all your favorite wallpapers. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(favoritesProviders.notifier).clearAll();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

