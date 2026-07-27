import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/index.dart';
import '../../widgets/index.dart';

class RatingScreen extends ConsumerStatefulWidget {
  final String jobId;
  final String userName;
  final String userAvatar;

  const RatingScreen({
    Key? key,
    required this.jobId,
    required this.userName,
    required this.userAvatar,
  }) : super(key: key);

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  double _rating = 0;
  bool _submitting = false;
  final _reviewController = TextEditingController();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    if (widget.jobId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing job information.')),
      );
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to submit a rating.')),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await ref.read(jobServiceProvider).rateJob(
            widget.jobId,
            _rating,
            _reviewController.text.trim().isEmpty
                ? null
                : _reviewController.text.trim(),
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rating submitted successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit rating: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Rate Delivery',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // User Avatar
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.person_outline,
                  color: AppColors.primary,
                  size: 50,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // User Name
            Text(
              'Rate ${widget.userName}',
              style: AppTextStyles.headingMedium,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Star Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = (index + 1).toDouble()),
                  child: Icon(
                    _rating > index ? Icons.star : Icons.star_outline,
                    size: 48,
                    color: AppColors.accent,
                  ),
                );
              }),
            ),

            const SizedBox(height: AppSpacing.md),

            // Rating Text
            Text(
              _rating == 0
                  ? 'Select a rating'
                  : '${_rating.toInt()} Star${_rating > 1 ? 's' : ''}',
              style: AppTextStyles.bodyMedium,
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // Review Text
            Text(
              'Write a Review',
              style: AppTextStyles.headingSmall,
            ),

            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: _reviewController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Share your experience with this delivery...',
                filled: true,
                fillColor: AppColors.surfaceVariant,
              ),
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // Submit Button
            PrimaryButton(
              label: _submitting ? 'Submitting...' : 'Submit Rating',
              onPressed: _submitting ? null : _submitRating,
            ),

            const SizedBox(height: AppSpacing.md),

            // Skip Button
            SecondaryButton(
              label: 'Skip',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
