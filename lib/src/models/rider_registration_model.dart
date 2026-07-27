import 'package:json_annotation/json_annotation.dart';

// part 'rider_registration_model.g.dart';

/// Model for Step 1: Rider Personal Data
@JsonSerializable()
class RiderPersonalData {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String password;
  @JsonKey(name: 'password_confirmation')
  final String passwordConfirmation;
  @JsonKey(name: 'date_of_birth')
  final String dateOfBirth; // YYYY-MM-DD format
  @JsonKey(name: 'profile_image_path')
  String? profileImagePath; // Local file path for image before upload
  final dynamic
      profileImageFile; // XFile or other file object for web/native upload

  RiderPersonalData({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.password,
    required this.passwordConfirmation,
    required this.dateOfBirth,
    this.profileImagePath,
    this.profileImageFile,
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toFormData() {
    final formData = <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'mobile_number': phone, // API expects mobile_number not phone
      'password': password,
      'password_confirmation': passwordConfirmation,
      'date_of_birth': dateOfBirth,
    };

    if (profileImageFile != null) {
      formData['profile_image'] = profileImageFile;
    } else if (profileImagePath != null && profileImagePath!.isNotEmpty) {
      formData['profile_image'] = profileImagePath;
    }

    return formData;
  }

  /// Form data used for rider profile completion only.
  Map<String, dynamic> toProfileFormData() {
    final formData = <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'mobile_number': phone,
    };

    if (profileImageFile != null) {
      formData['profile_image'] = profileImageFile;
    } else if (profileImagePath != null && profileImagePath!.isNotEmpty) {
      formData['profile_image'] = profileImagePath;
    }

    return formData;
  }

  // factory RiderPersonalData.fromJson(Map<String, dynamic> json) =>
  //     _$RiderPersonalDataFromJson(json);
  // Map<String, dynamic> toJson() => _$RiderPersonalDataToJson(this);
}

/// Model for Step 2: Rider License/Documentation
@JsonSerializable()
class RiderLicenseData {
  @JsonKey(name: 'license_number')
  final String licenseNumber;
  @JsonKey(name: 'license_expiry_date')
  final String licenseExpiryDate; // YYYY-MM-DD format
  @JsonKey(name: 'license_image_path')
  String? licenseImagePath; // Local file path for image
  @JsonKey(name: 'license_back_image_path')
  String? licenseBackImagePath; // Back of license image
  final dynamic licenseImageFile;
  final dynamic licenseBackImageFile;

  RiderLicenseData({
    required this.licenseNumber,
    required this.licenseExpiryDate,
    this.licenseImagePath,
    this.licenseBackImagePath,
    this.licenseImageFile,
    this.licenseBackImageFile,
  });

  Map<String, dynamic> toFormData() {
    final formData = <String, dynamic>{
      'license_number': licenseNumber,
      'license_expiry_date': licenseExpiryDate,
    };

    if (licenseImageFile != null) {
      formData['license_image'] = licenseImageFile;
    } else if (licenseImagePath != null && licenseImagePath!.isNotEmpty) {
      formData['license_image'] = licenseImagePath;
    }

    if (licenseBackImageFile != null) {
      formData['license_back_image'] = licenseBackImageFile;
    } else if (licenseBackImagePath != null &&
        licenseBackImagePath!.isNotEmpty) {
      formData['license_back_image'] = licenseBackImagePath;
    }

    return formData;
  }

  // factory RiderLicenseData.fromJson(Map<String, dynamic> json) =>
  //     _$RiderLicenseDataFromJson(json);
  // Map<String, dynamic> toJson() => _$RiderLicenseDataToJson(this);
}

/// Model for Step 3: Rider Guarantor(s)
@JsonSerializable()
class RiderGuarantor {
  final String
      id; // Unique identifier for this guarantor (can be empty for new)
  @JsonKey(name: 'guarantor_name')
  final String name;
  @JsonKey(name: 'guarantor_phone')
  final String phone;
  @JsonKey(name: 'guarantor_email')
  final String? email;
  @JsonKey(name: 'guarantor_nin')
  final String nin; // National Identification Number
  @JsonKey(name: 'guarantor_relationship')
  final String? relationship; // e.g., Friend, Family, Employer
  @JsonKey(name: 'guarantor_state')
  final String state;
  @JsonKey(name: 'guarantor_address')
  final String address;
  @JsonKey(name: 'guarantor_nin_image_path')
  String? ninImagePath; // Local file path for NIN document
  final dynamic ninImageFile;
  @JsonKey(name: 'guarantor_id_type')
  final String idType; // e.g., NIN, Passport, Driver's License
  @JsonKey(name: 'guarantor_id_image_path')
  String? idImagePath; // Local file path for ID document
  final dynamic idImageFile;

  RiderGuarantor({
    this.id = '',
    required this.name,
    required this.phone,
    this.email,
    required this.nin,
    this.relationship,
    this.state = '',
    this.address = '',
    this.ninImagePath,
    this.ninImageFile,
    required this.idType,
    this.idImagePath,
    this.idImageFile,
  });

