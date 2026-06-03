import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workshop_models.dart';
import '../models/user_model.dart';
import 'role_provider.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';

class AppState {
  final List<Customer> customers;
  final List<Vehicle> vehicles;
  final List<Supplier> suppliers;
  final List<Part> parts;
  final List<StockMovement> stockMovements;
  final List<JobCard> jobCards;
  final List<Invoice> invoices;
  final List<LedgerEntry> ledgerEntries;
  final List<Appointment> appointments;
  final List<AuditLog> auditLogs;
  final List<NotificationLog> notificationLogs;
  final List<UserAccount> users;

  AppState({
    required this.customers,
    required this.vehicles,
    required this.suppliers,
    required this.parts,
    required this.stockMovements,
    required this.jobCards,
    required this.invoices,
    required this.ledgerEntries,
    required this.appointments,
    required this.auditLogs,
    required this.notificationLogs,
    required this.users,
  });

  AppState copyWith({
    List<Customer>? customers,
    List<Vehicle>? vehicles,
    List<Supplier>? suppliers,
    List<Part>? parts,
    List<StockMovement>? stockMovements,
    List<JobCard>? jobCards,
    List<Invoice>? invoices,
    List<LedgerEntry>? ledgerEntries,
    List<Appointment>? appointments,
    List<AuditLog>? auditLogs,
    List<NotificationLog>? notificationLogs,
    List<UserAccount>? users,
  }) {
    return AppState(
      customers: customers ?? this.customers,
      vehicles: vehicles ?? this.vehicles,
      suppliers: suppliers ?? this.suppliers,
      parts: parts ?? this.parts,
      stockMovements: stockMovements ?? this.stockMovements,
      jobCards: jobCards ?? this.jobCards,
      invoices: invoices ?? this.invoices,
      ledgerEntries: ledgerEntries ?? this.ledgerEntries,
      appointments: appointments ?? this.appointments,
      auditLogs: auditLogs ?? this.auditLogs,
      notificationLogs: notificationLogs ?? this.notificationLogs,
      users: users ?? this.users,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customers': customers.map((x) => x.toMap()).toList(),
      'vehicles': vehicles.map((x) => x.toMap()).toList(),
      'suppliers': suppliers.map((x) => x.toMap()).toList(),
      'parts': parts.map((x) => x.toMap()).toList(),
      'stock_movements': stockMovements.map((x) => x.toMap()).toList(),
      'appointments': appointments.map((x) => x.toMap()).toList(),
      'job_cards': jobCards.map((x) => x.toMap()).toList(),
      'invoices': invoices.map((x) => x.toMap()).toList(),
      'ledger_entries': ledgerEntries.map((x) => x.toMap()).toList(),
      'audit_logs': auditLogs.map((x) => x.toMap()).toList(),
      'users': users.map((x) => x.toMap()).toList(),
    };
  }
}

class AppStateNotifier extends Notifier<AppState> {
  final DatabaseService _dbService = DatabaseService();
  final NotificationService _notifService = NotificationService();
  final ApiService _apiService = ApiService();

  @override
  AppState build() {
    // Run async load, but return mock data synchronously to populate the UI immediately
    loadAsync();
    final mock = _dbService.getMockInitialData();
    return _fromMap(mock);
  }

  // --- Persistence & Initialization ---
  Future<void> loadAsync() async {
    final persisted = await _dbService.loadState();
    if (persisted != null) {
      state = _fromMap(persisted);
    }
    try {
      final apiData = await _apiService.fetchAllData();
      state = _fromMap(apiData);
      await _dbService.saveState(apiData);
      print(">>> REST API state sync loaded successfully.");
    } catch (e) {
      print(">>> REST API sync failed, running in local/offline mode. Exception: $e");
    }
  }

  Future<void> _syncToApi(Future<void> Function() apiCall) async {
    try {
      await apiCall();
    } catch (e) {
      print(">>> REST API sync failed (offline): $e");
    }
  }

