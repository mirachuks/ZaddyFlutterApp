// import 'package:flutter/material.dart';
// import '../config/theme.dart';

// class OnboardingScreen extends StatelessWidget {
//   const OnboardingScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         backgroundColor: AppColors.background,
//         elevation: 0,
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pushNamed('/login');
//             },
//             child: Text(
//               'Skip',
//               style: AppTextStyles.bodyLarge.copyWith(
//                 color: AppColors.textPrimary,
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(AppSpacing.lg),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               // Illustration area
//               Expanded(
//                 child: Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       // Simplified illustration (using icons instead)
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Column(
//                             children: [
//                               Icon(
//                                 Icons.two_wheeler,
//                                 size: 80,
//                                 color: AppColors.primary,
//                               ),
//                               const SizedBox(height: 10),
//                               Icon(
//                                 Icons.person,
//                                 size: 60,
//                                 color: AppColors.textSecondary,
//                               ),
//                             ],
//                           ),
//                           const SizedBox(width: 30),
//                           Icon(
//                             Icons.shopping_bag,
//                             size: 80,
//                             color: AppColors.textSecondary,
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               // Title
//               Text(
//                 'Are you a user or a rider?',
//                 style: AppTextStyles.displaySmall,
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: AppSpacing.md),
//               // Subtitle
//               Text(
//                 'Choose how you want to use Zaddy—send deliveries or earn by delivering.',
//                 style: AppTextStyles.bodyLarge.copyWith(
//                   color: AppColors.textSecondary,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: AppSpacing.xl),
//               // User Button
//               SizedBox(
//                 width: double.infinity,
//                 height: 60,
//                 child: ElevatedButton(
//                   onPressed: () {
//                     Navigator.of(context).pushReplacementNamed('/login');
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.primary,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                   ),


//                   child: Text(
//                     'User',
//                     style: AppTextStyles.displaySmall.copyWith(
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: AppSpacing.md),
//               // Rider Button
//               SizedBox(
//                 width: double.infinity,
//                 height: 60,
//                 child: OutlinedButton(
//                   onPressed: () {
//                     Navigator.of(context).pushNamed('/rider-boarding');
//                   },
//                   style: OutlinedButton.styleFrom(
//                     side: const BorderSide(color: AppColors.primary, width: 2),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                   ),
//                   child: Text(
//                     'Rider',
//                     style: AppTextStyles.displaySmall.copyWith(
//                       color: AppColors.primary,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('has_seen_onboarding', true);
              if (context.mounted) {
                Navigator.of(context).pushNamed('/login');
              }
            },
            child: Text(
              'Skip',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Illustration area
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Simplified illustration (using icons instead)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              Icon(
                                Icons.two_wheeler,
                                size: 80,
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: 10),
                              Icon(
                                Icons.person,
                                size: 60,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                          const SizedBox(width: 30),
                          Icon(
                            Icons.shopping_bag,
                            size: 80,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Title
              Text(
                'Are you a user or a rider?',
                style: AppTextStyles.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              // Subtitle
              Text(
                'Choose how you want to use ZaddyExpress, send deliveries or earn by delivering.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              
              // User Button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('has_seen_onboarding', true);
                    if (context.mounted) {
                      Navigator.of(context).pushNamed('/user-registration');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'User',
                    style: AppTextStyles.displaySmall.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              
              // Rider Button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: OutlinedButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('has_seen_onboarding', true);
                    if (context.mounted) {
                      Navigator.of(context).pushNamed('/rider-boarding');
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Rider',
                    style: AppTextStyles.displaySmall.copyWith(
                      color: AppColors.primary,
                    ),
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