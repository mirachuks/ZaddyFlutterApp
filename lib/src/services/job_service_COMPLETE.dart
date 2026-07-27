import 'api_client.dart';
import '../models/index.dart';

class JobService {
  final ApiClient apiClient;

  JobService({required this.apiClient});

  /// =========================================================================
  /// TRANSFORM DATA: Flutter format → Laravel API format
  /// =========================================================================
  Map<String, dynamic> _transformJobDataForApi(Map<String, dynamic> jobData) {
    final transformed = <String, dynamic>{};
    
    // Handle user_id (Laravel expects user_id, not customerId)
    if (jobData.containsKey('user_id')) {
      transformed['user_id'] = jobData['user_id'];
    } else if (jobData.containsKey('customerId')) {
      transformed['user_id'] = jobData['customerId'];
    }
    
    // Handle title (map from itemDescription if needed)
    if (jobData.containsKey('title')) {
      transformed['title'] = jobData['title'];
    } else if (jobData.containsKey('itemDescription')) {
      transformed['title'] = jobData['itemDescription'];
    }
    
    // Handle description
    if (jobData.containsKey('description')) {
      transformed['description'] = jobData['description'];
    }
    
    // Handle pickup location (flatten if it's an object)
    if (jobData['pickupLocation'] is Map) {
      final pickupLoc = jobData['pickupLocation'] as Map<String, dynamic>;
      transformed['pickup_address'] = pickupLoc['address'] ?? '';
      if (pickupLoc['latitude'] != null) transformed['pickup_lat'] = pickupLoc['latitude'];
      if (pickupLoc['longitude'] != null) transformed['pickup_lng'] = pickupLoc['longitude'];
    } else {
      transformed['pickup_address'] = jobData['pickup_address'] ?? '';
      if (jobData['pickup_lat'] != null) transformed['pickup_lat'] = jobData['pickup_lat'];
      if (jobData['pickup_lng'] != null) transformed['pickup_lng'] = jobData['pickup_lng'];
    }
    
    // Handle dropoff location (flatten if it's an object)
    if (jobData['dropoffLocation'] is Map) {
      final dropoffLoc = jobData['dropoffLocation'] as Map<String, dynamic>;
      transformed['dropoff_address'] = dropoffLoc['address'] ?? '';
      if (dropoffLoc['latitude'] != null) transformed['dropoff_lat'] = dropoffLoc['latitude'];
      if (dropoffLoc['longitude'] != null) transformed['dropoff_lng'] = dropoffLoc['longitude'];
    } else {
      transformed['dropoff_address'] = jobData['dropoff_address'] ?? '';
      if (jobData['dropoff_lat'] != null) transformed['dropoff_lat'] = jobData['dropoff_lat'];
      if (jobData['dropoff_lng'] != null) transformed['dropoff_lng'] = jobData['dropoff_lng'];
    }
    
    // Handle price (map from estimatedFare if needed)
    if (jobData.containsKey('price')) {
      transformed['price'] = jobData['price'];
    } else if (jobData.containsKey('estimatedFare')) {
      transformed['price'] = jobData['estimatedFare'];
    }
    
    // Handle price_type
    if (jobData.containsKey('price_type')) {
      transformed['price_type'] = jobData['price_type'] ?? 'fixed';
    } else {
      transformed['price_type'] = 'fixed';
    }
    
    // Handle mobility_type_needed
    if (jobData.containsKey('mobility_type_needed')) {
      transformed['mobility_type_needed'] = jobData['mobility_type_needed'];
    }
    
    // Handle expires_at
    if (jobData.containsKey('expires_at')) {
      transformed['expires_at'] = jobData['expires_at'];
    }
    
    return transformed;
  }

  /// =========================================================================
  /// PARSE RESPONSE: Convert API response to Job object
  /// =========================================================================
  Job _parseJobFromResponse(Map<String, dynamic> jobInfo) {
    // Extract nested data if wrapped
    if (jobInfo.containsKey('data') && jobInfo['data'] is Map) {
      return Job.fromJson(jobInfo['data'] as Map<String, dynamic>);
    }
    return Job.fromJson(jobInfo);
  }

