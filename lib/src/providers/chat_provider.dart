import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../services/index.dart';
import 'api_provider.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  final apiClient = ref.watch(apiClientProvider).maybeWhen(
    data: (value) => value,
    orElse: () => ApiClient(),
  );
  final prefs = ref.watch(sharedPreferencesProvider).maybeWhen(
    data: (value) => value,
    orElse: () => null,
  );
  return ChatService(apiClient: apiClient, preferences: prefs);
});

// Chat Threads Provider - Get list of all chat conversations
final chatThreadsProvider = FutureProvider<List<ChatThread>>((ref) async {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.getChatThreads();
});

// Chat Messages Provider - Get messages for a specific user/thread
final chatMessagesProvider = FutureProvider.family<List<ChatMessage>, String>((ref, userId) async {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.getChatMessages(userId);
});

// Message Sending State Notifier
final messageSendingProvider = StateNotifierProvider<MessageSendingNotifier, MessageSendingState>(
  (ref) => MessageSendingNotifier(ref.watch(chatServiceProvider)),
);

class MessageSendingState {
  final bool isLoading;
  final String? error;
  final bool sent;

  MessageSendingState({
    this.isLoading = false,
    this.error,
    this.sent = false,
  });

  MessageSendingState copyWith({
    bool? isLoading,
    String? error,
    bool? sent,
  }) {
    return MessageSendingState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      sent: sent ?? this.sent,
    );
  }
}

class MessageSendingNotifier extends StateNotifier<MessageSendingState> {
  final ChatService _chatService;

  MessageSendingNotifier(this._chatService) : super(MessageSendingState());

  Future<void> sendMessage(String receiverId, String message) async {
    state = state.copyWith(isLoading: true, error: null, sent: false);
    try {
      await _chatService.sendMessage(receiverId, message);
      state = state.copyWith(isLoading: false, sent: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> sendAttachment(String receiverId, dynamic file, {String? caption}) async {
    state = state.copyWith(isLoading: true, error: null, sent: false);
    try {
      // file is expected to be XFile or similar
      await _chatService.sendAttachment(receiverId, file);
      state = state.copyWith(isLoading: false, sent: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() {
    state = MessageSendingState();
  }
}