  Map<String, dynamic> toFormData({required int index}) {
    final formData = <String, dynamic>{
      'guarantors[$index][name]': name,
      'guarantors[$index][phone]': phone,
      if (email != null && email!.isNotEmpty)
        'guarantors[$index][email]': email,
      'guarantors[$index][nin]': nin,
      if (relationship != null && relationship!.isNotEmpty)
        'guarantors[$index][relationship]': relationship,
      if (state.isNotEmpty) 'guarantors[$index][state]': state,
      if (address.isNotEmpty) 'guarantors[$index][address]': address,
      'guarantors[$index][id_type]': idType,
    };

    if (ninImageFile != null) {
      formData['guarantors[$index][nin_image]'] = ninImageFile;
    } else if (ninImagePath != null && ninImagePath!.isNotEmpty) {
      formData['guarantors[$index][nin_image]'] = ninImagePath;
    }

    if (idImageFile != null) {
      formData['guarantors[$index][id_image]'] = idImageFile;
    } else if (idImagePath != null && idImagePath!.isNotEmpty) {
      formData['guarantors[$index][id_image]'] = idImagePath;
    }

    return formData;
  }
}

/// Model for Step 4: Rider Bike Details
@JsonSerializable()
class RiderBikeData {
  @JsonKey(name: 'bike_brand')
  final String brand;
  @JsonKey(name: 'bike_model')
  final String model;
  @JsonKey(name: 'bike_production_year')
  final String productionYear; // YYYY format
  @JsonKey(name: 'bike_plate_number')
  final String plateNumber;
  @JsonKey(name: 'bike_color')
  final String color;
  @JsonKey(name: 'bike_registration_cert_path')
  String? registrationCertPath; // Local file path for registration certificate
  @JsonKey(name: 'bike_image_path')
  String? bikeImagePath; // Local file path for bike photo
  final dynamic registrationCertFile;
  final dynamic bikeImageFile;
  @JsonKey(name: 'bike_engine_number')
  final String? engineNumber;
  @JsonKey(name: 'bike_chassis_number')
  final String? chassisNumber;

  RiderBikeData({
    required this.brand,
    required this.model,
    required this.productionYear,
    required this.plateNumber,
    this.color = '',
    this.registrationCertPath,
    this.bikeImagePath,
    this.registrationCertFile,
    this.bikeImageFile,
    this.engineNumber,
    this.chassisNumber,
  });

  Map<String, dynamic> toFormData() {
    final formData = <String, dynamic>{
      'bike_brand': brand,
      'bike_model': model,
      'bike_production_year': productionYear,
      'bike_plate_number': plateNumber,
      'bike_color': color,
      if (engineNumber != null && engineNumber!.isNotEmpty)
        'bike_engine_number': engineNumber,
      if (chassisNumber != null && chassisNumber!.isNotEmpty)
        'bike_chassis_number': chassisNumber,
    };

    if (registrationCertFile != null) {
      formData['bike_registration_cert'] = registrationCertFile;
    } else if (registrationCertPath != null &&
        registrationCertPath!.isNotEmpty) {
      formData['bike_registration_cert'] = registrationCertPath;
    }

    if (bikeImageFile != null) {
      formData['bike_image'] = bikeImageFile;
    } else if (bikeImagePath != null && bikeImagePath!.isNotEmpty) {
      formData['bike_image'] = bikeImagePath;
    }

    return formData;
  }
}

/// Complete Rider Registration State
class RiderRegistrationState {
  final RiderPersonalData? personalData;
  final RiderLicenseData? licenseData;
  final List<RiderGuarantor> guarantors; // At least 1 required
  final RiderBikeData? bikeData;
  final int currentStep; // 1-4

  RiderRegistrationState({
    this.personalData,
    this.licenseData,
    this.guarantors = const [],
    this.bikeData,
    this.currentStep = 1,
  });

  bool get isStep1Complete =>
      personalData != null &&
      personalData!.firstName.isNotEmpty &&
      personalData!.lastName.isNotEmpty &&
      personalData!.email.isNotEmpty &&
      personalData!.phone.isNotEmpty;

  bool get isStep2Complete =>
      licenseData != null &&
      licenseData!.licenseNumber.isNotEmpty &&
      licenseData!.licenseImagePath != null;

  bool get isStep3Complete =>
      guarantors.isNotEmpty &&
      guarantors.every((g) =>
          g.name.isNotEmpty &&
          g.phone.isNotEmpty &&
          g.nin.isNotEmpty &&
          g.ninImagePath != null);

  bool get isStep4Complete =>
      bikeData != null &&
      bikeData!.brand.isNotEmpty &&
      bikeData!.model.isNotEmpty &&
      bikeData!.plateNumber.isNotEmpty &&
      bikeData!.registrationCertPath != null &&
      bikeData!.bikeImagePath != null;

  RiderRegistrationState copyWith({
    RiderPersonalData? personalData,
    RiderLicenseData? licenseData,
    List<RiderGuarantor>? guarantors,
    RiderBikeData? bikeData,
    int? currentStep,
  }) {
    return RiderRegistrationState(
      personalData: personalData ?? this.personalData,
      licenseData: licenseData ?? this.licenseData,
      guarantors: guarantors ?? this.guarantors,
      bikeData: bikeData ?? this.bikeData,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}
