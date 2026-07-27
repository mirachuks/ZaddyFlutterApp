import 'package:flutter/material.dart';
import '../config/theme.dart';

class StepProgressIndicator extends StatelessWidget {
  final int totalSteps;
  final int currentStep;
  final List<String> stepLabels;

  const StepProgressIndicator({
    Key? key,
    required this.totalSteps,
    required this.currentStep,
    required this.stepLabels,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(totalSteps, (index) {
            final stepNumber = index + 1;
            final isCompleted = stepNumber < currentStep;
            final isCurrent = stepNumber == currentStep;

            return Expanded(
              child: Row(
                children: [
                  // Step circle
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted || isCurrent
                          ? AppColors.primary
                          : AppColors.grey100,
                      border: Border.all(
                        color: isCompleted || isCurrent
                            ? AppColors.primary
                            : AppColors.grey300,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: isCompleted
                          ? Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 24,
                            )
                          : Text(
                              '$stepNumber',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: isCurrent
                                    ? Colors.white
                                    : AppColors.grey500,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  // Connector line
                  if (index < totalSteps - 1)
                    Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: isCompleted
                            ? AppColors.primary
                            : AppColors.grey300,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: stepLabels.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final isCompleted = index + 1 < currentStep;
              final isCurrent = index + 1 == currentStep;

              return Opacity(
                opacity: isCompleted || isCurrent ? 1.0 : 0.5,
                child: Text(
                  stepLabels[index],
                  style: isCurrent
                      ? AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        )
                      : AppTextStyles.labelSmall,
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