  AppState _fromMap(Map<String, dynamic> map) {
    _notifService.clearLogs();
    
    // Check if parts are below minimum stock on load
    final partsList = List<Part>.from((map['parts'] as List? ?? []).map((x) => Part.fromMap(x)));
    for (var part in partsList) {
      if (part.stockCount <= part.minStock) {
        _notifService.triggerStaffAlert(
          staffRole: 'Storekeeper',
          message: 'تنبيه مخزون منخفض: قطع الغيار (${part.name}) قاربت على النفاد. الرصيد المتبقي: ${part.stockCount} ${part.unit}.',
        );
      }
    }

    return AppState(
      customers: List<Customer>.from((map['customers'] as List? ?? []).map((x) => Customer.fromMap(x))),
      vehicles: List<Vehicle>.from((map['vehicles'] as List? ?? []).map((x) => Vehicle.fromMap(x))),
      suppliers: List<Supplier>.from((map['suppliers'] as List? ?? []).map((x) => Supplier.fromMap(x))),
      parts: partsList,
      stockMovements: List<StockMovement>.from((map['stock_movements'] as List? ?? []).map((x) => StockMovement.fromMap(x))),
      appointments: List<Appointment>.from((map['appointments'] as List? ?? []).map((x) => Appointment.fromMap(x))),
      jobCards: List<JobCard>.from((map['job_cards'] as List? ?? []).map((x) => JobCard.fromMap(x))),
      invoices: List<Invoice>.from((map['invoices'] as List? ?? []).map((x) => Invoice.fromMap(x))),
      ledgerEntries: List<LedgerEntry>.from((map['ledger_entries'] as List? ?? []).map((x) => LedgerEntry.fromMap(x))),
      auditLogs: List<AuditLog>.from((map['audit_logs'] as List? ?? []).map((x) => AuditLog.fromMap(x))),
      users: List<UserAccount>.from((map['users'] as List? ?? []).map((x) => UserAccount.fromMap(x))),
      notificationLogs: _notifService.logs,
    );
  }

  Future<void> _save() async {
    final map = state.toMap();
    await _dbService.saveState(map);
  }

  void _addAuditLog(String role, String action, String details) {
    final newLog = AuditLog(
      id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now().toIso8601String().replaceAll('T', ' ').substring(0, 16),
      userRole: role,
      action: action,
      details: details,
    );
    state = state.copyWith(
      auditLogs: [newLog, ...state.auditLogs],
    );
  }

  // --- CRM Operations ---
  void addCustomer({
    required String name,
    required String phone,
    required String email,
    required String address,
    required String type,
    required double creditLimit,
    required String activeRole,
  }) {
    final customer = Customer(
      id: 'cust_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: phone,
      email: email,
      address: address,
      type: type,
      creditLimit: creditLimit,
      isActive: true,
    );
    state = state.copyWith(
      customers: [...state.customers, customer],
    );
    _addAuditLog(activeRole, 'إضافة عميل', 'تم تسجيل العميل الجديد: ${customer.name} (${customer.type == 'credit' ? 'آجل' : 'نقدي'}).');
    _save();
    _syncToApi(() => _apiService.saveCustomer(customer));
  }

  void addVehicle({
    required String customerId,
    required String plateNumber,
    required String chassisNumber,
    required String make,
    required String model,
    required String year,
    required String color,
    required int odometer,
    required String notes,
    required String activeRole,
  }) {
    final vehicle = Vehicle(
      id: 'veh_${DateTime.now().millisecondsSinceEpoch}',
      customerId: customerId,
      plateNumber: plateNumber,
      chassisNumber: chassisNumber,
      make: make,
      model: model,
      year: year,
      color: color,
      odometer: odometer,
      notes: notes,
    );
    state = state.copyWith(
      vehicles: [...state.vehicles, vehicle],
    );
    final cust = state.customers.firstWhere((x) => x.id == customerId);
    _addAuditLog(activeRole, 'إضافة سيارة للعميل', 'تم تسجيل سيارة جديدة (${vehicle.make} ${vehicle.model} - لوحة ${vehicle.plateNumber}) للعميل ${cust.name}.');
    _save();
    _syncToApi(() => _apiService.saveVehicle(vehicle));
  }

  // --- Supplier Operations ---
  void addSupplier({
    required String name,
    required String phone,
    required String address,
    required String paymentTerms,
    required String activeRole,
  }) {
    final supplier = Supplier(
      id: 'supp_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: phone,
      address: address,
      paymentTerms: paymentTerms,
      isActive: true,
    );
    state = state.copyWith(
      suppliers: [...state.suppliers, supplier],
    );
    _addAuditLog(activeRole, 'إضافة مورد', 'تم تسجيل المورد الجديد: ${supplier.name}.');
    _save();
    _syncToApi(() => _apiService.saveSupplier(supplier));
  }

