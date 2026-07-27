import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/index.dart';
import '../services/index.dart';
import 'api_provider.dart';
import 'auth_provider.dart';

final jobServiceProvider = Provider<JobService>((ref) {
  final apiClient = ref.watch(apiClientProvider).maybeWhen(
        data: (value) => value,
        orElse: () => ApiClient(),
      );
  return JobService(apiClient: apiClient);
});

// Customer Job Providers
final customerJobsProvider =
    FutureProvider.family<List<Job>, int>((ref, page) async {
  final jobService = ref.watch(jobServiceProvider);
  final currentUser = ref.watch(currentUserProvider);

  if (currentUser == null) {
    return [];
  }

  final jobs = await jobService.getCustomerJobs(
    userId: currentUser.id,
    page: page,
    limit: 100,
  );

  return jobs;
});

final availableJobsProvider =
    FutureProvider.family<List<Job>, Map<String, double>>((ref, coords) async {
  final jobService = ref.watch(jobServiceProvider);
  return jobService.getAvailableJobs(
    latitude: coords['lat']!,
    longitude: coords['lng']!,
  );
});

final availableJobsStreamProvider = StreamProvider.autoDispose
    .family<List<Job>, Map<String, double>>((ref, coords) async* {
  final jobService = ref.watch(jobServiceProvider);
  while (true) {
    final jobs = await jobService.getAvailableJobs(
      latitude: coords['lat']!,
      longitude: coords['lng']!,
    );
    yield jobs;
    await Future.delayed(const Duration(seconds: 20));
  }
});

final jobDetailsProvider =
    FutureProvider.family<Job, String>((ref, jobId) async {
  final jobService = ref.watch(jobServiceProvider);
  return jobService.getJobDetails(jobId);
});

final riderApplicationsProvider =
    FutureProvider<List<JobApplication>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return [];
  }

  final jobService = ref.watch(jobServiceProvider);
  return jobService.getRiderApplications();
});

final riderRecentActivitiesProvider = StreamProvider.autoDispose
    .family<List<JobApplication>, int>((ref, pollIntervalSeconds) async* {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    yield [];
    return;
  }

  final jobService = ref.watch(jobServiceProvider);

  while (true) {
    try {
      final applications = await jobService.getRiderApplications();
      applications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      yield applications;
    } catch (_) {
      yield [];
    }

    await Future.delayed(Duration(seconds: pollIntervalSeconds));
  }
});

// Stream provider for monitoring customer job status changes (polls every 5 seconds)
final customerJobStatusStreamProvider =
    StreamProvider.autoDispose.family<Job?, String>((ref, jobId) async* {
  final jobService = ref.watch(jobServiceProvider);
  Job? lastJob;

  while (true) {
    try {
      final job = await jobService.getJobDetails(jobId);
      if (lastJob?.status != job.status) {
        // Status changed - emit the new job
        yield job;
        lastJob = job;
      } else {
        yield job;
        lastJob = job;
      }
    } catch (e) {
      print('Error monitoring job status: $e');
      yield lastJob;
    }

    // Poll every 5 seconds
    await Future.delayed(const Duration(seconds: 5));
  }
});

// State Notifier for Job Creation
final jobCreationProvider =
    StateNotifierProvider<JobCreationNotifier, JobCreationState>(
  (ref) => JobCreationNotifier(ref.watch(jobServiceProvider)),
);

// State Notifier for Active Job (Rider)
final activeRiderJobProvider =
    StateNotifierProvider<ActiveJobNotifier, Job?>((ref) {
  return ActiveJobNotifier(ref);
});

class JobCreationState {
  final bool isLoading;
  final String? error;
  final Job? createdJob;

  JobCreationState({
    this.isLoading = false,
    this.error,
    this.createdJob,
  });

  JobCreationState copyWith({
    bool? isLoading,
    String? error,
    Job? createdJob,
  }) {
    return JobCreationState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      createdJob: createdJob ?? this.createdJob,
    );
  }
}

