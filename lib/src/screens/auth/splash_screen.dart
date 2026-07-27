import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../models/index.dart';
import '../../providers/index.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    final authState = ref.read(authStateProvider);
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    final hasShownSplash = prefs.getBool('has_shown_splash') ?? false;

    // Mark that the splash has been shown so next app open skips it
    if (!hasShownSplash) {
      await prefs.setBool('has_shown_splash', true);
    }

    if (authState.isInitialized) {
      if (authState.isAuthenticated) {
        if (authState.currentRole == UserType.rider) {
          Navigator.of(context).pushReplacementNamed('/rider-dashboard');
        } else {
          Navigator.of(context).pushReplacementNamed('/customer-dashboard');
        }
      } else if (hasSeenOnboarding) {
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) _navigateToNextScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(
                  Icons.delivery_dining,
                  size: 50,
                  color: AppColors.textInverse,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'ZaddyExpress',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textInverse,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Fast & Reliable Delivery',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.accent,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