  // --- Inventory & Purchasing Operations ---
  void addPart({
    required String code,
    required String name,
    required String category,
    required String brand,
    required String compatibleModels,
    required int minStock,
    required String unit,
    required double defaultPurchasePrice,
    required double defaultSellingPrice,
    required String location,
    required String activeRole,
  }) {
    final part = Part(
      id: 'part_${DateTime.now().millisecondsSinceEpoch}',
      code: code,
      name: name,
      category: category,
      brand: brand,
      compatibleModels: compatibleModels,
      minStock: minStock,
      unit: unit,
      defaultPurchasePrice: defaultPurchasePrice,
      defaultSellingPrice: defaultSellingPrice,
      targetMargin: ((defaultSellingPrice - defaultPurchasePrice) / defaultSellingPrice * 100),
      location: location,
      stockCount: 0,
    );
    state = state.copyWith(
      parts: [...state.parts, part],
    );
    _addAuditLog(activeRole, 'إضافة مادة مخزنية', 'تم تعريف قطعة الغيار الجديدة: ${part.name} (كود: ${part.code}).');
    _save();
    _syncToApi(() => _apiService.savePart(part));
  }

  void adjustStock(String partId, int changeQty, String reason, String activeRole) {
    Part? updatedPart;
    final updatedParts = state.parts.map((p) {
      if (p.id == partId) {
        final newCount = p.stockCount + changeQty;
        // Verify min stock
        if (newCount <= p.minStock) {
          _notifService.triggerStaffAlert(
            staffRole: 'Storekeeper',
            message: 'تنبيه مخزون منخفض: قطع الغيار (${p.name}) قاربت على النفاد. الرصيد المتبقي: $newCount ${p.unit}.',
          );
        }
        updatedPart = p.copyWith(stockCount: newCount);
        return updatedPart!;
      }
      return p;
    }).toList();

    final movement = StockMovement(
      id: 'mov_${DateTime.now().millisecondsSinceEpoch}',
      partId: partId,
      type: 'adjustment',
      quantity: changeQty,
      referenceId: 'ADJ-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      date: DateTime.now().toIso8601String().substring(0, 10),
      notes: reason,
    );

    state = state.copyWith(
      parts: updatedParts,
      stockMovements: [movement, ...state.stockMovements],
      notificationLogs: _notifService.logs,
    );

    final part = state.parts.firstWhere((x) => x.id == partId);
    _addAuditLog(activeRole, 'تعديل المخزون يدوياً', 'تعديل رصيد (${part.name}) بمقدار $changeQty. السبب: $reason.');
    _save();
    _syncToApi(() async {
      await _apiService.adjustStock(partId, changeQty, reason);
      await _apiService.saveStockMovement(movement);
    });
  }

  void createSupplierInvoice({
    required String supplierId,
    required String invoiceNo,
    required List<Map<String, dynamic>> items, // [{'partId': x, 'qty': y, 'cost': z}]
    required String activeRole,
  }) {
    final dateStr = DateTime.now().toIso8601String().substring(0, 10);
    double totalCost = 0.0;
    List<StockMovement> movements = [];

    final updatedParts = state.parts.map((part) {
      final item = items.firstWhere((i) => i['partId'] == part.id, orElse: () => {});
      if (item.isNotEmpty) {
        final qty = item['qty'] as int;
        final cost = (item['cost'] as num).toDouble();
        totalCost += (qty * cost);

        movements.add(StockMovement(
          id: 'mov_${DateTime.now().millisecondsSinceEpoch}_${part.id}',
          partId: part.id,
          type: 'receipt',
          quantity: qty,
          referenceId: invoiceNo,
          date: dateStr,
          notes: 'شراء وارد بموجب فاتورة مورد رقم $invoiceNo',
        ));

        return part.copyWith(
          stockCount: part.stockCount + qty,
          defaultPurchasePrice: cost,
        );
      }
      return part;
    }).toList();

    // Accounts Payable ledger update
    double previousBalance = 0.0;
    try {
      final supplierLedger = state.ledgerEntries.where((e) => e.partyId == supplierId && e.partyType == 'supplier');
      if (supplierLedger.isNotEmpty) {
        previousBalance = supplierLedger.last.balance;
      }
    } catch (e) {
      previousBalance = 0.0;
    }

    final runningBalance = previousBalance + totalCost; // credit increases supplier AP balance (we owe them)
    final ledgerEntry = LedgerEntry(
      id: 'led_${DateTime.now().millisecondsSinceEpoch}',
      partyId: supplierId,
      partyType: 'supplier',
      type: 'invoice',
      date: dateStr,
      referenceNo: invoiceNo,
      debit: 0.0,
      credit: totalCost,
      balance: runningBalance,
    );

    state = state.copyWith(
      parts: updatedParts,
      stockMovements: [...movements, ...state.stockMovements],
      ledgerEntries: [...state.ledgerEntries, ledgerEntry],
    );

    final supplier = state.suppliers.firstWhere((x) => x.id == supplierId);
    _addAuditLog(activeRole, 'شراء فاتورة مورد', 'تسجيل فاتورة شراء رقم $invoiceNo من المورد (${supplier.name}) بقيمة إجمالية ${totalCost.toStringAsFixed(2)} ج.م.');
    _save();
    _syncToApi(() async {
      for (var m in movements) {
        final p = updatedParts.firstWhere((x) => x.id == m.partId);
        await _apiService.savePart(p);
        await _apiService.saveStockMovement(m);
      }
      await _apiService.saveLedgerEntry(ledgerEntry);
    });
  }

