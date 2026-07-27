import 'api_client.dart';
import '../models/index.dart';

class JobService {
  final ApiClient apiClient;

  JobService({required this.apiClient});

  Future<List<Job>> getCustomerJobs(
      {required String userId, int page = 1, int limit = 20}) async {
    try {
      final response = await apiClient.getCustomerJobs(
          userId: userId, page: page, limit: limit);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return _parseJobListFromResponse(response.data);
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Job>> getAvailableJobs({
    required double latitude,
    required double longitude,
    int radius = 10,
  }) async {
    try {
      final response = await apiClient.getRiderJobs(
          latitude: latitude, longitude: longitude, radius: radius);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jobs = _parseJobListFromResponse(response.data);
        final excludedJobIds = await _fetchRiderActiveApplicationJobIds();
        return jobs
            .where((job) =>
                job.status.toLowerCase() == 'posted' &&
                !excludedJobIds.contains(job.id))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Set<String>> _fetchRiderActiveApplicationJobIds() async {
    final activeStatuses = {'accepted', 'matched', 'in_progress'};
    final jobIds = <String>{};

    for (final status in activeStatuses) {
      try {
        final applications = await getRiderApplications(status: status);
        for (final application in applications) {
          if (application.jobId.isNotEmpty) {
            jobIds.add(application.jobId);
          }
        }
      } catch (_) {
        continue;
      }
    }

    return jobIds;
  }

  List<Job> _parseJobListFromResponse(dynamic data) {
    List<dynamic> jobsList = [];

    if (data is List) {
      jobsList = data;
    } else if (data is Map<String, dynamic>) {
      final dynamic maybeData = data['data'];
      if (maybeData is List) {
        jobsList = maybeData;
      } else if (maybeData is Map<String, dynamic> &&
          maybeData['data'] is List) {
        jobsList = maybeData['data'] as List<dynamic>;
      } else if (data['jobs'] is List) {
        jobsList = data['jobs'] as List<dynamic>;
      }
    }

    return jobsList
        .where((job) => job is Map<String, dynamic> || job is Map)
        .map((job) => Job.fromJson(Map<String, dynamic>.from(job as Map)))
        .toList();
  }

  Future<Map<String, dynamic>> _extractResponsePayload(
      dynamic responseData) async {
    if (responseData is Map<String, dynamic>) {
      if (responseData.containsKey('data') &&
          responseData['data'] is Map<String, dynamic>) {
        return responseData['data'] as Map<String, dynamic>;
      }
      return responseData;
    }
    throw Exception('Unexpected API response format for job payload');
  }

  Future<Job> getJobDetails(String jobId) async {
    try {
      final response = await apiClient.getJobDetails(jobId);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final payload = await _extractResponsePayload(response.data);
        return Job.fromJson(payload);
      }
      throw Exception('Failed to fetch job details: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  Future<Job> createJob(Map<String, dynamic> jobData) async {
    try {
      final response = await apiClient.createJob(jobData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        // Extract job_id from response (API returns it at root level)
        final jobId = (data['job_id'] ?? data['id'])?.toString() ?? '';
        final customerId =
            (jobData['user_id'] ?? jobData['customer_id'] ?? '1').toString();
        final pickupAddress = jobData['pickup_address']?.toString() ?? '';
        final dropoffAddress = jobData['dropoff_address']?.toString() ?? '';
        final itemDescription = jobData['title']?.toString() ??
            jobData['item_description']?.toString() ??
            jobData['description']?.toString() ??
            '';
        final pickupLat = jobData['pickup_lat'] != null
            ? double.tryParse(jobData['pickup_lat'].toString())
            : null;
        final pickupLng = jobData['pickup_lng'] != null
            ? double.tryParse(jobData['pickup_lng'].toString())
            : null;
        final dropoffLat = jobData['dropoff_lat'] != null
            ? double.tryParse(jobData['dropoff_lat'].toString())
            : null;
        final dropoffLng = jobData['dropoff_lng'] != null
            ? double.tryParse(jobData['dropoff_lng'].toString())
            : null;
        final estimatedFare = jobData['price'] != null
            ? double.tryParse(jobData['price'].toString()) ?? 0.0
            : jobData['estimated_fare'] != null
                ? double.tryParse(jobData['estimated_fare'].toString()) ?? 0.0
                : 0.0;
        final platformCharge = jobData['platform_charge'] != null
            ? double.tryParse(jobData['platform_charge'].toString())
            : null;
        final totalPrice = jobData['total_price'] != null
            ? double.tryParse(jobData['total_price'].toString())
            : null;
        final urgency = jobData['urgency']?.toString() ?? 'normal';

        return Job(
          id: jobId,
          customerId: customerId,
          pickupLocation: Location(
            latitude: pickupLat,
            longitude: pickupLng,
            address: pickupAddress,
          ),
          dropoffLocation: Location(
            latitude: dropoffLat,
            longitude: dropoffLng,
            address: dropoffAddress,
          ),
          itemDescription: itemDescription,
          urgency: urgency,
          estimatedFare: estimatedFare,
          platformCharge: platformCharge,
          totalPrice: totalPrice,
          paymentStatus: 'pending',
          status: 'open',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      throw Exception('Failed to create job: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  /// =========================================================================
  /// CREATE JOB WITH MULTIPLE ITEMS
  /// Build a single job payload containing an `items` array and post to API.
  /// Returns a list containing the created Job (keeps compatibility with callers).
  /// =========================================================================
  Future<List<Job>> createJobsFromParcels(
      Map<String, dynamic> parcelData) async {
    try {
      final rawParcels = parcelData['parcels'] ?? parcelData['items'] ?? [];

      final List<Map<String, dynamic>> items = (rawParcels is List)
          ? rawParcels.map((p) {
              if (p is Map<String, dynamic>) return p;
              return Map<String, dynamic>.from(p as Map);
            }).toList()
          : <Map<String, dynamic>>[];

      double _sumPrices(List<Map<String, dynamic>> itemsList) {
        return itemsList.fold<double>(0.0, (sum, item) {
          final price = item['price'];
          if (price == null) return sum;
          if (price is num) return sum + price.toDouble();
          return sum + (double.tryParse(price.toString()) ?? 0.0);
        });
      }

      final itemDescriptions = items
          .map((item) =>
              item['title']?.toString() ??
              item['item_description']?.toString() ??
              '')
          .where((desc) => desc.isNotEmpty)
          .toList();
      final itemDescription = itemDescriptions.join(', ');
      final platformCharge = parcelData['platform_charge'] != null
          ? double.tryParse(parcelData['platform_charge'].toString()) ?? 0.0
          : 0.0;
      final totalPrice = parcelData['total_price'] != null
          ? double.tryParse(parcelData['total_price'].toString()) ?? 0.0
          : _sumPrices(items) + platformCharge;
      final firstItem = items.isNotEmpty ? items.first : <String, dynamic>{};
      final lastItem = items.isNotEmpty ? items.last : <String, dynamic>{};

      final apiPayload = {
        'user_id': parcelData['user_id'],
        if (parcelData.containsKey('price')) 'price': parcelData['price'],
        if (parcelData.containsKey('platform_charge'))
          'platform_charge': parcelData['platform_charge'],
        if (parcelData.containsKey('total_price'))
          'total_price': parcelData['total_price'],
        'price_type': parcelData['price_type'] ?? 'fixed',
        if (parcelData.containsKey('expires_at'))
          'expires_at': parcelData['expires_at'],
        'item_description': itemDescription,
        'pickup_address': firstItem['pickup_address'],
        'pickup_lat': firstItem['pickup_lat'],
        'pickup_lng': firstItem['pickup_lng'],
        'dropoff_address': lastItem['dropoff_address'],
        'dropoff_lat': lastItem['dropoff_lat'],
        'dropoff_lng': lastItem['dropoff_lng'],
        'items': items,
      }..removeWhere((k, v) => v == null);

      print('📤 Sending single job with ${items.length} item(s) to API');

      final job = await createJob(apiPayload);

      return [job];
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateJobStatus(String jobId, String status) async {
    try {
      await apiClient.updateJobStatus(jobId, status);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelJob(String jobId) async {
    try {
      await apiClient.cancelJob(jobId);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<JobApplication>> getRiderApplications({String? status}) async {
    try {
      final response = await apiClient.getRiderApplications(status: status);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        List<dynamic> appsList = [];

        if (data is Map<String, dynamic>) {
          final maybeData = data['data'];
          if (maybeData is List) {
            appsList = maybeData;
          } else if (maybeData is Map<String, dynamic> &&
              maybeData['data'] is List) {
            appsList = maybeData['data'] as List<dynamic>;
          }
        } else if (data is List) {
          appsList = data;
        }

        return appsList
            .where((app) => app is Map<String, dynamic> || app is Map)
            .map((app) =>
                JobApplication.fromJson(Map<String, dynamic>.from(app as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<JobApplication?> getActiveRiderApplication({String? status}) async {
    try {
      final response = await apiClient.getRiderActiveApplication(status: status);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        Map<String, dynamic>? appMap;
        if (data is Map<String, dynamic>) {
          if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
            appMap = Map<String, dynamic>.from(data['data'] as Map);
          } else {
            appMap = Map<String, dynamic>.from(data);
          }
        }

        if (appMap == null || appMap.isEmpty) return null;

        return JobApplication.fromJson(appMap);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<JobApplication>> getJobApplicationsForJob(String jobId) async {
    try {
      final response = await apiClient.getJobApplications(jobId);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        List<dynamic> appsList = [];

        if (data is Map<String, dynamic>) {
          final maybeData = data['data'];
          if (maybeData is List) {
            appsList = maybeData;
          } else if (maybeData is Map<String, dynamic> &&
              maybeData['data'] is List) {
            appsList = maybeData['data'] as List<dynamic>;
          }
        } else if (data is List) {
          appsList = data;
        }

        return appsList
            .where((app) => app is Map<String, dynamic> || app is Map)
            .map((app) =>
                JobApplication.fromJson(Map<String, dynamic>.from(app as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateJobApplicationStatus(
      String applicationId, String status) async {
    try {
      await apiClient.updateJobApplicationStatus(applicationId, status);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> acceptJobApplication(String applicationId) async {
    try {
      await updateJobApplicationStatus(applicationId, 'accepted');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> applyForJob(String jobId,
      {String? message, String? bidPrice}) async {
    try {
      await apiClient.applyForJob(jobId, data: {
        if (message != null && message.isNotEmpty) 'msg': message,
        if (bidPrice != null && bidPrice.isNotEmpty) 'bid_price': bidPrice,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<Job> acceptJob(String jobId) async {
    try {
      final response = await apiClient.acceptJob(jobId);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final payload = await _extractResponsePayload(response.data);
        return Job.fromJson(payload);
      }
      throw Exception('Failed to accept job: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateDeliveryState(String jobId, String state) async {
    try {
      await apiClient.updateDeliveryState(jobId, state);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> confirmDelivery(String jobId, String otp) async {
    try {
      await apiClient.confirmDelivery(jobId, otp);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> reportJob(String jobId, String message) async {
    try {
      await apiClient
          .post('/reports', data: {'job_id': jobId, 'message': message});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> rateJob(String jobId, double rating, String? review) async {
    try {
      await apiClient.rateRider(jobId, rating, review);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> autoConfirmJob(String jobId) async {
    try {
      await apiClient.autoConfirmJob(jobId);
    } catch (e) {
      rethrow;
    }
  }
}