class JobCreationNotifier extends StateNotifier<JobCreationState> {
  final JobService jobService;

  JobCreationNotifier(this.jobService) : super(JobCreationState());

  Future<void> createJob(Map<String, dynamic> jobData) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final job = await jobService.createJob(jobData);
      state = state.copyWith(
        isLoading: false,
        createdJob: job,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  void reset() {
    state = JobCreationState();
  }
}

class ActiveJobNotifier extends StateNotifier<Job?> {
  final Ref ref;
  final JobService jobService;
  int? _acceptedAtMs;

  ActiveJobNotifier(this.ref)
      : jobService = ref.watch(jobServiceProvider),
        super(null) {
    _initialize();
    ref.listen<User?>(currentUserProvider, (previous, next) {
      if (next == null) {
        state = null;
        _acceptedAtMs = null;
        return;
      }

      if (next.userType == UserType.rider && state == null) {
        _initialize();
      }
    });
  }

  int? get acceptedAtMs => _acceptedAtMs;

  Future<void> _initialize() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || currentUser.userType != UserType.rider) {
      return;
    }

    // Try authoritative server-side lookup first (new endpoint)
    try {
      final activeApp = await jobService.getActiveRiderApplication();
      if (activeApp != null && activeApp.jobId.isNotEmpty) {
        try {
          final recoveredJob = await jobService.getJobDetails(activeApp.jobId);
          state = recoveredJob;
          _acceptedAtMs = activeApp.createdAt.millisecondsSinceEpoch;
          await _persistActiveJob(recoveredJob, _acceptedAtMs);
          return;
        } catch (_) {}
      }
    } catch (_) {}

    final prefs = await ref.read(sharedPreferencesProvider.future);
    final storedRiderId = prefs.getString('active_rider_job_user_id');
    if (storedRiderId != null && storedRiderId != currentUser.id) {
      await _clearPersistedActiveJob(prefs: prefs);
      return;
    }

    final rawJobJson = prefs.getString('active_rider_job');
    final savedAcceptedAt = prefs.getInt('active_rider_job_accepted_at');

    if (rawJobJson != null) {
      try {
        final savedJob =
            Job.fromJson(jsonDecode(rawJobJson) as Map<String, dynamic>);
        state = savedJob;
        _acceptedAtMs = savedAcceptedAt;
        if (state != null) {
          try {
            final refreshedJob = await jobService.getJobDetails(state!.id);
            state = refreshedJob;
            await _persistActiveJob(refreshedJob, _acceptedAtMs);
          } catch (_) {}
        }
        return;
      } catch (_) {
        await _clearPersistedActiveJob(prefs: prefs);
      }
    }

