import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../features/patients/domain/patient.dart';

class PatientCard extends StatelessWidget {
  final Patient patient;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selectionMode;
  final bool isSelected;

  const PatientCard({
    super.key,
    required this.patient,
    this.onTap,
    this.onLongPress,
    this.selectionMode = false,
    this.isSelected = false,
  });

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'new':
        return AppTheme.statusNewBlue;
      case 'in progress':
        return AppTheme.statusInProgressYellow;
      case 'completed':
      case 'complete':
        return AppTheme.statusCompleteGreen;
      case 'negative':
        return AppTheme.statusCompleteGreen;
      case 'positive':
        return AppTheme.accentOrange;
      default:
        return AppTheme.backgroundLight;
    }
  }

  Color _getStatusTextColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'new':
        return AppTheme.statusNewText;
      case 'in progress':
        return AppTheme.statusInProgressText;
      case 'completed':
      case 'complete':
        return AppTheme.statusCompleteText;
      case 'negative':
        return AppTheme.statusCompleteText;
      case 'positive':
        return AppTheme.white;
      default:
        return AppTheme.textLight;
    }
  }

  Widget _buildStatusChip(String text) {
    return Container(
      margin: EdgeInsets.only(left: 4.w),
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 4.h),
      width: 70.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _getStatusColor(text),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          style: TextStyle(
            color: _getStatusTextColor(text),
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryBlue : AppTheme.textLight.withOpacity(0.1),
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              if (selectionMode)
                Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: IgnorePointer(
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (val) {},
                      activeColor: AppTheme.primaryBlue,
                    ),
                  ),
                ),
              CircleAvatar(
                radius: 20.r,
                backgroundColor: AppTheme.primaryBlue,
                child: Text(
                  patient.id.toString(),
                  style: TextStyle(
                    color: AppTheme.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 8.sp,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.patientName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                        color: AppTheme.textDark,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Registration date: ${patient.lastVisitDate?.split('T').first ?? "N/A"}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Age: ${patient.age ?? "N/A"}',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
