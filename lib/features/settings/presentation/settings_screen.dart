import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:country_state_city/country_state_city.dart' as csc;
import 'location_helper/location_helper.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _blockController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();

  List<csc.Country> _countries = [];
  List<csc.State> _states = [];
  List<csc.City> _cities = [];

  csc.Country? _selectedCountry;
  csc.State? _selectedState;

  bool _isLoadingLocation = false;
  bool _isSaving = false;
  String _vulnerablePopulation = 'Select';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    final countries = await csc.getAllCountries();
    if (mounted) setState(() => _countries = countries);
  }

  Future<void> _loadStates(String countryCode) async {
    final states = await csc.getStatesOfCountry(countryCode);
    if (mounted) setState(() => _states = states);
  }

  Future<void> _loadCities(String countryCode, String stateCode) async {
    final cities = await csc.getStateCities(countryCode, stateCode);
    if (mounted) setState(() => _cities = cities);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _tokenController.text = prefs.getString('auth_token') ?? '';
      _countryController.text = prefs.getString('country') ?? '';
      _stateController.text = prefs.getString('state') ?? '';
      _cityController.text = prefs.getString('city') ?? '';
      _pincodeController.text = prefs.getString('pincode') ?? '';
      _blockController.text = prefs.getString('block') ?? '';
      _villageController.text = prefs.getString('village') ?? '';
      _vulnerablePopulation = prefs.getString('vulnerable_population') ?? 'Select';
    });
    
    // Attempt to prepopulate lists if country/state are already typed in properly
    if (_countryController.text.isNotEmpty && _countries.isNotEmpty) {
      try {
        _selectedCountry = _countries.firstWhere((c) => c.name.toLowerCase() == _countryController.text.toLowerCase());
        if (_selectedCountry != null) {
          await _loadStates(_selectedCountry!.isoCode);
          if (_stateController.text.isNotEmpty) {
            _selectedState = _states.firstWhere((s) => s.name.toLowerCase() == _stateController.text.toLowerCase());
            if (_selectedState != null) {
              await _loadCities(_selectedState!.countryCode, _selectedState!.isoCode);
            }
          }
        }
      } catch (e) {
        // ignore
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', _tokenController.text.trim());
    await prefs.setString('country', _countryController.text.trim());
    await prefs.setString('state', _stateController.text.trim());
    await prefs.setString('city', _cityController.text.trim());
    await prefs.setString('pincode', _pincodeController.text.trim());
    await prefs.setString('block', _blockController.text.trim());
    await prefs.setString('village', _villageController.text.trim());
    await prefs.setString('vulnerable_population', _vulnerablePopulation);
    
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully!')),
      );
    }
  }

  Future<void> _clearSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Settings'),
        content: const Text('Are you sure you want to clear all settings? This will remove all saved preferences.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentOrange),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear all shared preferences

      setState(() {
        _tokenController.clear();
        _countryController.clear();
        _stateController.clear();
        _cityController.clear();
        _pincodeController.clear();
        _blockController.clear();
        _villageController.clear();
        _vulnerablePopulation = 'Select';
        _selectedCountry = null;
        _selectedState = null;
        _states.clear();
        _cities.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings cleared successfully.')),
        );
      }
    }
  }

  Future<void> _detectLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied, we cannot request permissions.');
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      List<Map<String, String?>> placemarks = await getPlacemarks(position);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _countryController.text = place['country'] ?? '';
          _stateController.text = place['administrativeArea'] ?? '';
          _cityController.text = place['locality'] ?? '';
          _pincodeController.text = place['postalCode'] ?? '';
        });
        
        // Auto trigger list loads for dropdowns based on new location
        if (_countries.isNotEmpty && _countryController.text.isNotEmpty) {
          try {
            _selectedCountry = _countries.firstWhere((c) => c.name.toLowerCase() == _countryController.text.toLowerCase());
            if (_selectedCountry != null) {
              await _loadStates(_selectedCountry!.isoCode);
              if (_stateController.text.isNotEmpty) {
                _selectedState = _states.firstWhere((s) => s.name.toLowerCase() == _stateController.text.toLowerCase());
                if (_selectedState != null) {
                  await _loadCities(_selectedState!.countryCode, _selectedState!.isoCode);
                }
              }
            }
          } catch(e) {}
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error detecting location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'API Configuration',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            SizedBox(height: 12.h),
            _buildTextField(
              controller: _tokenController,
              label: 'Auth Token (paste here if token expired)',
              icon: Icons.key,
            ),
            SizedBox(height: 24.h),

            Text(
              'Location Settings',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoadingLocation ? null : _detectLocation,
                icon: _isLoadingLocation 
                    ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: CircularProgressIndicator(
                          color: AppTheme.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(Icons.my_location, size: 20.sp),
                label: Text(
                  _isLoadingLocation ? 'Detecting...' : 'Auto Detect Location',
                  style: TextStyle(fontSize: 16.sp),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            
            // Row 1: Country and State
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildAutocomplete<csc.Country>(
                    controller: _countryController,
                    label: 'Country',
                    icon: Icons.flag,
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) return _countries;
                      return _countries.where((c) => c.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                    },
                    displayStringForOption: (c) => c.name,
                    onSelected: (csc.Country selection) {
                      _selectedCountry = selection;
                      _countryController.text = selection.name;
                      _stateController.clear();
                      _cityController.clear();
                      _selectedState = null;
                      _states.clear();
                      _cities.clear();
                      _loadStates(selection.isoCode);
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildAutocomplete<csc.State>(
                    controller: _stateController,
                    label: 'State',
                    icon: Icons.map,
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) return _states;
                      return _states.where((s) => s.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                    },
                    displayStringForOption: (s) => s.name,
                    onSelected: (csc.State selection) {
                      if (_selectedCountry == null) return;
                      _selectedState = selection;
                      _stateController.text = selection.name;
                      _cityController.clear();
                      _cities.clear();
                      _loadCities(selection.countryCode, selection.isoCode);
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            
            // Row 2: City and Pincode
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildAutocomplete<csc.City>(
                    controller: _cityController,
                    label: 'City',
                    icon: Icons.location_city,
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) return _cities;
                      return _cities.where((c) => c.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                    },
                    displayStringForOption: (c) => c.name,
                    onSelected: (csc.City selection) {
                      _cityController.text = selection.name;
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildTextField(
                    controller: _pincodeController,
                    label: 'Pincode',
                    icon: Icons.pin_drop,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Row 3: Block and Village
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _blockController,
                    label: 'Block',
                    icon: Icons.business,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildTextField(
                    controller: _villageController,
                    label: 'Village',
                    icon: Icons.holiday_village,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Field Settings Section
            Text(
              'Field Settings',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
              ),
            ),
            SizedBox(height: 16.h),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Default Key Vulnerable Population',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppTheme.textLight.withValues(alpha: 0.2)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _vulnerablePopulation,
                      isExpanded: true,
                      icon: Icon(Icons.keyboard_arrow_down, color: AppTheme.primaryBlue),
                      items: ['Select', 'Urban', 'Rural', 'Migratory', 'Homeless']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppTheme.textDark,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _vulnerablePopulation = newValue!;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 32.h),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: _clearSettings,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentOrange,
                      side: const BorderSide(color: AppTheme.accentOrange),
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'Clear',
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: _isSaving
                        ? SizedBox(
                            height: 20.h,
                            width: 20.h,
                            child: const CircularProgressIndicator(
                              color: AppTheme.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 12.sp, color: AppTheme.textDark),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        labelText: label,
        labelStyle: TextStyle(fontSize: 12.sp),
        prefixIcon: Icon(icon, color: AppTheme.primaryBlue, size: 18.sp),
        filled: true,
        fillColor: AppTheme.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppTheme.textLight.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppTheme.textLight.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
      ),
    );
  }

  Widget _buildAutocomplete<T extends Object>({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Iterable<T> Function(TextEditingValue) optionsBuilder,
    required String Function(T) displayStringForOption,
    required void Function(T) onSelected,
  }) {
    return Autocomplete<T>(
      optionsBuilder: optionsBuilder,
      displayStringForOption: displayStringForOption,
      onSelected: onSelected,
      fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
        // Keep the main controller in sync, or just use the field one and listen
        if (fieldTextEditingController.text != controller.text) {
          fieldTextEditingController.text = controller.text;
        }
        fieldTextEditingController.addListener(() {
          controller.text = fieldTextEditingController.text;
        });

        return TextField(
          controller: fieldTextEditingController,
          focusNode: fieldFocusNode,
          style: TextStyle(fontSize: 12.sp, color: AppTheme.textDark),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            labelText: label,
            labelStyle: TextStyle(fontSize: 12.sp),
            prefixIcon: Icon(icon, color: AppTheme.primaryBlue, size: 18.sp),
            filled: true,
            fillColor: AppTheme.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppTheme.textLight.withValues(alpha: 0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppTheme.textLight.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
            ),
          ),
        );
      },
      optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<T> onSelected, Iterable<T> options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: SizedBox(
              height: 200.0,
              width: MediaQuery.of(context).size.width / 2 - 24.w,
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final T option = options.elementAt(index);
                  return GestureDetector(
                    onTap: () {
                      onSelected(option);
                    },
                    child: ListTile(
                      title: Text(displayStringForOption(option), style: TextStyle(fontSize: 12.sp)),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
