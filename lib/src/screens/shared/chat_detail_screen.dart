import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/index.dart';
import '../../utils/web_file_picker.dart';
import '../../widgets/index.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String userId;
  final String userName;
  final String? riderRole;
  final String? riderPhoneNumber;

  const ChatDetailScreen({
    Key? key,
    required this.userId,
    required this.userName,
    this.riderRole,
    this.riderPhoneNumber = '+234 800 123 4567',
  }) : super(key: key);

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _picker = ImagePicker();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final messageText = _messageController.text;
    _messageController.clear();

    // Send message via provider
    await ref.read(messageSendingProvider.notifier).sendMessage(
      widget.userId,
      messageText,
    );

    // Optionally refresh messages after sending
    ref.invalidate(chatMessagesProvider(widget.userId));
  }

  void _showCallDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.userName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phone: ${widget.riderPhoneNumber}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Choose an action:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${widget.riderPhoneNumber} copied to clipboard',
                  ),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Copy Number'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Calling ${widget.riderPhoneNumber}...',
                  ),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text(
              'Call Now',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.userId));
    final sendingState = ref.watch(messageSendingProvider);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button and rider info
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // Rider avatar
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.1),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person_outline,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // Rider name and role
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.userName,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.riderRole ?? 'Rider',
                          style: AppTextStyles.captionSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Call button
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.phone,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    onPressed: () {
                      _showCallDialog(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Messages List
          messagesAsync.when(
            loading: () => Expanded(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (error, stack) => Expanded(
              child: Center(
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
            ),
            data: (messages) {
              if (messages.isEmpty) {
                return Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.message_outlined, size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: AppSpacing.md),
                        Text('No messages yet', style: AppTextStyles.bodyLarge),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Start the conversation', style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                );
              }

              return Expanded(
                child: ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isSent = message.senderId != widget.userId;

                    return Align(
                      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: isSent ? AppColors.primary : AppColors.grey100,
                          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        child: Column(
                          crossAxisAlignment: isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (message.attachmentUrl != null && message.attachmentUrl!.isNotEmpty) ...[
                                  if (message.attachmentType == 'image' &&
                                      (message.attachmentUrl!.startsWith('http') || message.attachmentUrl!.startsWith('data:'))) ...[
                                    SizedBox(
                                      width: 200,
                                      height: 200,
                                      child: Image.network(
                                        message.attachmentUrl!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ] else ...[
                                    Container(
                                      padding: const EdgeInsets.all(AppSpacing.md),
                                      decoration: BoxDecoration(
                                        color: isSent ? AppColors.primaryLight : AppColors.grey100,
                                        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.insert_drive_file),
                                          const SizedBox(width: AppSpacing.sm),
                                          Flexible(child: Text(message.attachmentUrl!.split('/').last)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: AppSpacing.sm),
                                ],
                                if (message.message.isNotEmpty) ...[
                                  Text(
                                    message.message,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: isSent ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                ],
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              message.createdAt.toString().split('.')[0],
                              style: AppTextStyles.captionSmall.copyWith(
                                color: isSent ? Colors.white70 : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.accent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            enabled: !sendingState.isLoading,
                            decoration: InputDecoration(
                              hintText: 'Type your message',
                              hintStyle: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.md,
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // Attachment button
                        IconButton(
                          icon: const Icon(Icons.attach_file),
                          color: AppColors.textSecondary,
                          onPressed: sendingState.isLoading
                              ? null
                              : () async {
                                  // Pick image file (works on web and mobile)
                                  try {
                                    final picked = await WebFilePicker.pickImageFile();
                                    if (picked != null) {
                                      await ref
                                          .read(messageSendingProvider.notifier)
                                          .sendAttachment(widget.userId, picked);
                                      ref.invalidate(chatMessagesProvider(widget.userId));
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('No file selected')),
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error picking file: $e')),
                                    );
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Send button
                GestureDetector(
                  onTap: sendingState.isLoading ? null : _sendMessage,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: sendingState.isLoading ? AppColors.textSecondary : AppColors.accent,
                    ),
                    child: Center(
                      child: sendingState.isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 24,
                            ),
                    ),
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
