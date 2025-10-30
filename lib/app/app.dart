import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'themes/app_theme.dart';
import '../core/constants/app_constants.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/pro_upgrade/pro_upgrade_screen.dart';

/// Root application widget
class MovieWallsApp extends StatelessWidget {
  const MovieWallsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone 11 Pro size as base
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const SplashScreen(),
          routes: {
            '/pro-upgrade': (context) => const ProUpgradeScreen(),
          },
        );
      },
    );
  }
}