  void recordSupplierPayment({
    required String supplierId,
    required double amount,
    required String referenceNo,
    required String activeRole,
  }) {
    final dateStr = DateTime.now().toIso8601String().substring(0, 10);
    double previousBalance = 0.0;

    final supplierLedger = state.ledgerEntries.where((e) => e.partyId == supplierId && e.partyType == 'supplier');
    if (supplierLedger.isNotEmpty) {
      previousBalance = supplierLedger.last.balance;
    }

    final runningBalance = previousBalance - amount; // debit decreases supplier AP balance (we paid them)
    final ledgerEntry = LedgerEntry(
      id: 'led_${DateTime.now().millisecondsSinceEpoch}',
      partyId: supplierId,
      partyType: 'supplier',
      type: 'payment',
      date: dateStr,
      referenceNo: referenceNo,
      debit: amount,
      credit: 0.0,
      balance: runningBalance,
    );

    state = state.copyWith(
      ledgerEntries: [...state.ledgerEntries, ledgerEntry],
    );

    final supplier = state.suppliers.firstWhere((x) => x.id == supplierId);
    _addAuditLog(activeRole, 'دفع للمورد', 'سداد دفعة للمورد (${supplier.name}) بقيمة ${amount.toStringAsFixed(2)} ج.م. سند رقم: $referenceNo');
    _save();
    _syncToApi(() => _apiService.saveLedgerEntry(ledgerEntry));
  }

  // --- Job Cards Lifecycle & Operations ---
  void createJobCard({
    required String customerId,
    required String vehicleId,
    required String complaint,
    required int odometer,
    required String activeRole,
  }) {
    final now = DateTime.now();
    final dateStr = now.toIso8601String().substring(0, 10);
    final timeStr = now.toIso8601String().substring(11, 16);
    
    final customer = state.customers.firstWhere((c) => c.id == customerId);
    final vehicle = state.vehicles.firstWhere((v) => v.id == vehicleId);

    final jobCard = JobCard(
      id: 'job_${now.millisecondsSinceEpoch}',
      cardNo: 'JC-${now.year}-${now.millisecondsSinceEpoch.toString().substring(7)}',
      customerId: customerId,
      vehicleId: vehicleId,
      complaint: complaint,
      odometer: odometer,
      status: 'New',
      tasks: [],
      parts: [],
      createdAt: '$dateStr $timeStr',
      statusLogs: [
        StatusLog(status: 'New', timestamp: '$dateStr $timeStr', userRole: activeRole)
      ],
    );

    state = state.copyWith(
      jobCards: [jobCard, ...state.jobCards],
    );

    _notifService.triggerCustomerAlert(
      customerName: customer.name,
      phone: customer.phone,
      vehicleInfo: '${vehicle.make} ${vehicle.model} (${vehicle.plateNumber})',
      status: 'Under Inspection',
    );

    state = state.copyWith(notificationLogs: _notifService.logs);
    _addAuditLog(activeRole, 'إنشاء بطاقة عمل صيانة', 'تم فتح كرت العمل رقم ${jobCard.cardNo} للعميل: ${customer.name}.');
    _save();
    _syncToApi(() => _apiService.saveJobCard(jobCard));
  }

  void addJobTask(String jobCardId, String description, String type, String technicianName, double estimatedHours, double price, String activeRole) {
    final updatedJobCards = state.jobCards.map((jc) {
      if (jc.id == jobCardId) {
        final newTask = JobTask(
          id: 'task_${DateTime.now().millisecondsSinceEpoch}',
          description: description,
          type: type,
          technicianName: technicianName,
          estimatedHours: estimatedHours,
          price: price,
          status: 'pending',
          timeLogs: [],
        );
        return jc.copyWith(tasks: [...jc.tasks, newTask]);
      }
      return jc;
    }).toList();

    state = state.copyWith(jobCards: updatedJobCards);
    final target = state.jobCards.firstWhere((x) => x.id == jobCardId);
    _addAuditLog(activeRole, 'إضافة عملية عمل لكرت الصيانة', 'تمت إضافة مهمة ($description) للفني ($technicianName) في كرت الصيانة ${target.cardNo}.');
    _save();
    _syncToApi(() => _apiService.saveJobCard(target));
  }

