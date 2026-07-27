import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RiderRegistrationReviewScreen extends ConsumerStatefulWidget {
  const RiderRegistrationReviewScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RiderRegistrationReviewScreen> createState() => _RiderRegistrationReviewScreenState();
}

class _RiderRegistrationReviewScreenState extends ConsumerState<RiderRegistrationReviewScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rider Registration Review'),
      ),
      body: const Center(
        child: Text('Review your details before submitting.'),
      ),
    );
  }
}
