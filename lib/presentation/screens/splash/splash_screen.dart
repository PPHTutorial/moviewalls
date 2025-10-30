import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/permissions/permission_service.dart';
import '../home/home_screen.dart';

/// Splash screen displayed while app initializes
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _controller.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Wait at least 2 seconds for splash animation
      await Future.delayed(const Duration(seconds: 2));
      
      // Request all permissions with context
      if (mounted) {
        await PermissionService.instance.requestAllPermissions(context: context);
      }
      
      // Navigate to home
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      }
    } catch (e) {
      print('Splash initialization error: $e');
      // Still navigate even if there's an error
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children:  [
              // App Logo/Icon
              Icon(
                Icons.movie_filter_rounded,
                size: 100.w,
                color: AppColors.accentColor,
              ),
              SizedBox(height: 24.h),
              // App Name
              Text(
                AppConstants.appName,
                style: AppTextStyles.headline1.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 36.sp,
                ),
              ),
              SizedBox(height: 8.h),
              // Tagline
              Text(
                'Cinematic Wallpapers',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 48.h),
              // Loading indicator
              SizedBox(
                width: 40.w,
                height: 40.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.accentColor,
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

