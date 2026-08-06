import re

with open('lib/features/patients/presentation/patient_registration_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Change ResponsiveGridRow to default to 5 columns on desktop
text = text.replace('columns = 4;', 'columns = 5;')

# 2. Add Age read-only field right after DOB
age_field = '''                  _buildTextField(
                    'Age (in Years)',
                    'NA',
                    initialValue: 'NA',
                    enabled: false,
                  ),
'''
# Find the end of DOB field
dob_field_end = "onChanged: (v) => setState(() => _dob = v),\n                    ),"
text = text.replace(dob_field_end, dob_field_end + '\n' + age_field)

# 3. Restructure the ResponsiveGridRow blocks.
# We will combine the first two ResponsiveGridRow blocks into one giant one so fields flow naturally.
# The first block ends with Aadhaar.
# The second block starts with ABHA.
# The separator is:
#                   ],
#                 ),
#                 _buildSectionHeader('Address & Identification'),
#                 ResponsiveGridRow(
#                   children: [

separator = '''                  ],
                ),
                _buildSectionHeader('Address & Identification'),
                ResponsiveGridRow(
                  children: ['''

# Replace the separator with just nothing (so they merge into one children list)
text = text.replace(separator, '')

with open('lib/features/patients/presentation/patient_registration_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)
print('Done!')
