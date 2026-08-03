import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDbHelper {
  static final LocalDbHelper instance = LocalDbHelper._init();
  static Database? _database;

  LocalDbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sachi_local.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('DROP TABLE IF EXISTS local_patient_history');
        await db.execute('DROP TABLE IF EXISTS local_patients');
        await _createDB(db, newVersion);
      },
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT';
    const intType = 'INTEGER';
    const boolType = 'INTEGER'; // SQLite uses 0 and 1 for booleans

    await db.execute('''
CREATE TABLE local_patients (
  id $idType,
  mrn $textType,
  patient_name $textType,
  gaurdian_name $textType,
  date_of_birth $textType,
  age $intType,
  maratial_status $textType,
  occupation $textType,
  residential_status $textType,
  mobile_number $intType,
  aadhaar_number $textType,
  abha_number $textType,
  mail $textType,
  country $textType,
  state $textType,
  city $textType,
  pincode $textType,
  block $textType,
  village $textType,
  address $textType,
  add_line_1 $textType,
  add_line_2 $textType,
  sync_status $intType
)
''');

    await db.execute('''
CREATE TABLE local_patient_history (
  id $idType,
  patient_id $intType,
  hpv_test $boolType,
  other_med_condition $textType,
  family_cervical_cancer $textType,
  lmp_date $textType,
  menopause_status $textType,
  intimately_active $textType,
  multiple_intimate_partners $textType,
  first_intimate_age $intType,
  no_pregnancies $intType,
  no_normal_deliveries $intType,
  no_csection_deliveries $intType,
  no_preterm_deliveries $intType,
  no_miscarriages $intType,
  live_children $intType,
  
  -- The following two are kept locally to support the 'mappings' object needed by the backend API:
  symptoms_mapping $textType,
  screening_history_mapping $textType,
  substance_usage $textType,
  
  FOREIGN KEY (patient_id) REFERENCES local_patients (id) ON DELETE CASCADE
)
''');
  }

  Future<int> insertPatient(Map<String, dynamic> patient) async {
    final db = await instance.database;
    return await db.insert('local_patients', patient);
  }

  Future<int> insertPatientHistory(Map<String, dynamic> history) async {
    final db = await instance.database;
    return await db.insert('local_patient_history', history);
  }

  Future<List<Map<String, dynamic>>> getPatients() async {
    final db = await instance.database;
    return await db.query('local_patients', orderBy: 'id DESC');
  }

  Future<Map<String, dynamic>?> getPatientDetails(int id) async {
    final db = await instance.database;
    final patientRes = await db.query('local_patients', where: 'id = ?', whereArgs: [id]);
    if (patientRes.isEmpty) return null;
    
    final historyRes = await db.query('local_patient_history', where: 'patient_id = ?', whereArgs: [id]);
    
    return {
      ...patientRes.first,
      'history': historyRes.isNotEmpty ? historyRes.first : null,
    };
  }

  Future<void> updatePatient(int id, Map<String, dynamic> patient, Map<String, dynamic> history) async {
    final db = await instance.database;
    await db.update('local_patients', patient, where: 'id = ?', whereArgs: [id]);
    await db.update('local_patient_history', history, where: 'patient_id = ?', whereArgs: [id]);
  }

  Future<Map<String, int>> getDashboardStats() async {
    final db = await instance.database;
    final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM local_patients');
    final syncResult = await db.rawQuery('SELECT COUNT(*) as count FROM local_patients WHERE sync_status = 0');
    
    int total = Sqflite.firstIntValue(totalResult) ?? 0;
    int pendingSync = Sqflite.firstIntValue(syncResult) ?? 0;
    
    return {
      'total': total,
      'pendingSync': pendingSync,
    };
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
