import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../widgets/index.dart';
import '../../providers/parcel_delivery_provider.dart';
import '../../models/parcel_model.dart';
import '../../utils/platform_support.dart';

class PostDeliveryScreenV2 extends ConsumerStatefulWidget {
  const PostDeliveryScreenV2({Key? key}) : super(key: key);

  @override
  ConsumerState<PostDeliveryScreenV2> createState() => _PostDeliveryScreenV2State();
}

class _PostDeliveryScreenV2State extends ConsumerState<PostDeliveryScreenV2> {
  dynamic _mapController;
  final Set<dynamic> _markers = {};
  dynamic _currentMapCenter = const {'lat': 6.5244, 'lng': 3.3792}; // Lagos coordinates
  int _currentParcelIndex = 0;
  bool _isPickupMode = true; // true = pickup, false = dropoff
  final Set<dynamic> _polylines = {};
  bool _isAddingMore = false; // Track if user clicked "Add More Location"
  bool _isContinuing = false; // Track if user clicked "Continue"
  
  // Address controllers
  late TextEditingController _pickupController;
  late TextEditingController _dropoffController;
  
  @override
  void initState() {
    super.initState();
    _pickupController = TextEditingController();
    _dropoffController = TextEditingController();
  }
  
  @override
  void dispose() {
    _mapController.dispose();
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  void _onMapCreated(dynamic controller) {
    _mapController = controller;
  }

  void _showPackageDetailsModal(int parcelIndex, bool isAddingMore) {
    _isAddingMore = isAddingMore;
    _isContinuing = !isAddingMore;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => PackageDetailsModal(
        parcelIndex: parcelIndex,
        onSave: (details) {
          ref.read(parcelDeliveryProvider.notifier).updateParcelPackageDetails(
            parcelIndex,
            details,
          );
          Navigator.pop(context);
          
          // After modal closes, handle navigation
          Future.delayed(const Duration(milliseconds: 300), () {
            _handlePostModalAction(parcelIndex);
          });
        },
      ),
    );
  }

  void _handlePostModalAction(int parcelIndex) {
    if (_isAddingMore) {
      // User clicked "Add More Location" - create new parcel and show its form
      ref.read(parcelDeliveryProvider.notifier).addNewParcel();
      setState(() {
        _currentParcelIndex += 1;
        // Clear address controllers for new parcel
        _pickupController.clear();
        _dropoffController.clear();
      });
      _updateMapWithParcel(_currentParcelIndex);
      // The UI will automatically update to show the new parcel form
    } else if (_isContinuing) {
      // User clicked "Continue" - navigate to order summary screen
      Navigator.of(context).pushNamed('/order-summary', arguments: {
        'parcels': ref.read(parcelDeliveryProvider).parcels,
      });
    }
  }

  void _handleAddMoreLocation() {
    final delivery = ref.read(parcelDeliveryProvider);
    final currentParcel = delivery.parcels[_currentParcelIndex];
    
    // Validate current parcel has locations filled
    final validation = ref.read(parcelDeliveryProvider.notifier).validateCurrentParcel(_currentParcelIndex);
    
    if (!validation.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validation.message),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Show package details modal for current parcel with "Add More" flag
    _showPackageDetailsModal(_currentParcelIndex, true);
  }

