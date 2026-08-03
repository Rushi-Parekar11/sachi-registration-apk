import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../data/patients_provider.dart';
import '../../../shared/widgets/patient_card.dart';
import '../../../core/providers/connectivity_provider.dart';

import '../domain/patient.dart';
import 'widgets/patient_details_dialog.dart';
import 'patient_registration_screen.dart';

class PatientsScreen extends ConsumerStatefulWidget {
  const PatientsScreen({super.key});

  @override
  ConsumerState<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends ConsumerState<PatientsScreen> {
  String? _selectedStatus = 'All';
  String? _selectedViaResult = 'All';

  Widget _buildHeaderDropdown(String title, String? currentValue, List<String> options, ValueChanged<String?> onChanged) {
    bool isActive = currentValue != null && currentValue != 'All';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PopupMenuButton<String>(
          initialValue: currentValue ?? 'All',
          onSelected: onChanged,
          child: Row(
            children: [
              Text(
                isActive ? currentValue! : title,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isActive ? AppTheme.primaryBlue : AppTheme.textLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.arrow_drop_down, size: 16.sp, color: isActive ? AppTheme.primaryBlue : AppTheme.textLight),
            ],
          ),
          itemBuilder: (context) {
            return options.map((option) {
              return PopupMenuItem<String>(
                value: option,
                child: Text(option, style: TextStyle(fontSize: 12.sp)),
              );
            }).toList();
          },
        ),
        if (isActive)
          GestureDetector(
            onTap: () => onChanged('All'),
            child: Padding(
              padding: EdgeInsets.only(left: 2.w),
              child: Icon(Icons.close, size: 14.sp, color: AppTheme.accentOrange),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(patientsProvider);
    final isOnline = ref.watch(isOnlineProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppTheme.white),
            SizedBox(width: 8.w),
            Text(
              'SACHI',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp),
            ),
            SizedBox(width: 16.w),
            if (!isOnline)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off, size: 12.sp, color: AppTheme.white),
                    SizedBox(width: 4.w),
                    Text(
                      'Offline',
                      style: TextStyle(fontSize: 10.sp, color: AppTheme.white),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: AppTheme.white),
            onPressed: () {},
          ),
          CircleAvatar(
            radius: 16.r,
            backgroundColor: AppTheme.white.withOpacity(0.2),
            child: Text(
              'TA',
              style: TextStyle(color: AppTheme.white, fontSize: 12.sp),
            ),
          ),
          SizedBox(width: 16.w),
        ],
      ),
      body: patientsAsync.when(
        data: (patients) {
          var filteredPatients = patients;
          if (_selectedStatus != 'All') {
            filteredPatients = filteredPatients.where((p) => p.status.toLowerCase().replaceAll(' ', '') == _selectedStatus!.toLowerCase().replaceAll(' ', '')).toList();
          }
          if (_selectedViaResult != 'All') {
            filteredPatients = filteredPatients.where((p) {
              final via = p.viaTestResult?.isNotEmpty == true ? p.viaTestResult! : 'N/A';
              return via.toLowerCase() == _selectedViaResult!.toLowerCase();
            }).toList();
          }

          return Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '(${filteredPatients.length} shown, ${patients.length} of ${ref.read(patientsProvider.notifier).totalCount} loaded)',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Search Bar & Filter
                Row(
                  children: [
                    // Search Bar (approx 80%)
                    Expanded(
                      flex: 8,
                      child: Container(
                        height: 40.h, // reduced height
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: AppTheme.textLight.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search,
                              color: AppTheme.textLight,
                              size: 18.sp,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search by name...',
                                  hintStyle: TextStyle(
                                    color: AppTheme.textLight,
                                    fontSize: 14.sp,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // Filter Icon (approx 20%)
                    Expanded(
                      flex: 2,
                      child: PopupMenuButton<String>(
                        icon: Container(
                          height: 40.h,
                          decoration: BoxDecoration(
                            color: AppTheme.white,
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: AppTheme.textLight.withOpacity(0.2),
                            ),
                          ),
                          child: Icon(Icons.filter_list, color: AppTheme.primaryBlue, size: 20.sp),
                        ),
                        offset: const Offset(0, 45),
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 'all', child: Text('All time', style: TextStyle(fontSize: 14.sp))),
                          PopupMenuItem(value: '7days', child: Text('Last 7 days', style: TextStyle(fontSize: 14.sp))),
                          PopupMenuItem(value: '30days', child: Text('Last 30 days', style: TextStyle(fontSize: 14.sp))),
                          PopupMenuItem(value: 'custom', child: Text('Custom Date Range', style: TextStyle(fontSize: 14.sp))),
                        ],
                        onSelected: (value) {
                          // TODO: implement date filtering logic
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),

                // Column Headers
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Row(
                    children: [
                      SizedBox(width: 48.w, child: Text('ID', style: TextStyle(fontSize: 12.sp, color: AppTheme.textLight, fontWeight: FontWeight.bold))),
                      Expanded(child: Text('Name', style: TextStyle(fontSize: 12.sp, color: AppTheme.textLight, fontWeight: FontWeight.bold))),
                      _buildHeaderDropdown('Status', _selectedStatus, ['All', 'New', 'In progress', 'Completed'], (val) {
                        setState(() => _selectedStatus = val);
                      }),
                      SizedBox(width: 8.w),
                      _buildHeaderDropdown('VIA test', _selectedViaResult, ['All', 'Positive', 'Negative', 'Suspicious'], (val) {
                        setState(() => _selectedViaResult = val);
                      }),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),

                // List
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredPatients.length + 1,
                    itemBuilder: (context, index) {
                      if (index == filteredPatients.length) {
                        final notifier = ref.read(patientsProvider.notifier);
                        if (notifier.hasMore) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            child: Center(
                              child: TextButton(
                                onPressed: () {
                                  notifier.loadMore();
                                },
                                child: Text('Load next 100 patients'),
                              ),
                            ),
                          );
                        } else {
                          return SizedBox.shrink();
                        }
                      }
                      
                      final patient = filteredPatients[index];
                      return PatientCard(
                        patient: patient,
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => PatientDetailsDialog(patient: patient),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String hint;

  const _FilterDropdown(this.hint);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppTheme.textLight.withOpacity(0.2)),
      ),
      child: Center(
        child: Text(
          hint,
          style: TextStyle(color: AppTheme.textLight, fontSize: 12.sp),
        ),
      ),
    );
  }
}
