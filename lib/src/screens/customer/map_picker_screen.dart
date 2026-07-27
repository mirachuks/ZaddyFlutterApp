import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../utils/platform_support.dart';
import '../../widgets/index.dart';

class MapPickerScreen extends StatefulWidget {
  final String title;
  final LocationCoordinates initialLocation;
  final Function(LocationCoordinates, String) onLocationSelected;

  const MapPickerScreen({
    Key? key,
    required this.title,
    required this.initialLocation,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late LocationCoordinates _selectedLocation;
  final TextEditingController _addressController = TextEditingController();
  final List<String> _addressSuggestions = [
    'Victoria Island, Lagos',
    'Lekki Phase 1, Lagos',
    'Ikoyi, Lagos',
    'Ajah, Lagos',
    '1004 Estate, Lagos',
    'Surulere, Lagos',
    'Yaba, Lagos',
    'Ikeja, Lagos',
    'Shomolu, Lagos',
    'Mushin, Lagos',
  ];

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    _addressController.text = 'Victoria Island, Lagos';
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _confirmLocation() {
    final address = _addressController.text.isEmpty ? 'Selected Location' : _addressController.text;
    widget.onLocationSelected(_selectedLocation, address);
    Navigator.pop(context, {
      'location': _selectedLocation,
      'address': address,
    });
  }

  void _selectSuggestion(String suggestion) {
    setState(() {
      _addressController.text = suggestion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Map area placeholder
          Expanded(
            flex: 2,
            child: Container(
              color: AppColors.border,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map,
                      size: 80,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Location Selector',
                      style: AppTextStyles.headingMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Choose from suggestions below\nLatitude: ${_selectedLocation.latitude.toStringAsFixed(6)}\nLongitude: ${_selectedLocation.longitude.toStringAsFixed(6)}',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Address search and suggestions
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Address input
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: CustomTextField(
                      label: 'Address',
                      hint: 'Search or select address',
                      controller: _addressController,
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),

                  // Address suggestions
                  Expanded(
                    child: ListView.builder(
                      itemCount: _addressSuggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _addressSuggestions[index];
                        final isSelected = _addressController.text == suggestion;
                        return ListTile(
                          leading: Icon(
                            Icons.location_on_outlined,
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          ),
                          title: Text(
                            suggestion,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          onTap: () => _selectSuggestion(suggestion),
                          selected: isSelected,
                          selectedTileColor: AppColors.primary.withOpacity(0.05),
                        );
                      },
                    ),
                  ),

                  // Confirm button
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _confirmLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppBorderRadius.md),
                          ),
                        ),
                        child: const Text(
                          'Confirm Location',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