  /// =========================================================================
  /// GET CUSTOMER JOBS
  /// =========================================================================
  Future<List<Job>> getCustomerJobs({
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await apiClient.getCustomerJobs(
        userId: userId,
        page: page,
        limit: limit,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final jobsList = data['data'] ?? [];
          if (jobsList is List) {
            return jobsList
                .map((job) => Job.fromJson(job as Map<String, dynamic>))
                .toList();
          }
        }
      }
      return [];
    } catch (e) {
      print('❌ Error getting customer jobs: $e');
      rethrow;
    }
  }

  /// =========================================================================
  /// GET AVAILABLE JOBS (for riders)
  /// =========================================================================
  Future<List<Job>> getAvailableJobs({
    required double latitude,
    required double longitude,
    int radius = 10,
  }) async {
    try {
      final response = await apiClient.getRiderJobs(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final jobsList = data['data'] ?? [];
          if (jobsList is List) {
            return jobsList
                .map((job) => Job.fromJson(job as Map<String, dynamic>))
                .toList();
          }
        }
      }
      return [];
    } catch (e) {
      print('❌ Error getting available jobs: $e');
      rethrow;
    }
  }

  /// =========================================================================
  /// GET JOB DETAILS
  /// =========================================================================
  Future<Job> getJobDetails(String jobId) async {
    try {
      final response = await apiClient.getJobDetails(jobId);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return _parseJobFromResponse(data);
        }
      }
      throw Exception(
        'Failed to fetch job details: ${response.statusCode}'
      );
    } catch (e) {
      print('❌ Error getting job details: $e');
      rethrow;
    }
  }

  /// =========================================================================
  /// CREATE SINGLE JOB (Backward compatible)
  /// =========================================================================
  Future<Job> createJob(Map<String, dynamic> jobData) async {
    try {
      // Transform Flutter data to Laravel API format
      final apiData = _transformJobDataForApi(jobData);
      
      print('📤 Sending single job to API: $apiData');
      
      final response = await apiClient.createJob(apiData);
      
      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception(
          'Failed to create job: ${response.statusCode} - ${response.statusMessage}'
        );
      }

      // Parse response data
      Map<String, dynamic> jobInfo = {};
      
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        jobInfo = (data['data'] as Map<String, dynamic>?) ?? data;
      }

      print('✅ Job created successfully: ${jobInfo['id']}');
      return Job.fromJson(jobInfo);
      
    } catch (e) {
      print('❌ Error in createJob: $e');
      rethrow;
    }
  }

  /// =========================================================================
  /// CREATE JOBS FROM MULTIPLE PARCELS (NEW!)
  /// This sends an array of parcels to the API
  /// Laravel will loop through and create individual jobs
  /// =========================================================================
  Future<List<Job>> createJobsFromParcels(
    Map<String, dynamic> parcelData,
  ) async {
    try {
      final parcels = parcelData['parcels'] ?? parcelData['items'] ?? [];

      final items = (parcels is List)
          ? parcels.map((p) {
              if (p is Map<String, dynamic>) return p;
              return Map<String, dynamic>.from(p as Map);
            }).toList()
          : <dynamic>[];

      final apiPayload = {
        'user_id': parcelData['user_id'],
        if (parcelData.containsKey('price')) 'price': parcelData['price'],
        'price_type': parcelData['price_type'] ?? 'fixed',
        if (parcelData.containsKey('expires_at')) 'expires_at': parcelData['expires_at'],
        'items': items,
      }..removeWhere((k, v) => v == null);

      print('📤 Sending single job with ${items.length} item(s) to API');

      final job = await createJob(apiPayload);

      return [job];
    } catch (e) {
      print('❌ Error creating parcel jobs: $e');
      rethrow;
    }
  }

  /// =========================================================================
  /// UPDATE JOB STATUS
  /// =========================================================================
  Future<void> updateJobStatus(String jobId, String status) async {
    try {
      // Map Flutter status to Laravel status
      final laravelStatus = mapFlutterStatusToLaravel(status);
      print('🔄 Updating job $jobId status to: $laravelStatus');
      
      await apiClient.updateJobStatus(jobId, laravelStatus);
      
      print('✅ Job status updated');
    } catch (e) {
      print('❌ Error updating job status: $e');
      rethrow;
    }
  }

  /// =========================================================================
  /// CANCEL JOB
  /// =========================================================================
  Future<void> cancelJob(String jobId) async {
    try {
      print('🚫 Cancelling job $jobId');
      await apiClient.cancelJob(jobId);
      print('✅ Job cancelled');
    } catch (e) {
      print('❌ Error cancelling job: $e');
      rethrow;
    }
  }

  /// =========================================================================
  /// APPLY FOR JOB (Rider perspective)
  /// =========================================================================
  Future<void> applyForJob(
    String jobId, {
    String? bidPrice,
    String? message,
  }) async {
    try {
      print('📝 Applying for job $jobId');
      
      final applicationData = {
        'job_id': jobId,
        if (bidPrice != null) 'bid_price': bidPrice,
        if (message != null) 'msg': message,
      };
      
      await apiClient.applyForJob(jobId);
      print('✅ Applied for job successfully');
      
    } catch (e) {
      print('❌ Error applying for job: $e');
      rethrow;
    }
  }

  /// =========================================================================
  /// UPDATE DELIVERY STATE
  /// =========================================================================
  Future<void> updateDeliveryState(String jobId, String state) async {
    try {
      print('🚗 Updating delivery state to: $state');
      await apiClient.updateDeliveryState(jobId, state);
      print('✅ Delivery state updated');
    } catch (e) {
      print('❌ Error updating delivery state: $e');
      rethrow;
    }
  }

  /// =========================================================================
  /// CONFIRM DELIVERY
  /// =========================================================================
  Future<void> confirmDelivery(String jobId, String otp) async {
    try {
      print('✔️ Confirming delivery for job $jobId');
      await apiClient.confirmDelivery(jobId, otp);
      print('✅ Delivery confirmed');
    } catch (e) {
      print('❌ Error confirming delivery: $e');
      rethrow;
    }
  }

  /// =========================================================================
  /// RATE JOB/RIDER
  /// =========================================================================
  Future<void> rateJob(String jobId, double rating, String? review) async {
    try {
      print('⭐ Rating job $jobId: $rating stars');
      await apiClient.rateRider(jobId, rating, review);
      print('✅ Rating submitted');
    } catch (e) {
      print('❌ Error rating job: $e');
      rethrow;
    }
  }

  /// =========================================================================
  /// STATUS MAPPING: Flutter → Laravel
  /// =========================================================================
  String mapFlutterStatusToLaravel(String flutterStatus) {
    const statusMap = {
      'posted': 'open',
      'accepted': 'matched',
      'in_progress': 'in_progress',
      'delivered': 'completed',
      'cancelled': 'cancelled',
    };
    
    return statusMap[flutterStatus] ?? flutterStatus;
  }
}
