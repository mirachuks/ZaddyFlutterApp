import 'package:flutter/material.dart';
import 'dart:async';
import '../../config/theme.dart';
import '../../widgets/index.dart';
import '../../models/parcel_model.dart';

class RiderSearchingScreen extends StatefulWidget {
  final List<Parcel> parcels;
  final double estimatedFare;
  final VoidCallback onComplete;

  const RiderSearchingScreen({
    Key? key,
    required this.parcels,
    required this.estimatedFare,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<RiderSearchingScreen> createState() => _RiderSearchingScreenState();
}

class _RiderSearchingScreenState extends State<RiderSearchingScreen>
    with TickerProviderStateMixin {
  late Timer _countdownTimer;
  int _secondsRemaining = 120; // 2 minutes
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    
    // Setup countdown timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsRemaining--;
      });
      
      // When countdown reaches 0, trigger search completion
      if (_secondsRemaining == 0) {
        _countdownTimer.cancel();
        widget.onComplete();
      }
    });

    // Setup animation for loading indicator
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  String _formatTime() {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Finding Riders',
        showBackButton: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Static icon (not animated)
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary,
                  width: 3,
                ),
              ),
              child: Icon(
                Icons.two_wheeler,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            
            const SizedBox(height: AppSpacing.xxxl),
            
            // Animated searching message with dots
            _AnimatedSearchingText(),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Fare information
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
              child: Column(
                children: [
                  Text(
                    'Offering Fare',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '₦${widget.estimatedFare.toStringAsFixed(0)}',
                    style: AppTextStyles.displayLarge.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.xxxl),
            
            // Countdown timer
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Time Remaining',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _formatTime(),
                    style: AppTextStyles.displayMedium.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.xxxl),
            
            // Parcel count
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_shipping,
                    color: AppColors.info,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    '${widget.parcels.length} parcel${widget.parcels.length > 1 ? 's' : ''} to deliver',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Animated searching text with dots
class _AnimatedSearchingText extends StatefulWidget {
  @override
  State<_AnimatedSearchingText> createState() => _AnimatedSearchingTextState();
}

class _AnimatedSearchingTextState extends State<_AnimatedSearchingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Calculate dots based on animation value (0 to 1)
        int dots = (((_animationController.value * 3) % 3) + 1).toInt();
        String dotString = '.' * dots;

        return Text(
          'Searching for nearby riders$dotString',
          style: AppTextStyles.headingMedium,
          textAlign: TextAlign.center,
        );
      },
    );
  }
}
