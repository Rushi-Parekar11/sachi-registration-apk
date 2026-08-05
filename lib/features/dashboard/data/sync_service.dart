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

    if (tenantId.isEmpty) {
      throw Exception('Tenant ID is missing. Please set it in Settings or configure DEV_TENANT_ID in .env.');
    }

    final db = LocalDbHelper.instance;
    final pendingPatients = await db.getPatients(); // gets all patients, but we should only sync those pending

    final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3109/api/v1/sachi';
    final url = Uri.parse('$baseUrl/transition/patients');

    int syncedCount = 0;
    List<int> toDeleteIds = [];

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

      // Construct payload mimicking the backend expected model
      final payload = {
        'tenantId': tenantId,
        'patient': {
          'mrn': patient['mrn'],
          'patient_name': patient['patient_name'],
          'gaurdian_name': patient['gaurdian_name'],
          'date_of_birth': patient['date_of_birth'],
          'age': patient['age'],
          'maratial_status': patient['maratial_status'],
          'occupation': patient['occupation'],
          'residential_status': patient['residential_status'],
          'mobile_number': patient['mobile_number']?.toString(),
          'aadhaar_number': patient['aadhaar_number'],
          'abha_number': patient['abha_number'],
          'mail': patient['mail'],
          'country': patient['country'],
          'state': patient['state'],
          'city': patient['city'],
          'pincode': patient['pincode'],
          'block': patient['block'],
          'village': patient['village'],
          'address': patient['address'],
          'add_line_1': patient['add_line_1'],
          'add_line_2': patient['add_line_2'],
        },
        if (cleanHistory != null) 'history': cleanHistory,
        'mappings': {
          'symptoms': symptoms,
          'screeningHistory': screeningHistory,
          'substances': substances,
        }
      };

      try {
        final headers = {
          'Content-Type': 'application/json',
          'x-gateway-authenticated': 'true',
          'x-tenant-id': tenantId,
          'x-user-id': 'mobile-sync',
          'x-user-permissions': 'sachi:patient:create',
        };

        // If an explicit auth token is set (like for DEV environment bypassing gateway), append it
        final token = dotenv.env['AUTH_TOKEN'];
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
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
          // Throw immediately so the snackbar shows the real API error reason
          String apiError = response.body;
          try {
            final decoded = jsonDecode(response.body);
            apiError = decoded['error']?['message'] ?? decoded['message'] ?? response.body;
          } catch (_) {}
          throw Exception(
            'Server rejected patient $patientId (HTTP ${response.statusCode}): $apiError',
          );
        }
      } catch (e) {
        print('Error syncing patient $patientId: $e');
        rethrow;
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
    } else if (syncedCount == 0) {
      throw Exception('Failed to sync patients. Check network and tenant ID.');
    }
  }
}
