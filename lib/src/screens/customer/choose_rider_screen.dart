import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/index.dart';
import '../../models/parcel_model.dart';

class RiderOffer {
  final String riderId;
  final String riderName;
  final double rating;
  final String vehicleType;
  final String vehiclePlate;
  final double price;
  final String eta;
  final String avatarUrl;
  final String? phone;
  final String? email;

  RiderOffer({
    required this.riderId,
    required this.riderName,
    required this.rating,
    required this.vehicleType,
    required this.vehiclePlate,
    required this.price,
    required this.eta,
    required this.avatarUrl,
    this.phone,
    this.email,
  });
}

class ChooseRiderScreen extends StatefulWidget {
  final List<Parcel> parcels;
  final double estimatedFare;
  final List<RiderOffer>? riderOffers;

  const ChooseRiderScreen({
    Key? key,
    required this.parcels,
    required this.estimatedFare,
    this.riderOffers,
  }) : super(key: key);

  @override
  State<ChooseRiderScreen> createState() => _ChooseRiderScreenState();
}

class _ChooseRiderScreenState extends State<ChooseRiderScreen> {
  late List<RiderOffer> _riderOffers;

  @override
  void initState() {
    super.initState();
    // Use provided offers or generate default ones
    _riderOffers = widget.riderOffers ??
        [
          RiderOffer(
            riderId: 'rider_001',
            riderName: 'Ahmed Hassan',
            rating: 4.8,
            vehicleType: 'Motorcycle',
            vehiclePlate: 'ABC 123XY',
            price: widget.estimatedFare,
            eta: '5 mins',
            avatarUrl: '',
          ),
          RiderOffer(
            riderId: 'rider_002',
            riderName: 'Chinedu Okoro',
            rating: 4.6,
            vehicleType: 'Tricycle',
            vehiclePlate: 'XYZ 456AB',
            price: widget.estimatedFare - 100,
            eta: '8 mins',
            avatarUrl: '',
          ),
          RiderOffer(
            riderId: 'rider_003',
            riderName: 'Fatima Muhammad',
            rating: 4.9,
            vehicleType: 'Car',
            vehiclePlate: 'LKJ 789CD',
            price: widget.estimatedFare + 200,
            eta: '3 mins',
            avatarUrl: '',
          ),
        ];
  }

  void _acceptRider(RiderOffer rider) {
    // Navigate to PaymentScreen first
    Navigator.pushNamed(
      context,
      '/payment',
      arguments: {
        'parcels': widget.parcels,
        'estimatedFare': widget.estimatedFare,
      },
    );
  }

  void _declineRider(String riderId) {
    setState(() {
      _riderOffers.removeWhere((rider) => rider.riderId == riderId);
    });
    
    if (_riderOffers.isEmpty) {
      // Show dialog that no riders remain
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No More Riders'),
          content: const Text('No more riders are available. Would you like to retry?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Go back to order summary
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Go back to order summary
                // Could trigger retry here if needed
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map background (placeholder)
          Container(
            color: AppColors.border.withOpacity(0.5),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Map View',
                    style: AppTextStyles.headingSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Rider offers list overlay
          Column(
            children: [
              // Top app bar
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      Text(
                        'Choose a Rider',
                        style: AppTextStyles.headingSmall,
                      ),
                      const SizedBox(width: 48), // Placeholder for symmetry
                    ],
                  ),
                ),
              ),

              // Spacer to push rider cards to bottom
              Expanded(
                child: SizedBox.expand(),
              ),

              // Rider offers cards
              Container(
                margin: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        '${_riderOffers.length} Rider${_riderOffers.length > 1 ? 's' : ''} Available',
                        style: AppTextStyles.headingSmall,
                      ),
                    ),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _riderOffers.length,
                        separatorBuilder: (_, __) => Divider(
                          color: AppColors.border,
                          height: 1,
                          indent: AppSpacing.lg,
                          endIndent: AppSpacing.lg,
                        ),
                        itemBuilder: (context, index) {
                          final rider = _riderOffers[index];
                          return _buildRiderOfferCard(rider);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiderOfferCard(RiderOffer rider) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rider info header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.2),
                ),
                child: Center(
                  child: Text(
                    rider.riderName.substring(0, 1).toUpperCase(),
                    style: AppTextStyles.headingSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              // Rider details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rider.riderName,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '${rider.rating}',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ETA
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    rider.eta,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '₦${rider.price.toStringAsFixed(0)}',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Vehicle info
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  rider.vehicleType,
                  style: AppTextStyles.bodySmall,
                ),
                Text(
                  rider.vehiclePlate,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Action buttons
          Row(
            spacing: AppSpacing.md,
            children: [
              // Decline button
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _declineRider(rider.riderId),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                  ),
                  child: const Text('Decline'),
                ),
              ),

              // Accept button
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _acceptRider(rider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                  ),
                  child: const Text(
                    'Accept',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
