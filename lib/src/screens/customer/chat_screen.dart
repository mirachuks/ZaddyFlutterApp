import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/index.dart';
import '../../widgets/index.dart';

class CustomerChatScreen extends ConsumerWidget {
  const CustomerChatScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatThreadsAsync = ref.watch(chatThreadsProvider);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Messages',
        showBackButton: false,
      ),
      body: chatThreadsAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text('Error loading messages', style: AppTextStyles.bodyLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(error.toString(), style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
            ],
          ),
        ),
        data: (threads) {
          if (threads.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.message_outlined, size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: AppSpacing.md),
                  Text('No messages yet', style: AppTextStyles.bodyLarge),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Start a conversation with a rider', style: AppTextStyles.bodySmall),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: threads.length,
            itemBuilder: (context, index) {
              final thread = threads[index];
              final isUnread = thread.unreadCount > 0;

              return GestureDetector(
                onTap: () => Navigator.of(context).pushNamed(
                  '/chat-detail',
                  arguments: {
                    'userId': thread.userId2,
                    'userName': thread.otherUserName ?? 'User',
                  },
                ),
                child: CustomCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: thread.otherUserAvatar != null
                            ? ClipOval(
                                child: Image.network(
                                  thread.otherUserAvatar!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Center(
                                    child: Icon(
                                      Icons.person_outline,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.person_outline,
                                  color: AppColors.primary,
                                ),
                              ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  thread.otherUserName ?? 'Unknown User',
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: isUnread ? FontWeight.bold : null,
                                  ),
                                ),
                                Text(
                                  _formatTimeAgo(thread.lastMessageTime),
                                  style: AppTextStyles.captionSmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              thread.lastMessage ?? 'No messages yet',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isUnread ? AppColors.textPrimary : AppColors.textSecondary,
                                fontWeight: isUnread ? FontWeight.w500 : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Now';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return dateTime.toString().split(' ')[0];
    }
  }
}

extension on CustomCard {
  CustomCard copyWith({EdgeInsets? margin}) {
    return CustomCard(
      padding: padding,
      onTap: onTap,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      child: child,
    );
  }
}
