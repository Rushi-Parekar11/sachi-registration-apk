import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/dashboard_stats.dart';
import '../../../core/database/local_db_helper.dart';

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final stats = await LocalDbHelper.instance.getDashboardStats();
  
  return DashboardStats(
    totalPatients: stats['total'] ?? 0,
    reportsPrepared: 0,
    reportsAwaited: 0,
    mediaFilesPending: stats['pendingSync'] ?? 0,
  );
});
