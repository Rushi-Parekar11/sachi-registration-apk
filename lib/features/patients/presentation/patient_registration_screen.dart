import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/database/local_db_helper.dart';
import '../data/patients_provider.dart';
import '../../dashboard/data/dashboard_provider.dart';
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:country_state_city/country_state_city.dart' as csc;
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/patient.dart';

class ResponsiveGridRow extends StatelessWidget {
  final List<Widget> children;
  const ResponsiveGridRow({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 2;
        if (constraints.maxWidth >= 850) {
          columns = 4;
        } else if (constraints.maxWidth >= 600) {
          columns = 3;
        }

        double spacing = 8.w;
        // Floor the itemWidth to avoid wrapping issues due to floating point precision
        double itemWidth = ((constraints.maxWidth - (spacing * (columns - 1))) / columns).floorToDouble();

        return Wrap(
          spacing: spacing,
          runSpacing: 0,
          children: children.map((child) => SizedBox(width: itemWidth, child: child)).toList(),
        );
      },
    );
  }
}

class PatientRegistrationScreen extends ConsumerStatefulWidget {
  final Patient? patient;
  const PatientRegistrationScreen({super.key, this.patient});

  @override
  ConsumerState<PatientRegistrationScreen> createState() =>
      _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState
    extends ConsumerState<PatientRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Form Fields - Personal
  String _patientName = '';
  String _guardianName = '';
  String _maritalStatus = 'Select';
  String _dob = '';
  String _phone = '';
  String _aadhaar = '';
  String _abha = '';
  String _country = '';
  String _state = '';
  String _city = '';
  String _block = '';
  String _village = '';
  String _pincode = '';
  String _vulnerablePopulation = '';
  String _occupation = '';

  // Form Fields - Reproductive
  List<String> _screeningHistory = [];
  bool? _hpvVaccinated;
  String _otherMedCondition = '';
  String _familyCancer = '';
  List<String> _symptoms = [];

  // Form Fields - Menstrual
  String _menopauseStatus = 'Select';
  String _lmpDate = '';
  String _sexuallyActive = 'Undisclosed';
  String _multiplePartners = 'Undisclosed';
  String _firstIntimateAge = '';

  // Form Fields - Obstetric
  String _totalPregnancies = '0';
  String _normalDeliveries = '0';
  String _pretermDeliveries = '0';
  String _csectionDeliveries = '0';
  String _abortions = '0';
  String _liveChildren = '0';

  List<csc.Country> _countries = [];
  List<csc.State> _states = [];
  List<csc.City> _cities = [];

  csc.Country? _selectedCountry;
  csc.State? _selectedState;
  csc.City? _selectedCity;

  final Map<String, String> _screeningTestResults = {};
  String? _hpvRiskLevel;
  List<String> _substanceUsage = [];

