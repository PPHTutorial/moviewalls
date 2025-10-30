import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/themes/app_dimensions.dart';
import '../../../core/constants/app_constants.dart';
import '../../screens/pro_upgrade/pro_upgrade_screen.dart';
import '../../../services/iap/purchase_service.dart';
import '../../../services/storage/cache_service.dart';

/// Settings screen
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _cacheSize = 'Calculating...';
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
    _loadAppInfo();
  }

  Future<void> _loadCacheSize() async {
    final size = await CacheService.instance.getFormattedCacheSize();
    if (mounted) {
      setState(() {
        _cacheSize = size;
      });
    }
  }

  Future<void> _loadAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: AppTextStyles.headline4,
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(AppDimensions.space16),
        children: [
          // Appearance Section
          _buildSectionHeader('Appearance'),
          _buildListTile(
            icon: Icons.palette_outlined,
            title: 'Theme',
            subtitle: 'Dark',
            onTap: () {
              // TODO: Theme selector
            },
          ),
          _buildListTile(
            icon: Icons.grid_view,
            title: 'Grid Size',
            subtitle: '2 columns',
            onTap: () {
              // TODO: Grid size selector
            },
          ),
          
          SizedBox(height: AppDimensions.space24),
          
          // Cache Section
          _buildSectionHeader('Storage'),
          _buildListTile(
            icon: Icons.storage,
            title: 'Cache Size',
            subtitle: _cacheSize,
          ),
          _buildListTile(
            icon: Icons.delete_outline,
            title: 'Clear Cache',
            onTap: () => _clearCache(),
          ),
          
          SizedBox(height: AppDimensions.space24),
          
          // Subscription Section
          _buildSectionHeader('Subscription'),
          _buildListTile(
            icon: Icons.star,
            title: 'Go Pro',
            subtitle: 'Unlock all features',
            trailing: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.space8,
                vertical: AppDimensions.space4,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.proGradientStart, AppColors.proGradientEnd],
                ),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              child: Text(
                'UPGRADE',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProUpgradeScreen(),
                ),
              );
            },
          ),
          _buildListTile(
            icon: Icons.restore,
            title: 'Restore Purchases',
            onTap: () async {
              try {
                await PurchaseService.instance.restorePurchases();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Restoring purchases...')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to restore: $e')),
                  );
                }
              }
            },
          ),
          
          SizedBox(height: AppDimensions.space24),
          
          // About Section
          _buildSectionHeader('About'),
          _buildListTile(
            icon: Icons.info_outline,
            title: 'App Version',
            subtitle: _appVersion,
          ),
          _buildListTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => _launchUrl(AppConstants.privacyPolicyUrl),
          ),
          _buildListTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () => _launchUrl(AppConstants.termsOfServiceUrl),
          ),
          _buildListTile(
            icon: Icons.star_outline,
            title: 'Rate App',
            onTap: () {
              // TODO: Open app store for rating
            },
          ),
          _buildListTile(
            icon: Icons.email_outlined,
            title: 'Contact Support',
            subtitle: AppConstants.supportEmail,
            onTap: () => _launchUrl('mailto:${AppConstants.supportEmail}'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppDimensions.space8,
        bottom: AppDimensions.space8,
      ),
      child: Text(
        title,
        style: AppTextStyles.labelLarge.copyWith(
          color: AppColors.accentColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: AppDimensions.space8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.accentColor),
        title: Text(title, style: AppTextStyles.bodyLarge),
        subtitle: subtitle != null
            ? Text(subtitle, style: AppTextStyles.bodySmall)
            : null,
        trailing: trailing ??
            (onTap != null
                ? const Icon(Icons.chevron_right, color: AppColors.textSecondary)
                : null),
        onTap: onTap,
      ),
    );
  }

  Future<void> _clearCache() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text(
          'This will remove all cached images. You may need to re-download wallpapers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await CacheService.instance.clearCache();
              await _loadCacheSize();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache cleared successfully')),
                );
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }
}

