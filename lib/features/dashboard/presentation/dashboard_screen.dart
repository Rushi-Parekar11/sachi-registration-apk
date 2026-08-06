import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../data/dashboard_provider.dart';
import '../data/sync_service.dart';
import '../../../core/database/local_db_helper.dart';
import '../../patients/data/patients_provider.dart';
import '../../../shared/widgets/patient_card.dart';

import '../../../core/providers/connectivity_provider.dart';
import '../../patients/presentation/widgets/patient_details_dialog.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isSyncing = false;
  double _syncProgress = 0.0;
  String _lastSyncTime = 'Never';
  bool _isSelectionMode = false;
  final Set<int> _selectedPatientIds = {};
  String _searchQuery = '';
  String _dateFilter = 'all'; 
  DateTime? _selectedCustomDate;

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedPatientIds.contains(id)) {
        _selectedPatientIds.remove(id);
        if (_selectedPatientIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedPatientIds.add(id);
      }
    });
  }

  Future<void> _deleteSelectedPatients() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Patients'),
        content: Text(
          'Are you sure you want to delete ${_selectedPatientIds.length} offline patient(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await LocalDbHelper.instance.deletePatients(_selectedPatientIds.toList());
      setState(() {
        _isSelectionMode = false;
        _selectedPatientIds.clear();
      });
      ref.refresh(patientsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Patients deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting patients: $e')));
      }
    }
  }

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
        content: Text(
          deleteAfter
              ? 'Are you sure you want to sync and delete successfully synced patients from this device?'
              : 'Are you sure you want to sync offline patients?',
        ),
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

    setState(() {
      _isSyncing = true;
      _syncProgress = 0.0;
    });
    try {
      await SyncService.instance.syncPatients(
        deleteAfterSync: deleteAfter,
        onProgress: (current, total) {
          if (mounted) {
            setState(() {
              _syncProgress = total > 0 ? (current / total) : 0.0;
            });
          }
        },
      );
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sync failed: $e')));
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
        actions: [SizedBox(width: 16.w)],
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
                    Row(
                      children: [
                        SizedBox(
                          width: 80.w,
                          child: LinearProgressIndicator(
                            value: _syncProgress,
                            backgroundColor: AppTheme.white,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '${(_syncProgress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentOrange,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _performSync(false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: AppTheme.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 4.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: Icon(Icons.cloud_upload, size: 12.sp),
                          label: Text(
                            'Sync',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                  statsAsync.when(
                    data: (stats) => Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Total Registered Patients',
                            value: stats.totalPatients.toString(),
                            icon: Icons.people,
                            iconColor: AppTheme.primaryBlue,
                            iconBgColor: AppTheme.primaryBlue.withOpacity(0.1),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _StatCard(
                            title: 'Remaining Sync Patients',
                            value: stats.mediaFilesPending.toString(),
                            icon: Icons.cloud_upload_outlined,
                            iconColor: Colors.green,
                            iconBgColor: Colors.green.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Total Registered Patients',
                            value: '0',
                            icon: Icons.people,
                            iconColor: AppTheme.primaryBlue,
                            iconBgColor: AppTheme.primaryBlue.withOpacity(0.1),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _StatCard(
                            title: 'Remaining Sync Patients',
                            value: '0',
                            icon: Icons.cloud_upload_outlined,
                            iconColor: Colors.green,
                            iconBgColor: Colors.green.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppTheme.textDark,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Search patients...',
                            hintStyle: TextStyle(
                              fontSize: 12.sp,
                              color: AppTheme.textLight,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              size: 18.sp,
                              color: AppTheme.textLight,
                            ),
                            filled: true,
                            fillColor: AppTheme.white,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 12.h,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                color: AppTheme.textLight.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                color: AppTheme.textLight.withValues(
                                  alpha: 0.2,
                                ),
                              ),
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
                          icon: Icon(
                            Icons.filter_list,
                            color: AppTheme.primaryBlue,
                            size: 20.sp,
                          ),
                          position: PopupMenuPosition.under,
                          onSelected: (value) async {
                            if (value == 'filter_on_date') {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedCustomDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  _dateFilter = 'filter_on_date';
                                  _selectedCustomDate = picked;
                                });
                              }
                            } else {
                              setState(() {
                                _dateFilter = value;
                                _selectedCustomDate = null;
                              });
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'all',
                              child: Text('All time'),
                            ),
                            const PopupMenuItem(
                              value: 'today',
                              child: Text('Today registered'),
                            ),
                            const PopupMenuItem(
                              value: 'last_7_days',
                              child: Text('Last 7 days'),
                            ),
                            PopupMenuItem(
                              value: 'filter_on_date',
                              child: Text(
                                _dateFilter == 'filter_on_date' && _selectedCustomDate != null 
                                    ? 'Date: ${_selectedCustomDate!.toIso8601String().split('T')[0]}' 
                                    : 'Select date'
                              ),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Offline patients (${patientsAsync.value?.where((p) => p.status == 'Pending Sync').length ?? 0})',
                            style: TextStyle(
                              fontSize: 14.sp,
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
                      if (_isSelectionMode)
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                final offlinePatients =
                                    patientsAsync.value
                                        ?.where(
                                          (p) => p.status == 'Pending Sync',
                                        )
                                        .toList() ??
                                    [];
                                setState(() {
                                  if (_selectedPatientIds.length ==
                                      offlinePatients.length) {
                                    _selectedPatientIds.clear();
                                  } else {
                                    _selectedPatientIds.addAll(
                                      offlinePatients.map((p) => p.id),
                                    );
                                  }
                                });
                              },
                              icon: Icon(
                                Icons.done_all,
                                size: 16.sp,
                                color: AppTheme.primaryBlue,
                              ),
                              label: Text(
                                'Select All',
                                style: TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _selectedPatientIds.isEmpty
                                  ? null
                                  : _deleteSelectedPatients,
                              icon: Icon(
                                Icons.delete_outline,
                                color: _selectedPatientIds.isEmpty
                                    ? Colors.grey
                                    : Colors.red,
                                size: 20.sp,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            SizedBox(width: 8.w),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _isSelectionMode = false;
                                  _selectedPatientIds.clear();
                                });
                              },
                              icon: Icon(
                                Icons.close,
                                color: AppTheme.textDark,
                                size: 20.sp,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
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
                        var offlinePatients = patients
                            .where((p) => p.status == 'Pending Sync')
                            .toList();
                            
                        if (_searchQuery.isNotEmpty) {
                          offlinePatients = offlinePatients.where((p) {
                            return (p.patientName).toLowerCase().contains(_searchQuery);
                          }).toList();
                        }
                        
                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);
                        
                        if (_dateFilter == 'today') {
                          offlinePatients = offlinePatients.where((p) {
                            if (p.lastVisitDate == null) return false;
                            try {
                              final d = DateTime.parse(p.lastVisitDate!);
                              return d.year == today.year && d.month == today.month && d.day == today.day;
                            } catch (_) { return false; }
                          }).toList();
                        } else if (_dateFilter == 'last_7_days') {
                          final sevenDaysAgo = today.subtract(const Duration(days: 7));
                          offlinePatients = offlinePatients.where((p) {
                            if (p.lastVisitDate == null) return false;
                            try {
                              final d = DateTime.parse(p.lastVisitDate!);
                              return d.isAfter(sevenDaysAgo) || d.isAtSameMomentAs(sevenDaysAgo);
                            } catch (_) { return false; }
                          }).toList();
                        } else if (_dateFilter == 'filter_on_date' && _selectedCustomDate != null) {
                          final target = _selectedCustomDate!;
                          offlinePatients = offlinePatients.where((p) {
                            if (p.lastVisitDate == null) return false;
                            try {
                              final d = DateTime.parse(p.lastVisitDate!);
                              return d.year == target.year && d.month == target.month && d.day == target.day;
                            } catch (_) { return false; }
                          }).toList();
                        }

                        if (offlinePatients.isEmpty) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 48.h),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.insert_drive_file_outlined,
                                    size: 48.sp,
                                    color: AppTheme.textLight,
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'No offline patient registered.',
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
                                  context.push(
                                    '/patient-registration',
                                    extra: patient,
                                  );
                                }
                              },
                              selectionMode: _isSelectionMode,
                              isSelected: _selectedPatientIds.contains(
                                patient.id,
                              ),
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
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const Center(
                        child: Text('No offline patient registered.'),
                      ),
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
            child: Icon(icon, color: iconColor, size: 24.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
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
