import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/patient.dart';

class PatientDetailsDialog extends StatelessWidget {
  final Patient patient;

  const PatientDetailsDialog({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 400.w,
        color: AppTheme.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              color: AppTheme.primaryBlue,
              padding: EdgeInsets.all(20.w),
              child: Row(
                children: [
                  Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      color: AppTheme.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(Icons.person, color: AppTheme.white, size: 28.sp),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              patient.patientName,
                              style: TextStyle(
                                color: AppTheme.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (patient.age != null) ...[
                              SizedBox(width: 8.w),
                              Text(
                                'Age: ${patient.age}',
                                style: TextStyle(
                                  color: AppTheme.white.withOpacity(0.9),
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Patient ID: ${patient.id}',
                          style: TextStyle(
                            color: AppTheme.white.withOpacity(0.9),
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: AppTheme.white),
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Screening History',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  
                  // Screenings List
                  if (patient.screenings == null || patient.screenings!.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      child: Text(
                        'No screenings available.',
                        style: TextStyle(color: AppTheme.textLight, fontSize: 12.sp),
                      ),
                    )
                  else
                    ...patient.screenings!.asMap().entries.map((entry) => _buildScreeningItem(entry.value, entry.key + 1)),
                ],
              ),
            ),
            
            Divider(height: 1, color: AppTheme.textLight.withOpacity(0.2)),

            // Footer Actions
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.delete_outline, color: AppTheme.accentOrange, size: 16.sp),
                    label: Text(
                      'Delete patient',
                      style: TextStyle(color: AppTheme.textDark, fontSize: 12.sp),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.accentOrange),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.add, size: 16.sp),
                    label: Text('New screening', style: TextStyle(fontSize: 12.sp)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: AppTheme.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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

  Widget _buildScreeningItem(Screening screening, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.primaryBlue, width: 1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Screening $index',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  screening.date.split('T').first,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppTheme.statusCompleteGreen,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              screening.status,
              style: TextStyle(
                color: AppTheme.statusCompleteText,
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Icon(Icons.remove_red_eye_outlined, size: 20.sp, color: AppTheme.textDark),
          SizedBox(width: 12.w),
          Icon(Icons.delete_outline, size: 20.sp, color: AppTheme.textDark),
        ],
      ),
    );
  }
}