  void addJobPart(String jobCardId, String partId, int quantity, String activeRole) {
    final dateStr = DateTime.now().toIso8601String().substring(0, 10);
    final targetPart = state.parts.firstWhere((p) => p.id == partId);

    if (targetPart.stockCount < quantity) {
      // Stock insufficient, trigger alert
      _notifService.triggerStaffAlert(
        staffRole: 'Storekeeper',
        message: 'عجز في الصرف: مطلوب صرف عدد $quantity من (${targetPart.name}) لكرت صيانة، والمتوفر فقط: ${targetPart.stockCount}.',
      );
      state = state.copyWith(notificationLogs: _notifService.logs);
      return;
    }

    final updatedParts = state.parts.map((p) {
      if (p.id == partId) {
        final newQty = p.stockCount - quantity;
        if (newQty <= p.minStock) {
          _notifService.triggerStaffAlert(
            staffRole: 'Storekeeper',
            message: 'تنبيه مخزون منخفض: قطع الغيار (${p.name}) بعد الصرف أصبحت: $newQty ${p.unit}.',
          );
        }
        return p.copyWith(stockCount: newQty);
      }
      return p;
    }).toList();

    final movement = StockMovement(
      id: 'mov_${DateTime.now().millisecondsSinceEpoch}',
      partId: partId,
      type: 'issue',
      quantity: -quantity,
      referenceId: jobCardId,
      date: dateStr,
      notes: 'صرف داخلي لكرت العمل رقم: ' + state.jobCards.firstWhere((j) => j.id == jobCardId).cardNo,
    );

    final updatedJobCards = state.jobCards.map((jc) {
      if (jc.id == jobCardId) {
        final newJobPart = JobPart(
          id: 'jpart_${DateTime.now().millisecondsSinceEpoch}',
          partId: partId,
          code: targetPart.code,
          name: targetPart.name,
          quantity: quantity,
          price: targetPart.defaultSellingPrice,
        );
        return jc.copyWith(parts: [...jc.parts, newJobPart]);
      }
      return jc;
    }).toList();

    state = state.copyWith(
      parts: updatedParts,
      stockMovements: [movement, ...state.stockMovements],
      jobCards: updatedJobCards,
      notificationLogs: _notifService.logs,
    );

    final target = state.jobCards.firstWhere((x) => x.id == jobCardId);
    _addAuditLog(activeRole, 'صرف قطع غيار', 'صرف عدد $quantity حبات من (${targetPart.name}) لكرت الصيانة ${target.cardNo}.');
    _save();
    _syncToApi(() async {
      final p = updatedParts.firstWhere((x) => x.id == targetPart.id);
      await _apiService.savePart(p);
      await _apiService.saveStockMovement(movement);
      await _apiService.saveJobCard(target);
    });
  }

  void removeJobPart(String jobCardId, String jobPartId, String activeRole) {
    final dateStr = DateTime.now().toIso8601String().substring(0, 10);
    final jc = state.jobCards.firstWhere((j) => j.id == jobCardId);
    final jp = jc.parts.firstWhere((p) => p.id == jobPartId);

    final updatedParts = state.parts.map((p) {
      if (p.id == jp.partId) {
        return p.copyWith(stockCount: p.stockCount + jp.quantity);
      }
      return p;
    }).toList();

    final movement = StockMovement(
      id: 'mov_${DateTime.now().millisecondsSinceEpoch}',
      partId: jp.partId,
      type: 'return',
      quantity: jp.quantity,
      referenceId: jobCardId,
      date: dateStr,
      notes: 'إرجاع قطع غيار من كرت العمل الملغى/المعدل رقم: ' + jc.cardNo,
    );

    final updatedJobCards = state.jobCards.map((j) {
      if (j.id == jobCardId) {
        final filteredParts = j.parts.where((x) => x.id != jobPartId).toList();
        return j.copyWith(parts: filteredParts);
      }
      return j;
    }).toList();

    state = state.copyWith(
      parts: updatedParts,
      stockMovements: [movement, ...state.stockMovements],
      jobCards: updatedJobCards,
    );

    _addAuditLog(activeRole, 'إرجاع قطع غيار للمخزن', 'إرجاع عدد ${jp.quantity} حبات من (${jp.name}) من كرت الصيانة ${jc.cardNo} إلى المخزن.');
    _save();
    final target = state.jobCards.firstWhere((x) => x.id == jobCardId);
    _syncToApi(() async {
      final p = updatedParts.firstWhere((x) => x.id == jp.partId);
      await _apiService.savePart(p);
      await _apiService.saveStockMovement(movement);
      await _apiService.saveJobCard(target);
    });
  }

