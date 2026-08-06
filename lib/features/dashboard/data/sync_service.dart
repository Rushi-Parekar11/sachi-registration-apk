import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/database/local_db_helper.dart';

class SyncService {
  static final SyncService instance = SyncService._init();
  SyncService._init();

  Future<void> syncPatients({required bool deleteAfterSync}) async {
    final prefs = await SharedPreferences.getInstance();
    // Read from SharedPreferences first; fall back to DEV_TENANT_ID from .env
    final savedTenantId = prefs.getString('tenant_id')?.trim() ?? '';
    final tenantId = savedTenantId.isNotEmpty
        ? savedTenantId
        : (dotenv.env['DEV_TENANT_ID']?.trim() ?? '');

    // Read Auth Token from SharedPreferences first; fall back to AUTH_TOKEN from .env
    final savedToken = prefs.getString('auth_token')?.trim() ?? '';
    final authToken = savedToken.isNotEmpty 
        ? savedToken 
        : (dotenv.env['AUTH_TOKEN']?.trim() ?? '');

    if (tenantId.isEmpty) {
      throw Exception('Tenant ID is missing. Please set it in Settings or configure DEV_TENANT_ID in .env.');
    }

    final db = LocalDbHelper.instance;
    final pendingPatients = await db.getPatients(); // gets all patients, but we should only sync those pending

    final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3109/api/v1/sachi';
    // tenantId goes in the URL query param — matching how the web app hits the API
    final url = Uri.parse('$baseUrl/transition/patients').replace(
      queryParameters: {'tenantId': tenantId},
    );

    int syncedCount = 0;
    int failedCount = 0;
    List<int> toDeleteIds = [];
    List<String> syncErrors = [];

    for (var patient in pendingPatients) {
      if (patient['sync_status'] == 1) continue; // Already synced

      final patientId = patient['id'] as int;
      final history = await db.getPatientHistory(patientId);

      Map<String, dynamic>? cleanHistory;
      List<dynamic> symptoms = [];
      List<dynamic> screeningHistory = [];
      List<dynamic> substances = [];

      if (history != null) {
        cleanHistory = Map.from(history);
        
        if (cleanHistory.containsKey('symptoms_mapping')) {
          try {
            symptoms = jsonDecode(cleanHistory['symptoms_mapping'] as String);
          } catch (_) {}
          cleanHistory.remove('symptoms_mapping');
        }
        if (cleanHistory.containsKey('screening_history_mapping')) {
          try {
            screeningHistory = jsonDecode(cleanHistory['screening_history_mapping'] as String);
          } catch (_) {}
          cleanHistory.remove('screening_history_mapping');
        }
        if (cleanHistory.containsKey('substance_usage')) {
          try {
            substances = jsonDecode(cleanHistory['substance_usage'] as String);
          } catch (_) {}
          cleanHistory.remove('substance_usage');
        }
      }

      // --- Sanitize date_of_birth: ensure it's in YYYY-MM-DD format ---
      String? rawDob = patient['date_of_birth'] as String?;
      String? isoDob;
      int calculatedAge = 0;

      // Guard: skip patient if DOB is missing — server requires it
      if (rawDob == null || rawDob.isEmpty) {
        print('Skipping patient $patientId: Date of Birth is missing.');
        failedCount++;
        syncErrors.add('Patient $patientId: Missing Date of Birth.');
        continue;
      }

      try {
        if (rawDob.contains('/')) {
          // Stored as DD/MM/YYYY — convert to YYYY-MM-DD
          final parts = rawDob.split('/');
          if (parts.length == 3) {
            isoDob = '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
            final dob = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
            final today = DateTime.now();
            calculatedAge = today.year - dob.year -
                ((today.month < dob.month || (today.month == dob.month && today.day < dob.day)) ? 1 : 0);
          }
        } else if (rawDob.contains('-')) {
          // Already in YYYY-MM-DD format (from date picker)
          isoDob = rawDob;
          final parts = rawDob.split('-');
          if (parts.length == 3) {
            final dob = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
            final today = DateTime.now();
            calculatedAge = today.year - dob.year -
                ((today.month < dob.month || (today.month == dob.month && today.day < dob.day)) ? 1 : 0);
          }
        } else {
          isoDob = rawDob; // fallback: send as-is
        }
      } catch (_) {
        isoDob = rawDob; // fallback: send as-is
      }


      // --- Helper: convert empty/placeholder strings to null ---
      String? nullIfBlank(dynamic val) {
        if (val == null) return null;
        // Trim leading/trailing commas and spaces (address concatenation artifacts)
        final s = val.toString().trim().replaceAll(RegExp(r'^[,\s]+|[,\s]+$'), '');
        // Only strip truly empty or non-data strings (NOT 'none'/'undisclosed' — those are valid server values)
        if (s.isEmpty || s.toLowerCase() == 'na') return null;
        return s;
      }

      // --- Sanitize history before sending to server ---
      if (cleanHistory != null) {
        // Remove local DB-only fields — server does not expect these
        cleanHistory.remove('id');
        cleanHistory.remove('patient_id');

        // lmp_date: empty string → null
        if ((cleanHistory['lmp_date'] as String?)?.isEmpty ?? false) {
          cleanHistory['lmp_date'] = null;
        }

        // first_intimate_age of 0 means "not disclosed" — send null
        if ((cleanHistory['first_intimate_age'] as int?) == 0) {
          cleanHistory['first_intimate_age'] = null;
        }

        // hpv_test: SQLite stores as int (0/1), server expects boolean
        if (cleanHistory['hpv_test'] != null) {
          cleanHistory['hpv_test'] = cleanHistory['hpv_test'] == 1;
        }

        // Only null out true unset placeholders — 'Select' means nothing chosen.
        // 'None', 'No', 'undisclosed' are VALID values the server accepts.
        for (final key in ['menopause_status', 'intimately_active', 'multiple_intimate_partners',
                           'other_med_condition', 'family_cervical_cancer']) {
          final v = cleanHistory[key]?.toString().trim() ?? '';
          if (v.toLowerCase() == 'select' || v.isEmpty) {
            cleanHistory[key] = null;
          }
        }
        // Server is case-sensitive: normalize these to lowercase
        for (final key in ['intimately_active', 'multiple_intimate_partners']) {
          if (cleanHistory[key] != null) {
            cleanHistory[key] = cleanHistory[key].toString().toLowerCase();
          }
        }
        // Remove fields not expected by the server (web app doesn't send these)
        cleanHistory.remove('lmp_date');
        cleanHistory.remove('first_intimate_age');
        cleanHistory.remove('live_children');
      }

      // Construct payload matching the web app's working API format
      final Map<String, dynamic> mappings = {};
      if (symptoms.isNotEmpty) mappings['symptoms'] = symptoms;
      if (screeningHistory.isNotEmpty) mappings['screeningHistory'] = screeningHistory;
      if (substances.isNotEmpty) mappings['substances'] = substances;

      final payload = {
        // tenantId is sent as URL query param — NOT in body (matches web app)
        'patient': {
          'mrn': 'AUTO', // server generates the real MRN
          'patient_name': patient['patient_name'],
          'gaurdian_name': nullIfBlank(patient['gaurdian_name']),
          'date_of_birth': isoDob,
          'age': calculatedAge > 0 ? calculatedAge : (patient['age'] as int? ?? 0),
          'maratial_status': patient['maratial_status'],
          'occupation': nullIfBlank(patient['occupation']),
          'residential_status': patient['residential_status'],
          'mobile_number': patient['mobile_number'] is int
              ? patient['mobile_number']
              : int.tryParse(patient['mobile_number']?.toString() ?? '') ?? 0,
          'aadhaar_number': nullIfBlank(patient['aadhaar_number']),
          'abha_number': nullIfBlank(patient['abha_number']),
          'mail': patient['mail'] ?? '',
          'country': patient['country'],
          'state': patient['state'],
          'city': patient['city'],
          'pincode': nullIfBlank(patient['pincode']),
          'block': nullIfBlank(patient['block']),
          'village': nullIfBlank(patient['village']),
          'address': nullIfBlank(patient['address']),
          'add_line_1': patient['add_line_1'] != null && patient['add_line_1'].toString().isNotEmpty ? patient['add_line_1'] : '',
          'add_line_2': patient['add_line_2'] != null && patient['add_line_2'].toString().isNotEmpty ? patient['add_line_2'] : '',
        },
        if (cleanHistory != null) 'history': cleanHistory,
        'mappings': mappings,
      };

      try {
        final headers = {
          'Content-Type': 'application/json',
          'x-gateway-authenticated': 'true',
          'x-tenant-id': tenantId,
          'x-user-id': 'mobile-sync',
          'x-user-permissions': 'sachi:patient:create',
        };

        // If an explicit auth token is set (from UI or .env), append it
        if (authToken.isNotEmpty) {
          headers['Authorization'] = 'Bearer $authToken';
        }

        final response = await http.post(
          url,
          headers: headers,
          body: jsonEncode(payload),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Successfully synced
          syncedCount++;
          if (deleteAfterSync) {
            toDeleteIds.add(patientId);
          } else {
            // Update local DB status to Synced (1)
            final updatedData = Map<String, dynamic>.from(patient);
            updatedData['sync_status'] = 1;
            await db.updatePatient(patientId, updatedData, history ?? {});
          }
        } else {
          // Debug: print full payload and server response to help diagnose errors
          print('=== SYNC DEBUG: Patient $patientId ===');
          print('Payload sent: ${jsonEncode(payload)}');
          print('HTTP Status: ${response.statusCode}');
          print('Server Response: ${response.body}');
          print('======================================');

          // Record error and continue instead of throwing immediately
          String apiError = response.body;
          try {
            final decoded = jsonDecode(response.body);
            apiError = decoded['error']?['message'] ?? decoded['message'] ?? response.body;
          } catch (_) {}
          
          if (response.statusCode == 401 || response.statusCode == 403) {
            // Token expired or invalid: ABORT ENTIRE SYNC so we don't waste battery looping 50 offline patients
            throw Exception('Authentication Failed: Token is expired or revoked. Please update your Auth Token in Settings.');
          }
          
          failedCount++;
          syncErrors.add('Patient $patientId (HTTP ${response.statusCode}): $apiError');
        }
      } catch (e) {
        print('Error syncing patient $patientId: $e');
        failedCount++;
        syncErrors.add('Patient $patientId: $e');
        continue; // Continue to the next patient instead of rethrowing
      }
    }

    // Delete synced patients if requested
    if (deleteAfterSync && toDeleteIds.isNotEmpty) {
      for (int id in toDeleteIds) {
        await db.deletePatient(id);
      }
    }

    if (syncedCount > 0) {
      final now = DateTime.now();
      // Format as "Today, 12:30 PM" or simply "YYYY-MM-DD HH:mm"
      final timeStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour)}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";
      await prefs.setString('last_sync_time', timeStr);
    }

    if (syncedCount == 0 && pendingPatients.where((p) => p['sync_status'] == 0).isEmpty) {
      throw Exception('No pending patients to sync.');
    } else if (failedCount > 0) {
      // If some failed, throw a combined error message at the end
      final errorSummary = syncErrors.take(3).join('\n'); // Show first 3 errors
      throw Exception('Synced $syncedCount patients, but $failedCount failed:\n$errorSummary${failedCount > 3 ? '\n...and more' : ''}');
    } else if (syncedCount == 0) {
      throw Exception('Failed to sync patients. Check network and tenant ID.');
    }
  }
}
