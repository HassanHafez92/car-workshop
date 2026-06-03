import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/workshop_models.dart';
import '../models/user_model.dart';

class ApiService {
  final String baseUrl = 'https://hassan1992-car-workshop-api.hf.space/api';

  Future<bool> isOnline() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/status')).timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> fetchAllData() async {
    final response = await _get('/status'); // Check connection
    if (response.statusCode != 200) {
      throw Exception('Server returned status code ${response.statusCode}');
    }

    final customers = await _getJsonList('/customers');
    final vehicles = await _getJsonList('/vehicles');
    final suppliers = await _getJsonList('/suppliers');
    final parts = await _getJsonList('/parts');
    final stockMovements = await _getJsonList('/stockmovements');
    final appointments = await _getJsonList('/appointments');
    final jobCards = await _getJsonList('/jobcards');
    final invoices = await _getJsonList('/invoices');
    final ledgerEntries = await _getJsonList('/ledgerentries');
    final auditLogs = await _getJsonList('/auditlogs');
    final users = await _getJsonList('/auth/users');

    return {
      'customers': customers,
      'vehicles': vehicles,
      'suppliers': suppliers,
      'parts': parts,
      'stock_movements': stockMovements,
      'appointments': appointments,
      'job_cards': jobCards,
      'invoices': invoices,
      'ledger_entries': ledgerEntries,
      'audit_logs': auditLogs,
      'users': users,
    };
  }

  Future<void> saveCustomer(Customer customer) async {
    await _post('/customers', customer.toMap());
  }

  Future<void> saveVehicle(Vehicle vehicle) async {
    await _post('/vehicles', vehicle.toMap());
  }

  Future<void> saveSupplier(Supplier supplier) async {
    await _post('/suppliers', supplier.toMap());
  }

  Future<void> savePart(Part part) async {
    await _post('/parts', part.toMap());
  }

  Future<void> adjustStock(String partId, int change, String reason) async {
    await _post('/parts/adjust', {'part_id': partId, 'change': change, 'reason': reason});
  }

  Future<void> saveStockMovement(StockMovement movement) async {
    await _post('/stockmovements', movement.toMap());
  }

  Future<void> saveAppointment(Appointment appointment) async {
    await _post('/appointments', appointment.toMap());
  }

  Future<void> saveJobCard(JobCard jobCard) async {
    await _post('/jobcards', jobCard.toMap());
  }

  Future<void> saveInvoice(Invoice invoice) async {
    await _post('/invoices', invoice.toMap());
  }

  Future<void> saveLedgerEntry(LedgerEntry entry) async {
    await _post('/ledgerentries', entry.toMap());
  }

  Future<void> registerUser(UserAccount user) async {
    await _post('/auth/register', user.toMap());
  }

  Future<void> toggleUserStatus(String userId, bool isActive) async {
    await _post('/auth/users/$userId/status', {'is_active': isActive});
  }

  Future<UserAccount> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'password': password,
      }),
    ).timeout(const Duration(seconds: 4));

    if (response.statusCode == 200) {
      final map = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return UserAccount.fromMap(map);
    } else if (response.statusCode == 400) {
      final err = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      throw Exception(err['detail'] ?? 'الحساب معطل حالياً.');
    } else if (response.statusCode == 401) {
      throw Exception('اسم المستخدم أو كلمة المرور غير صحيحة.');
    } else {
      throw Exception('فشل الاتصال بالخادم.');
    }
  }

  // --- Helper Methods ---
  Future<http.Response> _get(String path) async {
    return await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 4));
  }

  Future<List<dynamic>> _getJsonList(String path) async {
    final response = await _get(path);
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    }
    throw Exception('Failed to fetch $path: status ${response.statusCode}');
  }

  Future<void> _post(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    ).timeout(const Duration(seconds: 4));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed POST $path: status ${response.statusCode}');
    }
  }
}
