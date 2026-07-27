import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../widgets/index.dart';
import '../../providers/delivery_provider.dart';
import '../../models/delivery_model.dart';
import '../../services/location_suggestion_service.dart';

class AddressAutocompleteInput extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final ValueChanged<LocationSuggestion> onSuggestionSelected;

  const AddressAutocompleteInput({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onSuggestionSelected,
  });

  @override
  State<AddressAutocompleteInput> createState() => _AddressAutocompleteInputState();
}

class _AddressAutocompleteInputState extends State<AddressAutocompleteInput> {
  Timer? _debounceTimer;
  List<LocationSuggestion> _suggestions = [];
  bool _isLoading = false;
  bool _hasInteracted = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.trim().length < 3) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() => _isLoading = true);
    }

    final results = await LocationSuggestionService.fetchSuggestions(query);
    if (!mounted) return;

    setState(() {
      _suggestions = results;
      _isLoading = false;
    });
  }

  void _onChanged(String value) {
    widget.onChanged(value);
    _hasInteracted = true;

    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    if (value.trim().length >= 3) {
      _debounceTimer = Timer(LocationSuggestionService.debounceDuration, () {
        _fetchSuggestions(value);
      });
    } else {
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<LocationSuggestion>(
      optionsBuilder: (TextEditingValue value) async {
        final query = value.text;
        if (query.trim().length < 3) {
          if (mounted) {
            setState(() {
              _suggestions = [];
              _isLoading = false;
            });
          }
          return const <LocationSuggestion>[];
        }

        if (!_hasInteracted || _suggestions.isEmpty) {
          _onChanged(query);
        }
        return _suggestions.isNotEmpty ? _suggestions : <LocationSuggestion>[
          const LocationSuggestion(
            addressString: 'Searching locations in Enugu, Nigeria...',
            lat: 0,
            lng: 0,
          ),
        ];
      },
      onSelected: (suggestion) {
        widget.controller.text = suggestion.addressString;
        widget.onSuggestionSelected(suggestion);
      },
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: widget.controller,
          focusNode: focusNode,
          keyboardType: TextInputType.text,
          onTap: () {
            _hasInteracted = true;
            final currentText = widget.controller.text.trim();
            if (currentText.length >= 3) {
              _fetchSuggestions(currentText);
            } else {
              setState(() {
                _suggestions = [];
                _isLoading = true;
              });
            }
          },
          onEditingComplete: () {
            final currentText = widget.controller.text.trim();
            if (currentText.length >= 3) {
              _fetchSuggestions(currentText);
            }
          },
          onChanged: (value) {
            widget.controller.text = value;
            _onChanged(value);
          },
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final displayOptions = options.toList();
        final fallbackOptions = [
          const LocationSuggestion(
            addressString: 'Searching locations in Enugu, Nigeria...',
            lat: 0,
            lng: 0,
          ),
        ];
        final visibleOptions = displayOptions.isEmpty ? fallbackOptions : displayOptions;

        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            child: Container(
              width: MediaQuery.sizeOf(context).width - 32,
              constraints: const BoxConstraints(maxHeight: 240),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Text('Searching locations...'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: visibleOptions.length,
                      itemBuilder: (context, index) {
                        final suggestion = visibleOptions[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.map_outlined, size: 18),
                          title: Text(
                            suggestion.addressString,
                            style: AppTextStyles.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => onSelected(suggestion),
                        );
                      },
                    ),
            ),
          ),
        );
      },
    );
  }
}

class PostDeliveryScreen extends ConsumerStatefulWidget {
  const PostDeliveryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PostDeliveryScreen> createState() =>
      _PostDeliveryScreenState();
}

class _PostDeliveryScreenState extends ConsumerState<PostDeliveryScreen> {
  late ScrollController _scrollController;
  final Map<int, TextEditingController> _locationControllers = {};