  bool _ageUndisclosed = true;
  String _ageAtMarriage = '';
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadCountries();
    if (widget.patient != null) {
      _loadExistingPatient(widget.patient!.id);
    } else {
      _loadSettings();
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _country = prefs.getString('country') ?? '';
      _state = prefs.getString('state') ?? '';
      _city = prefs.getString('city') ?? '';
      _pincode = prefs.getString('pincode') ?? '';
      _block = prefs.getString('block') ?? '';
      _village = prefs.getString('village') ?? '';
      
      final savedVulnerablePop = prefs.getString('vulnerable_population');
      if (savedVulnerablePop != null && savedVulnerablePop != 'Select') {
        _vulnerablePopulation = savedVulnerablePop;
      }
    });
    
    // Attempt to match selected country/state/city for dropdown enablement
    if (_country.isNotEmpty) {
      final countries = await csc.getAllCountries();
      try {
        _selectedCountry = countries.firstWhere((c) => c.name == _country);
        if (_selectedCountry != null && _state.isNotEmpty) {
          final states = await csc.getStatesOfCountry(_selectedCountry!.isoCode);
          if (mounted) {
            setState(() {
              _states = states;
              _selectedState = states.firstWhere((s) => s.name == _state);
            });
            if (_selectedState != null && _city.isNotEmpty) {
              final cities = await csc.getStateCities(
                _selectedState!.countryCode,
                _selectedState!.isoCode,
              );
              if (mounted) {
                setState(() {
                  _cities = cities;
                  _selectedCity = cities.firstWhere((c) => c.name == _city);
                });
              }
            }
          }
        }
      } catch (e) {
        // Ignored if not found
      }
    }
    if (mounted) setState(() => _isLoadingData = false);
  }

  Future<void> _loadExistingPatient(int id) async {
    final data = await LocalDbHelper.instance.getPatientDetails(id);
    if (data == null) return;

    setState(() {
      _patientName = data['patient_name'] ?? '';
      _guardianName = data['gaurdian_name'] ?? '';
      _maritalStatus = data['maratial_status'] ?? 'Select';
      _dob = data['date_of_birth'] ?? '';
      _phone = (data['mobile_number'] ?? '').toString();
      if (_phone == '0') _phone = '';
      _aadhaar = data['aadhaar_number'] ?? '';
      _abha = data['abha_number'] ?? '';
      _country = data['country'] ?? '';
      _state = data['state'] ?? '';
      _city = data['city'] ?? '';
      _block = data['block'] ?? '';
      _village = data['village'] ?? '';
      _pincode = data['pincode'] ?? '';
      _vulnerablePopulation = data['residential_status'] ?? '';
      _occupation = data['occupation'] ?? '';

      final history = data['history'] as Map<String, dynamic>?;
      if (history != null) {
        _hpvVaccinated = history['hpv_test'] == 1;
        _otherMedCondition = history['other_med_condition'] == 'None'
            ? ''
            : history['other_med_condition'] ?? '';
        _familyCancer = history['family_cervical_cancer'] == 'No'
            ? ''
            : history['family_cervical_cancer'] ?? '';
        _lmpDate = history['lmp_date'] ?? '';
        _menopauseStatus = history['menopause_status'] ?? 'Select';
        _sexuallyActive = history['intimately_active'] ?? 'Undisclosed';
        _multiplePartners =
            history['multiple_intimate_partners'] ?? 'Undisclosed';
        int firstAge = history['first_intimate_age'] ?? 0;
        if (firstAge > 0) {
          _ageAtMarriage = firstAge.toString();
          _ageUndisclosed = false;
        } else {
          _ageUndisclosed = true;
        }
        _totalPregnancies = (history['no_pregnancies'] ?? 0).toString();
        _normalDeliveries = (history['no_normal_deliveries'] ?? 0).toString();
        _pretermDeliveries = (history['no_preterm_deliveries'] ?? 0).toString();
        _csectionDeliveries = (history['no_csection_deliveries'] ?? 0)
            .toString();
        _abortions = (history['no_miscarriages'] ?? 0).toString();
        _liveChildren = (history['live_children'] ?? 0).toString();

        try {
          if (history['symptoms_mapping'] != null) {
            final List symps = jsonDecode(history['symptoms_mapping']);
            _symptoms = symps.map((e) => e['customValue'] as String).toList();
          }
        } catch (_) {}
        try {
          if (history['substance_usage'] != null) {
            final List subs = jsonDecode(history['substance_usage']);
            _substanceUsage = subs
                .map((e) => e['customValue'] as String)
                .toList();
          }
        } catch (_) {}
        try {
          if (history['screening_history_mapping'] != null) {
            final List screen = jsonDecode(
              history['screening_history_mapping'],
            );
            _screeningHistory.clear();
            _screeningTestResults.clear();
            for (var item in screen) {
              final val = jsonDecode(item['customValue']);
              _screeningHistory.add(val['test']);
              if (val['result'] != null) {
                _screeningTestResults[val['test']] = val['result'];
              }
              if (val['riskLevel'] != null) {
                _hpvRiskLevel = val['riskLevel'];
              }
            }
          }
        } catch (_) {}
      }
    });
    if (mounted) setState(() => _isLoadingData = false);
  }

  Future<void> _loadCountries() async {
    final countries = await csc.getAllCountries();
    setState(() {
      _countries = countries;
    });
  }

  Future<void> _showSelectionDialog<T>({
    required String title,
    required List<T> items,
    required String Function(T) displayString,
    required Function(T) onSelected,
  }) async {
    String searchQuery = '';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredItems = items
                .where(
                  (item) => displayString(
                    item,
                  ).toLowerCase().contains(searchQuery.toLowerCase()),
                )
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: Icon(Icons.search, size: 18.sp),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        searchQuery = val;
                      });
                    },
                  ),
                  SizedBox(height: 12.h),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return ListTile(
                          title: Text(
                            displayString(item),
                            style: TextStyle(fontSize: 12.sp),
                          ),
                          onTap: () {
                            onSelected(item);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchableDropdown(
    String label,
    String value, {
    bool isRequired = false,
    bool enabled = true,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: TextStyle(
                color: AppTheme.textDark,
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
              ),
              children: [
                if (isRequired)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: AppTheme.accentOrange),
                  ),
              ],
            ),
          ),
          SizedBox(height: 4.h),
          FormField<String>(
            validator: (val) {
              if (isRequired && (value.isEmpty || value == 'Select')) {
                return '';
              }
              return null;
            },
            builder: (FormFieldState<String> state) {
              return InkWell(
                onTap: enabled ? onTap : null,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 14.h,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: state.hasError
                          ? Colors.red
                          : (enabled
                                ? AppTheme.textLight.withOpacity(0.3)
                                : AppTheme.textLight.withOpacity(0.1)),
                    ),
                    color: enabled
                        ? Colors.transparent
                        : AppTheme.backgroundLight,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          value.isEmpty ? 'Select' : value,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: value.isEmpty
                                ? AppTheme.textLight
                                : (enabled
                                      ? AppTheme.textDark
                                      : AppTheme.textLight),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: enabled ? AppTheme.textDark : AppTheme.textLight,
                        size: 18.sp,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<String> _getPreviousTestResultOptions(String test) {
    switch (test) {
      case 'Pap smear':
        return ['Normal', 'Unsatisfactory', 'Abnormal'];
      case 'HPV':
        return ['Negative', 'Positive'];
      case 'VIA':
        return ['Negative', 'Positive'];
      case 'Colposcopy':
        return ['Normal', 'Abnormal'];
      default:
        return [];
    }
  }

  Widget _buildCheckbox(
    String label,
    List<String> list, {
    bool isExclusive = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: list.contains(label),
          onChanged: (v) {
            setState(() {
              if (v == true) {
                if (isExclusive) {
                  list.clear();
                } else if (list.contains('None')) {
                  list.remove('None');
                }
                list.add(label);
              } else {
                list.remove(label);
              }
            });
          },
          activeColor: AppTheme.primaryBlue,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
        ),
        SizedBox(width: 4.w),
        Expanded(
          child: Text(label, style: TextStyle(fontSize: 10.sp)),
        ),
      ],
    );
  }

  Widget _buildDateField(
    String label,
    String hint, {
    required String value,
    required Function(String) onChanged,
    bool isRequired = false,
    bool enabled = true,
  }) {
    final controller = TextEditingController(text: value);
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: TextStyle(
                color: AppTheme.textDark,
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
              ),
              children: [
                if (isRequired)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: AppTheme.accentOrange),
                  ),
              ],
            ),
          ),
          SizedBox(height: 4.h),
          TextFormField(
            controller: controller,
            enabled: enabled,
            readOnly: true,
            style: TextStyle(fontSize: 12.sp, color: AppTheme.textDark),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: enabled ? AppTheme.white : AppTheme.backgroundLight,
              hintText: hint,
              hintStyle: TextStyle(color: AppTheme.textLight, fontSize: 12.sp),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 18.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.r),
                borderSide: BorderSide(
                  color: AppTheme.textLight.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.r),
                borderSide: BorderSide(
                  color: AppTheme.textLight.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.r),
                borderSide: BorderSide(color: AppTheme.primaryBlue),
              ),
              errorStyle: const TextStyle(height: 0, color: Colors.transparent),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.r),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.r),
                borderSide: const BorderSide(color: Colors.red),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.r),
                borderSide: BorderSide(
                  color: AppTheme.textLight.withOpacity(0.1),
                ),
              ),
              suffixIcon: Icon(Icons.calendar_today, size: 16.sp, color: AppTheme.textLight),
            ),
            onTap: () async {
              DateTime initialDate = DateTime.now();
              if (value.isNotEmpty) {
                try {
                  final parts = value.split('-');
                  if (parts.length == 3) {
                    initialDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
                  }
                } catch (e) {}
              }
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppTheme.primaryBlue,
                        onPrimary: AppTheme.white,
                        onSurface: AppTheme.textDark,
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (pickedDate != null) {
                String formattedDate = "${pickedDate.day.toString().padLeft(2, '0')}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.year}";
                onChanged(formattedDate);
                controller.text = formattedDate;
              }
            },
            validator: (val) {
              if (isRequired && (val == null || val.isEmpty)) {
                return '';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint, {
    bool isRequired = false,
    bool enabled = true,
    TextInputType type = TextInputType.text,
    Function(String)? onChanged,
    String? initialValue,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            RichText(
              text: TextSpan(
                text: label,
                style: TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  if (isRequired)
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: AppTheme.accentOrange),
                    ),
                ],
              ),
            ),
            SizedBox(height: 4.h),
          ],
          TextFormField(
            initialValue: initialValue,
            enabled: enabled,
            keyboardType: type,
            style: TextStyle(fontSize: 12.sp, color: AppTheme.textDark),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: enabled ? AppTheme.white : AppTheme.backgroundLight,
              hintText: hint,
              hintStyle: TextStyle(color: AppTheme.textLight, fontSize: 12.sp),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 18.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.r),
                borderSide: BorderSide(
                  color: AppTheme.textLight.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.r),
                borderSide: BorderSide(
                  color: AppTheme.textLight.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.r),
                borderSide: BorderSide(color: AppTheme.primaryBlue),
              ),
              errorStyle: const TextStyle(height: 0, color: Colors.transparent),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.r),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.r),
                borderSide: const BorderSide(color: Colors.red),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.r),
                borderSide: BorderSide(
                  color: AppTheme.textLight.withOpacity(0.1),
                ),
              ),
            ),
            validator: (value) {
              if (isRequired && (value == null || value.isEmpty)) {
                return '';
              }
              return null;
            },
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items, {
    bool isRequired = false,
    bool enabled = true,
    Function(String?)? onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: TextStyle(
                color: AppTheme.textDark,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
              children: [
                if (isRequired)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: AppTheme.accentOrange),
                  ),
              ],
            ),
          ),
          SizedBox(height: 4.h),
          DropdownButtonFormField<String>(
            value: value,
            isDense: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: enabled ? AppTheme.white : AppTheme.backgroundLight,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 12.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.r),
                borderSide: BorderSide(
                  color: AppTheme.textLight.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.r),
                borderSide: BorderSide(
                  color: AppTheme.textLight.withOpacity(0.3),
                ),
              ),
              errorStyle: const TextStyle(height: 0, color: Colors.transparent),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.r),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.r),
                borderSide: const BorderSide(color: Colors.red),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.r),
                borderSide: BorderSide(
                  color: AppTheme.textLight.withOpacity(0.1),
                ),
              ),
            ),
            items: items
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e, style: TextStyle(fontSize: 12.sp)),
                  ),
                )
                .toList(),
            onChanged: enabled ? onChanged : null,
            validator: (val) {
              if (isRequired &&
                  (val == null || val.isEmpty || val == 'Select')) {
                return '';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm({bool reset = false}) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final db = LocalDbHelper.instance;

      // Auto-generate a dummy MRN for local storage (will be replaced by backend or sent as AUTO)
      final mrn = 'LOCAL-${DateTime.now().millisecondsSinceEpoch}';

      int calculatedAge = 0;
      try {
        if (_dob.isNotEmpty) {
          final parts = _dob.split('-');
          if (parts.length == 3) {
            int year = int.parse(
              parts.last.length == 4 ? parts.last : parts.first,
            );
            calculatedAge = DateTime.now().year - year;
          }
        }
      } catch (e) {
        calculatedAge = 30; // fallback
      }

      final patientData = {
        'mrn': mrn,
        'patient_name': _patientName,
        'gaurdian_name': _guardianName,
        'date_of_birth': _dob,
        'age': calculatedAge,
        'maratial_status': _maritalStatus,
        'occupation': _occupation.isNotEmpty ? _occupation : 'Not Specified',
        'residential_status': _vulnerablePopulation.isNotEmpty
            ? _vulnerablePopulation
            : 'General',
        'mobile_number': int.tryParse(_phone) ?? 0,
        'aadhaar_number': _aadhaar,
        'abha_number': _abha,
        'mail': '',
        'country': _country,
        'state': _state,
        'city': _city,
        'pincode': _pincode,
        'block': _block,
        'village': _village,
        'address': '$_village, $_city, $_state',
        'add_line_1': '$_block, $_village',
        'add_line_2': '',
        'sync_status': 0,
      };

      final historyData = {
        'hpv_test': _hpvVaccinated == true ? 1 : 0,
        'other_med_condition': _otherMedCondition.isNotEmpty
            ? _otherMedCondition
            : 'None',
        'family_cervical_cancer': _familyCancer.isNotEmpty
            ? _familyCancer
            : 'No',
        'lmp_date': _lmpDate,
        'menopause_status': _menopauseStatus,
        'intimately_active': _sexuallyActive,
        'multiple_intimate_partners': _multiplePartners,
        'first_intimate_age': _ageUndisclosed
            ? 0
            : (int.tryParse(_ageAtMarriage) ?? 0),
        'no_pregnancies': int.tryParse(_totalPregnancies) ?? 0,
        'no_normal_deliveries': int.tryParse(_normalDeliveries) ?? 0,
        'no_csection_deliveries': int.tryParse(_csectionDeliveries) ?? 0,
        'no_preterm_deliveries': int.tryParse(_pretermDeliveries) ?? 0,
        'no_miscarriages': int.tryParse(_abortions) ?? 0,
        'live_children': int.tryParse(_liveChildren) ?? 0,
        'symptoms_mapping': jsonEncode(
          _symptoms.map((s) => {'customValue': s}).toList(),
        ),
        'screening_history_mapping': jsonEncode(
          _screeningHistory.map((test) {
            final res = _screeningTestResults[test];
            final Map<String, dynamic> map = {'test': test};
            if (res != null) map['result'] = res;
            if (test == 'HPV' && _hpvRiskLevel != null)
              map['riskLevel'] = _hpvRiskLevel!;
            return map; // do NOT double-encode; outer jsonEncode handles serialization
          }).toList(),
        ),
        'substance_usage': jsonEncode(
          _substanceUsage.map((s) => {'customValue': s}).toList(),
        ),
      };

      if (widget.patient != null) {
        await db.updatePatient(widget.patient!.id, patientData, historyData);
      } else {
        int patientId = await db.insertPatient(patientData);
        historyData['patient_id'] = patientId;
        await db.insertPatientHistory(historyData);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient data saved locally!')),
      );

      // Refresh the patients list
      ref.read(patientsProvider.notifier).refresh();
      // Refresh dashboard stats
      ref.refresh(dashboardStatsProvider);

      if (reset) {
        _formKey.currentState!.reset();
        setState(() {
          _screeningHistory.clear();
          _hpvVaccinated = null;
          _symptoms.clear();
          _sexuallyActive = 'Undisclosed';
          _multiplePartners = 'Undisclosed';
          _maritalStatus = 'Select';
          _country = '';
          _state = '';
          _city = '';
          _selectedCountry = null;
          _selectedState = null;
          _selectedCity = null;
          _screeningTestResults.clear();
          _hpvRiskLevel = null;
          _substanceUsage.clear();
          _vulnerablePopulation = '';
          _occupation = '';
          _ageUndisclosed = true;
          _ageAtMarriage = '';
          _firstIntimateAge = '';
          _menopauseStatus = 'Select';
        });
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        if (mounted) context.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white, // One plain white background
      appBar: AppBar(
        title: Text(
          'New Patient Registration',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.textDark,
        elevation: 1,
      ),
      body: _isLoadingData ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Personal Details
              _buildSectionHeader('Personal Details & Contact Information'),
              ResponsiveGridRow(
                children: [
                  _buildTextField(
                    'Patient Name',
                    'Enter patient name',
                    isRequired: true,
                    initialValue: _patientName,
                    onChanged: (v) => _patientName = v,
                  ),
                  _buildTextField(
                    "Husband's / Father's Name",
                    'Enter name',
                    isRequired: true,
                    initialValue: _guardianName,
                    onChanged: (v) => _guardianName = v,
                  ),
                  _buildDropdown(
                    'Marital Status',
                    _maritalStatus,
                    ['Select', 'Single', 'Married', 'Divorced', 'Widowed'],
                    isRequired: true,
                    onChanged: (v) => _maritalStatus = v!,
                  ),
                  _buildDropdown(
                    'Status',
                    'Select',
                    ['Select'],
                    isRequired: true,
                    enabled: false,
                  ),
                  _buildDateField(
                    'Date of Birth',
                    'dd-mm-yyyy',
                    isRequired: true,
                    value: _dob,
                    onChanged: (v) => setState(() => _dob = v),
                  ),
                  _buildTextField(
                    'Phone Number',
                    'Phone',
                    isRequired: true,
                    type: TextInputType.phone,
                    initialValue: _phone,
                    onChanged: (v) => _phone = v,
                  ),
                  _buildTextField(
                    'Aadhaar No.',
                    'Aadhaar',
                    initialValue: _aadhaar,
                    onChanged: (v) => _aadhaar = v,
                  ),
                ],
              ),
              _buildSectionHeader('Address & Identification'),
              ResponsiveGridRow(
                children: [
                  _buildTextField(
                    'ABHA No.',
                    'ABHA',
                    initialValue: _abha,
                    onChanged: (v) => _abha = v,
                  ),
                  _buildSearchableDropdown(
                    'Country',
                    _country,
                    isRequired: true,
                    onTap: () {
                      _showSelectionDialog<csc.Country>(
                        title: 'Select Country',
                        items: _countries,
                        displayString: (c) => c.name,
                        onSelected: (country) async {
                          setState(() {
                            _selectedCountry = country;
                            _country = country.name;
                            _selectedState = null;
                            _state = '';
                            _selectedCity = null;
                            _city = '';
                            _states = [];
                            _cities = [];
                          });
                          final states = await csc.getStatesOfCountry(
                            country.isoCode,
                          );
                          if (mounted)
                            setState(() {
                              _states = states;
                            });
                        },
                      );
                    },
                  ),
                  _buildSearchableDropdown(
                    'State',
                    _state,
                    isRequired: true,
                    enabled: _selectedCountry != null,
                    onTap: () {
                      if (_selectedCountry == null) return;
                      _showSelectionDialog<csc.State>(
                        title: 'Select State',
                        items: _states,
                        displayString: (s) => s.name,
                        onSelected: (state) async {
                          setState(() {
                            _selectedState = state;
                            _state = state.name;
                            _selectedCity = null;
                            _city = '';
                            _cities = [];
                          });
                          final cities = await csc.getStateCities(
                            state.countryCode,
                            state.isoCode,
                          );
                          if (state.name.toLowerCase() == 'maharashtra') {
                            cities.add(
                              csc.City(
                                name: 'Ch.sambhajinagar',
                                countryCode: state.countryCode,
                                stateCode: state.isoCode,
                                latitude: '',
                                longitude: '',
                              ),
                            );
                            cities.sort((a, b) => a.name.compareTo(b.name));
                          }
                          if (mounted)
                            setState(() {
                              _cities = cities;
                            });
                        },
                      );
                    },
                  ),
                  _buildTextField(
                    'Pincode',
                    'Pincode',
                    isRequired: true,
                    type: TextInputType.number,
                    initialValue: _pincode,
                    onChanged: (v) => _pincode = v,
                  ),
                ],
              ),
              ResponsiveGridRow(
                children: [
                  _buildSearchableDropdown(
                    'City',
                    _city,
                    isRequired: true,
                    enabled: _selectedState != null,
                    onTap: () {
                      if (_selectedState == null) return;
                      _showSelectionDialog<csc.City>(
                        title: 'Select City',
                        items: _cities,
                        displayString: (c) => c.name,
                        onSelected: (city) {
                          setState(() {
                            _selectedCity = city;
                            _city = city.name;
                          });
                        },
                      );
                    },
                  ),
                  _buildTextField(
                    'Block',
                    'xyz',
                    initialValue: _block,
                    onChanged: (v) => _block = v,
                  ),
                  _buildTextField(
                    'Village',
                    'Enter village',
                    initialValue: _village,
                    onChanged: (v) => _village = v,
                  ),
                  _buildTextField(
                    'Pincode',
                    'Pincode',
                    isRequired: true,
                    type: TextInputType.number,
                    initialValue: _pincode,
                    onChanged: (v) => _pincode = v,
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                'Type of Key and Vulnerable Population',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 4.h,
                children: ['Urban', 'Rural', 'Migratory', 'Homeless']
                    .map(
                      (e) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Radio<String>(
                            value: e,
                            groupValue: _vulnerablePopulation,
                            onChanged: (v) =>
                                setState(() => _vulnerablePopulation = v!),
                            activeColor: AppTheme.primaryBlue,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: const VisualDensity(
                              horizontal: -4,
                              vertical: -4,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Text(e, style: TextStyle(fontSize: 10.sp)),
                        ],
                      ),
                    )
                    .toList(),
              ),
              SizedBox(height: 12.h),
              Text(
                'Occupation',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 4.h,
                children:
                    [
                          'Business',
                          'Service',
                          'Homemaker',
                          'Government',
                          'Private',
                          'Driver',
                          'Factory worker',
                          'Beggar',
                          'Rag picker',
                          'Daily wages worker',
                          'Other',
                        ]
                        .map(
                          (e) => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Radio<String>(
                                value: e,
                                groupValue: _occupation,
                                onChanged: (v) =>
                                    setState(() => _occupation = v!),
                                activeColor: AppTheme.primaryBlue,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: const VisualDensity(
                                  horizontal: -4,
                                  vertical: -4,
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Text(e, style: TextStyle(fontSize: 10.sp)),
                            ],
                          ),
                        )
                        .toList(),
              ),
              SizedBox(height: 12.h),

              // Reproductive History
              _buildSectionHeader('Reproductive & Lifestyle History'),
              Text(
                'Have you had Screening Test before?',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: ['Pap smear', 'HPV', 'VIA', 'Colposcopy', 'No']
                    .map(
                      (e) => Expanded(
                        flex: e.length > 5 ? 2 : 1,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _screeningHistory.contains(e),
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    if (e == 'No') {
                                      _screeningHistory.clear();
                                      _screeningTestResults.clear();
                                    } else {
                                      _screeningHistory.remove('No');
                                    }
                                    _screeningHistory.add(e);
                                  } else {
                                    _screeningHistory.remove(e);
                                    _screeningTestResults.remove(e);
                                  }
                                });
                              },
                              activeColor: AppTheme.primaryBlue,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: const VisualDensity(
                                horizontal: -4,
                                vertical: -4,
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Flexible(
                              child: Text(
                                e,
                                style: TextStyle(fontSize: 9.sp),
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
              if (_screeningHistory.isNotEmpty &&
                  !_screeningHistory.contains('No'))
                Padding(
                  padding: EdgeInsets.only(top: 8.h, bottom: 8.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _screeningHistory.where((e) => e != 'No').map((
                      test,
                    ) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 80.w,
                              child: Text(
                                test,
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _screeningTestResults[test],
                                isDense: true,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppTheme.white,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 8.h,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24.r),
                                    borderSide: BorderSide(
                                      color: AppTheme.textLight.withOpacity(
                                        0.3,
                                      ),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24.r),
                                    borderSide: BorderSide(
                                      color: AppTheme.textLight.withOpacity(
                                        0.3,
                                      ),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24.r),
                                    borderSide: BorderSide(
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                ),
                                hint: Text(
                                  'Select Result',
                                  style: TextStyle(fontSize: 10.sp),
                                ),
                                items: _getPreviousTestResultOptions(test)
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(
                                          e,
                                          style: TextStyle(fontSize: 10.sp),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  setState(() {
                                    _screeningTestResults[test] = v!;
                                    if (test == 'HPV' && v != 'Negative') {
                                      _hpvRiskLevel = null;
                                    }
                                  });
                                },
                              ),
                            ),
                            if (test == 'HPV' &&
                                _screeningTestResults['HPV'] == 'Negative') ...[
                              SizedBox(width: 8.w),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _hpvRiskLevel,
                                  isDense: true,
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                      vertical: 8.h,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24.r),
                                      borderSide: BorderSide(
                                        color: AppTheme.textLight.withOpacity(
                                          0.3,
                                        ),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24.r),
                                      borderSide: BorderSide(
                                        color: AppTheme.textLight.withOpacity(
                                          0.3,
                                        ),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24.r),
                                      borderSide: BorderSide(
                                        color: AppTheme.primaryBlue,
                                      ),
                                    ),
                                  ),
                                  hint: Text(
                                    'Risk Level',
                                    style: TextStyle(fontSize: 10.sp),
                                  ),
                                  items: ['High Risk', 'Low Risk']
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(
                                            e,
                                            style: TextStyle(fontSize: 10.sp),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) {
                                    setState(() {
                                      _hpvRiskLevel = v;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              SizedBox(height: 8.h),
              Text(
                'HPV Vaccinated?',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Radio<bool>(
                    value: true,
                    groupValue: _hpvVaccinated,
                    onChanged: (v) => setState(
                      () =>
                          _hpvVaccinated = _hpvVaccinated == true ? null : true,
                    ),
                    toggleable: true,
                    activeColor: AppTheme.primaryBlue,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: const VisualDensity(
                      horizontal: -4,
                      vertical: -4,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Text('Yes', style: TextStyle(fontSize: 10.sp)),
                  SizedBox(width: 12.w),
                  Radio<bool>(
                    value: false,
                    groupValue: _hpvVaccinated,
                    onChanged: (v) => setState(
                      () => _hpvVaccinated = _hpvVaccinated == false
                          ? null
                          : false,
                    ),
                    toggleable: true,
                    activeColor: AppTheme.primaryBlue,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: const VisualDensity(
                      horizontal: -4,
                      vertical: -4,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Text('No', style: TextStyle(fontSize: 10.sp)),
                ],
              ),
              SizedBox(height: 8.h),
              _buildTextField(
                'Any other medical condition?',
                'Describe condition (if any)',
                initialValue: _otherMedCondition,
                onChanged: (v) => _otherMedCondition = v,
              ),
              _buildTextField(
                'Family history of cancer? (if yes)',
                'Relation and Type of Cancer',
                initialValue: _familyCancer,
                onChanged: (v) => _familyCancer = v,
              ),
              Text(
                'Symptoms',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildCheckbox(
                          'Excessive vaginal discharge',
                          _symptoms,
                        ),
                      ),
                      Expanded(
                        child: _buildCheckbox(
                          'Itching in external anogenital region',
                          _symptoms,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCheckbox(
                          'Pain during sexual intercourse',
                          _symptoms,
                        ),
                      ),
                      Expanded(
                        child: _buildCheckbox(
                          'Bleeding after intercourse',
                          _symptoms,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                'Any substance usage?',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Wrap(
                spacing: 8.w,
                runSpacing: 4.h,
                children: [
                  FractionallySizedBox(
                    widthFactor: 0.31,
                    child: _buildCheckbox('Smoke', _substanceUsage),
                  ),
                  FractionallySizedBox(
                    widthFactor: 0.31,
                    child: _buildCheckbox('Alcohol', _substanceUsage),
                  ),
                  FractionallySizedBox(
                    widthFactor: 0.31,
                    child: _buildCheckbox('Betel Leaf', _substanceUsage),
                  ),
                  FractionallySizedBox(
                    widthFactor: 0.31,
                    child: _buildCheckbox('Tobacco', _substanceUsage),
                  ),
                  FractionallySizedBox(
                    widthFactor: 0.31,
                    child: _buildCheckbox('Other', _substanceUsage),
                  ),
                  FractionallySizedBox(
                    widthFactor: 0.31,
                    child: _buildCheckbox(
                      'None',
                      _substanceUsage,
                      isExclusive: true,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Menstrual & Sexual History
              _buildSectionHeader('Menstrual & Sexual History'),
              ResponsiveGridRow(
                children: [
                  _buildDropdown(
                    'Menopause Status',
                    _menopauseStatus,
                    [
                      'Select',
                      'Less than 1 year',
                      'More than 1 year',
                      'Unknown',
                    ],
                    enabled: _lmpDate.isEmpty,
                    onChanged: (v) => setState(() => _menopauseStatus = v!),
                  ),
                  _buildDateField(
                    'Date of LMP',
                    'dd-mm-yyyy',
                    enabled:
                        _menopauseStatus == 'Select' ||
                        _menopauseStatus.isEmpty,
                    value: _lmpDate,
                    onChanged: (v) => setState(() => _lmpDate = v),
                  ),
                ],
              ),
              Text(
                'Sexually active?',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: ['Yes', 'No', 'Undisclosed']
                    .map(
                      (e) => Row(
                        children: [
                          Radio<String>(
                            value: e,
                            groupValue: _sexuallyActive,
                            onChanged: (v) =>
                                setState(() => _sexuallyActive = v!),
                            activeColor: AppTheme.primaryBlue,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          Text(e, style: TextStyle(fontSize: 10.sp)),
                          SizedBox(width: 8.w),
                        ],
                      ),
                    )
                    .toList(),
              ),
              SizedBox(height: 8.h),
              Text(
                'Multiple sexual partners?',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: ['Yes', 'No', 'Undisclosed']
                    .map(
                      (e) => Row(
                        children: [
                          Radio<String>(
                            value: e,
                            groupValue: _multiplePartners,
                            onChanged: (v) =>
                                setState(() => _multiplePartners = v!),
                            activeColor: AppTheme.primaryBlue,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          Text(e, style: TextStyle(fontSize: 10.sp)),
                          SizedBox(width: 8.w),
                        ],
                      ),
                    )
                    .toList(),
              ),
              SizedBox(height: 12.h),
              Text(
                'Age at Marriage or first sexual intercourse (In years)',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Checkbox(
                    value: _ageUndisclosed,
                    onChanged: (v) {
                      setState(() {
                        _ageUndisclosed = v == true;
                        if (_ageUndisclosed) _firstIntimateAge = '';
                      });
                    },
                    activeColor: AppTheme.primaryBlue,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: const VisualDensity(
                      horizontal: -4,
                      vertical: -4,
                    ),
                  ),
                  Text('Undisclosed', style: TextStyle(fontSize: 10.sp)),
                  SizedBox(width: 16.w),
                  SizedBox(
                    width: 100.w,
                    child: _buildTextField(
                      '',
                      'Age',
                      enabled: !_ageUndisclosed,
                      type: TextInputType.number,
                      initialValue: _firstIntimateAge,
                      onChanged: (v) => _firstIntimateAge = v,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Obstetric History
              _buildSectionHeader('Obstetric History'),
              ResponsiveGridRow(
                children: [
                  _buildTextField(
                    'Total Pregnancies',
                    '0',
                    type: TextInputType.number,
                    initialValue: _totalPregnancies,
                    onChanged: (v) => _totalPregnancies = v,
                  ),
                  _buildTextField(
                    'Normal Deliveries',
                    '0',
                    type: TextInputType.number,
                    initialValue: _normalDeliveries,
                    onChanged: (v) => _normalDeliveries = v,
                  ),
                  _buildTextField(
                    'Pre-term Deliveries',
                    '0',
                    type: TextInputType.number,
                    initialValue: _pretermDeliveries,
                    onChanged: (v) => _pretermDeliveries = v,
                  ),
                  _buildTextField(
                    'C-Section Deliveries',
                    '0',
                    type: TextInputType.number,
                    initialValue: _csectionDeliveries,
                    onChanged: (v) => _csectionDeliveries = v,
                  ),
                  _buildTextField(
                    'Abortions & Miscarriages',
                    '0',
                    type: TextInputType.number,
                    initialValue: _abortions,
                    onChanged: (v) => _abortions = v,
                  ),
                  _buildTextField(
                    'Live Children',
                    '0',
                    type: TextInputType.number,
                    initialValue: _liveChildren,
                    onChanged: (v) => _liveChildren = v,
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _submitForm(reset: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.white,
                        foregroundColor: AppTheme.primaryBlue,
                        side: const BorderSide(color: AppTheme.primaryBlue),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                      ),
                      child: Text(
                        'Save and Add new patient',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _submitForm(reset: false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                      ),
                      child: Text(
                        'Save and Return to dashboard',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: AppTheme.white,
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
      ),
    );
  }
}