  void _handleContinue() {
    final delivery = ref.read(parcelDeliveryProvider);
    final currentParcel = delivery.parcels[_currentParcelIndex];
    
    // Check if current parcel has at least pickup and dropoff filled
    if (!currentParcel.isPickupFilled || !currentParcel.isDropoffFilled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill both pickup and dropoff locations'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Show package details modal with "Continue" flag
    _showPackageDetailsModal(_currentParcelIndex, false);
  }

  void _updateMapWithParcel(int index) {
    if (kIsWeb) return; // Maps not supported on web
    
    // Native platform map code would go here
    // GoogleMaps widget (Marker, MarkerId, InfoWindow, BitmapDescriptor, LatLng, Polyline, PolylineId)
    // are not available on web and should only be used with !kIsWeb guards
  }

  @override
  Widget build(BuildContext context) {
    final delivery = ref.watch(parcelDeliveryProvider);
    final currentParcel = _currentParcelIndex < delivery.parcels.length
        ? delivery.parcels[_currentParcelIndex]
        : null;

    if (currentParcel == null) {
      return const Scaffold(
        body: Center(child: Text('No parcel data')),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Delivery Route - Parcel ${currentParcel.parcelNumber} of ${delivery.parcelCount}',
        showBackButton: true,
      ),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Parcel ${currentParcel.parcelNumber} Locations',
                      style: AppTextStyles.headingSmall,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Pickup Address
                    Text(
                      'Pickup',
                      style: AppTextStyles.labelMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _pickupController,
                      decoration: InputDecoration(
                        hintText: 'Enter or select location',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppBorderRadius.md),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.location_on,
                            color: AppColors.primary,
                          ),
                          onPressed: () async {
                            final result = await Navigator.pushNamed(
                              context,
                              '/map-picker',
                              arguments: {
                                'title': 'Select Pickup Location',
                                'latitude': 6.5244,
                                'longitude': 3.3792,
                                'locationType': 'pickup',
                                'parcelIndex': _currentParcelIndex,
                              },
                            ) as Map<String, dynamic>?;
                            
                            if (result != null) {
                              final location = kIsWeb
                                  ? LocationCoordinates(
                                      latitude: (result['location'] as Map)['latitude'] as double,
                                      longitude: (result['location'] as Map)['longitude'] as double,
                                    )
                                  : result['location'] as LocationCoordinates;
                              final address = result['address'] as String;
                              
                              setState(() {
                                _pickupController.text = address;
                              });
                              
                              ref.read(parcelDeliveryProvider.notifier).updateParcelPickup(
                                _currentParcelIndex,
                                address,
                                location.latitude,
                                location.longitude,
                              );
                            }
                          },
                          tooltip: 'Select on Map',
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                      ),
                      onChanged: (value) {
                        ref.read(parcelDeliveryProvider.notifier).updateParcelPickup(
                          _currentParcelIndex,
                          value,
                          6.5244,
                          3.3792,
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Dropoff Address
                    Text(
                      'Dropoff',
                      style: AppTextStyles.labelMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _dropoffController,
                      decoration: InputDecoration(
                        hintText: 'Enter or select location',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppBorderRadius.md),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.flag,
                            color: AppColors.error,
                          ),
                          onPressed: () async {
                            final result = await Navigator.pushNamed(
                              context,
                              '/map-picker',
                              arguments: {
                                'title': 'Select Dropoff Location',
                                'latitude': 6.5500,
                                'longitude': 3.3900,
                                'locationType': 'dropoff',
                                'parcelIndex': _currentParcelIndex,
                              },
                            ) as Map<String, dynamic>?;
                            
                            if (result != null) {
                              final location = kIsWeb
                                  ? LocationCoordinates(
                                      latitude: (result['location'] as Map)['latitude'] as double,
                                      longitude: (result['location'] as Map)['longitude'] as double,
                                    )
                                  : result['location'] as LocationCoordinates;
                              final address = result['address'] as String;
                              
                              setState(() {
                                _dropoffController.text = address;
                              });
                              
                              ref.read(parcelDeliveryProvider.notifier).updateParcelDropoff(
                                _currentParcelIndex,
                                address,
                                location.latitude,
                                location.longitude,
                              );
                            }
                          },
                          tooltip: 'Select on Map',
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                      ),
                      onChanged: (value) {
                        ref.read(parcelDeliveryProvider.notifier).updateParcelDropoff(
                          _currentParcelIndex,
                          value,
                          6.5500,
                          3.3900,
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Action buttons
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _handleAddMoreLocation,
                        icon: const Icon(Icons.add),
                        label: const Text('Add More Location'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _handleContinue,
                        icon: const Icon(Icons.check),
                        label: const Text('Continue'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Parcel tabs
                    if (delivery.parcelCount > 1) ...[
                      Text(
                        'All Parcels',
                        style: AppTextStyles.labelMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: List.generate(
                          delivery.parcelCount,
                          (index) => GestureDetector(
                            onTap: () {
                              setState(() {
                                _currentParcelIndex = index;
                              });
                              _updateMapWithParcel(index);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: _currentParcelIndex == index
                                    ? AppColors.primary
                                    : AppColors.border,
                                borderRadius: BorderRadius.circular(AppSpacing.md),
                              ),
                              child: Text(
                                'Parcel ${index + 1}',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: _currentParcelIndex == index
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        );
  }
}
class PackageDetailsModal extends ConsumerStatefulWidget {
  final int parcelIndex;
  final Function(PackageDetails) onSave;

  const PackageDetailsModal({
    Key? key,
    required this.parcelIndex,
    required this.onSave,
  }) : super(key: key);

  @override
  ConsumerState<PackageDetailsModal> createState() => _PackageDetailsModalState();
}

class _PackageDetailsModalState extends ConsumerState<PackageDetailsModal> {
  late TextEditingController _itemNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _recipientNameController;
  late TextEditingController _recipientPhoneController;
  String _selectedCategory = 'Electronics';

  final List<String> _categories = [
    'Electronics',
    'Documents',
    'Food',
    'Fashion',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    final delivery = ref.read(parcelDeliveryProvider);
    final parcel = delivery.parcels[widget.parcelIndex];
    
    _itemNameController = TextEditingController(text: parcel.packageDetails.itemName);
    _descriptionController = TextEditingController(text: parcel.packageDetails.itemDescription ?? '');
    _recipientNameController = TextEditingController(text: parcel.packageDetails.recipientName);
    _recipientPhoneController = TextEditingController(text: parcel.packageDetails.recipientPhone);
    _selectedCategory = parcel.packageDetails.itemCategory.isNotEmpty
        ? parcel.packageDetails.itemCategory
        : 'Electronics';
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _descriptionController.dispose();
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_itemNameController.text.isEmpty ||
        _recipientNameController.text.isEmpty ||
        _recipientPhoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields (*)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final details = PackageDetails(
      itemName: _itemNameController.text,
      itemCategory: _selectedCategory,
      itemDescription: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      recipientName: _recipientNameController.text,
      recipientPhone: _recipientPhoneController.text,
      isFilled: true,
    );

    widget.onSave(details);
  }

  @override
  Widget build(BuildContext context) {
    final delivery = ref.watch(parcelDeliveryProvider);
    final parcel = delivery.parcels[widget.parcelIndex];

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        color: Colors.white,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Parcel ${parcel.parcelNumber} - Package Details',
                    style: AppTextStyles.headingSmall.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Form
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item Name
                      Text('Item Name *', style: AppTextStyles.labelMedium),
                      const SizedBox(height: AppSpacing.sm),
                      CustomTextField(
                        label: '',
                        hint: 'e.g., Clothes, Noodles, Pizza',
                        controller: _itemNameController,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Category
                      Text('Item Category *', style: AppTextStyles.labelMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: _categories.map((cat) {
                          return FilterChip(
                            label: Text(cat),
                            selected: _selectedCategory == cat,
                            onSelected: (selected) {
                              setState(() => _selectedCategory = cat);
                            },
                            selectedColor: AppColors.primary,
                            labelStyle: AppTextStyles.labelSmall.copyWith(
                              color: _selectedCategory == cat
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Description
                      Text('Description (Optional)', style: AppTextStyles.labelMedium),
                      const SizedBox(height: AppSpacing.sm),
                      CustomTextField(
                        label: '',
                        hint: 'e.g., Handle with care',
                        controller: _descriptionController,
                        maxLines: 3,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Recipient Name
                      Text('Recipient Name *', style: AppTextStyles.labelMedium),
                      const SizedBox(height: AppSpacing.sm),
                      CustomTextField(
                        label: '',
                        hint: 'Full name',
                        controller: _recipientNameController,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Recipient Phone
                      Text('Phone Number *', style: AppTextStyles.labelMedium),
                      const SizedBox(height: AppSpacing.sm),
                      CustomTextField(
                        label: '',
                        hint: '+234 xxx xxxx xxx',
                        controller: _recipientPhoneController,
                      ),
                      const SizedBox(height: AppSpacing.xxxl),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          label: 'Save Parcel ${parcel.parcelNumber}',
                          onPressed: _handleSave,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
