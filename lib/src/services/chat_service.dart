import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/form_data_utils.dart';

import 'api_client.dart';
import '../models/index.dart';

class ChatService {
  static const _messagesStorageKey = 'chat_messages';
  static const _threadsStorageKey = 'chat_threads';
  static const _defaultUserId = 'current_user';

  final ApiClient apiClient;
  final SharedPreferences? preferences;
  SharedPreferences? _resolvedPreferences;

  ChatService({ApiClient? apiClient, this.preferences})
      : apiClient = apiClient ?? ApiClient();

  Future<SharedPreferences> _prefs() async {
    _resolvedPreferences ??= preferences ?? await SharedPreferences.getInstance();
    return _resolvedPreferences!;
  }

  Future<List<ChatMessage>> getChatMessages(String userId, {int page = 1, int limit = 50}) async {
    try {
      final response = await apiClient.getChatMessages(userId, page: page, limit: limit);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final messages = _parseMessages(response.data)
            .where((message) => message.senderId == userId || message.receiverId == userId)
            .toList();
        messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return messages;
      }
    } catch (_) {}

    return _readStoredMessages(userId);
  }

  Future<void> sendMessage(String receiverId, String message) async {
    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: _defaultUserId,
      receiverId: receiverId,
      message: message,
      createdAt: DateTime.now(),
      senderName: 'You',
    );

    final existing = await _readStoredMessages(receiverId);
    final updatedMessages = [newMessage, ...existing];
    await _saveMessages(updatedMessages);

    try {
      await apiClient.sendMessage(receiverId, message);
    } catch (_) {
      // Fall back to local persistence when the chat endpoint is unavailable.
    }
  }

  Future<void> sendAttachment(String receiverId, XFile file, {String? caption, String? attachmentType}) async {
    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: _defaultUserId,
      receiverId: receiverId,
      message: caption ?? '',
      createdAt: DateTime.now(),
      senderName: 'You',
      attachmentUrl: file.path ?? file.name,
      attachmentType: attachmentType ?? (file.mimeType != null && file.mimeType!.startsWith('image') ? 'image' : 'file'),
    );

    final existing = await _readStoredMessages(receiverId);
    final updatedMessages = [newMessage, ...existing];
    await _saveMessages(updatedMessages);

    try {
      // Prepare payload and attempt to send as multipart
      final payload = <String, dynamic>{
        'receiver_id': receiverId,
        'message': caption ?? '',
        'attachment': file,
      };

      final prepared = await FormDataUtils.prepareFormData(payload);
      await apiClient.post('/messages', data: prepared);
    } catch (_) {
      // ignore network errors, message persisted locally
    }
  }

  Future<List<ChatThread>> getChatThreads() async {
    try {
      final response = await apiClient.getChatThreads();
      if (response.statusCode == 200 || response.statusCode == 201) {
        return _parseThreads(response.data);
      }
    } catch (_) {}

    final messages = await _readStoredMessages();
    if (messages.isEmpty) {
      return [];
    }

    final threadsByUser = <String, ChatThread>{};
    for (final message in messages) {
      final otherUserId = message.senderId == _defaultUserId ? message.receiverId : message.senderId;
      final normalizedId = otherUserId.isEmpty ? message.id : otherUserId;
      final existing = threadsByUser[normalizedId];
      final thread = ChatThread(
        id: existing?.id ?? normalizedId,
        userId1: _defaultUserId,
        userId2: normalizedId,
        lastMessage: message.message,
        lastMessageTime: message.createdAt,
        unreadCount: existing?.unreadCount ?? 0,
        otherUserName: message.senderName ?? _formatUserName(normalizedId),
      );
      threadsByUser[normalizedId] = thread;
    }

    return threadsByUser.values.toList()
      ..sort((a, b) => (b.lastMessageTime ?? DateTime.now()).compareTo(a.lastMessageTime ?? DateTime.now()));
  }

  List<ChatMessage> _parseMessages(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => ChatMessage.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    if (data is Map<String, dynamic>) {
      final maybeData = data['data'];
      if (maybeData is List) {
        return maybeData
            .whereType<Map>()
            .map((item) => ChatMessage.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
      if (maybeData is Map<String, dynamic>) {
        return [ChatMessage.fromJson(maybeData)];
      }
      return [ChatMessage.fromJson(data)];
    }

    return [];
  }

  List<ChatThread> _parseThreads(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => ChatThread.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    if (data is Map<String, dynamic>) {
      final maybeData = data['data'];
      if (maybeData is List) {
        return maybeData
            .whereType<Map>()
            .map((item) => ChatThread.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
      if (maybeData is Map<String, dynamic>) {
        return [ChatThread.fromJson(maybeData)];
      }
      return [ChatThread.fromJson(data)];
    }

    return [];
  }

  Future<List<ChatMessage>> _readStoredMessages([String? currentUserId]) async {
    final prefs = await _prefs();
    final raw = prefs.getString(_messagesStorageKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw);
    final messages = (decoded as List)
        .whereType<Map>()
        .map((item) => ChatMessage.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    if (currentUserId == null || currentUserId.isEmpty) {
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return messages;
    }

    final filtered = messages
        .where((message) => message.senderId == currentUserId || message.receiverId == currentUserId)
        .toList();
    filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return filtered;
  }

  Future<void> _saveMessages(List<ChatMessage> messages) async {
    final prefs = await _prefs();
    final encoded = jsonEncode(messages.map((message) => message.toJson()).toList());
    await prefs.setString(_messagesStorageKey, encoded);
  }

  String _formatUserName(String userId) {
    final parts = userId.split('_');
    if (parts.length > 1) {
      return parts.sublist(1).join(' ').trim();
    }
    return userId.isEmpty ? 'User' : userId;
  }
}
