import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../data/dashboard_provider.dart';
import '../data/sync_service.dart';
import '../../patients/data/patients_provider.dart';
import '../../../shared/widgets/patient_card.dart';

import '../../../core/providers/connectivity_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isSyncing = false;
  String _lastSyncTime = 'Never';

  @override
  void initState() {
    super.initState();
    _loadLastSyncTime();
  }

  Future<void> _loadLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _lastSyncTime = prefs.getString('last_sync_time') ?? 'Never';
      });
    }
  }

  Future<void> _performSync(bool deleteAfter) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Sync'),
        content: Text(deleteAfter 
          ? 'Are you sure you want to sync and delete successfully synced patients from this device?' 
          : 'Are you sure you want to sync offline patients?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSyncing = true);
    try {
      await SyncService.instance.syncPatients(deleteAfterSync: deleteAfter);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sync completed successfully!')),
        );
      }
      ref.refresh(dashboardStatsProvider);
      ref.read(patientsProvider.notifier).refresh();
      _loadLastSyncTime();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(isOnlineProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final patientsAsync = ref.watch(patientsProvider);

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
          SizedBox(width: 16.w),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Offline sync banner
            Container(
              color: AppTheme.statusInProgressYellow,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.sync_disabled,
                        color: AppTheme.accentOrange,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Offline Mode',
                        style: TextStyle(
                          color: AppTheme.accentOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (_isSyncing)
                    const CircularProgressIndicator()
                  else
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _performSync(false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: AppTheme.white,
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: Icon(Icons.cloud_upload, size: 12.sp),
                          label: Text('Sync', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold)),
                        ),
                        SizedBox(width: 8.w),
                        ElevatedButton.icon(
                          onPressed: () => _performSync(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentOrange,
                            foregroundColor: AppTheme.white,
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: Icon(Icons.delete, size: 12.sp),
                          label: Text('Sync & Delete', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last synced: $_lastSyncTime',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 12.sp,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Stats Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      double ratio = constraints.maxWidth > 600 ? 3.0 : 1.8;
                      return statsAsync.when(
                        data: (stats) => GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12.w,
                          mainAxisSpacing: 12.h,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: ratio,
                          children: [
                            _StatCard(
                              title: 'Total Registered Patients',
                              value: stats.totalPatients.toString(),
                              icon: Icons.people,
                              iconColor: AppTheme.primaryBlue,
                              iconBgColor: AppTheme.primaryBlue.withOpacity(0.1),
                            ),
                            _StatCard(
                              title: 'Remaining Sync Patients',
                              value: stats.mediaFilesPending.toString(),
                              icon: Icons.cloud_upload_outlined,
                              iconColor: Colors.green,
                              iconBgColor: Colors.green.withOpacity(0.1),
                            ),
                          ],
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, __) => GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12.w,
                          mainAxisSpacing: 12.h,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: ratio,
                          children: [
                            _StatCard(
                              title: 'Total Registered Patients',
                              value: '0',
                              icon: Icons.people,
                              iconColor: AppTheme.primaryBlue,
                              iconBgColor: AppTheme.primaryBlue.withOpacity(0.1),
                            ),
                            _StatCard(
                              title: 'Remaining Sync Patients',
                              value: '0',
                              icon: Icons.cloud_upload_outlined,
                              iconColor: Colors.green,
                              iconBgColor: Colors.green.withOpacity(0.1),
                            ),
                          ],
                        ),
                      );
                    }
                  ),

                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          style: TextStyle(fontSize: 12.sp, color: AppTheme.textDark),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Search patients...',
                            hintStyle: TextStyle(fontSize: 12.sp, color: AppTheme.textLight),
                            prefixIcon: Icon(Icons.search, size: 18.sp, color: AppTheme.textLight),
                            filled: true,
                            fillColor: AppTheme.white,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(color: AppTheme.textLight.withValues(alpha: 0.2)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(color: AppTheme.textLight.withValues(alpha: 0.2)),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: AppTheme.textLight.withValues(alpha: 0.2),
                          ),
                        ),
                        child: PopupMenuButton<String>(
                          icon: Icon(Icons.filter_list, color: AppTheme.primaryBlue, size: 20.sp),
                          position: PopupMenuPosition.under,
                          onSelected: (value) {
                            // Filter logic here
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'today',
                              child: Text('Today registered'),
                            ),
                            const PopupMenuItem(
                              value: 'last_7_days',
                              child: Text('Last 7 days'),
                            ),
                            const PopupMenuItem(
                              value: 'filter_on_date',
                              child: Text('Filter on date'),
                            ),
                            const PopupMenuItem(
                              value: 'between_two_dates',
                              child: Text('Between two dates'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.push('/patient-registration');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: AppTheme.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      icon: Icon(Icons.person_add, size: 20.sp),
                      label: Text(
                        'Register New Patient',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 24.h),
                  Row(
                    children: [
                      Text(
                        'Offline Patients',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      CircleAvatar(
                        radius: 6.r,
                        backgroundColor: AppTheme.statusInProgressYellow,
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // List of offline patients wrapped in a white container
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: patientsAsync.when(
                      data: (patients) {
                        final offlinePatients = patients.where((p) => p.status == 'Pending Sync').toList();
                        if (offlinePatients.isEmpty) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 48.h),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.insert_drive_file_outlined, size: 48.sp, color: AppTheme.textLight),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'Failed to load patients',
                                    style: TextStyle(
                                      color: AppTheme.textLight,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: offlinePatients.length,
                          itemBuilder: (context, index) {
                            final patient = offlinePatients[index];
                            return PatientCard(
                              patient: patient,
                              onTap: () {
                                if (_isSelectionMode) {
                                  _toggleSelection(patient.id);
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (context) => PatientDetailsDialog(patient: patient),
                                  );
                                }
                              },
                              selectionMode: _isSelectionMode,
                              isSelected: _selectedPatientIds.contains(patient.id),
                              onLongPress: () {
                                if (!_isSelectionMode) {
                                  setState(() {
                                    _isSelectionMode = true;
                                    _selectedPatientIds.add(patient.id);
                                  });
                                }
                              },
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const Center(child: Text('Failed to load patients')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(color: AppTheme.textLight, fontSize: 11.sp),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