  void toggleTaskTimer(String jobCardId, String taskId) {
    final nowStr = DateTime.now().toIso8601String();
    
    final updatedJobCards = state.jobCards.map((jc) {
      if (jc.id == jobCardId) {
        final updatedTasks = jc.tasks.map((task) {
          if (task.id == taskId) {
            if (task.status == 'pending') {
              // Start timer
              return task.copyWith(
                status: 'active',
                timeLogs: [...task.timeLogs, TimeLog(start: nowStr, end: null)],
              );
            } else if (task.status == 'active') {
              // Stop timer & complete task
              final activeLog = task.timeLogs.last;
              final completedLogs = task.timeLogs.sublist(0, task.timeLogs.length - 1);
              return task.copyWith(
                status: 'completed',
                timeLogs: [...completedLogs, TimeLog(start: activeLog.start, end: nowStr)],
              );
            }
          }
          return task;
        }).toList();
        return jc.copyWith(tasks: updatedTasks);
      }
      return jc;
    }).toList();

    state = state.copyWith(jobCards: updatedJobCards);
    _save();
    final target = state.jobCards.firstWhere((x) => x.id == jobCardId);
    _syncToApi(() => _apiService.saveJobCard(target));
  }

  void updateJobStatus(String jobCardId, String newStatus, String activeRole) {
    final now = DateTime.now();
    final dateStr = now.toIso8601String().substring(0, 10);
    final timeStr = now.toIso8601String().substring(11, 16);

    final updatedJobCards = state.jobCards.map((jc) {
      if (jc.id == jobCardId) {
        final logs = [...jc.statusLogs, StatusLog(status: newStatus, timestamp: '$dateStr $timeStr', userRole: activeRole)];
        return jc.copyWith(status: newStatus, statusLogs: logs);
      }
      return jc;
    }).toList();

    state = state.copyWith(jobCards: updatedJobCards);

    final jc = state.jobCards.firstWhere((x) => x.id == jobCardId);
    final customer = state.customers.firstWhere((x) => x.id == jc.customerId);
    final vehicle = state.vehicles.firstWhere((x) => x.id == jc.vehicleId);

    // Dynamic notifications to customer
    _notifService.triggerCustomerAlert(
      customerName: customer.name,
      phone: customer.phone,
      vehicleInfo: '${vehicle.make} ${vehicle.model} (${vehicle.plateNumber})',
      status: newStatus,
      invoiceAmount: newStatus == 'Completed' ? (jc.parts.fold(0.0, (sum, p) => sum + (p.price * p.quantity)) + jc.tasks.fold(0.0, (sum, t) => sum + t.price)) * 1.15 : null,
    );

    // In-app alert to staff if completed (ready for receptionist to invoice)
    if (newStatus == 'Completed') {
      _notifService.triggerStaffAlert(
        staffRole: 'Receptionist',
        message: 'كرت الصيانة ${jc.cardNo} للعميل ${customer.name} تم إنجازه بالكامل من الفني وهو جاهز لإصدار الفاتورة.',
      );
    }

    state = state.copyWith(notificationLogs: _notifService.logs);
    _addAuditLog(activeRole, 'تحديث حالة كرت الصيانة', 'تحديث كرت العمل ${jc.cardNo} إلى (${newStatus}).');
    _save();
    _syncToApi(() => _apiService.saveJobCard(jc));
  }

  // --- Invoicing & POS Operations ---
  void generateInvoiceFromJobCard({
    required String jobCardId,
    required double discount,
    required String activeRole,
  }) {
    final jc = state.jobCards.firstWhere((j) => j.id == jobCardId);
    final double laborTotal = jc.tasks.fold(0.0, (sum, t) => sum + t.price);
    final double partsTotal = jc.parts.fold(0.0, (sum, p) => sum + (p.price * p.quantity));
    final double preTax = (laborTotal + partsTotal) - discount;
    final double tax = preTax * 0.15; // 15% VAT
    final double netTotal = preTax + tax;

    final invoice = Invoice(
      id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
      invoiceNo: 'INV-WS-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      jobCardId: jobCardId,
      customerId: jc.customerId,
      vehicleId: jc.vehicleId,
      laborTotal: laborTotal,
      partsTotal: partsTotal,
      discount: discount,
      tax: tax,
      netTotal: netTotal,
      status: 'pending_accounting',
      paymentMethod: 'cash',
      createdAt: DateTime.now().toIso8601String().replaceAll('T', ' ').substring(0, 16),
    );

    state = state.copyWith(
      invoices: [invoice, ...state.invoices],
    );

    // Update job card status to 'Delivered' automatically upon invoicing
    updateJobStatus(jobCardId, 'Delivered', activeRole);

    // Alert accountant of new pending invoice
    _notifService.triggerStaffAlert(
      staffRole: 'Accountant',
      message: 'فاتورة معلقة بانتظار المراجعة والترحيل لكرت الصيانة ${jc.cardNo}. القيمة: ${netTotal.toStringAsFixed(2)} ج.م.',
    );

    state = state.copyWith(notificationLogs: _notifService.logs);
    _addAuditLog(activeRole, 'إصدار مسودة فاتورة', 'تم إنشاء الفاتورة رقم ${invoice.invoiceNo} برصيد ${netTotal.toStringAsFixed(2)} ج.م. بانتظار مراجعة الحسابات.');
    _save();
    _syncToApi(() => _apiService.saveInvoice(invoice));
  }