    _acceptedAtMs = savedAcceptedAt;
    await recoverActiveJobFromApplications();
  }

  Future<void> acceptJob(String jobId) async {
    try {
      await jobService.acceptJob(jobId);
      final refreshedJob = await jobService.getJobDetails(jobId);
      state = refreshedJob;
      _acceptedAtMs = DateTime.now().millisecondsSinceEpoch;
      await _persistActiveJob(refreshedJob, _acceptedAtMs!);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> recoverActiveJobFromApplications() async {
    try {
      final applications = await _fetchActiveRiderApplications();
      // Ensure we prefer the most recent application first (descending by createdAt)
      applications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      for (final application in applications) {
        if (application.jobId.isEmpty) continue;
        try {
          final recoveredJob = await jobService.getJobDetails(application.jobId);
          // If the job is still active OR the application/job pair isn't fully terminal,
          // treat this as the rider's active job and persist it.
          if (_isActiveJobStatus(recoveredJob.status) ||
              !_isTerminalJobWithTerminalApplication(recoveredJob, application)) {
            state = recoveredJob;
            // Use the application createdAt as the accepted timestamp when available
            _acceptedAtMs = application.createdAt.millisecondsSinceEpoch;
            await _persistActiveJob(recoveredJob, _acceptedAtMs);
            return;
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<List<JobApplication>> _fetchActiveRiderApplications() async {
    try {
      final applications = await jobService.getRiderApplications();
      return applications.where(_isActiveApplication).toList();
    } catch (_) {
      return <JobApplication>[];
    }
  }

  bool _isActiveApplication(JobApplication application) {
    final status = (application.status ?? '').toLowerCase();
    return status == 'accepted' ||
        status == 'matched' ||
        status == 'in_progress' ||
        status == 'picked_up';
  }

  Future<void> refreshActiveJob() async {
    if (state == null) {
      await recoverActiveJobFromApplications();
      return;
    }
    try {
      final refreshedJob = await jobService.getJobDetails(state!.id);
      state = refreshedJob;
      final shouldClear = await _shouldClearActiveJob(refreshedJob);
      if (shouldClear) {
        await clear();
      } else {
        await _persistActiveJob(refreshedJob, _acceptedAtMs);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateDeliveryState(String state) async {
    if (this.state == null) return;
    try {
      await jobService.updateDeliveryState(this.state!.id, state);
      final job = await jobService.getJobDetails(this.state!.id);
      this.state = job;
      final shouldClear = await _shouldClearActiveJob(job);
      if (shouldClear) {
        await clear();
      } else {
        await _persistActiveJob(job, _acceptedAtMs);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> confirmDelivery(String otp) async {
    if (state == null) return;
    try {
      await jobService.confirmDelivery(state!.id, otp);
      final job = await jobService.getJobDetails(state!.id);
      this.state = job;
      final shouldClear = await _shouldClearActiveJob(job);
      if (shouldClear) {
        await clear();
      } else {
        await _persistActiveJob(job, _acceptedAtMs);
      }
    } catch (e) {
      rethrow;
    }
  }

  bool _isActiveJobStatus(String? status) {
    final normalizedStatus = status?.toLowerCase() ?? '';
    return !['cancelled', 'completed', 'delivered'].contains(normalizedStatus);
  }

  bool _isTerminalJobStatus(String? status) {
    final normalizedStatus = status?.toLowerCase() ?? '';
    return ['cancelled', 'completed', 'delivered'].contains(normalizedStatus);
  }

  bool _isTerminalApplicationStatus(String? status) {
    final normalizedStatus = status?.toLowerCase() ?? '';
    return ['cancelled', 'rejected', 'withdrawn', 'completed', 'delivered']
        .contains(normalizedStatus);
  }

  Future<bool> _shouldClearActiveJob(Job job) async {
    if (!_isTerminalJobStatus(job.status)) {
      return false;
    }

    try {
      final applications = await jobService.getJobApplicationsForJob(job.id);
      if (applications.isEmpty) {
        return true;
      }
      return applications.every((app) => _isTerminalApplicationStatus(app.status));
    } catch (_) {
      return false;
    }
  }

  bool _isTerminalJobWithTerminalApplication(
      Job job, JobApplication application) {
    return _isTerminalJobStatus(job.status) &&
        _isTerminalApplicationStatus(application.status);
  }

  Future<void> _persistActiveJob(Job job, int? acceptedAtMs) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final currentUser = ref.read(currentUserProvider);
    final riderId = currentUser?.id ?? job.riderId ?? job.customerId;

    await prefs.setString('active_rider_job', jsonEncode(job.toJson()));
    await prefs.setString('active_rider_job_user_id', riderId);
    if (acceptedAtMs != null) {
      await prefs.setInt('active_rider_job_accepted_at', acceptedAtMs);
    }
  }

  Future<void> _clearPersistedActiveJob({SharedPreferences? prefs}) async {
    final SharedPreferences sharedPrefs =
        prefs ?? await ref.read(sharedPreferencesProvider.future);
    await sharedPrefs.remove('active_rider_job');
    await sharedPrefs.remove('active_rider_job_user_id');
    await sharedPrefs.remove('active_rider_job_accepted_at');
  }

  Future<void> clear() async {
    state = null;
    _acceptedAtMs = null;
    await _clearPersistedActiveJob();
  }
}