  // Track which fields have red border (validation errors)
  final Set<int> _errorFields = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initializeControllers();
  }

  void _initializeControllers() {
    final delivery = ref.read(deliveryProvider);
    for (int i = 0; i < delivery.waypoints.length; i++) {
      _locationControllers[i] = TextEditingController(
        text: delivery.waypoints[i].addressString,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (var controller in _locationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _getLocationLabel(int index, WaypointType type) {
    if (type == WaypointType.pickup) {
      return 'From (Pickup Location)';
    }
    final dropoffNumber = ref
        .read(deliveryProvider)
        .waypoints
        .asMap()
        .entries
        .where((e) => e.value.type == WaypointType.dropoff && e.key <= index)
        .length;
    return 'To (Delivery Location $dropoffNumber)';
  }

  void _addLocationController() {
    final delivery = ref.read(deliveryProvider);
    final newIndex = delivery.waypoints.length;
    _locationControllers[newIndex] = TextEditingController();
  }

  double _estimateDistanceForCurrentParcel(DeliveryState delivery) {
    Waypoint? pickup;
    Waypoint? dropoff;

    for (final waypoint in delivery.waypoints) {
      if (pickup == null && waypoint.type == WaypointType.pickup) {
        pickup = waypoint;
      }
      if (dropoff == null && waypoint.type == WaypointType.dropoff) {
        dropoff = waypoint;
      }
      if (pickup != null && dropoff != null) {
        break;
      }
    }

    if (pickup == null || dropoff == null) {
      return 0.0;
    }

    return LocationSuggestionService.calculateDistanceKm(
      startLat: pickup.coordinates.lat,
      startLng: pickup.coordinates.lng,
      endLat: dropoff.coordinates.lat,
      endLng: dropoff.coordinates.lng,
    );
  }

  double _estimatePriceForCurrentParcel(DeliveryState delivery) {
    final distanceKm = _estimateDistanceForCurrentParcel(delivery);
    return distanceKm * LocationSuggestionService.ratePerKm;
  }

  Future<void> _handleAddMoreLocation() async {
    final validation = ref.read(deliveryProvider.notifier).validateCurrentLocations();

    if (!validation.isValid) {
      setState(() {
        _errorFields.clear();
        if (validation.failedFieldIndex != null) {
          _errorFields.add(validation.failedFieldIndex!);
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validation.message),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _errorFields.clear();
    });

    if (!mounted) return;
    await _showQuickDetailsModal(
      ref.read(deliveryProvider).waypoints.length - 1,
    );
  }

  Future<void> _showQuickDetailsModal(int waypointIndex) async {
    final delivery = ref.read(deliveryProvider);
    final waypoint = delivery.waypoints[waypointIndex];
    final currentDetails = waypoint.packageDetails;

    final itemNameController = TextEditingController(text: currentDetails.itemName);
    final itemCategoryController =
        TextEditingController(text: currentDetails.itemCategory);
    final itemDescriptionController =
        TextEditingController(text: currentDetails.itemDescription ?? '');
    final recipientNameController =
        TextEditingController(text: currentDetails.recipientName);
    final recipientPhoneController =
        TextEditingController(text: currentDetails.recipientPhone);

    String selectedCategory = currentDetails.itemCategory.isNotEmpty
        ? currentDetails.itemCategory
        : 'Electronics';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Quick Details for ${waypoint.addressString}',
                        style: AppTextStyles.headingSmall,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Delivery Location',
                        style: AppTextStyles.labelSmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                waypoint.addressString,
                                style: AppTextStyles.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      CustomTextField(
                        label: 'Item Name *',
                        controller: itemNameController,
                        hint: 'e.g.Clothes, Noodles, Pizza',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Item Category *',
                            style: AppTextStyles.labelSmall,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              'Electronics',
                              'Documents',
                              'Food',
                              'Fashion',
                              'Others',
                            ]
                                .map(
                                  (category) => GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedCategory = category;
                                        itemCategoryController.text = category;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                        vertical: AppSpacing.sm,
                                      ),
                                      decoration: BoxDecoration(
                                        color: selectedCategory == category
                                            ? AppColors.primary
                                            : AppColors.border,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: selectedCategory == category
                                              ? AppColors.primary
                                              : AppColors.border,
                                        ),
                                      ),
                                      child: Text(
                                        category,
                                        style: AppTextStyles.labelSmall.copyWith(
                                          color: selectedCategory == category
                                              ? AppColors.textInverse
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      CustomTextField(
                        label: 'Item Description (Optional)',
                        controller: itemDescriptionController,
                        hint: 'e.g., Handle with care, fragile icing',
                        maxLines: 2,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      CustomTextField(
                        label: 'Recipient Name *',
                        controller: recipientNameController,
                        hint: 'Full name of recipient',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      CustomTextField(
                        label: 'Recipient Phone *',
                        controller: recipientPhoneController,
                        hint: '+234 (XXX) XXX-XXXX',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          label: 'Save Stop',
                          onPressed: () {
                            if (itemNameController.text.isEmpty ||
                                recipientNameController.text.isEmpty ||
                                recipientPhoneController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Please fill all required fields (marked with *)'),
                                ),
                              );
                              return;
                            }

                            ref.read(deliveryProvider.notifier).updateWaypointPackageDetails(
                              waypointIndex,
                              PackageDetails(
                                itemName: itemNameController.text,
                                itemCategory: selectedCategory,
                                itemDescription: itemDescriptionController.text.isEmpty
                                    ? null
                                    : itemDescriptionController.text,
                                recipientName: recipientNameController.text,
                                recipientPhone: recipientPhoneController.text,
                                isFilled: true,
                              ),
                            );

                            ref.read(deliveryProvider.notifier).addDropoffWaypoint();
                            _addLocationController();

                            Navigator.pop(context);

                            Future.delayed(const Duration(milliseconds: 300), () {
                              if (_scrollController.hasClients) {
                                _scrollController.animateTo(
                                  _scrollController.position.maxScrollExtent,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                );
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleContinue() async {
    final validation =
        ref.read(deliveryProvider.notifier).validateCurrentLocations();

    if (!validation.isValid) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validation.message),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushNamed('/package-details');
  }

  @override
  Widget build(BuildContext context) {
    final delivery = ref.watch(deliveryProvider);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Enter Your Route',
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Locations',
                      style: AppTextStyles.headingSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Start by entering your pickup and delivery locations',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    
                    // Pickup and Dropoff Autocomplete Fields
                    ...List.generate(delivery.waypoints.length, (index) {
                      final waypoint = delivery.waypoints[index];
                      final isPickup = waypoint.type == WaypointType.pickup;
                      final hasError = _errorFields.contains(index);

                      if (!_locationControllers.containsKey(index)) {
                        _locationControllers[index] =
                            TextEditingController(text: waypoint.addressString);
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getLocationLabel(index, waypoint.type),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: hasError ? AppColors.error : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          AddressAutocompleteInput(
                            controller: _locationControllers[index]!,
                            hint: isPickup ? 'Enter pickup address' : 'Enter delivery address',
                            onChanged: (value) {
                              _locationControllers[index]!.text = value;
                              ref.read(deliveryProvider.notifier).updateWaypointLocation(
                                index,
                                value,
                                0,
                                0,
                              );
                              if (hasError && value.isNotEmpty) {
                                setState(() {
                                  _errorFields.remove(index);
                                });
                              }
                            },
                            onSuggestionSelected: (selection) {
                              _locationControllers[index]!.text = selection.addressString;
                              ref.read(deliveryProvider.notifier).updateWaypointLocation(
                                index,
                                selection.addressString,
                                selection.lat,
                                selection.lng,
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      );
                    }),
                    
                    const SizedBox(height: AppSpacing.md),
                    if (_estimateDistanceForCurrentParcel(delivery) > 0)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(AppBorderRadius.md),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estimated Delivery Price',
                              style: AppTextStyles.labelMedium,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${_estimateDistanceForCurrentParcel(delivery).toStringAsFixed(1)} km • ₦${_estimatePriceForCurrentParcel(delivery).toStringAsFixed(0)}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: AppSpacing.md),
                    SecondaryButton(
                      label: 'Add More Location',
                      onPressed: _handleAddMoreLocation,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(
                top: BorderSide(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: 'Continue',
                    onPressed: _handleContinue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


//THE OLD CODE

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../config/theme.dart';
// import '../../widgets/index.dart';
// import '../../providers/delivery_provider.dart';
// import '../../models/delivery_model.dart';

// class PostDeliveryScreen extends ConsumerStatefulWidget {
//   const PostDeliveryScreen({Key? key}) : super(key: key);

//   @override
//   ConsumerState<PostDeliveryScreen> createState() =>
//       _PostDeliveryScreenState();
// }

// class _PostDeliveryScreenState extends ConsumerState<PostDeliveryScreen> {
//   late ScrollController _scrollController;
//   final Map<int, TextEditingController> _locationControllers = {};

//   // Track which fields have red border (validation errors)
//   final Set<int> _errorFields = {};

//   @override
//   void initState() {
//     super.initState();
//     _scrollController = ScrollController();
//     // Initialize controllers for initial waypoints
//     _initializeControllers();
//   }

//   void _initializeControllers() {
//     final delivery = ref.read(deliveryProvider);
//     for (int i = 0; i < delivery.waypoints.length; i++) {
//       _locationControllers[i] = TextEditingController(
//         text: delivery.waypoints[i].addressString,
//       );
//     }
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     for (var controller in _locationControllers.values) {
//       controller.dispose();
//     }
//     super.dispose();
//   }

//   String _getLocationLabel(int index, WaypointType type) {
//     if (type == WaypointType.pickup) {
//       return 'From (Pickup Location)';
//     }
//     final dropoffNumber = ref
//         .read(deliveryProvider)
//         .waypoints
//         .asMap()
//         .entries
//         .where((e) => e.value.type == WaypointType.dropoff && e.key <= index)
//         .length;
//     return 'To (Delivery Location $dropoffNumber)';
//   }

//   void _addLocationController() {
//     final delivery = ref.read(deliveryProvider);
//     final newIndex = delivery.waypoints.length;
//     _locationControllers[newIndex] = TextEditingController();
//   }

//   Future<void> _handleAddMoreLocation() async {
//     final validation = ref.read(deliveryProvider.notifier).validateCurrentLocations();

//     if (!validation.isValid) {
//       // Highlight empty fields with red border
//       setState(() {
//         _errorFields.clear();
//         if (validation.failedFieldIndex != null) {
//           _errorFields.add(validation.failedFieldIndex!);
//         }
//       });

//       // Show toast/snackbar
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(validation.message),
//           backgroundColor: AppColors.error,
//           duration: const Duration(seconds: 2),
//         ),
//       );
//       return;
//     }

//     // Clear error state
//     setState(() {
//       _errorFields.clear();
//     });

//     // Show quick details modal for the current last dropoff
//     if (!mounted) return;
//     await _showQuickDetailsModal(
//       ref.read(deliveryProvider).waypoints.length - 1,
//     );
//   }

//   Future<void> _showQuickDetailsModal(int waypointIndex) async {
//     final delivery = ref.read(deliveryProvider);
//     final waypoint = delivery.waypoints[waypointIndex];
//     final currentDetails = waypoint.packageDetails;

//     final itemNameController = TextEditingController(text: currentDetails.itemName);
//     final itemCategoryController =
//         TextEditingController(text: currentDetails.itemCategory);
//     final itemDescriptionController =
//         TextEditingController(text: currentDetails.itemDescription ?? '');
//     final recipientNameController =
//         TextEditingController(text: currentDetails.recipientName);
//     final recipientPhoneController =
//         TextEditingController(text: currentDetails.recipientPhone);

//     String selectedCategory = currentDetails.itemCategory.isNotEmpty
//         ? currentDetails.itemCategory
//         : 'Electronics';

//     return showModalBottomSheet<void>(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: AppColors.background,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (BuildContext context) {
//         return StatefulBuilder(
//           builder: (BuildContext context, StateSetter setState) {
//             return Padding(
//               padding: EdgeInsets.only(
//                 bottom: MediaQuery.of(context).viewInsets.bottom,
//               ),
//               child: SingleChildScrollView(
//                 child: Padding(
//                   padding: const EdgeInsets.all(AppSpacing.lg),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Text(
//                         'Quick Details for ${waypoint.addressString}',
//                         style: AppTextStyles.headingSmall,
//                       ),
//                       const SizedBox(height: AppSpacing.md),
//                       Text(
//                         'Delivery Location',
//                         style: AppTextStyles.labelSmall,
//                       ),
//                       const SizedBox(height: AppSpacing.sm),
//                       Container(
//                         padding: const EdgeInsets.all(AppSpacing.md),
//                         decoration: BoxDecoration(
//                           color: AppColors.border,
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Row(
//                           children: [
//                             Icon(
//                               Icons.location_on,
//                               color: AppColors.primary,
//                             ),
//                             const SizedBox(width: AppSpacing.md),
//                             Expanded(
//                               child: Text(
//                                 waypoint.addressString,
//                                 style: AppTextStyles.bodySmall,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: AppSpacing.lg),
//                       CustomTextField(
//                         label: 'Item Name *',
//                         controller: itemNameController,
//                         hint: 'e.g., iPhone 13 Pro, Box of Cupcakes',
//                       ),
//                       const SizedBox(height: AppSpacing.md),
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Item Category *',
//                             style: AppTextStyles.labelSmall,
//                           ),
//                           const SizedBox(height: AppSpacing.sm),
//                           Wrap(
//                             spacing: AppSpacing.sm,
//                             runSpacing: AppSpacing.sm,
//                             children: [
//                               'Electronics',
//                               'Documents',
//                               'Food',
//                               'Fashion',
//                               'Others',
//                             ]
//                                 .map(
//                                   (category) => GestureDetector(
//                                     onTap: () {
//                                       setState(() {
//                                         selectedCategory = category;
//                                         itemCategoryController.text = category;
//                                       });
//                                     },
//                                     child: Container(
//                                       padding: const EdgeInsets.symmetric(
//                                         horizontal: AppSpacing.md,
//                                         vertical: AppSpacing.sm,
//                                       ),
//                                       decoration: BoxDecoration(
//                                         color: selectedCategory == category
//                                             ? AppColors.primary
//                                             : AppColors.border,
//                                         borderRadius: BorderRadius.circular(20),
//                                         border: Border.all(
//                                           color: selectedCategory == category
//                                               ? AppColors.primary
//                                               : AppColors.border,
//                                         ),
//                                       ),
//                                       child: Text(
//                                         category,
//                                         style: AppTextStyles.labelSmall.copyWith(
//                                           color: selectedCategory == category
//                                               ? AppColors.textInverse
//                                               : AppColors.textPrimary,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 )
//                                 .toList(),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: AppSpacing.lg),
//                       CustomTextField(
//                         label: 'Item Description (Optional)',
//                         controller: itemDescriptionController,
//                         hint: 'e.g., Handle with care, fragile icing',
//                         maxLines: 2,
//                       ),
//                       const SizedBox(height: AppSpacing.lg),
//                       CustomTextField(
//                         label: 'Recipient Name *',
//                         controller: recipientNameController,
//                         hint: 'Full name of recipient',
//                       ),
//                       const SizedBox(height: AppSpacing.md),
//                       CustomTextField(
//                         label: 'Recipient Phone *',
//                         controller: recipientPhoneController,
//                         hint: '+234 (XXX) XXX-XXXX',
//                         keyboardType: TextInputType.phone,
//                       ),
//                       const SizedBox(height: AppSpacing.xl),
//                       SizedBox(
//                         width: double.infinity,
//                         child: PrimaryButton(
//                           label: 'Save Stop',
//                           onPressed: () {
//                             // Validate
//                             if (itemNameController.text.isEmpty ||
//                                 recipientNameController.text.isEmpty ||
//                                 recipientPhoneController.text.isEmpty) {
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(
//                                   content: Text(
//                                       'Please fill all required fields (marked with *)'),
//                                 ),
//                               );
//                               return;
//                             }

//                             // Update waypoint
//                             ref.read(deliveryProvider.notifier).updateWaypointPackageDetails(
//                               waypointIndex,
//                               PackageDetails(
//                                 itemName: itemNameController.text,
//                                 itemCategory: selectedCategory,
//                                 itemDescription: itemDescriptionController.text.isEmpty
//                                     ? null
//                                     : itemDescriptionController.text,
//                                 recipientName: recipientNameController.text,
//                                 recipientPhone: recipientPhoneController.text,
//                                 isFilled: true,
//                               ),
//                             );

//                             // Add new dropoff
//                             ref.read(deliveryProvider.notifier).addDropoffWaypoint();
//                             _addLocationController();

//                             Navigator.pop(context);

//                             // Scroll to show new field
//                             Future.delayed(const Duration(milliseconds: 300), () {
//                               if (_scrollController.hasClients) {
//                                 _scrollController.animateTo(
//                                   _scrollController.position.maxScrollExtent,
//                                   duration: const Duration(milliseconds: 300),
//                                   curve: Curves.easeOut,
//                                 );
//                               }
//                             });
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   Future<void> _handleContinue() async {
//     final validation =
//         ref.read(deliveryProvider.notifier).validateCurrentLocations();

//     if (!validation.isValid) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(validation.message),
//           backgroundColor: AppColors.error,
//         ),
//       );
//       return;
//     }

//     // Navigate to package details screen
//     if (!mounted) return;
//     Navigator.of(context).pushNamed('/package-details');
//   }

//   @override
//   Widget build(BuildContext context) {
//     final delivery = ref.watch(deliveryProvider);

//     return Scaffold(
//       appBar: const CustomAppBar(
//         title: 'Enter Your Route',
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: SingleChildScrollView(
//               controller: _scrollController,
//               child: Padding(
//                 padding: const EdgeInsets.all(AppSpacing.lg),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Add Locations',
//                       style: AppTextStyles.headingSmall,
//                     ),
//                     const SizedBox(height: AppSpacing.sm),
//                     Text(
//                       'Start by entering your pickup and delivery locations',
//                       style: AppTextStyles.bodySmall.copyWith(
//                         color: AppColors.textSecondary,
//                       ),
//                     ),
//                     const SizedBox(height: AppSpacing.xl),
//                     // Pickup and Dropoff fields
//                     ...List.generate(delivery.waypoints.length, (index) {
//                       final waypoint = delivery.waypoints[index];
//                       final isPickup = waypoint.type == WaypointType.pickup;
//                       final hasError = _errorFields.contains(index);

//                       // Initialize controller if not exists
//                       if (!_locationControllers.containsKey(index)) {
//                         _locationControllers[index] =
//                             TextEditingController(text: waypoint.addressString);
//                       }

//                       return Column(
//                         children: [
//                           CustomTextField(
//                             label: _getLocationLabel(index, waypoint.type),
//                             controller: _locationControllers[index],
//                             hint: isPickup
//                                 ? 'Enter pickup address'
//                                 : 'Enter delivery address',
//                             prefixIcon: Icons.location_on_outlined,
//                             onChanged: (value) {
//                               ref.read(deliveryProvider.notifier).updateWaypointLocation(
//                                 index,
//                                 value,
//                                 0, // TODO: Get actual coordinates from geocoding
//                                 0,
//                               );
//                               if (hasError && value.isNotEmpty) {
//                                 setState(() {
//                                   _errorFields.remove(index);
//                                 });
//                               }
//                             },
//                           ),
//                           const SizedBox(height: AppSpacing.lg),
//                         ],
//                       );
//                     }),
//                     const SizedBox(height: AppSpacing.md),
//                     // Add More Location Button
//                     SecondaryButton(
//                       label: 'Add More Location',
//                       onPressed: _handleAddMoreLocation,
//                     ),
//                     const SizedBox(height: AppSpacing.xl),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           // Continue Button (Sticky at bottom)
//           Container(
//             padding: const EdgeInsets.all(AppSpacing.lg),
//             decoration: BoxDecoration(
//               color: AppColors.background,
//               border: Border(
//                 top: BorderSide(
//                   color: AppColors.border,
//                   width: 1,
//                 ),
//               ),
//             ),
//             child: Column(
//               children: [
//                 SizedBox(
//                   width: double.infinity,
//                   child: PrimaryButton(
//                     label: 'Continue',
//                     onPressed: _handleContinue,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
