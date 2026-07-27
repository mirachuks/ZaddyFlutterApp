import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/index.dart';
import 'jobs_screen.dart';
import 'active_jobs_screen.dart';
import 'earnings_screen.dart';
import 'profile_screen.dart';

class RiderDashboard extends ConsumerStatefulWidget {
  const RiderDashboard({Key? key}) : super(key: key);

  @override
  ConsumerState<RiderDashboard> createState() => _RiderDashboardState();
}

class _RiderDashboardState extends ConsumerState<RiderDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final activeJob = ref.watch(activeRiderJobProvider);
    final pages = [
      activeJob != null ? const RiderActiveJobsScreen() : const RiderJobsScreen(),
      const RiderActiveJobsScreen(),
      const RiderEarningsScreen(),
      const RiderProfileScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_outlined),
            activeIcon: Icon(Icons.local_shipping),
            label: 'Active',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wallet_outlined),
            activeIcon: Icon(Icons.wallet),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
