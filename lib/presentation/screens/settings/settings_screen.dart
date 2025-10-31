import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_review/in_app_review.dart';
import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/themes/app_dimensions.dart';
import '../../screens/pro_upgrade/pro_upgrade_screen.dart';
import '../../../services/iap/purchase_service.dart';
import '../../../services/storage/cache_service.dart';
import '../../providers/theme_provider.dart';

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
          Consumer(
            builder: (context, ref, child) {
              final themeMode = ref.watch(themeModeProvider);
              final themeModeText = themeMode == ThemeMode.light
                  ? 'Light'
                  : themeMode == ThemeMode.dark
                      ? 'Dark'
                      : 'System';
              return _buildListTile(
                icon: Icons.palette_outlined,
                title: 'Theme',
                subtitle: themeModeText,
                trailing: Switch(
                  value: themeMode == ThemeMode.dark,
                  onChanged: (value) {
                    ref.read(themeModeProvider.notifier).setThemeMode(
                          value ? ThemeMode.dark : ThemeMode.light,
                        );
                  },
                ),
              );
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
            onTap: () => _showPrivacyPolicy(context),
          ),
          _buildListTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () => _showTermsOfService(context),
          ),
          _buildListTile(
            icon: Icons.star_outline,
            title: 'Rate App',
            onTap: () => _rateApp(),
          ),
          _buildListTile(
            icon: Icons.email_outlined,
            title: 'Contact Support',
            subtitle: 'deverloper.codeink.playconsole@gmail.com',
            onTap: () => _contactSupport(),
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

  Future<void> _rateApp() async {
    final InAppReview inAppReview = InAppReview.instance;
    try {
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      } else {
        // Fallback to opening store
        await _launchUrl(
          Platform.isAndroid
              ? 'https://play.google.com/store/apps/details?id=com.codeink.stsl.movie_posters'
              : 'https://apps.apple.com/app/idYOUR_APP_ID',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open app store')),
        );
      }
    }
  }

  Future<void> _contactSupport() async {
    final email = 'deverloper.codeink.playconsole@gmail.com';
    final subject = 'MovieWalls App Support';
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=${Uri.encodeComponent(subject)}',
    );
    await _launchUrl(uri.toString());
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Text(_privacyPolicyText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: SingleChildScrollView(
          child: Text(_termsOfServiceText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static String get _privacyPolicyText => '''
PRIVACY POLICY

Last updated: ${DateTime.now().year}

1. INFORMATION WE COLLECT
We collect information that you provide directly to us, such as when you create an account, make a purchase, or contact us for support.

2. HOW WE USE YOUR INFORMATION
- To provide and maintain our service
- To notify you about changes to our service
- To provide customer support
- To gather analysis or valuable information to improve our service
- To monitor the usage of our service
- To detect, prevent and address technical issues

3. DATA STORAGE
We store your data locally on your device. Some data may be synced with cloud services for backup purposes.

4. THIRD-PARTY SERVICES
Our app uses third-party services that may collect information used to identify you, including:
- Google Mobile Ads
- In-App Purchase services

5. SECURITY
We value your trust in providing us your Personal Information, thus we strive to use commercially acceptable means of protecting it.

6. CONTACT US
If you have any questions about this Privacy Policy, please contact us at deverloper.codeink.playconsole@gmail.com
''';

  static String get _termsOfServiceText => '''
TERMS OF SERVICE

Last updated: ${DateTime.now().year}

1. ACCEPTANCE OF TERMS
By accessing and using MovieWalls, you accept and agree to be bound by the terms and provision of this agreement.

2. USE LICENSE
Permission is granted to temporarily download one copy of the materials on MovieWalls for personal, non-commercial transitory viewing only.

3. DISCLAIMER
The materials on MovieWalls are provided on an 'as is' basis. MovieWalls makes no warranties, expressed or implied, and hereby disclaims and negates all other warranties.

4. LIMITATIONS
In no event shall MovieWalls or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit) arising out of the use or inability to use the materials on MovieWalls.

5. IN-APP PURCHASES
In-app purchases are processed by the respective app store (Google Play or App Store). All sales are final unless required by law.

6. SUBSCRIPTION TERMS
- Subscriptions auto-renew unless cancelled
- You can cancel anytime through your app store account
- No refunds for partial subscription periods

7. CONTENT
All movie poster and backdrop images are provided for personal use only. Redistribution or commercial use is prohibited.

8. MODIFICATIONS
MovieWalls may revise these terms at any time without notice. By using this app, you agree to be bound by the current version of these terms.

9. CONTACT INFORMATION
For questions about these Terms, please contact us at deverloper.codeink.playconsole@gmail.com
''';
}

