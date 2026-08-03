// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DashboardStats _$DashboardStatsFromJson(Map<String, dynamic> json) =>
    _DashboardStats(
      totalPatients: (json['totalPatients'] as num?)?.toInt() ?? 0,
      reportsPrepared: (json['reportsPrepared'] as num?)?.toInt() ?? 0,
      reportsAwaited: (json['reportsAwaited'] as num?)?.toInt() ?? 0,
      mediaFilesPending: (json['mediaFilesPending'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$DashboardStatsToJson(_DashboardStats instance) =>
    <String, dynamic>{
      'totalPatients': instance.totalPatients,
      'reportsPrepared': instance.reportsPrepared,
      'reportsAwaited': instance.reportsAwaited,
      'mediaFilesPending': instance.mediaFilesPending,
    };
