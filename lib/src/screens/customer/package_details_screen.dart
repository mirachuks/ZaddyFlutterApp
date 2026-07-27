
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../widgets/index.dart';
import '../../providers/delivery_provider.dart';
import '../../models/delivery_model.dart';

class PackageDetailsScreen extends ConsumerStatefulWidget {
  const PackageDetailsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PackageDetailsScreen> createState() =>
      _PackageDetailsScreenState();
}

class _PackageDetailsScreenState extends ConsumerState<PackageDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    final delivery = ref.read(deliveryProvider);
    final dropoffCount = delivery.dropoffCount;
    _tabController = TabController(length: dropoffCount, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    setState(() {
      _currentTabIndex = _tabController.index;
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _handleConfirmOrder() {
    final delivery = ref.read(deliveryProvider);
    final validation =
        ref.read(deliveryProvider.notifier).validateAllWaypoints();

    if (!validation.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validation.message),
          backgroundColor: AppColors.error,
        ),
      );

      if (_tabController.length > 1 && validation.failedFieldIndex != null) {
        int tabIndex = 0;
        for (int i = 0; i < validation.failedFieldIndex!; i++) {
          if (delivery.waypoints[i].type == WaypointType.dropoff) {
            tabIndex++;
          }
        }
        _tabController.animateTo(tabIndex);
      }

      return;
    }

    ref.read(deliveryProvider.notifier).setLoading(true);
    unawaited(_performBroadcast());
  }

  Future<void> _performBroadcast() async {
    try {
      await ref.read(deliveryProvider.notifier).broadcastOrder();

      final payload =
          ref.read(deliveryProvider.notifier).state.waypoints.asMap().entries.fold<Map<String, dynamic>>(
            {'stops': []},
            (Map<String, dynamic> acc, entry) {
              final index = entry.key;
              final waypoint = entry.value;
              final stops = List<Map<String, dynamic>>.from(acc['stops'] as List);
              stops.add({
                'sequence': index + 1,
                'type': waypoint.type.toString().split('.').last,
                'address': waypoint.addressString,
                'coordinates': {
                  'lat': waypoint.coordinates.lat,
                  'lng': waypoint.coordinates.lng,
                },
                if (waypoint.type == WaypointType.dropoff)
                  'package': {
                    'itemName': waypoint.packageDetails.itemName,
                    'itemCategory': waypoint.packageDetails.itemCategory,
                    'itemDescription': waypoint.packageDetails.itemDescription,
                    'recipientName': waypoint.packageDetails.recipientName,
                    'recipientPhone': waypoint.packageDetails.recipientPhone,
                  },
              });
              return {...acc, 'stops': stops};
            },
          );

      print('Order broadcast with payload: $payload');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order confirmed and broadcast successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      ref.read(deliveryProvider.notifier).resetDelivery();
      Navigator.of(context).pushReplacementNamed('/customer-dashboard');
    } catch (e) {
      ref.read(deliveryProvider.notifier).setLoading(false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final delivery = ref.watch(deliveryProvider);
    final isMultiStop = delivery.dropoffCount > 1;

    final dropoffWaypoints =
        delivery.waypoints.where((w) => w.type == WaypointType.dropoff).toList();

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Package Details',
      ),
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          if (isMultiStop)
            Container(
              color: AppColors.background,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: List.generate(
                  dropoffWaypoints.length,
                  (index) => Tab(text: 'Stop ${index + 1}'),
                ),
              ),
            ),
          Expanded(
            child: isMultiStop
                ? TabBarView(
                    controller: _tabController,
                    children: List.generate(
                      dropoffWaypoints.length,
                      (index) => _PackageDetailsForm(
                        waypointIndex: _getWaypointIndex(dropoffWaypoints[index]),
                        waypoint: dropoffWaypoints[index],
                      ),
                    ),
                  )
                : _PackageDetailsForm(
                    waypointIndex: _getWaypointIndex(dropoffWaypoints[0]),
                    waypoint: dropoffWaypoints[0],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
        ),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: delivery.isLoading
                    ? 'Processing...'
                    : 'Confirm & Broadcast Order',
                onPressed: _handleConfirmOrder,
                isLoading: delivery.isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getWaypointIndex(Waypoint waypoint) {
    return ref.read(deliveryProvider).waypoints.indexOf(waypoint);
  }
}

class _PackageDetailsForm extends ConsumerStatefulWidget {
  final int waypointIndex;
  final Waypoint waypoint;

  const _PackageDetailsForm({
    required this.waypointIndex,
    required this.waypoint,
  });

  @override
  ConsumerState<_PackageDetailsForm> createState() =>
      _PackageDetailsFormState();
}

class _PackageDetailsFormState extends ConsumerState<_PackageDetailsForm> {
  late TextEditingController _itemNameController;
  late TextEditingController _itemDescriptionController;
  late TextEditingController _recipientNameController;
  late TextEditingController _recipientPhoneController;

  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    final details = widget.waypoint.packageDetails;
    _itemNameController = TextEditingController(text: details.itemName);
    _itemDescriptionController =
        TextEditingController(text: details.itemDescription ?? '');
    _recipientNameController =
        TextEditingController(text: details.recipientName);
    _recipientPhoneController =
        TextEditingController(text: details.recipientPhone);
    _selectedCategory = details.itemCategory.isNotEmpty
        ? details.itemCategory
        : 'Electronics';
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _itemDescriptionController.dispose();
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    if (_itemNameController.text.isEmpty ||
        _recipientNameController.text.isEmpty ||
        _recipientPhoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    ref.read(deliveryProvider.notifier).updateWaypointPackageDetails(
      widget.waypointIndex,
      PackageDetails(
        itemName: _itemNameController.text,
        itemCategory: _selectedCategory,
        itemDescription:
            _itemDescriptionController.text.isEmpty
                ? null
                : _itemDescriptionController.text,
        recipientName: _recipientNameController.text,
        recipientPhone: _recipientPhoneController.text,
        isFilled: true,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Changes saved'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Detect the visible software keyboard height dynamically
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          // FIX: Append keyboard height here so the view expands and scrolls properly
          bottom: AppSpacing.xl + keyboardHeight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delivery Location',
                              style: AppTextStyles.labelSmall,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              widget.waypoint.addressString,
                              style: AppTextStyles.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Package Information',
              style: AppTextStyles.headingSmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            CustomTextField(
              label: 'Item Name *',
              controller: _itemNameController,
              hint: 'e.g., Watch, Noodle, Clothes',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.lg),
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
                              _selectedCategory = category;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: _selectedCategory == category
                                  ? AppColors.primary
                                  : AppColors.border,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _selectedCategory == category
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              category,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: _selectedCategory == category
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
              controller: _itemDescriptionController,
              hint: 'e.g., Handle with care',
              maxLines: 2,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Recipient Information',
              style: AppTextStyles.headingSmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            CustomTextField(
              label: 'Recipient Name *',
              controller: _recipientNameController,
              hint: 'Full name',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.lg),
            CustomTextField(
              label: 'Recipient Phone *',
              controller: _recipientPhoneController,
              hint: '+234 (XXX) XXX-XXXX',
              keyboardType: TextInputType.phone,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: SecondaryButton(
                label: 'Save Changes',
                onPressed: _saveChanges,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}



//OLD CODE WITH KEYBOARD FLOATING ISSUE
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../config/theme.dart';
// import '../../widgets/index.dart';
// import '../../providers/delivery_provider.dart';
// import '../../models/delivery_model.dart';

// class PackageDetailsScreen extends ConsumerStatefulWidget {
//   const PackageDetailsScreen({Key? key}) : super(key: key);

//   @override
//   ConsumerState<PackageDetailsScreen> createState() =>
//       _PackageDetailsScreenState();
// }

// class _PackageDetailsScreenState extends ConsumerState<PackageDetailsScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   int _currentTabIndex = 0;

//   @override
//   void initState() {
//     super.initState();
//     final delivery = ref.read(deliveryProvider);
//     final dropoffCount = delivery.dropoffCount;
//     _tabController = TabController(length: dropoffCount, vsync: this);
//     _tabController.addListener(_onTabChanged);
//   }

//   void _onTabChanged() {
//     setState(() {
//       _currentTabIndex = _tabController.index;
//     });
//   }

//   @override
//   void dispose() {
//     _tabController.removeListener(_onTabChanged);
//     _tabController.dispose();
//     super.dispose();
//   }

//   void _handleConfirmOrder() {
//     final delivery = ref.read(deliveryProvider);
//     final validation =
//         ref.read(deliveryProvider.notifier).validateAllWaypoints();

//     if (!validation.isValid) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(validation.message),
//           backgroundColor: AppColors.error,
//         ),
//       );

//       // Navigate to the failed tab if multi-stop
//       if (_tabController.length > 1 && validation.failedFieldIndex != null) {
//         // Find the tab index for the failed waypoint
//         int tabIndex = 0;
//         for (int i = 0; i < validation.failedFieldIndex!; i++) {
//           if (delivery.waypoints[i].type == WaypointType.dropoff) {
//             tabIndex++;
//           }
//         }
//         _tabController.animateTo(tabIndex);
//       }

//       return;
//     }

//     // Show loading state
//     ref.read(deliveryProvider.notifier).setLoading(true);

//     // Start async operation without awaiting (fire and forget)
//     unawaited(_performBroadcast());
//   }

//   Future<void> _performBroadcast() async {
//     try {
//       // Broadcast the order
//       await ref.read(deliveryProvider.notifier).broadcastOrder();

//       final payload =
//           ref.read(deliveryProvider.notifier).state.waypoints.asMap().entries.fold<Map<String, dynamic>>(
//             {'stops': []},
//             (Map<String, dynamic> acc, entry) {
//               final index = entry.key;
//               final waypoint = entry.value;
//               final stops = List<Map<String, dynamic>>.from(acc['stops'] as List);
//               stops.add({
//                 'sequence': index + 1,
//                 'type': waypoint.type.toString().split('.').last,
//                 'address': waypoint.addressString,
//                 'coordinates': {
//                   'lat': waypoint.coordinates.lat,
//                   'lng': waypoint.coordinates.lng,
//                 },
//                 if (waypoint.type == WaypointType.dropoff)
//                   'package': {
//                     'itemName': waypoint.packageDetails.itemName,
//                     'itemCategory': waypoint.packageDetails.itemCategory,
//                     'itemDescription': waypoint.packageDetails.itemDescription,
//                     'recipientName': waypoint.packageDetails.recipientName,
//                     'recipientPhone': waypoint.packageDetails.recipientPhone,
//                   },
//               });
//               return {...acc, 'stops': stops};
//             },
//           );

//       print('Order broadcast with payload: $payload');

//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Order confirmed and broadcast successfully!'),
//           backgroundColor: Colors.green,
//         ),
//       );

//       // Reset delivery state and navigate back to dashboard
//       ref.read(deliveryProvider.notifier).resetDelivery();
//       Navigator.of(context).pushReplacementNamed('/customer-dashboard');
//     } catch (e) {
//       ref.read(deliveryProvider.notifier).setLoading(false);

//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error: $e'),
//           backgroundColor: AppColors.error,
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final delivery = ref.watch(deliveryProvider);
//     final isMultiStop = delivery.dropoffCount > 1;

//     // Get all dropoff waypoints
//     final dropoffWaypoints =
//         delivery.waypoints.where((w) => w.type == WaypointType.dropoff).toList();

//     return Scaffold(
//       appBar: const CustomAppBar(
//         title: 'Package Details',
//       ),
//       body: Column(
//         children: [
//           // Tab bar for multi-stop (hidden for single stop)
//           if (isMultiStop)
//             Container(
//               color: AppColors.background,
//               child: TabBar(
//                 controller: _tabController,
//                 labelColor: AppColors.primary,
//                 unselectedLabelColor: AppColors.textSecondary,
//                 indicatorColor: AppColors.primary,
//                 tabs: List.generate(
//                   dropoffWaypoints.length,
//                   (index) => Tab(text: 'Stop ${index + 1}'),
//                 ),
//               ),
//             ),
//           // Content
//           Expanded(
//             child: isMultiStop
//                 ? TabBarView(
//                     controller: _tabController,
//                     children: List.generate(
//                       dropoffWaypoints.length,
//                       (index) => _PackageDetailsForm(
//                         waypointIndex: _getWaypointIndex(dropoffWaypoints[index]),
//                         waypoint: dropoffWaypoints[index],
//                       ),
//                     ),
//                   )
//                 : _PackageDetailsForm(
//                     waypointIndex: _getWaypointIndex(dropoffWaypoints[0]),
//                     waypoint: dropoffWaypoints[0],
//                   ),
//           ),
//         ],
//       ),
//       bottomNavigationBar: Container(
//         padding: const EdgeInsets.all(AppSpacing.lg),
//         decoration: BoxDecoration(
//           color: AppColors.background,
//           border: Border(
//             top: BorderSide(
//               color: AppColors.border,
//               width: 1,
//             ),
//           ),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             SizedBox(
//               width: double.infinity,
//               child: PrimaryButton(
//                 label: delivery.isLoading
//                     ? 'Processing...'
//                     : 'Confirm & Broadcast Order',
//                 onPressed: _handleConfirmOrder,
//                 isLoading: delivery.isLoading,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   int _getWaypointIndex(Waypoint waypoint) {
//     return ref.read(deliveryProvider).waypoints.indexOf(waypoint);
//   }
// }

// class _PackageDetailsForm extends ConsumerStatefulWidget {
//   final int waypointIndex;
//   final Waypoint waypoint;

//   const _PackageDetailsForm({
//     required this.waypointIndex,
//     required this.waypoint,
//   });

//   @override
//   ConsumerState<_PackageDetailsForm> createState() =>
//       _PackageDetailsFormState();
// }

// class _PackageDetailsFormState extends ConsumerState<_PackageDetailsForm> {
//   late TextEditingController _itemNameController;
//   late TextEditingController _itemDescriptionController;
//   late TextEditingController _recipientNameController;
//   late TextEditingController _recipientPhoneController;

//   late String _selectedCategory;

//   @override
//   void initState() {
//     super.initState();
//     final details = widget.waypoint.packageDetails;
//     _itemNameController = TextEditingController(text: details.itemName);
//     _itemDescriptionController =
//         TextEditingController(text: details.itemDescription ?? '');
//     _recipientNameController =
//         TextEditingController(text: details.recipientName);
//     _recipientPhoneController =
//         TextEditingController(text: details.recipientPhone);
//     _selectedCategory = details.itemCategory.isNotEmpty
//         ? details.itemCategory
//         : 'Electronics';
//   }

//   @override
//   void dispose() {
//     _itemNameController.dispose();
//     _itemDescriptionController.dispose();
//     _recipientNameController.dispose();
//     _recipientPhoneController.dispose();
//     super.dispose();
//   }

//   void _saveChanges() {
//     // Validate
//     if (_itemNameController.text.isEmpty ||
//         _recipientNameController.text.isEmpty ||
//         _recipientPhoneController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please fill all required fields'),
//           backgroundColor: AppColors.error,
//         ),
//       );
//       return;
//     }

//     // Update waypoint
//     ref.read(deliveryProvider.notifier).updateWaypointPackageDetails(
//       widget.waypointIndex,
//       PackageDetails(
//         itemName: _itemNameController.text,
//         itemCategory: _selectedCategory,
//         itemDescription:
//             _itemDescriptionController.text.isEmpty
//                 ? null
//                 : _itemDescriptionController.text,
//         recipientName: _recipientNameController.text,
//         recipientPhone: _recipientPhoneController.text,
//         isFilled: true,
//       ),
//     );

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Changes saved'),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: Padding(
//         padding: const EdgeInsets.all(AppSpacing.lg),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Destination info
//             Container(
//               padding: const EdgeInsets.all(AppSpacing.md),
//               decoration: BoxDecoration(
//                 color: AppColors.border,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Icon(
//                         Icons.location_on,
//                         color: AppColors.primary,
//                         size: 20,
//                       ),
//                       const SizedBox(width: AppSpacing.sm),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Delivery Location',
//                               style: AppTextStyles.labelSmall,
//                             ),
//                             const SizedBox(height: AppSpacing.xs),
//                             Text(
//                               widget.waypoint.addressString,
//                               style: AppTextStyles.bodySmall,
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: AppSpacing.xl),
//             // Form section
//             Text(
//               'Package Information',
//               style: AppTextStyles.headingSmall,
//             ),
//             const SizedBox(height: AppSpacing.lg),
//             CustomTextField(
//               label: 'Item Name *',
//               controller: _itemNameController,
//               hint: 'e.g., Watch, Noodle, Clothes', ' ,
//               onChanged: (_) => setState(() {}),
//             ),
//             const SizedBox(height: AppSpacing.lg),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Item Category *',
//                   style: AppTextStyles.labelSmall,
//                 ),
//                 const SizedBox(height: AppSpacing.sm),
//                 Wrap(
//                   spacing: AppSpacing.sm,
//                   runSpacing: AppSpacing.sm,
//                   children: [
//                     'Electronics',
//                     'Documents',
//                     'Food',
//                     'Fashion',
//                     'Others',
//                   ]
//                       .map(
//                         (category) => GestureDetector(
//                           onTap: () {
//                             setState(() {
//                               _selectedCategory = category;
//                             });
//                           },
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: AppSpacing.md,
//                               vertical: AppSpacing.sm,
//                             ),
//                             decoration: BoxDecoration(
//                               color: _selectedCategory == category
//                                   ? AppColors.primary
//                                   : AppColors.border,
//                               borderRadius: BorderRadius.circular(20),
//                               border: Border.all(
//                                 color: _selectedCategory == category
//                                     ? AppColors.primary
//                                     : AppColors.border,
//                               ),
//                             ),
//                             child: Text(
//                               category,
//                               style: AppTextStyles.labelSmall.copyWith(
//                                 color: _selectedCategory == category
//                                     ? AppColors.textInverse
//                                     : AppColors.textPrimary,
//                               ),
//                             ),
//                           ),
//                         ),
//                       )
//                       .toList(),
//                 ),
//               ],
//             ),
//             const SizedBox(height: AppSpacing.lg),
//             CustomTextField(
//               label: 'Item Description (Optional)',
//               controller: _itemDescriptionController,
//               hint: 'e.g., Handle with care',
//               maxLines: 2,
//               onChanged: (_) => setState(() {}),
//             ),
//             const SizedBox(height: AppSpacing.xl),
//             Text(
//               'Recipient Information',
//               style: AppTextStyles.headingSmall,
//             ),
//             const SizedBox(height: AppSpacing.lg),
//             CustomTextField(
//               label: 'Recipient Name *',
//               controller: _recipientNameController,
//               hint: 'Full name',
//               onChanged: (_) => setState(() {}),
//             ),
//             const SizedBox(height: AppSpacing.lg),
//             CustomTextField(
//               label: 'Recipient Phone *',
//               controller: _recipientPhoneController,
//               hint: '+234 (XXX) XXX-XXXX',
//               keyboardType: TextInputType.phone,
//               onChanged: (_) => setState(() {}),
//             ),
//             const SizedBox(height: AppSpacing.xl),
//             SizedBox(
//               width: double.infinity,
//               child: SecondaryButton(
//                 label: 'Save Changes',
//                 onPressed: _saveChanges,
//               ),
//             ),
//             const SizedBox(height: AppSpacing.xl),
//           ],
//         ),
//       ),
//     );
//   }
// }
