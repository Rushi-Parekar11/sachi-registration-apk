import re

with open('lib/features/patients/presentation/patient_registration_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Expanded sections state
content = content.replace('final _scrollController = ScrollController();',
'''final _scrollController = ScrollController();
  final Map<String, bool> _expandedSections = {
    'personal': true,
    'address': true,
    'reproductive': true,
    'menstrual': true,
    'obstetric': true,
  };''')

# 2. Add _buildCollapsibleSection
build_section_header = '''  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryBlue,
        ),
      ),
    );
  }'''

build_collapsible_section = '''  Widget _buildCollapsibleSection(String id, String title, IconData icon, Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(title),
              child,
            ],
          );
        } else {
          bool isExpanded = _expandedSections[id] ?? true;
          return Card(
            elevation: 0,
            margin: EdgeInsets.only(bottom: 16.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
              side: BorderSide(color: AppTheme.textLight.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _expandedSections[id] = !isExpanded;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundLight,
                      borderRadius: isExpanded 
                          ? BorderRadius.vertical(top: Radius.circular(12.r))
                          : BorderRadius.circular(12.r),
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
                        const Spacer(),
                        Icon(
                          isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: AppTheme.primaryBlue,
                        ),
                      ],
                    ),
                  ),
                ),
                if (isExpanded)
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: child,
                  ),
              ],
            ),
          );
        }
      },
    );
  }'''

content = content.replace(build_section_header, build_section_header + '\n\n' + build_collapsible_section)

# 3. Replace the sections inside the build method
import re

# We will use regex to find each section block.
# Since the file is well formatted, we can match from _buildSectionHeader to the next _buildSectionHeader or SizedBox(height: 32.h)

def wrap_section(match):
    full_text = match.group(0)
    # determine section type
    if 'Personal Details' in full_text:
        id = 'personal'
        icon = 'Icons.account_circle'
        title = 'Personal Details & Contact Information'
    elif 'Address' in full_text:
        id = 'address'
        icon = 'Icons.location_on'
        title = 'Address & Identification'
    elif 'Reproductive & Lifestyle History' in full_text:
        id = 'reproductive'
        icon = 'Icons.favorite'
        title = 'Reproductive & Lifestyle History'
    elif 'Menstrual & Sexual History' in full_text:
        id = 'menstrual'
        icon = 'Icons.water_drop'
        title = 'Menstrual & Sexual History'
    elif 'Obstetric History' in full_text:
        id = 'obstetric'
        icon = 'Icons.child_care'
        title = 'Obstetric History'
    else:
        return full_text
        
    # Remove the _buildSectionHeader line
    header_line_re = re.compile(r'\s*_buildSectionHeader\(.*?\),\n')
    inner_content = header_line_re.sub('', full_text, count=1)
    
    # Wrap inner_content in Column
    res = f"              _buildCollapsibleSection(\n                '{id}',\n                '{title}',\n                {icon},\n                Column(\n                  crossAxisAlignment: CrossAxisAlignment.stretch,\n                  children: [\n{inner_content}\n                  ],\n                ),\n              ),\n"
    return res

# The blocks are separated by // <Section Name> comments.
# Let's find the whole chunk inside children: [ of the main form.
# It starts at // Personal Details and ends before SizedBox(height: 32.h),

start_idx = content.find('// Personal Details')
end_idx = content.find('SizedBox(height: 32.h),', start_idx)

if start_idx != -1 and end_idx != -1:
    sections_text = content[start_idx:end_idx]
    
    # split by // 
    parts = sections_text.split('              // ')
    
    new_sections_text = ""
    for part in parts:
        if not part.strip():
            continue
        part = "              // " + part
        # wrap it
        wrapped = wrap_section(re.match(r'(?s).*?(?=\n\s*// |\Z)', part).group(0))
        new_sections_text += wrapped
        
    content = content[:start_idx] + new_sections_text + content[end_idx:]

with open('lib/features/patients/presentation/patient_registration_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done")
