import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/index.dart';

/// A lightweight app-wide poller that invalidates key providers periodically
/// so UI consumers refresh automatically.
final appPollerProvider = StateNotifierProvider<AppPoller, int>((ref) {
  final p = AppPoller(ref);
  ref.onDispose(() {
    p.dispose();
  });
  return p;
});

class AppPoller extends StateNotifier<int> {
  final Ref ref;
  Timer? _timer;

  AppPoller(this.ref) : super(0) {
    _start();
  }

  void _start() {
    // Run immediately then schedule periodic ticks
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _tick());
  }

  void _tick() {
    // increment tick counter so listeners can watch the value if needed
    state = state + 1;

    // Invalidate providers so consumers refresh their data automatically.
    try {
      ref.invalidate(walletProvider);
    } catch (_) {}

    try {
      // notificationsProvider is a family; invalidate the common page 1
      ref.invalidate(notificationsProvider(1));
    } catch (_) {}

    try {
      ref.invalidate(transactionsProvider(1));
    } catch (_) {}

    try {
      // Invalidate customer jobs (page 1) so orders and home screens refresh
      ref.invalidate(customerJobsProvider(1));
    } catch (_) {}
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