  void postInvoice(String invoiceId, String paymentMethod, String activeRole) {
    final dateStr = DateTime.now().toIso8601String().substring(0, 10);
    double invoiceAmount = 0.0;
    String customerId = '';
    String invoiceNo = '';

    final updatedInvoices = state.invoices.map((inv) {
      if (inv.id == invoiceId) {
        invoiceAmount = inv.netTotal;
        customerId = inv.customerId;
        invoiceNo = inv.invoiceNo;
        return inv.copyWith(status: 'posted', paymentMethod: paymentMethod);
      }
      return inv;
    }).toList();

    // Accounts Receivable ledger entry if it is on Credit
    // Cash/Card payments update instantly or have separate receipts
    List<LedgerEntry> updatedLedgers = List.from(state.ledgerEntries);
    if (paymentMethod == 'credit') {
      double previousBalance = 0.0;
      final custLedger = state.ledgerEntries.where((e) => e.partyId == customerId && e.partyType == 'customer');
      if (custLedger.isNotEmpty) {
        previousBalance = custLedger.last.balance;
      }
      final runningBalance = previousBalance + invoiceAmount; // debit increases customer AR balance

      updatedLedgers.add(LedgerEntry(
        id: 'led_${DateTime.now().millisecondsSinceEpoch}',
        partyId: customerId,
        partyType: 'customer',
        type: 'invoice',
        date: dateStr,
        referenceNo: invoiceNo,
        debit: invoiceAmount,
        credit: 0.0,
        balance: runningBalance,
      ));
    } else {
      // Cash/Card posted invoice also automatically records a matching payment immediately in the ledger
      double previousBalance = 0.0;
      final custLedger = state.ledgerEntries.where((e) => e.partyId == customerId && e.partyType == 'customer');
      if (custLedger.isNotEmpty) {
        previousBalance = custLedger.last.balance;
      }
      
      // Invoice Debit Entry
      updatedLedgers.add(LedgerEntry(
        id: 'led_${DateTime.now().millisecondsSinceEpoch}_deb',
        partyId: customerId,
        partyType: 'customer',
        type: 'invoice',
        date: dateStr,
        referenceNo: invoiceNo,
        debit: invoiceAmount,
        credit: 0.0,
        balance: previousBalance + invoiceAmount,
      ));

      // Payment Credit Entry
      updatedLedgers.add(LedgerEntry(
        id: 'led_${DateTime.now().millisecondsSinceEpoch}_cred',
        partyId: customerId,
        partyType: 'customer',
        type: 'payment',
        date: dateStr,
        referenceNo: 'RCPT-$invoiceNo',
        debit: 0.0,
        credit: invoiceAmount,
        balance: previousBalance, // balance returns to previous
      ));
    }

    state = state.copyWith(
      invoices: updatedInvoices,
      ledgerEntries: updatedLedgers,
    );

    final customer = state.customers.firstWhere((x) => x.id == customerId);
    _addAuditLog(activeRole, 'ترحيل فاتورة صيانة للعميل', 'تم ترحيل الفاتورة رقم $invoiceNo للحسابات للعميل (${customer.name}) عبر السداد ($paymentMethod).');
    _save();
    final targetInvoice = state.invoices.firstWhere((x) => x.id == invoiceId);
    _syncToApi(() async {
      await _apiService.saveInvoice(targetInvoice);
      final count = paymentMethod == 'credit' ? 1 : 2;
      for (int i = 0; i < count; i++) {
        final entry = updatedLedgers[updatedLedgers.length - count + i];
        await _apiService.saveLedgerEntry(entry);
      }
    });
  }

