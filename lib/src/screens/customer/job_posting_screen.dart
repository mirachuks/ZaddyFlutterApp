import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart' hide Location;

import '../../config/theme.dart';
import '../../models/index.dart';
import '../../utils/platform_support.dart';
import '../../widgets/index.dart';
import '../../providers/index.dart';

class JobPostingScreen extends ConsumerStatefulWidget {
  const JobPostingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<JobPostingScreen> createState() => _JobPostingScreenState();
}

class _JobPostingScreenState extends ConsumerState<JobPostingScreen> {
  dynamic _mapController;
  dynamic locationService;

  late TextEditingController _itemDescriptionController;
  late TextEditingController _itemWeightController;
  late TextEditingController _priceController;

  final _formKey = GlobalKey<FormState>();

  // Job Details
  Location? _pickupLocation;
  Location? _dropoffLocation;
  String _urgency = 'normal'; // urgent, normal, scheduled
  double _estimatedFare = 3500;

  bool _isSelectingPickup = false;
  bool _isSelectingDropoff = false;
  bool _mapVisible = false;

  final Set<dynamic> _markers = {};

  @override
  void initState() {
    super.initState();
    _itemDescriptionController = TextEditingController();
    _itemWeightController = TextEditingController();
    _priceController = TextEditingController(text: '3500');
  }

