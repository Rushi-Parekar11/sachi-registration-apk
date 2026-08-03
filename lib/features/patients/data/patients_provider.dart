import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/patient.dart';
import '../../../core/database/local_db_helper.dart';

class PatientsNotifier extends AsyncNotifier<List<Patient>> {
  final bool _hasMore = false;
  int _totalCount = 0;

  bool get hasMore => _hasMore;
  int get totalCount => _totalCount;

  @override
  Future<List<Patient>> build() async {
    return _fetchPatients();
  }

  Future<List<Patient>> _fetchPatients() async {
    final dbPatients = await LocalDbHelper.instance.getPatients();
    _totalCount = dbPatients.length;
    return dbPatients.map((row) {
      return Patient(
        id: row['id'] as int,
        patientName: (row['patient_name'] ?? 'Unknown') as String,
        status: row['sync_status'] == 0 ? 'Pending Sync' : 'Synced',
        age: row['age'] as int?,
      );
    }).toList();
  }

  Future<void> loadMore() async {}

  Future<void> refresh() async {
    state = const AsyncLoading<List<Patient>>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      return _fetchPatients();
    });
  }
}

final patientsProvider = AsyncNotifierProvider<PatientsNotifier, List<Patient>>(() {
  return PatientsNotifier();
});
