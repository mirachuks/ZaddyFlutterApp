import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../models/index.dart';
import '../../providers/index.dart';
import '../../screens/shared/rating_screen.dart';
import '../../widgets/index.dart';

class OrderDetailsScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailsScreen({Key? key, required this.orderId})
      : super(key: key);

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final jobDetailsAsync = ref.watch(jobDetailsProvider(widget.orderId));
    final jobStatusStreamAsync = ref.watch(customerJobStatusStreamProvider(widget.orderId));

    Job? liveJob;
    if (jobStatusStreamAsync is AsyncData<Job?>) {
      liveJob = jobStatusStreamAsync.value;
    }

    final jobToShow = liveJob ?? jobDetailsAsync.asData?.value;

    final jobAsync = liveJob != null
        ? AsyncValue.data(jobToShow!)
        : jobDetailsAsync;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Order Details',
      ),
      body: jobAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text('Error loading order', style: AppTextStyles.bodyLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(error.toString(), style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
            ],
          ),
        ),
        data: (job) {
          // Determine status color and label
          Color statusColor;
          String statusLabel;

          switch (job.status) {
            case 'posted':
              statusColor = AppColors.warning;
              statusLabel = 'Posted';
              break;
            case 'accepted':
              statusColor = AppColors.info;
              statusLabel = 'Accepted';
              break;
            case 'picked_up':
              statusColor = AppColors.info;
              statusLabel = 'In Transit';
              break;
            case 'delivered':
              statusColor = AppColors.success;
              statusLabel = 'Delivered';
              break;
            case 'cancelled':
              statusColor = AppColors.error;
              statusLabel = 'Cancelled';
              break;
            default:
              statusColor = AppColors.textSecondary;
              statusLabel = job.status.toUpperCase();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order ID and Status
                CustomCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order #${job.id}',
                            style: AppTextStyles.headingMedium,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppBorderRadius.full),
                            ),
                            child: Text(
                              statusLabel,
                              style: AppTextStyles.labelSmall
                                  .copyWith(color: statusColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Posted: ${job.createdAt.toString().split('.')[0]}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

      if (job.rider != null) ...[
        Text('Rider Details', style: AppTextStyles.headingSmall),
        const SizedBox(height: AppSpacing.md),
        CustomCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: job.rider!.avatar?.isNotEmpty == true
                    ? NetworkImage(job.rider!.avatar!) as ImageProvider
                    : null,
                child: job.rider!.avatar?.isEmpty == true
                    ? Icon(Icons.person, color: AppColors.primary)
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.rider!.fullName, style: AppTextStyles.headingSmall),
                    const SizedBox(height: AppSpacing.xs),
                    if (job.rider!.phone.isNotEmpty)
                      Text(job.rider!.phone, style: AppTextStyles.bodyMedium),
                    if (job.rider!.email.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(job.rider!.email, style: AppTextStyles.bodySmall),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),
      ],

                _LocationCard(
                  icon: Icons.location_on_outlined,
                  label: 'Pickup',
                  address: job.pickupLocation.address,
                  time: 'Now',
                ),

                const SizedBox(height: AppSpacing.md),

                _LocationCard(
                  icon: Icons.location_on_outlined,
                  label: 'Dropoff',
                  address: job.dropoffLocation.address,
                  time: 'TBD',
                ),

                const SizedBox(height: AppSpacing.lg),

                // Item Details
                Text('Item Details', style: AppTextStyles.headingSmall),
                const SizedBox(height: AppSpacing.md),

                if (job.items != null && job.items!.isNotEmpty) ...[
                  for (final item in job.items!)
                    CustomCard(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.15),
                                  borderRadius:
                                      BorderRadius.circular(AppBorderRadius.full),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.inventory_2_outlined,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: AppTextStyles.headingSmall,
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      item.description ?? 'No item description available',
                                      style: AppTextStyles.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text('Receiver Details', style: AppTextStyles.labelMedium),
                          const SizedBox(height: AppSpacing.sm),
                          if (item.receiverName != null && item.receiverName!.isNotEmpty) ...[
                            _DetailRow(
                              label: 'Name',
                              value: item.receiverName!,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          if (item.receiverPhone != null && item.receiverPhone!.isNotEmpty) ...[
                            _DetailRow(
                              label: 'Phone',
                              value: item.receiverPhone!,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          if ((item.receiverName == null || item.receiverName!.isEmpty) &&
                              (item.receiverPhone == null || item.receiverPhone!.isEmpty)) ...[
                            Text(
                              'No receiver details provided',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          _DetailRow(
                            label: 'Pickup',
                            value: item.pickupAddress ?? 'Unknown pickup address',
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _DetailRow(
                            label: 'Dropoff',
                            value: item.dropoffAddress ?? 'Unknown dropoff address',
                          ),
                          if (item.price != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            _DetailRow(
                              label: 'Item fare',
                              value: '₦${item.price!.toStringAsFixed(2)}',
                            ),
                          ],
                          if (item.itemCategory != null && item.itemCategory!.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.sm),
                            _DetailRow(
                              label: 'Category',
                              value: item.itemCategory!,
                            ),
                          ],
                        ],
                      ),
                    ),
                ] else ...[
                  CustomCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(AppBorderRadius.md),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.shopping_bag_outlined,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    job.itemDescription,
                                    style: AppTextStyles.bodyLarge,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Urgency: ${job.urgency}',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.lg),

                // Pricing
                Text('Pricing', style: AppTextStyles.headingSmall),
                const SizedBox(height: AppSpacing.md),

                CustomCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      _PricingRow(
                        label: 'Total Fare',
                        amount: '₦${(job.totalPrice ?? job.estimatedFare).toStringAsFixed(2)}',
                        isBold: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),
                if (job.status == 'completed')
                  CustomCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: AppColors.success, size: 28),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          'Delivery Completed',
                          style: AppTextStyles.headingSmall.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (job.status == 'in_progress' || job.status == 'delivered')
                  ...[
                    SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final jobService = ref.read(jobServiceProvider);
                          await jobService.updateJobStatus(job.id, 'completed');
                          ref.refresh(jobDetailsProvider(job.id));
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Order marked as received. Thank you!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => RatingScreen(
                                  jobId: job.id,
                                  userName: job.rider?.fullName ?? 'Your Rider',
                                  userAvatar: job.rider?.avatar ?? '',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to confirm receipt: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Confirm Received'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            final TextEditingController _reportController =
                                TextEditingController();
                            return AlertDialog(
                              title: const Text('Report / Dispute'),
                              content: TextField(
                                controller: _reportController,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                    hintText: 'Describe the issue'),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    final msg = _reportController.text.trim();
                                    Navigator.pop(context);
                                    if (msg.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Report message cannot be empty'),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                      return;
                                    }
                                    try {
                                      final jobService = ref.read(jobServiceProvider);
                                      await jobService.reportJob(job.id, msg);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Report submitted'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to submit report: $e'),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('Send'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Text(
                        'Report / Dispute',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String address;
  final String time;

  const _LocationCard({
    required this.icon,
    required this.label,
    required this.address,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.labelMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(address, style: AppTextStyles.bodySmall),
                const SizedBox(height: AppSpacing.xs),
                Text(time, style: AppTextStyles.captionSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingRow extends StatelessWidget {
  final String label;
  final String amount;
  final bool isBold;

  const _PricingRow({
    required this.label,
    required this.amount,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBold ? AppTextStyles.bodyLarge : AppTextStyles.bodyMedium,
        ),
        Text(
          amount,
          style: isBold ? AppTextStyles.bodyLarge : AppTextStyles.bodyMedium,
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: AppTextStyles.bodySmall),
      ],
    );
  }
}