  void recordCustomerPayment({
    required String customerId,
    required double amount,
    required String referenceNo,
    required String activeRole,
  }) {
    final dateStr = DateTime.now().toIso8601String().substring(0, 10);
    double previousBalance = 0.0;

    final custLedger = state.ledgerEntries.where((e) => e.partyId == customerId && e.partyType == 'customer');
    if (custLedger.isNotEmpty) {
      previousBalance = custLedger.last.balance;
    }

    final runningBalance = previousBalance - amount; // credit decreases customer AR balance (they paid us)
    final ledgerEntry = LedgerEntry(
      id: 'led_${DateTime.now().millisecondsSinceEpoch}',
      partyId: customerId,
      partyType: 'customer',
      type: 'payment',
      date: dateStr,
      referenceNo: referenceNo,
      debit: 0.0,
      credit: amount,
      balance: runningBalance,
    );

    state = state.copyWith(
      ledgerEntries: [...state.ledgerEntries, ledgerEntry],
    );

    final customer = state.customers.firstWhere((x) => x.id == customerId);
    _addAuditLog(activeRole, 'تسجيل دفعة مقبوضة', 'تم تحصيل دفعة من العميل (${customer.name}) بقيمة ${amount.toStringAsFixed(2)} ج.م. سند قبض رقم: $referenceNo');
    _save();
    _syncToApi(() => _apiService.saveLedgerEntry(ledgerEntry));
  }

  // --- Calendar & Appointments ---
  void addAppointment({
    required String customerId,
    required String vehicleId,
    required String dateTime,
    required String serviceType,
    required String assignedBay,
    required String activeRole,
  }) {
    final appointment = Appointment(
      id: 'app_${DateTime.now().millisecondsSinceEpoch}',
      customerId: customerId,
      vehicleId: vehicleId,
      dateTime: dateTime,
      serviceType: serviceType,
      status: 'confirmed',
      assignedBay: assignedBay,
    );

    state = state.copyWith(
      appointments: [...state.appointments, appointment],
    );

    final customer = state.customers.firstWhere((x) => x.id == customerId);
    _addAuditLog(activeRole, 'حجز موعد صيانة', 'تم حجز موعد صيانة للعميل: ${customer.name} بتاريخ: $dateTime.');
    _save();
    _syncToApi(() => _apiService.saveAppointment(appointment));
  }

  void updateAppointmentStatus(String appointmentId, String status, String activeRole) {
    final updated = state.appointments.map((a) {
      if (a.id == appointmentId) {
        return a.copyWith(status: status);
      }
      return a;
    }).toList();

    state = state.copyWith(appointments: updated);
    final target = state.appointments.firstWhere((x) => x.id == appointmentId);
    final customer = state.customers.firstWhere((x) => x.id == target.customerId);
    _addAuditLog(activeRole, 'تغيير حالة الموعد', 'تم تغيير حالة موعد العميل: ${customer.name} إلى: $status.');
    _save();
    _syncToApi(() => _apiService.saveAppointment(target));
  }

  void checkInAppointment(String appointmentId, String complaint, int odometer, String activeRole) {
    final target = state.appointments.firstWhere((x) => x.id == appointmentId);
    
    // Create Job Card
    createJobCard(
      customerId: target.customerId,
      vehicleId: target.vehicleId,
      complaint: complaint.isNotEmpty ? complaint : target.serviceType,
      odometer: odometer,
      activeRole: activeRole,
    );

    // Update appointment status to 'arrived'
    updateAppointmentStatus(appointmentId, 'arrived', activeRole);
  }

  void registerUser(UserAccount newUser, String activeRole) {
    state = state.copyWith(
      users: [...state.users, newUser],
    );
    _addAuditLog(activeRole, 'تسجيل مستخدم جديد', 'تم إنشاء حساب مستخدم جديد: ${newUser.name} بلقب ${newUser.username} ودور ${newUser.role.nameAr}.');
    _save();
    _syncToApi(() => _apiService.registerUser(newUser));
  }

  void toggleUserActive(String userId, bool isActive, String activeRole) {
    final updatedUsers = state.users.map((u) {
      if (u.id == userId) {
        return u.copyWith(isActive: isActive);
      }
      return u;
    }).toList();
    
    state = state.copyWith(users: updatedUsers);
    
    final target = state.users.firstWhere((x) => x.id == userId);
    _addAuditLog(activeRole, 'تغيير حالة مستخدم', 'تم تعديل حالة حساب الموظف (${target.name}) إلى ${isActive ? 'نشط' : 'معطل'}.');
    _save();
    _syncToApi(() => _apiService.toggleUserStatus(userId, isActive));
  }
}

// --- Provider Exposure ---
final appStateProvider = NotifierProvider<AppStateNotifier, AppState>(AppStateNotifier.new);
