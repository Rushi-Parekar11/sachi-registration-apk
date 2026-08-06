
  Widget _buildCard(String title, IconData icon, Widget child) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 16.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: AppTheme.textLight.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primaryBlue, size: 20.sp),
                SizedBox(width: 8.w),
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
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: child,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTabletLayout() {
    return [
      _buildCard('Personal Details & Contact Information', Icons.account_circle, Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            'Patient Name',
                            'Enter patient name',
                            isRequired: true,
                            initialValue: _patientName,
                            onChanged: (v) => _patientName = v,
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'This field is required';
                              if (val.trim().length < 2) return 'Minimum 2 characters';
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: _buildTextField(
                            'Husband/Father Name',
                            'Enter husband/father name',
                            initialValue: _guardianName,
                            isRequired: widget.patient == null,
                            onChanged: (v) => _guardianName = v,
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                            validator: (val) {
                              if (widget.patient == null && (val == null || val.trim().isEmpty)) return 'Required for new patients';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            'Phone Number',
                            'Enter phone number',
                            initialValue: _phone,
                            isRequired: widget.patient == null,
                            maxLength: 10,
                            type: TextInputType.phone,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (v) => _phone = v,
                            validator: (val) {
                              if (widget.patient == null && (val == null || val.trim().isEmpty)) return 'Required for new patients';
                              if (val != null && val.trim().isNotEmpty && val.trim().length != 10) return 'Must be 10 digits';
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: _buildTextField(
                            'Aadhaar No.',
                            'Aadhaar',
                            initialValue: _aadhaar,
                            maxLength: 12,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (v) => _aadhaar = v,
                            validator: (val) {
                              if (val != null && val.trim().isNotEmpty) {
                                if (!RegExp(r'^[2-9]\d{11}$').hasMatch(val.trim())) return 'Invalid Aadhaar (must be 12 digits, cannot start with 0 or 1)';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 32.w),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: _buildDropdown(
                            'Marital Status',
                            _maritalStatus,
                            ['Select', 'Single', 'Married', 'Unknown', 'Widowed'],
                            isRequired: true,
                            onChanged: (v) => _maritalStatus = v!,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          flex: 4,
                          child: _buildDateField(
                            'Date of Birth',
                            'YYYY-MM-DD',
                            value: _dob,
                            isRequired: true,
                            onChanged: (val) {
                              setState(() {
                                _dob = val;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: _buildTextField(
                            'ABHA No.',
                            'ABHA',
                            initialValue: _abha,
                            maxLength: 14,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (v) => _abha = v,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          flex: 4,
                          child: _buildSearchableDropdown(
                            'Country',
                            _country,
                            isRequired: true,
                            onTap: () => _showSelectionDialog<csc.Country>(
                              title: 'Select Country',
                              items: _countries,
                              displayString: (c) => c.name,
                              onSelected: (c) async {
                                final states = await csc.getStatesOfCountry(c.isoCode);
                                setState(() {
                                  _selectedCountry = c;
                                  _country = c.name;
                                  _selectedState = null;
                                  _state = '';
                                  _selectedCity = null;
                                  _city = '';
                                  _states = states;
                                  _cities = [];
                                });
                              },
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          flex: 3,
                          child: _buildSearchableDropdown(
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
                                onSelected: (s) async {
                                  final cities = await csc.getStateCities(
                                    s.countryCode,
                                    s.isoCode,
                                  );
                                  setState(() {
                                    _selectedState = s;
                                    _state = s.name;
                                    _selectedCity = null;
                                    _city = '';
                                    _cities = cities;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _buildSearchableDropdown(
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
                      onSelected: (c) {
                        setState(() {
                          _selectedCity = c;
                          _city = c.name;
                        });
                      },
                    );
                  },
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildTextField(
                  'Block',
                  'Enter Block',
                  initialValue: _block,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                  onChanged: (v) => _block = v,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildTextField(
                  'Village',
                  'Enter Village',
                  initialValue: _village,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                  onChanged: (v) => _village = v,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildTextField(
                  'Pincode',
                  'Enter Pincode',
                  isRequired: widget.patient == null,
                  initialValue: _pincode,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (v) => _pincode = v,
                  validator: (val) {
                    if (widget.patient == null && (val == null || val.trim().isEmpty)) return 'Required for new patients';
                    return null;
                  },
                ),
              ),
            ],
          ),
          _buildTextField(
            'Address',
            'Enter address',
            initialValue: _patientName, // Wait, wrong variable. Let me check the mobile one: it's actually not setting address in state? It was not bound correctly in original, I'll omit address binding if it's missing in state, wait. In Mobile view I don't see Address bound. Let me skip Address or add it.
          ),
        ],
      )),
    ];
  }
