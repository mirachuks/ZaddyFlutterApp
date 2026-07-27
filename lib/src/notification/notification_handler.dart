import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/wallet_provider.dart';

class NotificationHandler {
  static Timer? _timer;

  /// Start polling for notifications and handle actionable payloads.
  static void init(WidgetRef ref, GlobalKey<NavigatorState> navigatorKey) {
    // cancel existing timer
    _timer?.cancel();

    // run immediately once, then periodically
    _checkOnceAndSchedule(ref, navigatorKey);
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkOnceAndSchedule(ref, navigatorKey);
    });
  }

  static Future<void> _checkOnceAndSchedule(WidgetRef ref, GlobalKey<NavigatorState> navigatorKey) async {
    try {
      final walletService = await ref.read(walletServiceProvider.future);
      final notifications = await walletService.getNotifications(page: 1, limit: 20);

      for (final n in notifications) {
        final payload = n.payload;
        if (payload == null) continue;

        final action = payload['action']?.toString();
        if (action == 'redirect_to_payment') {
          final jobId = payload['job_id']?.toString() ?? payload['jobId']?.toString();
          if (jobId != null) {
            if (navigatorKey.currentState != null) {
              navigatorKey.currentState!.pushNamed('/payment', arguments: {'jobId': jobId});

              try {
                await walletService.markNotificationRead(n.id);
              } catch (_) {
                // ignore marking error
              }

              break;
            }

            // If the navigator isn't ready yet, retry in a moment.
            Future.delayed(const Duration(milliseconds: 250), () {
              if (navigatorKey.currentState != null) {
                navigatorKey.currentState!.pushNamed('/payment', arguments: {'jobId': jobId});
              }
            });
            break;
          }
        }
      }
    } catch (e) {
      // ignore background errors
    }
  }

  static void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
