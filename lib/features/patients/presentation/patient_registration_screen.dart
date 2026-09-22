import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        double itemWidth =
            ((constraints.maxWidth - (spacing * (columns - 1))) / columns)
                .floorToDouble();

        return Wrap(
          spacing: spacing,
          runSpacing: 0,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(),
        );
      },
    );
  }
}

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }

    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 8) {
      return oldValue;
    }

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if ((i == 1 || i == 3) && i != digits.length - 1) {
        buffer.write('-');
      } else if ((i == 1 && digits.length == 2) || (i == 3 && digits.length == 4)) {
        buffer.write('-');
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class PatientRegistrationScreen extends ConsumerStatefulWidget {
  final Patient? patient;
  final Map<String, dynamic>? aadharData;
  const PatientRegistrationScreen({super.key, this.patient, this.aadharData});

  @override
  ConsumerState<PatientRegistrationScreen> createState() =>
      _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState
    extends ConsumerState<PatientRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  List<String> _visibleOccupations = [
    'Business',
    'Service',
    'Homemaker',
    'Government',
  ];

  // FocusNodes for Validation
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _guardianFocus = FocusNode();
  final FocusNode _maritalStatusFocus = FocusNode();
  final FocusNode _dobFocus = FocusNode();
  final FocusNode _countryFocus = FocusNode();
  final FocusNode _stateFocus = FocusNode();
  final FocusNode _cityFocus = FocusNode();
  final FocusNode _pincodeFocus = FocusNode();

  Map<String, dynamic>? _initialValues;

  // Form Fields - Personal
  String _patientName = '';
  String _guardianName = '';
  String _maritalStatus = 'Select';
  String _dob = '';
  String _age = '';
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
  final TextEditingController _otherSymptomController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  @override
  void dispose() {
    _otherSymptomController.dispose();
    _ageController.dispose();
    _nameFocus.dispose();
    _guardianFocus.dispose();
    _maritalStatusFocus.dispose();
    _dobFocus.dispose();
    _countryFocus.dispose();
    _stateFocus.dispose();
    _cityFocus.dispose();
    _pincodeFocus.dispose();
    super.dispose();
  }

  // Form Fields - Menstrual
  String _menopauseStatus = 'Select';
  String _lmpDate = '';
  String _sexuallyActive = 'Undisclosed';
  String _multiplePartners = 'Undisclosed';
  String _firstIntimateAge = '';

  // Form Fields - Obstetric
  String _totalPregnancies = '';
  String _normalDeliveries = '';
  String _pretermDeliveries = '';
  String _csectionDeliveries = '';
  String _abortions = '';
  String _liveChildren = '';

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
      if (widget.aadharData != null) {
        _patientName = widget.aadharData!['name'] ?? '';
        _dob = widget.aadharData!['dob'] ?? '';
        _aadhaar = widget.aadharData!['aadharNumber'] ?? '';
      }
    }
  }

  void _captureInitialValues() {
    _initialValues = {
      'patientName': _patientName,
      'guardianName': _guardianName,
      'maritalStatus': _maritalStatus,
      'dob': _dob,
      'age': _age,
      'phone': _phone,
      'aadhaar': _aadhaar,
      'abha': _abha,
      'country': _country,
      'state': _state,
      'city': _city,
      'block': _block,
      'village': _village,
      'pincode': _pincode,
      'vulnerablePopulation': _vulnerablePopulation,
      'occupation': _occupation,
      'screeningHistory': List<String>.from(_screeningHistory),
      'hpvVaccinated': _hpvVaccinated,
      'otherMedCondition': _otherMedCondition,
      'familyCancer': _familyCancer,
      'symptoms': List<String>.from(_symptoms),
      'otherSymptom': _otherSymptomController.text,
      'menopauseStatus': _menopauseStatus,
      'lmpDate': _lmpDate,
      'sexuallyActive': _sexuallyActive,
      'multiplePartners': _multiplePartners,
      'firstIntimateAge': _firstIntimateAge,
      'totalPregnancies': _totalPregnancies,
      'normalDeliveries': _normalDeliveries,
      'pretermDeliveries': _pretermDeliveries,
      'csectionDeliveries': _csectionDeliveries,
      'abortions': _abortions,
      'liveChildren': _liveChildren,
      'substanceUsage': List<String>.from(_substanceUsage),
      'ageAtMarriage': _ageAtMarriage,
      'screeningTestResults': Map<String, String>.from(_screeningTestResults),
      'hpvRiskLevel': _hpvRiskLevel,
      'ageUndisclosed': _ageUndisclosed,
    };
  }

  bool _hasChanges() {
    if (_initialValues == null) return false;

    if (_initialValues!['patientName'] != _patientName) return true;
    if (_initialValues!['guardianName'] != _guardianName) return true;
    if (_initialValues!['maritalStatus'] != _maritalStatus) return true;
    if (_initialValues!['dob'] != _dob) return true;
    if (_initialValues!['age'] != _age) return true;
    if (_initialValues!['phone'] != _phone) return true;
    if (_initialValues!['aadhaar'] != _aadhaar) return true;
    if (_initialValues!['abha'] != _abha) return true;
    if (_initialValues!['country'] != _country) return true;
    if (_initialValues!['state'] != _state) return true;
    if (_initialValues!['city'] != _city) return true;
    if (_initialValues!['block'] != _block) return true;
    if (_initialValues!['village'] != _village) return true;
    if (_initialValues!['pincode'] != _pincode) return true;
    if (_initialValues!['vulnerablePopulation'] != _vulnerablePopulation) {
      return true;
    }
    if (_initialValues!['occupation'] != _occupation) return true;

    final initialScreening =
        _initialValues!['screeningHistory'] as List<String>;
    if (initialScreening.length != _screeningHistory.length ||
        !initialScreening.every((e) => _screeningHistory.contains(e))) {
      return true;
    }

    if (_initialValues!['hpvVaccinated'] != _hpvVaccinated) return true;
    if (_initialValues!['otherMedCondition'] != _otherMedCondition) return true;
    if (_initialValues!['familyCancer'] != _familyCancer) return true;

    final initialSymptoms = _initialValues!['symptoms'] as List<String>;
    if (initialSymptoms.length != _symptoms.length ||
        !initialSymptoms.every((e) => _symptoms.contains(e))) {
      return true;
    }

    if (_initialValues!['otherSymptom'] != _otherSymptomController.text) {
      return true;
    }

    if (_initialValues!['menopauseStatus'] != _menopauseStatus) return true;
    if (_initialValues!['lmpDate'] != _lmpDate) return true;
    if (_initialValues!['sexuallyActive'] != _sexuallyActive) return true;
    if (_initialValues!['multiplePartners'] != _multiplePartners) return true;
    if (_initialValues!['firstIntimateAge'] != _firstIntimateAge) return true;
    if (_initialValues!['totalPregnancies'] != _totalPregnancies) return true;
    if (_initialValues!['normalDeliveries'] != _normalDeliveries) return true;
    if (_initialValues!['pretermDeliveries'] != _pretermDeliveries) return true;
    if (_initialValues!['csectionDeliveries'] != _csectionDeliveries) {
      return true;
    }
    if (_initialValues!['abortions'] != _abortions) return true;
    if (_initialValues!['liveChildren'] != _liveChildren) return true;

    final initialSubstance = _initialValues!['substanceUsage'] as List<String>;
    if (initialSubstance.length != _substanceUsage.length ||
        !initialSubstance.every((e) => _substanceUsage.contains(e))) {
      return true;
    }

    if (_initialValues!['ageAtMarriage'] != _ageAtMarriage) return true;

    final initialResults =
        _initialValues!['screeningTestResults'] as Map<String, String>;
    if (initialResults.length != _screeningTestResults.length) return true;
    for (final key in initialResults.keys) {
      if (initialResults[key] != _screeningTestResults[key]) return true;
    }

    if (_initialValues!['hpvRiskLevel'] != _hpvRiskLevel) return true;
    if (_initialValues!['ageUndisclosed'] != _ageUndisclosed) return true;

    return false;
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

      final occ = prefs.getStringList('visible_occupations');
      if (occ != null && occ.isNotEmpty) {
        _visibleOccupations = occ;
      }
    });

    if (_country.isNotEmpty) {
      final countries = await csc.getAllCountries();
      try {
        _selectedCountry = countries.firstWhere((c) => c.name == _country);
        if (_selectedCountry != null && _state.isNotEmpty) {
          final states = await csc.getStatesOfCountry(
            _selectedCountry!.isoCode,
          );
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
    if (mounted) {
      setState(() {
        _isLoadingData = false;
        _captureInitialValues();
      });
    }
  }

  Future<void> _loadExistingPatient(int id) async {
    final data = await LocalDbHelper.instance.getPatientDetails(id);
    if (data == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient not found in local database.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _patientName = data['patient_name'] ?? '';
      _guardianName = data['gaurdian_name'] ?? '';
      _maritalStatus = data['maratial_status'] ?? 'Select';
      String rawDob = (data['date_of_birth'] ?? '').toString();
      if (rawDob.contains('T')) {
        rawDob = rawDob.split('T')[0];
      }
      _age = (data['age'] ?? '').toString();
      if (_age == '0') _age = '';
      _ageController.text = _age;
      int ageNum = int.tryParse(_age) ?? 0;
      String estimatedDob =
          ageNum > 0 ? '${DateTime.now().year - ageNum}-01-01' : '';
      if (rawDob.isNotEmpty &&
          estimatedDob.isNotEmpty &&
          rawDob == estimatedDob) {
        _dob = '';
      } else {
        _dob = rawDob;
      }
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
          _firstIntimateAge = firstAge.toString();
          _ageUndisclosed = false;
        } else {
          _ageUndisclosed = true;
        }
        _totalPregnancies =
            (history['no_pregnancies'] == null ||
                    history['no_pregnancies'] == 0)
                ? ''
                : history['no_pregnancies'].toString();
        _normalDeliveries =
            (history['no_normal_deliveries'] == null ||
                    history['no_normal_deliveries'] == 0)
                ? ''
                : history['no_normal_deliveries'].toString();
        _pretermDeliveries =
            (history['no_preterm_deliveries'] == null ||
                    history['no_preterm_deliveries'] == 0)
                ? ''
                : history['no_preterm_deliveries'].toString();
        _csectionDeliveries =
            (history['no_csection_deliveries'] == null ||
                    history['no_csection_deliveries'] == 0)
                ? ''
                : history['no_csection_deliveries'].toString();
        _abortions =
            (history['no_miscarriages'] == null ||
                    history['no_miscarriages'] == 0)
                ? ''
                : history['no_miscarriages'].toString();
        _liveChildren =
            (history['live_children'] == null || history['live_children'] == 0)
                ? ''
                : history['live_children'].toString();

        try {
          if (history['symptoms_mapping'] != null) {
            final List symps = jsonDecode(history['symptoms_mapping']);
            final List<String> loaded =
                symps.map((e) => e['customValue'] as String).toList();
            const standardSymptoms = [
              'Excessive vaginal discharge',
              'Itching in external anogenital region',
              'Ulcers in external anogenital region',
              'Lower abdominal pain',
              'Pain during sexual intercourse',
              'Bleeding after intercourse',
              'Intermenstrual bleeding',
              'Low back ache',
            ];
            _symptoms =
                loaded.where((s) => standardSymptoms.contains(s)).toList();
            final custom =
                loaded.where((s) => !standardSymptoms.contains(s)).toList();
            if (custom.isNotEmpty) {
              _otherSymptomController.text = custom.join(', ');
            }
          }
        } catch (_) {}

        try {
          if (history['substance_usage'] != null) {
            final List subs = jsonDecode(history['substance_usage']);
            _substanceUsage =
                subs.map((e) => e['customValue'] as String).toList();
          }
        } catch (_) {}

        try {
          if (history['screening_history_mapping'] != null) {
            final List screen = jsonDecode(
              history['screening_history_mapping'],
            );
            final List<String> restoredHistory = [];
            final Map<String, String> restoredResults = {};
            for (var item in screen) {
              dynamic val;
              if (item['customValue'] is String) {
                val = jsonDecode(item['customValue']);
              } else {
                val = item['customValue'];
              }
              if (val == null || val['test'] == null) continue;
              final String testName = val['test'] as String;
              restoredHistory.add(testName);
              if (val['result'] != null &&
                  (val['result'] as String).isNotEmpty) {
                restoredResults[testName] = val['result'] as String;
              }
              if (val['riskLevel'] != null) {
                _hpvRiskLevel = val['riskLevel'] as String;
              }
            }
            _screeningHistory = restoredHistory;
            _screeningTestResults
              ..clear()
              ..addAll(restoredResults);
          }
        } catch (e) {
          print('Error restoring screening history: $e');
        }
      }
    });

    if (mounted) {
      setState(() {
        _isLoadingData = false;
        _captureInitialValues();
      });
    }
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
                      prefixIcon: Icon(Icons.search, size: 14.sp),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
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

  Widget _buildSectionHeader(String title, {IconData? icon}) {
    return Container(
      margin: EdgeInsets.only(top: 24.h, bottom: 16.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8.r),
        border: Border(
          left: BorderSide(color: AppTheme.primaryBlue, width: 4.w),
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppTheme.primaryBlue, size: 16.sp),
            SizedBox(width: 8.w),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchableDropdown(
    String label,
    String value, {
    FocusNode? focusNode,
    bool isRequired = false,
    bool enabled = true,
    IconData? prefixIcon,
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
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
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
          Focus(
            focusNode: focusNode,
            child: FormField<String>(
              validator: (val) {
                if (isRequired && (value.isEmpty || value == 'Select')) {
                  return '';
                }
                return null;
              },
              builder: (formFieldState) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: enabled ? onTap : null,
                      borderRadius: BorderRadius.circular(8.r),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor:
                              enabled ? Colors.white : AppTheme.backgroundLight,
                          prefixIcon: prefixIcon != null
                              ? Icon(
                                  prefixIcon,
                                  color: AppTheme.textLight,
                                  size: 14.sp,
                                )
                              : null,
                          suffixIcon: Icon(
                            Icons.arrow_drop_down,
                            color: AppTheme.textLight,
                            size: 18.sp,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 10.h,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(
                              color: formFieldState.hasError
                                  ? Colors.red
                                  : Colors.grey.shade300,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(
                              color: formFieldState.hasError
                                  ? Colors.red
                                  : Colors.grey.shade300,
                            ),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Text(
                          value.isNotEmpty ? value : 'Select',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: value.isNotEmpty && value != 'Select'
                                ? AppTheme.textDark
                                : AppTheme.textLight,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint, {
    FocusNode? focusNode,
    Key? fieldKey,
    TextEditingController? controller,
    bool isRequired = false,
    bool enabled = true,
    TextInputType type = TextInputType.text,
    Function(String)? onChanged,
    String? initialValue,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    IconData? prefixIcon,
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
                  fontWeight: FontWeight.w500,
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
            key: fieldKey,
            focusNode: focusNode,
            controller: controller,
            initialValue: controller != null ? null : initialValue,
            enabled: enabled,
            keyboardType: type,
            style: TextStyle(fontSize: 12.sp, color: AppTheme.textDark),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: enabled ? Colors.white : AppTheme.backgroundLight,
              hintText: hint,
              hintStyle: TextStyle(color: AppTheme.textLight, fontSize: 12.sp),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: AppTheme.textLight, size: 14.sp)
                  : null,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 12.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: AppTheme.primaryBlue),
              ),
              errorMaxLines: 2,
              errorStyle: TextStyle(
                color: Colors.red,
                fontSize: 10.sp,
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: Colors.red),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            inputFormatters: inputFormatters,
            maxLength: maxLength,
            buildCounter:
                (
                  BuildContext context, {
                  int? currentLength,
                  int? maxLength,
                  bool? isFocused,
                }) => null,
            validator:
                validator ??
                (value) {
                  if (isRequired && (value == null || value.trim().isEmpty)) {
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
    FocusNode? focusNode,
    bool isRequired = false,
    bool enabled = true,
    IconData? prefixIcon,
    VoidCallback? onClear,
    Function(String?)? onChanged,
  }) {
    final hasSelection = value.isNotEmpty && value != 'Select';
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
                fontWeight: FontWeight.w500,
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
          Focus(
            focusNode: focusNode,
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              value: value,
              isDense: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: enabled ? Colors.white : AppTheme.backgroundLight,
                prefixIcon: prefixIcon != null
                    ? Icon(prefixIcon, color: AppTheme.textLight, size: 14.sp)
                    : null,
                suffixIcon: (hasSelection && onClear != null && enabled)
                    ? IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 14.sp,
                          color: AppTheme.textLight,
                        ),
                        onPressed: onClear,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                    : null,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 10.h,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                errorMaxLines: 2,
                errorStyle: TextStyle(
                  color: Colors.red,
                  fontSize: 10.sp,
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.grey.shade300),
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
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(
    String label,
    String hint, {
    FocusNode? focusNode,
    bool isRequired = false,
    bool enabled = true,
    required String value,
    required Function(String) onChanged,
  }) {
    final controller = TextEditingController(text: value);
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );

    Future<void> openPicker() async {
      DateTime initialDate = DateTime.now();
      if (value.isNotEmpty) {
        try {
          final parts = value.split('-');
          if (parts.length == 3) {
            final year = int.parse(
              parts[0].length == 4 ? parts[0] : parts[2],
            );
            final month = int.parse(parts[1]);
            final day = int.parse(
              parts[0].length == 4 ? parts[2] : parts[0],
            );
            initialDate = DateTime(year, month, day);
          }
        } catch (_) {}
      }
      final picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
      );
      if (picked != null) {
        final formatted =
            "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
        onChanged(formatted);
      }
    }

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
                fontWeight: FontWeight.w500,
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
          Focus(
            focusNode: focusNode,
            child: TextFormField(
              controller: controller,
              enabled: enabled,
              readOnly: false,
              keyboardType: TextInputType.number,
              inputFormatters: [
                DateInputFormatter(),
              ],
              style: TextStyle(fontSize: 12.sp, color: AppTheme.textDark),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                counterText: '',
                fillColor: enabled ? Colors.white : AppTheme.backgroundLight,
                hintText: hint.contains('YYYY') ? 'DD-MM-YYYY' : hint,
                hintStyle: TextStyle(
                  color: AppTheme.textLight,
                  fontSize: 12.sp,
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (value.isNotEmpty && enabled)
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 14.sp,
                          color: AppTheme.textLight,
                        ),
                        onPressed: () {
                          controller.clear();
                          onChanged('');
                        },
                      ),
                    if (enabled)
                      IconButton(
                        icon: Icon(
                          Icons.calendar_today_outlined,
                          color: AppTheme.textLight,
                          size: 14.sp,
                        ),
                        onPressed: openPicker,
                      ),
                  ],
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 10.h,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              onChanged: onChanged,
              validator: (val) {
                if (isRequired && (val == null || val.isEmpty)) {
                  return '';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(
    String label,
    List<String> selectedList, {
    bool isExclusive = false,
  }) {
    final isSelected = selectedList.contains(label);
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedList.remove(label);
          } else {
            if (isExclusive) {
              selectedList.clear();
            } else {
              selectedList.remove('None');
            }
            selectedList.add(label);
          }
        });
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24.w,
              height: 24.h,
              child: Checkbox(
                value: isSelected,
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      if (isExclusive) {
                        selectedList.clear();
                      } else {
                        selectedList.remove('None');
                      }
                      selectedList.add(label);
                    } else {
                      selectedList.remove(label);
                    }
                  });
                },
                activeColor: AppTheme.primaryBlue,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            SizedBox(width: 4.w),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 11.sp, color: AppTheme.textDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getPreviousTestResultOptions(String testName) {
    if (testName == 'HPV') {
      return ['Negative', 'Positive'];
    } else if (testName == 'VIA') {
      return ['Negative', 'Positive'];
    } else if (testName == 'Colposcopy') {
      return ['Normal', 'Abnormal'];
    } else {
      return ['Normal', 'Unsatisfactory', 'Abnormal'];
    }
  }

  Future<void> _submitForm({bool reset = false}) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_age.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Age is required. Please enter age.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final db = LocalDbHelper.instance;

      String mrn;
      if (widget.patient != null) {
        final existing = await db.getPatientDetails(widget.patient!.id);
        if (existing == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Patient not found in local database.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        mrn = (existing['mrn'] as String?)?.isNotEmpty == true
            ? existing['mrn'] as String
            : 'LOCAL-${DateTime.now().millisecondsSinceEpoch}';
      } else {
        mrn = 'LOCAL-${DateTime.now().millisecondsSinceEpoch}';
      }

      int calculatedAge = int.tryParse(_age.trim()) ?? 0;
      try {
        if (_dob.isNotEmpty) {
          final parts = _dob.split('-');
          if (parts.length == 3) {
            final year = int.parse(parts[0].length == 4 ? parts[0] : parts[2]);
            final month = int.parse(parts[1]);
            final day = int.parse(parts[0].length == 4 ? parts[2] : parts[0]);
            final dob = DateTime(year, month, day);
            final today = DateTime.now();
            calculatedAge =
                today.year -
                dob.year -
                ((today.month < dob.month ||
                        (today.month == dob.month && today.day < dob.day))
                    ? 1
                    : 0);
          }
        }
      } catch (e) {
        calculatedAge = int.tryParse(_age.trim()) ?? 0;
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

      final List<String> allSymptomsToSave = [..._symptoms];
      if (_otherSymptomController.text.trim().isNotEmpty) {
        allSymptomsToSave.add(_otherSymptomController.text.trim());
      }

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
            : (int.tryParse(_firstIntimateAge) ?? 0),
        'no_pregnancies': int.tryParse(_totalPregnancies) ?? 0,
        'no_normal_deliveries': int.tryParse(_normalDeliveries) ?? 0,
        'no_csection_deliveries': int.tryParse(_csectionDeliveries) ?? 0,
        'no_preterm_deliveries': int.tryParse(_pretermDeliveries) ?? 0,
        'no_miscarriages': int.tryParse(_abortions) ?? 0,
        'live_children': int.tryParse(_liveChildren) ?? 0,
        'symptoms_mapping': jsonEncode(
          allSymptomsToSave.map((s) => {'customValue': s}).toList(),
        ),
        'screening_history_mapping': jsonEncode(
          _screeningHistory.map((test) {
            final res = _screeningTestResults[test] ?? '';
            final Map<String, dynamic> map = {'test': test, 'result': res};
            if (test == 'HPV' && _hpvRiskLevel != null) {
              map['riskLevel'] = _hpvRiskLevel!;
            }
            return {'customValue': jsonEncode(map)};
          }).toList(),
        ),
        'substance_usage': jsonEncode(
          _substanceUsage.map((s) => {'customValue': s}).toList(),
        ),
      };

      try {
        if (widget.patient != null) {
          await db.updatePatient(
            widget.patient!.id,
            patientData,
            historyData,
          );
        } else {
          await db.insertPatientWithHistory(patientData, historyData);
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient data saved locally.')),
      );

      ref.read(patientsProvider.notifier).refresh();
      final _ = ref.refresh(dashboardStatsProvider);

      if (reset) {
        _formKey.currentState!.reset();
        setState(() {
          _screeningHistory.clear();
          _hpvVaccinated = null;
          _symptoms.clear();
          _otherSymptomController.clear();
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
          _totalPregnancies = '';
          _normalDeliveries = '';
          _csectionDeliveries = '';
          _pretermDeliveries = '';
          _abortions = '';
          _liveChildren = '';
          _age = '';
          _ageController.clear();
        });
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else if (mounted) {
        context.go('/dashboard');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all mandatory fields correctly.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        if (!_hasChanges()) {
          if (context.mounted) context.pop();
          return;
        }

        final shouldSave = await showDialog<bool?>(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            backgroundColor: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Save or Discard Information',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context, null),
                        child: Icon(
                          Icons.close,
                          color: Colors.grey.shade600,
                          size: 20.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Do you want to save or discard the changes made?',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppTheme.textLight,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                        ),
                        child: const Text('Discard'),
                      ),
                      SizedBox(width: 12.w),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

        if (shouldSave == null) return;

        if (shouldSave == true) {
          _submitForm(reset: false);
        } else {
          if (context.mounted) context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text(
            widget.patient == null
                ? 'Patient Registration'
                : 'Edit Patient Details',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: _isLoadingData
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section 1: Personal Details & Contact Information
                      _buildSectionHeader(
                        'Personal Details & Contact Information',
                        icon: Icons.person_outline,
                      ),
                      ResponsiveGridRow(
                        children: [
                          _buildTextField(
                            'Patient Name',
                            'Enter Patient Name',
                            focusNode: _nameFocus,
                            prefixIcon: Icons.person_outline,
                            isRequired: true,
                            initialValue: _patientName,
                            onChanged: (v) => _patientName = v,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z\s]'),
                              ),
                            ],
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Patient name is required';
                              }
                              if (val.trim().length < 2) {
                                return 'Must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                          _buildTextField(
                            'Guardian Name',
                            'Enter Guardian Name',
                            focusNode: _guardianFocus,
                            prefixIcon: Icons.person_outline,
                            isRequired: true,
                            initialValue: _guardianName,
                            onChanged: (v) => _guardianName = v,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z\s]'),
                              ),
                            ],
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Guardian name is required';
                              }
                              return null;
                            },
                          ),
                          _buildDropdown(
                            'Marital Status',
                            _maritalStatus,
                            [
                              'Select',
                              'Single',
                              'Married',
                              'Unknown',
                              'Widowed',
                            ],
                            focusNode: _maritalStatusFocus,
                            isRequired: true,
                            prefixIcon: Icons.family_restroom_outlined,
                            onChanged: (v) =>
                                setState(() => _maritalStatus = v!),
                          ),
                          _buildDateField(
                            'Date of Birth',
                            'DD-MM-YYYY',
                            focusNode: _dobFocus,
                            isRequired: false,
                            value: _dob,
                            onChanged: (v) => setState(() {
                              _dob = v;
                              if (_dob.isNotEmpty) {
                                try {
                                  final parts = _dob.split('-');
                                  if (parts.length == 3) {
                                    final isYearFirst = parts[0].length == 4;
                                    final year = int.parse(
                                      isYearFirst ? parts[0] : parts[2],
                                    );
                                    final month = int.parse(parts[1]);
                                    final day = int.parse(
                                      isYearFirst ? parts[2] : parts[0],
                                    );
                                    final dobDate = DateTime(
                                      year,
                                      month,
                                      day,
                                    );
                                    final today = DateTime.now();
                                    int calcAge = today.year - dobDate.year;
                                    if (today.month < dobDate.month ||
                                        (today.month == dobDate.month &&
                                            today.day < dobDate.day)) {
                                      calcAge--;
                                    }
                                    if (calcAge >= 0 && calcAge <= 120) {
                                      _age = calcAge.toString();
                                      _ageController.text = _age;
                                    }
                                  }
                                } catch (_) {}
                              } else {
                                _age = '';
                                _ageController.clear();
                              }
                            }),
                          ),
                          _buildTextField(
                            'Age',
                            'Enter Age',
                            prefixIcon: Icons.cake_outlined,
                            controller: _ageController,
                            isRequired: true,
                            enabled: true,
                            type: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (v) => setState(() {
                              _age = v;
                              if (_dob.isNotEmpty) {
                                try {
                                  final parts = _dob.split('-');
                                  if (parts.length == 3) {
                                    final year = int.parse(
                                      parts[0].length == 4
                                          ? parts[0]
                                          : parts[2],
                                    );
                                    final month = int.parse(parts[1]);
                                    final day = int.parse(
                                      parts[0].length == 4
                                          ? parts[2]
                                          : parts[0],
                                    );
                                    final dobDate = DateTime(
                                      year,
                                      month,
                                      day,
                                    );
                                    final today = DateTime.now();
                                    int calcAge = today.year - dobDate.year;
                                    if (today.month < dobDate.month ||
                                        (today.month == dobDate.month &&
                                            today.day < dobDate.day)) {
                                      calcAge--;
                                    }
                                    final enteredAge = int.tryParse(
                                      v.trim(),
                                    );
                                    if (enteredAge != null &&
                                        enteredAge != calcAge) {
                                      _dob = '';
                                    }
                                  }
                                } catch (_) {}
                              }
                            }),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Age is required';
                              }
                              final num = int.tryParse(val.trim());
                              if (num == null || num < 1 || num > 120) {
                                return 'Valid age (1-120)';
                              }
                              return null;
                            },
                          ),
                          _buildTextField(
                            'Phone Number',
                            'Enter 10-digit Phone',
                            prefixIcon: Icons.phone_outlined,
                            type: TextInputType.phone,
                            initialValue: _phone,
                            maxLength: 10,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (v) => _phone = v,
                            validator: (val) {
                              if (val != null && val.trim().isNotEmpty) {
                                if (!RegExp(
                                  r'^\d{10}$',
                                ).hasMatch(val.trim())) {
                                  return 'Phone must be exactly 10 digits';
                                }
                              }
                              return null;
                            },
                          ),
                          _buildTextField(
                            'Aadhaar Number',
                            'Enter 12-digit Aadhaar',
                            prefixIcon: Icons.badge_outlined,
                            initialValue: _aadhaar,
                            maxLength: 12,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (v) => _aadhaar = v,
                            validator: (val) {
                              if (val != null && val.trim().isNotEmpty) {
                                if (!RegExp(
                                  r'^[2-9]\d{11}$',
                                ).hasMatch(val.trim())) {
                                  return 'Invalid Aadhaar (12 digits, cannot start with 0 or 1)';
                                }
                              }
                              return null;
                            },
                          ),
                          _buildTextField(
                            'ABHA Number',
                            'Enter 14-digit ABHA',
                            prefixIcon: Icons.security_outlined,
                            initialValue: _abha,
                            maxLength: 14,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (v) => _abha = v,
                            validator: (val) {
                              if (val != null && val.trim().isNotEmpty) {
                                if (!RegExp(
                                  r'^\d{14}$',
                                ).hasMatch(val.trim())) {
                                  return 'ABHA must be exactly 14 digits';
                                }
                              }
                              return null;
                            },
                          ),
                          _buildSearchableDropdown(
                            'Country',
                            _country,
                            focusNode: _countryFocus,
                            isRequired: true,
                            prefixIcon: Icons.public_outlined,
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
                                  if (mounted) {
                                    setState(() {
                                      _states = states;
                                    });
                                  }
                                },
                              );
                            },
                          ),
                          _buildSearchableDropdown(
                            'State',
                            _state,
                            focusNode: _stateFocus,
                            isRequired: true,
                            prefixIcon: Icons.map_outlined,
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
                                  if (state.name.toLowerCase() ==
                                      'maharashtra') {
                                    cities.add(
                                      csc.City(
                                        name: 'Ch.sambhajinagar',
                                        countryCode: state.countryCode,
                                        stateCode: state.isoCode,
                                        latitude: '',
                                        longitude: '',
                                      ),
                                    );
                                    cities.sort(
                                      (a, b) => a.name.compareTo(b.name),
                                    );
                                  }
                                  if (mounted) {
                                    setState(() {
                                      _cities = cities;
                                    });
                                  }
                                },
                              );
                            },
                          ),
                          _buildSearchableDropdown(
                            'City',
                            _city,
                            focusNode: _cityFocus,
                            isRequired: true,
                            prefixIcon: Icons.location_city_outlined,
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
                            'Pincode',
                            'Enter Pincode',
                            focusNode: _pincodeFocus,
                            prefixIcon: Icons.pin_drop_outlined,
                            isRequired: true,
                            initialValue: _pincode,
                            onChanged: (v) => _pincode = v,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Pincode is required';
                              }
                              if (!RegExp(
                                r'^[a-zA-Z0-9\s-]{4,10}$',
                              ).hasMatch(val.trim())) {
                                return 'Please enter a valid pincode (4-10 characters)';
                              }
                              return null;
                            },
                          ),
                          _buildTextField(
                            'Block',
                            'Enter Block',
                            prefixIcon: Icons.grid_view_outlined,
                            initialValue: _block,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z\s]'),
                              ),
                            ],
                            onChanged: (v) => _block = v,
                            validator: (val) {
                              if (val != null &&
                                  val.isNotEmpty &&
                                  val.trim().isEmpty) {
                                return 'Cannot be only spaces';
                              }
                              return null;
                            },
                          ),
                          _buildTextField(
                            'Village',
                            'Enter Village',
                            prefixIcon: Icons.home_work_outlined,
                            initialValue: _village,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z\s]'),
                              ),
                            ],
                            onChanged: (v) => _village = v,
                            validator: (val) {
                              if (val != null &&
                                  val.isNotEmpty &&
                                  val.trim().isEmpty) {
                                return 'Cannot be only spaces';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Type of Vulnerable Population',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Wrap(
                        spacing: 12.w,
                        runSpacing: 4.h,
                        children:
                            ['Urban', 'Rural', 'Migratory', 'Homeless']
                                .map(
                                  (e) => Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Radio<String>(
                                        value: e,
                                        groupValue: _vulnerablePopulation,
                                        toggleable: true,
                                        onChanged: (v) => setState(
                                          () =>
                                              _vulnerablePopulation = v ?? '',
                                        ),
                                        activeColor: AppTheme.primaryBlue,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        e,
                                        style: TextStyle(fontSize: 11.sp),
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Occupation',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Wrap(
                        spacing: 12.w,
                        runSpacing: 4.h,
                        children: _visibleOccupations
                            .map(
                              (e) => Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Radio<String>(
                                    value: e,
                                    groupValue: _occupation,
                                    toggleable: true,
                                    onChanged: (v) =>
                                        setState(() => _occupation = v ?? ''),
                                    activeColor: AppTheme.primaryBlue,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(e, style: TextStyle(fontSize: 11.sp)),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                      SizedBox(height: 16.h),

                      // Section 2: Reproductive & Lifestyle History
                      _buildSectionHeader(
                        'Reproductive & Lifestyle History',
                        icon: Icons.medical_services_outlined,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Have had screening before?',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Wrap(
                            spacing: 12.w,
                            runSpacing: 4.h,
                            children:
                                [
                                      'Pap smear',
                                      'HPV',
                                      'VIA',
                                      'Colposcopy',
                                      'No',
                                    ]
                                    .map(
                                      (e) => Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Checkbox(
                                            value: _screeningHistory.contains(
                                              e,
                                            ),
                                            onChanged: (v) {
                                              setState(() {
                                                if (v == true) {
                                                  if (e == 'No') {
                                                    _screeningHistory.clear();
                                                    _screeningTestResults
                                                        .clear();
                                                  } else {
                                                    _screeningHistory.remove(
                                                      'No',
                                                    );
                                                  }
                                                  _screeningHistory.add(e);
                                                } else {
                                                  _screeningHistory.remove(e);
                                                  _screeningTestResults.remove(
                                                    e,
                                                  );
                                                }
                                              });
                                            },
                                            activeColor: AppTheme.primaryBlue,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize.shrinkWrap,
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            e,
                                            style: TextStyle(fontSize: 11.sp),
                                          ),
                                        ],
                                      ),
                                    )
                                    .toList(),
                          ),
                          if (_screeningHistory.isNotEmpty &&
                              !_screeningHistory.contains('No'))
                            Padding(
                              padding: EdgeInsets.only(
                                top: 8.h,
                                bottom: 8.h,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _screeningHistory
                                    .where((e) => e != 'No')
                                    .map((test) {
                                      return Padding(
                                        padding: EdgeInsets.only(bottom: 8.h),
                                        child: Wrap(
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          spacing: 12.w,
                                          runSpacing: 8.h,
                                          children: [
                                            SizedBox(
                                              width: 90.w,
                                              child: Text(
                                                test,
                                                style: TextStyle(
                                                  fontSize: 11.sp,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 180.w,
                                              child: DropdownButtonFormField<
                                                String
                                              >(
                                                isExpanded: true,
                                                value:
                                                    _screeningTestResults[test],
                                                isDense: true,
                                                decoration: InputDecoration(
                                                  filled: true,
                                                  fillColor: AppTheme.white,
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                        horizontal: 12.w,
                                                        vertical: 10.h,
                                                      ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8.r,
                                                        ),
                                                    borderSide: BorderSide(
                                                      color: Colors
                                                          .grey
                                                          .shade300,
                                                    ),
                                                  ),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8.r,
                                                        ),
                                                    borderSide: BorderSide(
                                                      color: Colors
                                                          .grey
                                                          .shade300,
                                                    ),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8.r,
                                                        ),
                                                    borderSide: const BorderSide(
                                                      color: AppTheme.primaryBlue,
                                                    ),
                                                  ),
                                                ),
                                                hint: Text(
                                                  'Select Result',
                                                  style: TextStyle(
                                                    fontSize: 12.sp,
                                                  ),
                                                ),
                                                items:
                                                    _getPreviousTestResultOptions(
                                                          test,
                                                        )
                                                        .map(
                                                          (
                                                            e,
                                                          ) => DropdownMenuItem(
                                                            value: e,
                                                            child: Text(
                                                              e,
                                                              style: TextStyle(
                                                                fontSize: 12.sp,
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                        .toList(),
                                                onChanged: (v) {
                                                  setState(() {
                                                    _screeningTestResults[test] =
                                                        v!;
                                                    if (test == 'HPV' &&
                                                        v != 'Negative') {
                                                      _hpvRiskLevel = null;
                                                    }
                                                  });
                                                },
                                              ),
                                            ),
                                            if (test == 'HPV' &&
                                                _screeningTestResults['HPV'] ==
                                                    'Negative')
                                              SizedBox(
                                                width: 140.w,
                                                child: DropdownButtonFormField<
                                                  String
                                                >(
                                                  isExpanded: true,
                                                  value: _hpvRiskLevel,
                                                  isDense: true,
                                                  decoration: InputDecoration(
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 12.w,
                                                          vertical: 10.h,
                                                        ),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8.r,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color: Colors
                                                            .grey
                                                            .shade300,
                                                      ),
                                                    ),
                                                    enabledBorder: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8.r,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color: Colors
                                                            .grey
                                                            .shade300,
                                                      ),
                                                    ),
                                                    focusedBorder: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8.r,
                                                          ),
                                                      borderSide: const BorderSide(
                                                        color: AppTheme
                                                            .primaryBlue,
                                                      ),
                                                    ),
                                                  ),
                                                  hint: Text(
                                                    'Risk Level',
                                                    style: TextStyle(
                                                      fontSize: 12.sp,
                                                    ),
                                                  ),
                                                  items:
                                                      ['High Risk', 'Low Risk']
                                                          .map(
                                                            (
                                                              e,
                                                            ) => DropdownMenuItem(
                                                              value: e,
                                                              child: Text(
                                                                e,
                                                                style: TextStyle(
                                                                  fontSize: 12.sp,
                                                                ),
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
                                        ),
                                      );
                                    })
                                    .toList(),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HPV Vaccinated?',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Radio<bool>(
                                value: true,
                                groupValue: _hpvVaccinated,
                                onChanged: (v) => setState(
                                  () => _hpvVaccinated = _hpvVaccinated == true
                                      ? null
                                      : true,
                                ),
                                toggleable: true,
                                activeColor: AppTheme.primaryBlue,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                              SizedBox(width: 4.w),
                              Text('Yes', style: TextStyle(fontSize: 11.sp)),
                              SizedBox(width: 16.w),
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
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                              SizedBox(width: 4.w),
                              Text('No', style: TextStyle(fontSize: 11.sp)),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth >= 600) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    'Any other medical condition?',
                                    'Describe condition if any',
                                    initialValue: _otherMedCondition,
                                    onChanged: (v) => _otherMedCondition = v,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: _buildTextField(
                                    'Family history of cancer?',
                                    'Relation & Type of Cancer',
                                    initialValue: _familyCancer,
                                    onChanged: (v) => _familyCancer = v,
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                _buildTextField(
                                  'Any other medical condition?',
                                  'Describe condition if any',
                                  initialValue: _otherMedCondition,
                                  onChanged: (v) => _otherMedCondition = v,
                                ),
                                _buildTextField(
                                  'Family history of cancer?',
                                  'Relation & Type of Cancer',
                                  initialValue: _familyCancer,
                                  onChanged: (v) => _familyCancer = v,
                                ),
                              ],
                            );
                          }
                        },
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Symptoms',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.h),
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
                                  'Ulcers in external anogenital region',
                                  _symptoms,
                                ),
                              ),
                              Expanded(
                                child: _buildCheckbox(
                                  'Lower abdominal pain',
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
                          Row(
                            children: [
                              Expanded(
                                child: _buildCheckbox(
                                  'Intermenstrual bleeding',
                                  _symptoms,
                                ),
                              ),
                              Expanded(
                                child: _buildCheckbox(
                                  'Low back ache',
                                  _symptoms,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      _buildTextField(
                        'Other Symptom',
                        'Enter other custom symptoms...',
                        prefixIcon: null,
                        initialValue: _otherSymptomController.text,
                        isRequired: false,
                        onChanged: (v) => _otherSymptomController.text = v,
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Any substance usage?',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.h),
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
                            child: _buildCheckbox(
                              'Betel Leaf',
                              _substanceUsage,
                            ),
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
                      SizedBox(height: 16.h),

                      // Section 3: Menstrual & Sexual History
                      _buildSectionHeader(
                        'Menstrual & Sexual History',
                        icon: Icons.favorite_outline,
                      ),
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
                            prefixIcon: Icons.history_toggle_off,
                            onClear: () =>
                                setState(() => _menopauseStatus = 'Select'),
                            onChanged: (v) =>
                                setState(() => _menopauseStatus = v!),
                          ),
                          _buildDateField(
                            'Date of LMP',
                            'DD-MM-YYYY',
                            enabled: _menopauseStatus == 'Select' ||
                                _menopauseStatus.isEmpty,
                            value: _lmpDate,
                            onChanged: (v) => setState(() => _lmpDate = v),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),

                      // Sexually active question on top, options underneath
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sexually active?',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Wrap(
                            spacing: 12.w,
                            runSpacing: 4.h,
                            children: ['Yes', 'No', 'Undisclosed'].map(
                              (e) => Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Radio<String>(
                                    value: e,
                                    groupValue: _sexuallyActive,
                                    toggleable: true,
                                    onChanged: (v) => setState(
                                      () => _sexuallyActive = v ?? '',
                                    ),
                                    activeColor: AppTheme.primaryBlue,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    e,
                                    style: TextStyle(fontSize: 11.sp),
                                  ),
                                  SizedBox(width: 16.w),
                                ],
                              ),
                            ).toList(),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),

                      // Multiple sexual partners question on top, options underneath
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Multiple sexual partners?',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Wrap(
                            spacing: 12.w,
                            runSpacing: 4.h,
                            children: ['Yes', 'No', 'Undisclosed'].map(
                              (e) => Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Radio<String>(
                                    value: e,
                                    groupValue: _multiplePartners,
                                    toggleable: true,
                                    onChanged: (v) => setState(
                                      () => _multiplePartners = v ?? '',
                                    ),
                                    activeColor: AppTheme.primaryBlue,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    e,
                                    style: TextStyle(fontSize: 11.sp),
                                  ),
                                  SizedBox(width: 16.w),
                                ],
                              ),
                            ).toList(),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),

                      // Age at marriage question on top, options underneath
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Age at marriage / first sexual intercourse (In years)',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Checkbox(
                                value: _ageUndisclosed,
                                onChanged: (v) {
                                  setState(() {
                                    _ageUndisclosed = v == true;
                                    if (_ageUndisclosed) {
                                      _firstIntimateAge = '';
                                      _ageAtMarriage = '';
                                    }
                                  });
                                },
                                activeColor: AppTheme.primaryBlue,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'Undisclosed',
                                style: TextStyle(fontSize: 11.sp),
                              ),
                            ],
                          ),
                          if (!_ageUndisclosed) ...[
                            SizedBox(height: 6.h),
                            SizedBox(
                              width: 140.w,
                              child: _buildTextField(
                                '',
                                'Age in years',
                                enabled: !_ageUndisclosed,
                                type: TextInputType.number,
                                initialValue: _firstIntimateAge,
                                maxLength: 3,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (v) {
                                  _firstIntimateAge = v;
                                  _ageAtMarriage = v;
                                },
                                validator: (val) {
                                  if (!_ageUndisclosed &&
                                      val != null &&
                                      val.trim().isNotEmpty) {
                                    final num = int.tryParse(val.trim());
                                    if (num == null || num < 0) {
                                      return 'Must be >= 0';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 16.h),

                      // Section 4: Obstetric History
                      _buildSectionHeader(
                        'Obstetric History',
                        icon: Icons.child_care_outlined,
                      ),
                      ResponsiveGridRow(
                        children: [
                          _buildTextField(
                            'Total Pregnancies',
                            '0',
                            type: TextInputType.number,
                            initialValue: _totalPregnancies,
                            maxLength: 2,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (v) => _totalPregnancies = v,
                            validator: (val) {
                              if (val != null && val.isNotEmpty) {
                                final num = int.tryParse(val);
                                if (num == null || num < 0 || num > 99) {
                                  return '0-99';
                                }
                              }
                              return null;
                            },
                          ),
                          _buildTextField(
                            'Normal Deliveries',
                            '0',
                            type: TextInputType.number,
                            initialValue: _normalDeliveries,
                            maxLength: 2,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (v) => _normalDeliveries = v,
                            validator: (val) {
                              if (val != null && val.isNotEmpty) {
                                final num = int.tryParse(val);
                                if (num == null || num < 0 || num > 99) {
                                  return '0-99';
                                }
                              }
                              return null;
                            },
                          ),
                          _buildTextField(
                            'Pre-term Deliveries',
                            '0',
                            type: TextInputType.number,
                            initialValue: _pretermDeliveries,
                            maxLength: 2,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (v) => _pretermDeliveries = v,
                            validator: (val) {
                              if (val != null && val.isNotEmpty) {
                                final num = int.tryParse(val);
                                if (num == null || num < 0 || num > 99) {
                                  return '0-99';
                                }
                              }
                              return null;
                            },
                          ),
                          _buildTextField(
                            'C-Section Deliveries',
                            '0',
                            type: TextInputType.number,
                            initialValue: _csectionDeliveries,
                            maxLength: 2,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (v) => _csectionDeliveries = v,
                            validator: (val) {
                              if (val != null && val.isNotEmpty) {
                                final num = int.tryParse(val);
                                if (num == null || num < 0 || num > 99) {
                                  return '0-99';
                                }
                              }
                              return null;
                            },
                          ),
                          _buildTextField(
                            'Abortions & Miscarriages',
                            '0',
                            type: TextInputType.number,
                            initialValue: _abortions,
                            maxLength: 2,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (v) => _abortions = v,
                            validator: (val) {
                              if (val != null && val.isNotEmpty) {
                                final num = int.tryParse(val);
                                if (num == null || num < 0 || num > 99) {
                                  return '0-99';
                                }
                              }
                              return null;
                            },
                          ),
                          _buildTextField(
                            'Live Children',
                            '0',
                            type: TextInputType.number,
                            initialValue: _liveChildren,
                            maxLength: 2,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (v) => _liveChildren = v,
                            validator: (val) {
                              if (val != null && val.isNotEmpty) {
                                final num = int.tryParse(val);
                                if (num == null || num < 0 || num > 99) {
                                  return '0-99';
                                }
                              }
                              return null;
                            },
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
                                side: const BorderSide(
                                  color: AppTheme.primaryBlue,
                                ),
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              child: Text(
                                'Save & Add new patient',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.sp,
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
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              child: Text(
                                'Save & Return to dashboard',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppTheme.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
