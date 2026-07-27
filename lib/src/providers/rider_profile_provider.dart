import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rider_profile_model.dart';
import 'api_provider.dart';

final riderProfileProvider = FutureProvider<RiderProfile>((ref) async {
  final riderService = await ref.watch(riderServiceProvider.future);
  return riderService.getMyRiderProfile();
});