  @override
  void dispose() {
    _itemDescriptionController.dispose();
    _itemWeightController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _openMap(bool isPickup) async {
    final result = await Navigator.pushNamed(
      context,
      '/map-picker',
      arguments: {
        'title': isPickup ? 'Select Pickup Location' : 'Select Dropoff Location',
        'latitude': 6.5244, // Lagos coordinates
        'longitude': 3.3792,
      },
    ) as Map<String, dynamic>?;

    if (result != null) {
      if (kIsWeb) {
        // On web, location is a map
        final latitude = (result['location'] as Map)['latitude'] as double;
        final longitude = (result['location'] as Map)['longitude'] as double;
        final address = result['address'] as String;
        
        setState(() {
          if (isPickup) {
            _pickupLocation = Location(
              latitude: latitude,
              longitude: longitude,
              address: address,
            );
          } else {
            _dropoffLocation = Location(
              latitude: latitude,
              longitude: longitude,
              address: address,
            );
          }
        });
      } else {
        // Native platform - LatLng type available
        final location = result['location'] as LocationCoordinates; // Use our cross-platform type
        final address = result['address'] as String;

        setState(() {
          if (isPickup) {
            _pickupLocation = Location(
              latitude: location.latitude,
              longitude: location.longitude,
              address: address,
            );
          } else {
            _dropoffLocation = Location(
              latitude: location.latitude,
              longitude: location.longitude,
              address: address,
            );
          }
        });
      }
    }
  }

  void _onMapCreated(dynamic controller) {
    _mapController = controller;
  }

  Future<void> _handleMapTap(dynamic position) async {
    if (kIsWeb) return; // Map tap not supported on web
    
    try {
      // For web, position is a map; for native, it's LatLng
      final latitude = position is Map ? position['latitude'] as double : (position.latitude as double);
      final longitude = position is Map ? position['longitude'] as double : (position.longitude as double);

      // For now, just create the location without address lookup on native
      const address = 'Selected Location';
      
      final locationObj = Location(
        latitude: latitude,
        longitude: longitude,
        address: address,
      );

      setState(() {
        if (_isSelectingPickup) {
          _pickupLocation = locationObj;
          // For web, we don't add actual markers - maps not supported
          if (!kIsWeb) {
            _markers.add({
              'id': 'pickup',
              'position': {'lat': latitude, 'lng': longitude},
              'title': 'Pickup: $address',
            });
          }
        } else {
          _dropoffLocation = locationObj;
          // For web, we don't add actual markers - maps not supported
          if (!kIsWeb) {
            _markers.add({
              'id': 'dropoff',
              'position': {'lat': latitude, 'lng': longitude},
              'title': 'Dropoff: $address',
            });
          }
        }
        _mapVisible = false;
      });

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _handlePostJob() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickupLocation == null || _dropoffLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select both pickup and dropoff locations')),
      );
      return;
    }

    // Get current user
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    // Prepare job data for API - map Flutter fields to Laravel API fields
    final jobData = {
      'user_profile_id': int.tryParse(currentUser.id) ?? 1, // Convert string ID to int
      'title': _itemDescriptionController.text, // Use item description as title
      'description': _itemWeightController.text.isNotEmpty
          ? 'Weight: ${_itemWeightController.text}kg\nUrgency: ${_urgency.toUpperCase()}'
          : 'Urgency: ${_urgency.toUpperCase()}',
      'pickup_address': _pickupLocation!.address,
      'pickup_lat': _pickupLocation!.latitude,
      'pickup_lng': _pickupLocation!.longitude,
      'dropoff_address': _dropoffLocation!.address,
      'price': double.parse(_priceController.text),
      'price_type': 'fixed', // Default to fixed pricing
    };

    try {
      // Show loading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Posting your order...'),
              ],
            ),
          );
        },
      );

      // Submit job to API via provider
      await ref.read(jobCreationProvider.notifier).createJob(jobData);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order posted successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate to find riders screen after a short delay
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      final createdJob = ref.read(jobCreationProvider).createdJob;
      if (createdJob != null) {
        Navigator.of(context).pushReplacementNamed(
          '/find-riders',
          arguments: createdJob,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open find riders screen. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to post order: ${e.toString()}'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_mapVisible) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            _isSelectingPickup ? 'Select Pickup Location' : 'Select Dropoff Location',
          ),
          backgroundColor: AppColors.primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() => _mapVisible = false);
            },
          ),
        ),
        body: kIsWeb
            ? const Center(child: Text('Map feature not available on web'))
            : Container(), // GoogleMap would be here on native
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Enter Your Route',
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // From Location
                  Text(
                    'From?',
                    style: AppTextStyles.headingSmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GestureDetector(
                    onTap: () => _openMap(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.grey50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.grey300,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_pickupLocation == null)
                                  Text(
                                    'Enter Location',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.grey500,
                                    ),
                                  )
                                else
                                  Text(
                                    _pickupLocation!.address,
                                    style: AppTextStyles.bodyMedium,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Use map',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.primary,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Add more location',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // To Location
                  Text(
                    'To?',
                    style: AppTextStyles.headingSmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GestureDetector(
                    onTap: () => _openMap(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.grey50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.grey300,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_dropoffLocation == null)
                                  Text(
                                    'Enter Location',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.grey500,
                                    ),
                                  )
                                else
                                  Text(
                                    _dropoffLocation!.address,
                                    style: AppTextStyles.bodyMedium,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Use map',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Item Description
                  Text(
                    'Item Description',
                    style: AppTextStyles.labelMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  CustomTextField(
                    label: '',
                    controller: _itemDescriptionController,
                    hint: 'Describe what you\'re sending',
                    maxLines: 3,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Item description is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Item Weight
                  CustomTextField(
                    label: 'Item Weight (kg) - Optional',
                    controller: _itemWeightController,
                    keyboardType: TextInputType.number,
                    hint: 'e.g., 2.5',
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Delivery Options
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.two_wheeler,
                              color: AppColors.primary,
                              size: 28,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Delivery',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Select your own fair price',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.grey600,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                // Show info modal
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Pricing Info'),
                                    content: const Text(
                                      'You can set your own price for this delivery. The recommended fare is based on distance and urgency.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: const Icon(Icons.info_outline),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Price Controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _estimatedFare =
                                      (_estimatedFare - 500).clamp(500, 100000);
                                  _priceController.text =
                                      _estimatedFare.toStringAsFixed(0);
                                });
                              },
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.primary,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.remove,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              children: [
                                CustomTextField(
                                  label: '',
                                  controller: _priceController,
                                  keyboardType: TextInputType.number,
                                  hint: 'Price',
                                  textAlign: TextAlign.center,
                                  onChanged: (value) {
                                    setState(() {
                                      _estimatedFare = double.tryParse(value) ?? 3500;
                                    });
                                  },
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Recommended fair',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.grey600,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _estimatedFare =
                                      _estimatedFare + 500.clamp(500, 100000);
                                  _priceController.text =
                                      _estimatedFare.toStringAsFixed(0);
                                });
                              },
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.primary,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.add,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Urgency Selection
                  Text(
                    'Urgency',
                    style: AppTextStyles.labelMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: ['urgent', 'normal', 'scheduled'].map((option) {
                      final label = option[0].toUpperCase() + option.substring(1);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _urgency = option);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              color: _urgency == option
                                  ? AppColors.primary
                                  : AppColors.grey100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _urgency == option
                                    ? AppColors.primary
                                    : Colors.transparent,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                label,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: _urgency == option
                                      ? Colors.white
                                      : AppColors.grey600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Find a Rider Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _handlePostJob,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Find a Rider',
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
        ),
      ),
    );
  }
}
