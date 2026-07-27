import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/index.dart';

class CityScreen extends StatefulWidget {
  const CityScreen({Key? key}) : super(key: key);

  @override
  State<CityScreen> createState() => _CityScreenState();
}

class _CityScreenState extends State<CityScreen> {
  String _selectedCity = 'Lagos';
  final _cities = ['Lagos', 'Abuja', 'Port Harcourt', 'Kano', 'Ibadan', 'Benin City'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select City'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        itemCount: _cities.length,
        itemBuilder: (context, index) {
          final city = _cities[index];
          return InkWell(
            onTap: () {
              setState(() => _selectedCity = city);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$city selected successfully')),
              );
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.border,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    city,
                    style: AppTextStyles.bodyLarge,
                  ),
                  if (_selectedCity == city)
                    const Icon(Icons.check, color: AppColors.primary),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
