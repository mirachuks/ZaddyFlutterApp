import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../models/parcel_model.dart';
import '../../models/job_model.dart';
import '../../providers/index.dart';
import 'view_chosen_rider_screen.dart';
import 'choose_rider_screen.dart';
import '../shared/rating_screen.dart';

class TrackDeliveryScreen extends ConsumerStatefulWidget {
  final List<Parcel>? parcels;
  final String? jobId;
  final Job? job;

  const TrackDeliveryScreen({Key? key, this.parcels, this.jobId, this.job})
      : super(key: key);

  @override
  ConsumerState<TrackDeliveryScreen> createState() =>
      _TrackDeliveryScreenState();
}

class _TrackDeliveryScreenState extends ConsumerState<TrackDeliveryScreen> {
  bool _loading = false;
  Job? _job;
  String? _error;
  Timer? _statusPollTimer;
  bool _ratingShown = false;

  @override
  void initState() {
    super.initState();
    _job = widget.job;
    if (_job == null && widget.jobId != null) {
      _fetchJob();
    }
    // Start polling for job status to detect delivery and show rating
    if (widget.jobId != null) {
      _statusPollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        try {
          final jobService = ref.read(jobServiceProvider);
          final fresh = await jobService.getJobDetails(widget.jobId!);
          setState(() {
            _job = fresh;
          });
          if (!_ratingShown && fresh.status == 'delivered' && fresh.review == null) {
            _ratingShown = true;
            if (!mounted) return;
            final riderName = fresh.rider?.fullName ?? 'Your Rider';
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RatingScreen(
                  jobId: fresh.id,
                  userName: riderName,
                  userAvatar: fresh.rider?.avatar ?? '',
                ),
              ),
            );
            _statusPollTimer?.cancel();
          }
        } catch (_) {}
      });
    }
  }

  Future<void> _fetchJob() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final jobService = ref.read(jobServiceProvider);
      final apiClient = await ref.read(apiClientProvider.future);
      final job = await jobService.getJobDetails(widget.jobId!);
      setState(() {
        _job = job;
      });

      // Try to fetch job applications to find the accepted rider
      final resp = await apiClient.getJobApplications(widget.jobId!);
      if (resp.statusCode == 200) {
        final data = resp.data as Map<String, dynamic>;
        if (data['data'] is List && (data['data'] as List).isNotEmpty) {
          final apps = (data['data'] as List)
              .map((a) => a as Map<String, dynamic>)
              .map((m) => m)
              .toList();
          Map<String, dynamic>? accepted;
          for (final m in apps) {
            final status = (m['status'] as String?)?.toLowerCase();
            final jobStatus = (m['job'] is Map)
                ? ((m['job']['status'] as String?)?.toLowerCase())
                : null;
            if (status == 'accepted' ||
                status == 'matched' ||
                jobStatus == 'accepted' ||
                jobStatus == 'matched') {
              accepted = m as Map<String, dynamic>;
              break;
            }
          }

          if (accepted != null || job.rider != null) {
            final riderOffer = RiderOffer(
              riderId: accepted?['rider_id']?.toString() ?? job.rider?.id ?? '',
              riderName: accepted?['rider_name']?.toString() ??
                  job.rider?.fullName ?? 'Rider',
              rating: accepted != null
                  ? double.tryParse(accepted['rating']?.toString() ?? '') ?? 4.5
                  : job.rating ?? 4.5,
              vehicleType: accepted?['vehicle_type']?.toString() ?? 'Motorcycle',
              vehiclePlate: accepted?['vehicle_plate']?.toString() ?? '',
              price: accepted != null
                  ? (accepted['offered_price'] != null
                      ? double.tryParse(accepted['offered_price'].toString()) ??
                          widget.job?.estimatedFare ??
                          0.0
                      : widget.job?.estimatedFare ?? 0.0)
                  : (job.totalPrice ?? job.estimatedFare),
              eta: accepted?['eta']?.toString() ?? 'Arriving',
              avatarUrl: accepted?['rider_avatar']?.toString() ??
                  job.rider?.avatar ?? '',
            );

            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ViewChosenRiderScreen(
                  parcels: widget.parcels ?? [],
                  rider: riderOffer,
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load tracking info';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If job exists and has an accepted rider, show the chosen rider view
    // If the job object already contains rider info mapped to `rider` or `riderId`, attempt to build a RiderOffer
    if (_job != null && _job!.rider != null) {
      final user = _job!.rider!;
      final riderOffer = RiderOffer(
        riderId: user.id,
        riderName: user.fullName,
        rating: 4.5,
        vehicleType: 'Motorcycle',
        vehiclePlate: '',
        price: _job!.estimatedFare,
        eta: 'Arriving',
        avatarUrl: user.avatar ?? '',
      );
      return ViewChosenRiderScreen(
          parcels: widget.parcels ?? [], rider: riderOffer);
    }

    // If job was passed in arguments and no rider assigned yet
    return Scaffold(
      appBar: AppBar(title: const Text('Track Delivery')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline,
                  size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                'Rider not assigned yet',
                style: AppTextStyles.headingSmall
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _error ??
                    'We are still assigning a rider. Please check back in a few moments.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _statusPollTimer?.cancel();
    super.dispose();
  }
}
