import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.go('/dashboard');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Dummy logo, replace with actual SVG or image asset later
            SizedBox(height: 24.h),
            Text(
              'SACHI',
              style: TextStyle(
                color: AppTheme.white,
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            SizedBox(height: 16.h),
            Image.asset(
              'assets/images/mediastra_logo.png',
              width: 200.w,
              errorBuilder: (context, error, stackTrace) => const SizedBox(), // Fallback if image not found yet
            ),
          ],
        ),
      ),
    );
  }
}
