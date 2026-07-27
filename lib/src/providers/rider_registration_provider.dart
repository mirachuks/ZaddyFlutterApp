import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';

/// Provider to manage the complete rider registration state across all 4 steps
final riderRegistrationProvider =
    StateNotifierProvider<RiderRegistrationNotifier, RiderRegistrationState>(
  (ref) => RiderRegistrationNotifier(),
);

class RiderRegistrationNotifier extends StateNotifier<RiderRegistrationState> {
  RiderRegistrationNotifier() : super(RiderRegistrationState());

  /// Update Step 1: Personal Data
  void setPersonalData(RiderPersonalData data) {
    state = state.copyWith(
      personalData: data,
      currentStep: 1,
    );
  }

  /// Update Step 2: License Data
  void setLicenseData(RiderLicenseData data) {
    state = state.copyWith(
      licenseData: data,
      currentStep: 2,
    );
  }

  /// Update Step 3: Add or update guarantor
  void addGuarantor(RiderGuarantor guarantor) {
    final updatedGuarantors = List<RiderGuarantor>.from(state.guarantors);

    // Check if we're updating existing guarantor
    final existingIndex =
        updatedGuarantors.indexWhere((g) => g.id == guarantor.id);
    if (existingIndex >= 0) {
      updatedGuarantors[existingIndex] = guarantor;
    } else {
      updatedGuarantors.add(guarantor);
    }

    state = state.copyWith(
      guarantors: updatedGuarantors,
      currentStep: 3,
    );
  }

  /// Remove a guarantor by index
  void removeGuarantor(int index) {
    if (index >= 0 && index < state.guarantors.length) {
      final updatedGuarantors = List<RiderGuarantor>.from(state.guarantors)
        ..removeAt(index);
      state = state.copyWith(guarantors: updatedGuarantors);
    }
  }

  /// Update multiple guarantors at once
  void updateGuarantors(List<RiderGuarantor> guarantors) {
    state = state.copyWith(
      guarantors: guarantors,
      currentStep: 3,
    );
  }

  /// Update multiple guarantors at once (compatibility alias)
  void setGuarantors(List<RiderGuarantor> guarantors) {
    updateGuarantors(guarantors);
  }

  /// Update Step 4: Bike Data
  void setBikeData(RiderBikeData data) {
    state = state.copyWith(
      bikeData: data,
      currentStep: 4,
    );
  }

  /// Move to next step
  void goToNextStep() {
    if (state.currentStep < 4) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  /// Move to previous step
  void goToPreviousStep() {
    if (state.currentStep > 1) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  /// Jump to specific step
  void goToStep(int step) {
    if (step >= 1 && step <= 4) {
      state = state.copyWith(currentStep: step);
    }
  }

  /// Reset the entire registration
  void resetRegistration() {
    state = RiderRegistrationState();
  }

  /// Reset the entire registration (compatibility alias)
  void reset() {
    resetRegistration();
  }

  /// Get all form data for final submission
  Map<String, dynamic> getCompleteFormData() {
    final formData = <String, dynamic>{};

    // Add personal data needed for rider profile completion only.
    if (state.personalData != null) {
      formData.addAll(state.personalData!.toProfileFormData());
      formData['legal_name'] = state.personalData!.fullName;
    }

    // Add license data
    if (state.licenseData != null) {
      formData.addAll(state.licenseData!.toFormData());
    }

    // Add guarantors
    for (int i = 0; i < state.guarantors.length; i++) {
      final guarantor = state.guarantors[i];
      formData.addAll(guarantor.toFormData(index: i));
    }

    // Add bike data
    if (state.bikeData != null) {
      formData.addAll(state.bikeData!.toFormData());
    }

    return formData;
  }

  /// Get list of file paths for upload
  List<MapEntry<String, String>> getFilesForUpload() {
    final files = <MapEntry<String, String>>[];

    // Profile image
    if (state.personalData?.profileImagePath != null &&
        state.personalData!.profileImagePath!.isNotEmpty) {
      files.add(
          MapEntry('profile_image', state.personalData!.profileImagePath!));
    }

    // License images
    if (state.licenseData?.licenseImagePath != null &&
        state.licenseData!.licenseImagePath!.isNotEmpty) {
      files
          .add(MapEntry('license_image', state.licenseData!.licenseImagePath!));
    }
    if (state.licenseData?.licenseBackImagePath != null &&
        state.licenseData!.licenseBackImagePath!.isNotEmpty) {
      files.add(MapEntry(
          'license_back_image', state.licenseData!.licenseBackImagePath!));
    }

    // Guarantor documents
    for (int i = 0; i < state.guarantors.length; i++) {
      final guarantor = state.guarantors[i];
      if (guarantor.ninImagePath != null &&
          guarantor.ninImagePath!.isNotEmpty) {
        files.add(MapEntry('guarantors[$i][nin_image]', guarantor.ninImagePath!));
      }
      if (guarantor.idImagePath != null && guarantor.idImagePath!.isNotEmpty) {
        files.add(MapEntry('guarantors[$i][id_image]', guarantor.idImagePath!));
      }
    }

    // Bike documents
    if (state.bikeData?.registrationCertPath != null &&
        state.bikeData!.registrationCertPath!.isNotEmpty) {
      files.add(MapEntry(
          'bike_registration_cert', state.bikeData!.registrationCertPath!));
    }
    if (state.bikeData?.bikeImagePath != null &&
        state.bikeData!.bikeImagePath!.isNotEmpty) {
      files.add(MapEntry('bike_image', state.bikeData!.bikeImagePath!));
    }

    return files;
  }
}
