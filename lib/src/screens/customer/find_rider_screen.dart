import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../widgets/index.dart';
import '../../models/index.dart';
import '../../providers/index.dart';

class FindRiderScreen extends ConsumerStatefulWidget {
  final Job? job;
  final List<Job>? jobs;
  final double? totalPrice;
  final double? platformCharge;

  const FindRiderScreen({
    Key? key,
    this.job,
    this.jobs,
    this.totalPrice,
    this.platformCharge,
  }) : super(key: key);

  @override
  ConsumerState<FindRiderScreen> createState() => _FindRiderScreenState();
}

class _FindRiderScreenState extends ConsumerState<FindRiderScreen> {
  late Future<List<JobApplication>> _applicationsFuture;
  Timer? _pollTimer;
  bool _acceptedRedirected = false;
  bool _isAccepting = false;
  Job? _serverJob;

  @override
  void initState() {
    super.initState();
    _ensureJobPersisted().then((_) {
      _refreshApplications();
      _startApplicationPolling();
    });

  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(appPollerProvider, (previous, next) {
      if (!mounted || _acceptedRedirected) return;
      _refreshApplications();
    });

    final jobs = _displayJobs;
    final firstJob = jobs.isNotEmpty ? jobs.first : null;
    final jobCount = jobs.length;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Find Riders',
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Summary Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order ID and Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (jobCount > 1) ...[
                              Text(
                                'Parcels: $jobCount',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            if (firstJob != null) ...[
                              Text(
                                'Order ID: ${firstJob.id}',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Status: ${firstJob.status.toUpperCase()}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(firstJob.status),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '₦${_displayTotalPrice.toStringAsFixed(0)}',
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Pickup Location
                    _buildLocationRow(
                      icon: Icons.location_on,
                      label: 'From',
                      address: _displayPickupAddress,
                      color: AppColors.success,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Dropoff Location
                    _buildLocationRow(
                      icon: Icons.location_on,
                      label: 'To',
                      address: _displayDropoffAddress,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    if (jobs.isNotEmpty) ...[
                      if (jobCount == 1 && firstJob!.itemDescription.isNotEmpty) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Item: ${firstJob.itemDescription}',
                              style: AppTextStyles.bodySmall,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                        ),
                      ] else ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Items: $jobCount parcel${jobCount > 1 ? 's' : ''}',
                              style: AppTextStyles.bodySmall,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              _displayItemText,
                              style: AppTextStyles.bodySmall,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                        ),
                      ],
                    ],

                    // Urgency Badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: _getUrgencyColor(firstJob?.urgency ?? 'normal'),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            (firstJob?.urgency ?? 'normal').toUpperCase(),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        if (_displayTotalPrice > 0)
                          Text(
                            'Total: ₦${_displayTotalPrice.toStringAsFixed(0)}',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Waiting for Riders Section
              Text(
                'Awaiting Rider Responses',
                style: AppTextStyles.headingSmall,
              ),
              const SizedBox(height: AppSpacing.md),

              // Applications List or Loading
              FutureBuilder<List<JobApplication>>(
                future: _applicationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Column(
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: AppColors.error,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Error loading applications',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final applications = snapshot.data ?? [];

                  if (applications.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                        child: Column(
                          children: [
                            Icon(
                              Icons.hourglass_empty,
                              size: 48,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Waiting for riders...',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Notifications will alert you when riders accept',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _refreshApplications,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Refresh'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.md,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Display Applications List
                  return Column(
                    children: [
                      Text(
                        '${applications.length} rider(s) interested',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: applications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final app = applications[index];
                          return _buildApplicationCard(app);
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              // Continue Button (for manual progression)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                      context,
                      '/payment',
                      arguments: {
                        'jobs': jobs.map((job) => job.toJson()).toList(),
                        'estimatedFare': _displayTotalPrice,
                        'total_price': _displayTotalPrice,
                        'platform_charge': widget.platformCharge ?? 0.0,
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Continue to Payment',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white,
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

  Widget _buildLocationRow({
    required IconData icon,
    required String label,
    required String address,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: AppTextStyles.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _acceptApplication(JobApplication app) async {
    setState(() {
      _isAccepting = true;
    });

    try {
      final jobService = ref.read(jobServiceProvider);
      await jobService.acceptJobApplication(app.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rider ${app.riderName ?? 'selected'} accepted.'),
          backgroundColor: AppColors.success,
        ),
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/payment',
        arguments: {
          'jobs': _displayJobs.map((job) => job.toJson()).toList(),
          'estimatedFare': _displayTotalPrice,
          'total_price': _displayTotalPrice,
          'platform_charge': widget.platformCharge ?? 0.0,
          'accepted_application': app.toJson(),
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept rider: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAccepting = false;
        });
      }
    }
  }

  Widget _buildApplicationCard(JobApplication app) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grey300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Rider Header
          Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Rider Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.riderName ?? 'Rider',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (app.status != null)
                      Text(
                        'Status: ${app.status}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              // Offer Price
              if (app.offeredPrice != null)
                Flexible(
                  fit: FlexFit.loose,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '₦${app.offeredPrice!.toStringAsFixed(0)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Accept Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isAccepting ? null : () => _acceptApplication(app),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
              child: _isAccepting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Select Rider',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'posted':
        return AppColors.warning;
      case 'accepted':
      case 'picked_up':
        return AppColors.info;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'urgent':
        return AppColors.error;
      case 'normal':
        return AppColors.primary;
      case 'scheduled':
        return AppColors.info;
      default:
        return AppColors.grey500;
    }
  }

  // --- Minimal helper implementations (restores missing methods) ---
  Future<void> _ensureJobPersisted() async {
    final job = widget.job ?? (widget.jobs != null && widget.jobs!.isNotEmpty ? widget.jobs!.first : null);
    if (job == null) return;
    _serverJob = job;
  }

  Future<void> _refreshApplications() async {
    setState(() {
      _applicationsFuture = _fetchJobApplications();
    });
    final apps = await _applicationsFuture;
    _handleAcceptedApplication(apps);
  }

  void _startApplicationPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || _acceptedRedirected) return;
      _refreshApplications();
    });
  }

  Future<void> _refreshJobStatus() async {
    // no-op minimal implementation; real implementation may fetch job details
    return;
  }

  Future<List<JobApplication>> _fetchJobApplications() async {
    // Minimal placeholder: return empty list when no API client available
    try {
      final apiClient = await ref.read(apiClientProvider.future);
      final jobId = _serverJob?.id ?? widget.job?.id ?? widget.jobs?.first.id;
      if (jobId == null) return [];
      final response = await apiClient.getJobApplications(jobId);
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['data'] is List) {
          return (data['data'] as List).map((e) => JobApplication.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  void _handleAcceptedApplication(List<JobApplication> applications) {
    if (_acceptedRedirected) return;
    for (final app in applications) {
      final status = app.status?.toLowerCase() ?? '';
      if (status == 'accepted' || status == 'matched') {
        _acceptedRedirected = true;
        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          '/payment',
          arguments: {
            'jobs': _displayJobs.map((j) => j.toJson()).toList(),
            'estimatedFare': _displayTotalPrice,
            'total_price': _displayTotalPrice,
            'platform_charge': widget.platformCharge ?? 0.0,
            'accepted_application': app.toJson(),
          },
        );
        break;
      }
    }
  }

  List<Job> get _displayJobs {
    if (widget.jobs != null && widget.jobs!.isNotEmpty) return widget.jobs!;
    if (widget.job != null) return [widget.job!];
    return [];
  }

  double get _displayTotalPrice {
    if (widget.totalPrice != null) return widget.totalPrice!;
    if (_displayJobs.isEmpty) return 0.0;
    return _displayJobs.fold<double>(0.0, (sum, job) {
      if (job.totalPrice != null && job.totalPrice! > 0) return sum + job.totalPrice!;
      final platform = job.platformCharge ?? 0.0;
      return sum + job.estimatedFare + platform;
    });
  }

  String get _displayPickupAddress {
    return _displayJobs.isNotEmpty ? _displayJobs.first.pickupLocation.address : 'Pickup address unavailable';
  }

  String get _displayDropoffAddress {
    return _displayJobs.isNotEmpty ? _displayJobs.last.dropoffLocation.address : 'Dropoff address unavailable';
  }

  String get _displayItemText {
    final descriptions = _displayJobs.map((j) => j.itemDescription).where((s) => s.isNotEmpty).toList();
    if (descriptions.isEmpty) return 'No item information available';
    return descriptions.join(', ');
  }
}
