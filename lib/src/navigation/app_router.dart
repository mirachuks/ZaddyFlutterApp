import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../screens/auth/index.dart';
import '../screens/auth/user_registration_screen.dart';
import '../screens/role_selector/index.dart';
import '../screens/customer/index.dart';
import '../screens/customer/customer_dashboard.dart';
import '../screens/customer/job_posting_screen.dart';
import '../screens/customer/map_picker_screen.dart';
import '../screens/customer/rider_searching_screen.dart';
import '../screens/customer/choose_rider_screen.dart';
import '../screens/customer/view_chosen_rider_screen.dart';
import '../screens/customer/payment_screen.dart';
import '../screens/customer/order_accepted_screen.dart';
import '../screens/customer/track_delivery_screen.dart';
import '../screens/rider/index.dart';
import '../screens/rider/rider_dashboard.dart';
import '../screens/rider/rider_registration_step1_screen.dart';
import '../screens/rider/rider_registration_step2_screen.dart';
import '../screens/rider/rider_registration_step3_screen.dart';
import '../screens/rider/rider_registration_step4_screen.dart';
import '../screens/rider/rider_registration_review_screen.dart';
import '../screens/shared/index.dart';
import '../screens/onboarding_screen.dart';
import '../screens/rider_boarding_screen.dart';
import '../models/parcel_model.dart';
import '../models/job_model.dart';
import '../models/job_application_model.dart';
import '../utils/platform_support.dart';
import '../config/theme.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth Routes
      case '/splash':
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );
      case '/onboarding':
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        );
      case '/rider-boarding':
        return MaterialPageRoute(
          builder: (_) => const RiderBoardingScreens(),
        );
      case '/login':
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );
      case '/user-registration':
        return MaterialPageRoute(
          builder: (_) => const UserRegistrationScreen(),
        );
      case '/rider-registration-step1':
        return MaterialPageRoute(
          builder: (_) => const RiderRegistrationStep1Screen(),
        );
      case '/rider-registration-step2':
        return MaterialPageRoute(
          builder: (_) => const RiderRegistrationStep2Screen(),
        );
      case '/rider-registration-step3':
        return MaterialPageRoute(
          builder: (_) => const RiderRegistrationStep3Screen(),
        );
      case '/rider-registration-step4':
        return MaterialPageRoute(
          builder: (_) => const RiderRegistrationStep4Screen(),
        );
      case '/rider-registration-review':
        return MaterialPageRoute(
          builder: (_) => const RiderRegistrationReviewScreen(),
        );
      case '/forgot-password':
        return MaterialPageRoute(
          builder: (_) => const ForgotPasswordScreen(),
        );
      case '/kyc-submission':
        return MaterialPageRoute(
          builder: (_) => const KYCSubmissionScreen(),
        );
      case '/kyc-pending':
        return MaterialPageRoute(
          builder: (_) => const KYCPendingScreen(),
        );

      // Role Selector
      case '/role-selector':
        return MaterialPageRoute(
          builder: (_) => const RoleSelectorScreen(),
        );

      // Customer Routes
      case '/customer-dashboard':
        return MaterialPageRoute(
          builder: (_) => const CustomerDashboard(),
        );
      case '/customer-orders':
        return MaterialPageRoute(
          builder: (_) => const CustomerOrdersScreen(),
        );
      case '/post-delivery':
        return MaterialPageRoute(
          builder: (_) => const PostDeliveryScreenV2(),
        );
      case '/map-picker':
        final args = settings.arguments as Map<String, dynamic>?;
        final lat = (args?['latitude'] as num?)?.toDouble() ?? 6.5244;
        final lng = (args?['longitude'] as num?)?.toDouble() ?? 3.3792;
        final title = args?['title'] as String? ?? 'Select Location';
        final locationType = args?['locationType'] as String? ?? 'pickup';
        final parcelIndex = args?['parcelIndex'] as int? ?? 0;
        return MaterialPageRoute(
          builder: (context) => MapPickerScreen(
            title: title,
            initialLocation: LocationCoordinates(latitude: lat, longitude: lng),
            onLocationSelected: (location, address) {
              // Pop with the selected location
              Navigator.pop(context, {'location': location, 'address': address});
            },
          ),
        );
      case '/rider-searching':
        final args = settings.arguments as Map<String, dynamic>?;
        final parcels = (args?['parcels'] as List?)?.cast<Parcel>() ?? [];
        final estimatedFare = (args?['estimatedFare'] as num?)?.toDouble() ?? 0.0;
        return MaterialPageRoute(
          builder: (context) => RiderSearchingScreen(
            parcels: parcels,
            estimatedFare: estimatedFare,
            onComplete: () {
              // Create Job object from parcels data
              final firstParcel = parcels.isNotEmpty ? parcels.first : null;
              final lastParcel = parcels.isNotEmpty ? parcels.last : null;
              
              if (firstParcel != null && lastParcel != null) {
                final itemDescriptions = parcels
                    .map((p) => p.packageDetails.itemName)
                    .join(', ');
                
                final job = Job(
                  id: const Uuid().v4(),
                  customerId: '',
                  pickupLocation: Location(
                    latitude: firstParcel.pickupCoordinates.lat,
                    longitude: firstParcel.pickupCoordinates.lng,
                    address: firstParcel.pickupAddress ?? 'Pickup Location',
                  ),
                  dropoffLocation: Location(
                    latitude: lastParcel.dropoffCoordinates.lat,
                    longitude: lastParcel.dropoffCoordinates.lng,
                    address: lastParcel.dropoffAddress ?? 'Dropoff Location',
                  ),
                  itemDescription: itemDescriptions,
                  urgency: 'normal',
                  estimatedFare: estimatedFare,
                  status: 'posted',
                  paymentStatus: 'pending',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                
                Navigator.pushReplacementNamed(context, '/find-rider', arguments: job);
              } else {
                // Fallback if parcels are empty
                Navigator.pop(context);
              }
            },
          ),
        );
      case '/choose-rider':
        final args = settings.arguments as Map<String, dynamic>?;
        final parcels = (args?['parcels'] as List?)?.cast<Parcel>() ?? [];
        final estimatedFare = (args?['estimatedFare'] as num?)?.toDouble() ?? 0.0;
        return MaterialPageRoute(
          builder: (_) => ChooseRiderScreen(
            parcels: parcels,
            estimatedFare: estimatedFare,
          ),
        );
      case '/view-chosen-rider':
        final args = settings.arguments as Map<String, dynamic>?;
        final parcels = (args?['parcels'] as List?)?.cast<Parcel>() ?? [];
        final riderData = args?['rider'] as RiderOffer?;
        final jobs = (args?['jobs'] as List?)
                ?.whereType<Job>()
                .toList() ??
            <Job>[];
        if (riderData == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Error: Rider not found')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => ViewChosenRiderScreen(
            parcels: parcels,
            rider: riderData,
            jobs: jobs,
          ),
        );
      case '/order-summary':
        final args = settings.arguments as Map<String, dynamic>?;
        final parcels = (args?['parcels'] as List?)?.cast<Parcel>() ?? [];
        return MaterialPageRoute(
          builder: (_) => OrderSummaryScreen(parcels: parcels),
        );
      case '/find-rider':
      case '/find-riders':
        final args = settings.arguments;
        List<Job> jobs = [];
        double? totalPrice;
        double? platformCharge;

        if (args is Job) {
          jobs = [args];
        } else if (args is List) {
          jobs = args
              .whereType<Job>()
              .toList();
          if (jobs.isEmpty) {
            jobs = args
                .where((element) => element is Map)
                .map((element) => Job.fromJson(Map<String, dynamic>.from(element as Map)))
                .toList();
          }
        } else if (args is Map) {
          if (args['jobs'] is List) {
            final rawJobs = args['jobs'] as List;
            jobs = rawJobs.map((jobItem) {
              if (jobItem is Job) return jobItem;
              if (jobItem is Map<String, dynamic>) return Job.fromJson(jobItem);
              if (jobItem is Map) return Job.fromJson(Map<String, dynamic>.from(jobItem));
              return null;
            }).whereType<Job>().toList();
          } else if (args['job'] is Job) {
            jobs = [args['job'] as Job];
          } else if (args['job'] is Map<String, dynamic>) {
            jobs = [Job.fromJson(args['job'] as Map<String, dynamic>)];
          }

          if (args['total_price'] != null) {
            totalPrice = double.tryParse(args['total_price'].toString());
          }
          if (args['platform_charge'] != null) {
            platformCharge = double.tryParse(args['platform_charge'].toString());
          }
        }

        if (jobs.isNotEmpty) {
          return MaterialPageRoute(
            builder: (_) => FindRiderScreen(
              jobs: jobs,
              totalPrice: totalPrice,
              platformCharge: platformCharge,
            ),
          );
        }

        // Show error screen if no valid Job object
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: const Text('Error'),
              backgroundColor: AppColors.error,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Invalid Order Data',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Expected Job object, got: ${args.runtimeType}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(_),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      case '/package-details':
        return MaterialPageRoute(
          builder: (_) => const PackageDetailsScreen(),
        );
      case '/job-posting':
        return MaterialPageRoute(
          builder: (_) => const JobPostingScreen(),
        );
      case '/order-details':
        final orderId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => OrderDetailsScreen(orderId: orderId),
        );
      case '/track-delivery':
        final args = settings.arguments as Map<String, dynamic>?;
        final parcels = (args?['parcels'] as List?)?.cast<Parcel>() ?? [];
        final jobId = args?['jobId']?.toString();
        final jobArg = (args != null && args['job'] is Job) ? args['job'] as Job : null;
        return MaterialPageRoute(
          builder: (_) => TrackDeliveryScreen(
            parcels: parcels,
            jobId: jobId,
            job: jobArg,
          ),
        );
      case '/topup':
        return MaterialPageRoute(
          builder: (_) => const TopUpScreen(),
        );
      case '/edit-profile':
        return MaterialPageRoute(
          builder: (_) => const EditProfileScreen(),
        );
      case '/city':
        return MaterialPageRoute(
          builder: (_) => const CityScreen(),
        );
      case '/settings':
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
        );
      case '/safety':
        return MaterialPageRoute(
          builder: (_) => const SafetyScreen(),
        );
      case '/help-support':
        return MaterialPageRoute(
          builder: (_) => const HelpSupportScreen(),
        );
      case '/policy':
        return MaterialPageRoute(
          builder: (_) => const PolicyScreen(),
        );
      case '/payment':
        final args = settings.arguments;
        List<Parcel> parcels = [];
        List<Job> jobs = [];
        double estimatedFare = 0.0;
        double platformCharge = 0.0;
        JobApplication? acceptedApplication;

        if (args is Job) {
          jobs = [args];
          estimatedFare = args.estimatedFare;
        } else if (args is Map<String, dynamic>) {
          final parcelList = args['parcels'];
          if (parcelList is List) {
            parcels = parcelList.whereType<Parcel>().toList();
          }

          final jobList = args['jobs'];
          if (jobList is List) {
            jobs = jobList.map((jobItem) {
              if (jobItem is Job) return jobItem;
              if (jobItem is Map<String, dynamic>) return Job.fromJson(jobItem);
              if (jobItem is Map) return Job.fromJson(Map<String, dynamic>.from(jobItem));
              return null;
            }).whereType<Job>().toList();
          }

          final singleJob = args['job'];
          if (singleJob is Job) {
            jobs = [singleJob];
          } else if (singleJob is Map<String, dynamic>) {
            jobs = [Job.fromJson(singleJob)];
          } else if (singleJob is Map) {
            jobs = [Job.fromJson(Map<String, dynamic>.from(singleJob))];
          }

          final double? fallbackJobAmount = jobs.isNotEmpty
              ? (jobs.first.totalPrice ?? jobs.first.estimatedFare)
              : null;
          final amountValue = args['estimatedFare'] ?? args['total_price'] ?? fallbackJobAmount ?? 0.0;
          estimatedFare = amountValue is num ? amountValue.toDouble() : 0.0;
          platformCharge = (args['platform_charge'] is num)
              ? args['platform_charge'].toDouble()
              : (jobs.isNotEmpty ? jobs.first.platformCharge ?? 0.0 : 0.0);

          final acceptedMap = args['accepted_application'];
          if (acceptedMap is Map<String, dynamic>) {
            acceptedApplication = JobApplication.fromJson(acceptedMap);
          } else if (acceptedMap is Map) {
            acceptedApplication = JobApplication.fromJson(Map<String, dynamic>.from(acceptedMap));
          }
        }

        return MaterialPageRoute(
          builder: (_) => PaymentScreen(
            parcels: parcels,
            jobs: jobs.isNotEmpty ? jobs : null,
            estimatedFare: estimatedFare,
            platformCharge: platformCharge,
            acceptedApplication: acceptedApplication,
          ),
        );
      case '/order-accepted':
        final args = settings.arguments as Map<String, dynamic>?;
        final parcels = (args?['parcels'] as List?)?.cast<Parcel>() ?? [];
        final estimatedFare = (args?['estimatedFare'] as num?)?.toDouble() ?? 0.0;
        final jobs = (args?['jobs'] as List?)?.cast<Job>() ?? [];
        final platformCharge = (args?['platform_charge'] as num?)?.toDouble() ?? 0.0;
        return MaterialPageRoute(
          builder: (_) => OrderAcceptedScreen(
            parcels: parcels,
            estimatedFare: estimatedFare,
            jobs: jobs,
            platformCharge: platformCharge,
          ),
        );
      case '/rider-dashboard':
        return MaterialPageRoute(
          builder: (_) => const RiderDashboardScreen(),
        );
      case '/rider-jobs':
        return MaterialPageRoute(
          builder: (_) => const RiderJobsScreen(),
        );
      case '/rider-active-jobs':
        return MaterialPageRoute(
          builder: (_) => const RiderActiveJobsScreen(),
        );
      case '/rider-profile':
        return MaterialPageRoute(
          builder: (_) => const RiderProfileScreen(),
        );
      case '/rider-withdrawal':
        return MaterialPageRoute(
          builder: (_) => const RiderWithdrawalScreen(),
        );
      case '/rider-edit-profile':
        return MaterialPageRoute(
          builder: (_) => const RiderEditProfileScreen(),
        );
      case '/rider-order-history':
        return MaterialPageRoute(
          builder: (_) => const RiderOrderHistoryScreen(),
        );
      case '/rider-earnings':
        return MaterialPageRoute(
          builder: (_) => const RiderEarningsScreen(),
        );
      case '/rider-update-documents':
        return MaterialPageRoute(
          builder: (_) => const UpdateDocumentsScreen(),
        );
      case '/rider-update-bank-details':
      case '/update_bank_details':
        return MaterialPageRoute(
          builder: (_) => const UpdateBankDetailsScreen(),
        );
      case '/rider-top-up':
        return MaterialPageRoute(
          builder: (_) => const TopUpScreen(),
        );
      case '/withdraw':
        return MaterialPageRoute(
          builder: (_) => const RiderWithdrawalScreen(),
        );
      case '/rider-terms':
        return MaterialPageRoute(
          builder: (_) => const RiderTermsScreen(),
        );
      case '/rider-policy':
        return MaterialPageRoute(
          builder: (_) => const RiderPolicyScreen(),
        );
      case '/customer-terms':
        return MaterialPageRoute(
          builder: (_) => const CustomerTermsScreen(),
        );
      case '/customer-policy':
        return MaterialPageRoute(
          builder: (_) => const CustomerPolicyScreen(),
        );

      // Shared Routes
      case '/chat':
        return MaterialPageRoute(
          builder: (_) => const CustomerChatScreen(),
        );
      case '/chat-detail':
        final args = settings.arguments as Map<String, dynamic>?;
        final userId = args?['userId']?.toString() ?? 'user-id';
        final userName = args?['userName']?.toString() ?? 'Rider Name';
        final riderRole = args?['riderRole']?.toString();
        final riderPhoneNumber = args?['riderPhoneNumber']?.toString();
        return MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            userId: userId,
            userName: userName,
            riderRole: riderRole,
            riderPhoneNumber: riderPhoneNumber,
          ),
        );
      case '/notifications':
        return MaterialPageRoute(
          builder: (_) => const NotificationsScreen(),
        );
      case '/rating':
        return MaterialPageRoute(
          builder: (_) => const RatingScreen(
            jobId: '',
            userName: 'Rider Name',
            userAvatar: 'avatar-url',
          ),
        );

      // Default
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }
}
