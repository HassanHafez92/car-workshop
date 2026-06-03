import 'dart:convert';

class Customer {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String type; // 'cash' or 'credit'
  final double creditLimit;
  final bool isActive;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.type,
    required this.creditLimit,
    required this.isActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'type': type,
      'creditLimit': creditLimit,
      'isActive': isActive,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      type: map['type'] ?? 'cash',
      creditLimit: (map['creditLimit'] as num?)?.toDouble() ?? 0.0,
      isActive: map['isActive'] ?? true,
    );
  }

  String toJson() => json.encode(toMap());
  factory Customer.fromJson(String source) => Customer.fromMap(json.decode(source));
}

class Vehicle {
  final String id;
  final String customerId;
  final String plateNumber;
  final String chassisNumber;
  final String make;
  final String model;
  final String year;
  final String color;
  final int odometer;
  final String notes;

  Vehicle({
    required this.id,
    required this.customerId,
    required this.plateNumber,
    required this.chassisNumber,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.odometer,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'plateNumber': plateNumber,
      'chassisNumber': chassisNumber,
      'make': make,
      'model': model,
      'year': year,
      'color': color,
      'odometer': odometer,
      'notes': notes,
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] ?? '',
      customerId: map['customerId'] ?? '',
      plateNumber: map['plateNumber'] ?? '',
      chassisNumber: map['chassisNumber'] ?? '',
      make: map['make'] ?? '',
      model: map['model'] ?? '',
      year: map['year'] ?? '',
      color: map['color'] ?? '',
      odometer: map['odometer'] ?? 0,
      notes: map['notes'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());
  factory Vehicle.fromJson(String source) => Vehicle.fromMap(json.decode(source));
}

class Supplier {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String paymentTerms; // 'cash' or 'credit'
  final bool isActive;

  Supplier({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.paymentTerms,
    required this.isActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'paymentTerms': paymentTerms,
      'isActive': isActive,
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      paymentTerms: map['paymentTerms'] ?? 'cash',
      isActive: map['isActive'] ?? true,
    );
  }

  String toJson() => json.encode(toMap());
  factory Supplier.fromJson(String source) => Supplier.fromMap(json.decode(source));
}

class Part {
  final String id;
  final String code;
  final String name;
  final String category;
  final String brand;
  final String compatibleModels;
  final int minStock;
  final String unit;
  final double defaultPurchasePrice;
  final double defaultSellingPrice;
  final double targetMargin;
  final String location; // 'main_store', 'sub_store', etc.
  final int stockCount;

  Part({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.brand,
    required this.compatibleModels,
    required this.minStock,
    required this.unit,
    required this.defaultPurchasePrice,
    required this.defaultSellingPrice,
    required this.targetMargin,
    required this.location,
    required this.stockCount,
  });

  Part copyWith({
    String? id,
    String? code,
    String? name,
    String? category,
    String? brand,
    String? compatibleModels,
    int? minStock,
    String? unit,
    double? defaultPurchasePrice,
    double? defaultSellingPrice,
    double? targetMargin,
    String? location,
    int? stockCount,
  }) {
    return Part(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      compatibleModels: compatibleModels ?? this.compatibleModels,
      minStock: minStock ?? this.minStock,
      unit: unit ?? this.unit,
      defaultPurchasePrice: defaultPurchasePrice ?? this.defaultPurchasePrice,
      defaultSellingPrice: defaultSellingPrice ?? this.defaultSellingPrice,
      targetMargin: targetMargin ?? this.targetMargin,
      location: location ?? this.location,
      stockCount: stockCount ?? this.stockCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'category': category,
      'brand': brand,
      'compatibleModels': compatibleModels,
      'minStock': minStock,
      'unit': unit,
      'defaultPurchasePrice': defaultPurchasePrice,
      'defaultSellingPrice': defaultSellingPrice,
      'targetMargin': targetMargin,
      'location': location,
      'stockCount': stockCount,
    };
  }

  factory Part.fromMap(Map<String, dynamic> map) {
    return Part(
      id: map['id'] ?? '',
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      brand: map['brand'] ?? '',
      compatibleModels: map['compatibleModels'] ?? '',
      minStock: map['minStock'] ?? 0,
      unit: map['unit'] ?? 'pcs',
      defaultPurchasePrice: (map['defaultPurchasePrice'] as num?)?.toDouble() ?? 0.0,
      defaultSellingPrice: (map['defaultSellingPrice'] as num?)?.toDouble() ?? 0.0,
      targetMargin: (map['targetMargin'] as num?)?.toDouble() ?? 0.0,
      location: map['location'] ?? 'main_store',
      stockCount: map['stockCount'] ?? 0,
    );
  }

  String toJson() => json.encode(toMap());
  factory Part.fromJson(String source) => Part.fromMap(json.decode(source));
}

class StockMovement {
  final String id;
  final String partId;
  final String type; // 'receipt', 'issue', 'return', 'adjustment'
  final int quantity;
  final String referenceId;
  final String date;
  final String notes;

  StockMovement({
    required this.id,
    required this.partId,
    required this.type,
    required this.quantity,
    required this.referenceId,
    required this.date,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'partId': partId,
      'type': type,
      'quantity': quantity,
      'referenceId': referenceId,
      'date': date,
      'notes': notes,
    };
  }

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'] ?? '',
      partId: map['partId'] ?? '',
      type: map['type'] ?? '',
      quantity: map['quantity'] ?? 0,
      referenceId: map['referenceId'] ?? '',
      date: map['date'] ?? '',
      notes: map['notes'] ?? '',
    );
  }
}

class TimeLog {
  final String start;
  final String? end;

  TimeLog({required this.start, this.end});

  Map<String, dynamic> toMap() {
    return {'start': start, 'end': end};
  }

  factory TimeLog.fromMap(Map<String, dynamic> map) {
    return TimeLog(
      start: map['start'] ?? '',
      end: map['end'],
    );
  }
}

class JobTask {
  final String id;
  final String description;
  final String type; // 'mechanical', 'electrical', 'body', 'ac', 'tuning'
  final String technicianName;
  final double estimatedHours;
  final double price;
  final String status; // 'pending', 'active', 'completed'
  final List<TimeLog> timeLogs;

  JobTask({
    required this.id,
    required this.description,
    required this.type,
    required this.technicianName,
    required this.estimatedHours,
    required this.price,
    required this.status,
    required this.timeLogs,
  });

  JobTask copyWith({
    String? id,
    String? description,
    String? type,
    String? technicianName,
    double? estimatedHours,
    double? price,
    String? status,
    List<TimeLog>? timeLogs,
  }) {
    return JobTask(
      id: id ?? this.id,
      description: description ?? this.description,
      type: type ?? this.type,
      technicianName: technicianName ?? this.technicianName,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      price: price ?? this.price,
      status: status ?? this.status,
      timeLogs: timeLogs ?? this.timeLogs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'type': type,
      'technicianName': technicianName,
      'estimatedHours': estimatedHours,
      'price': price,
      'status': status,
      'timeLogs': timeLogs.map((x) => x.toMap()).toList(),
    };
  }

  factory JobTask.fromMap(Map<String, dynamic> map) {
    return JobTask(
      id: map['id'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] ?? 'mechanical',
      technicianName: map['technicianName'] ?? '',
      estimatedHours: (map['estimatedHours'] as num?)?.toDouble() ?? 0.0,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'pending',
      timeLogs: List<TimeLog>.from((map['timeLogs'] as List? ?? []).map((x) => TimeLog.fromMap(x))),
    );
  }
}

class JobPart {
  final String id;
  final String partId;
  final String code;
  final String name;
  final int quantity;
  final double price;

  JobPart({
    required this.id,
    required this.partId,
    required this.code,
    required this.name,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'partId': partId,
      'code': code,
      'name': name,
      'quantity': quantity,
      'price': price,
    };
  }

  factory JobPart.fromMap(Map<String, dynamic> map) {
    return JobPart(
      id: map['id'] ?? '',
      partId: map['partId'] ?? '',
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? 0,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class StatusLog {
  final String status;
  final String timestamp;
  final String userRole;

  StatusLog({
    required this.status,
    required this.timestamp,
    required this.userRole,
  });

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'timestamp': timestamp,
      'userRole': userRole,
    };
  }

  factory StatusLog.fromMap(Map<String, dynamic> map) {
    return StatusLog(
      status: map['status'] ?? '',
      timestamp: map['timestamp'] ?? '',
      userRole: map['userRole'] ?? '',
    );
  }
}

class JobCard {
  final String id;
  final String cardNo;
  final String customerId;
  final String vehicleId;
  final String complaint;
  final int odometer;
  final String status; // 'New', 'Under Inspection', 'Waiting Customer Approval', 'In Progress', 'Waiting Parts', 'Completed', 'Delivered'
  final List<JobTask> tasks;
  final List<JobPart> parts;
  final String createdAt;
  final List<StatusLog> statusLogs;

  JobCard({
    required this.id,
    required this.cardNo,
    required this.customerId,
    required this.vehicleId,
    required this.complaint,
    required this.odometer,
    required this.status,
    required this.tasks,
    required this.parts,
    required this.createdAt,
    required this.statusLogs,
  });

  JobCard copyWith({
    String? id,
    String? cardNo,
    String? customerId,
    String? vehicleId,
    String? complaint,
    int? odometer,
    String? status,
    List<JobTask>? tasks,
    List<JobPart>? parts,
    String? createdAt,
    List<StatusLog>? statusLogs,
  }) {
    return JobCard(
      id: id ?? this.id,
      cardNo: cardNo ?? this.cardNo,
      customerId: customerId ?? this.customerId,
      vehicleId: vehicleId ?? this.vehicleId,
      complaint: complaint ?? this.complaint,
      odometer: odometer ?? this.odometer,
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      parts: parts ?? this.parts,
      createdAt: createdAt ?? this.createdAt,
      statusLogs: statusLogs ?? this.statusLogs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cardNo': cardNo,
      'customerId': customerId,
      'vehicleId': vehicleId,
      'complaint': complaint,
      'odometer': odometer,
      'status': status,
      'tasks': tasks.map((x) => x.toMap()).toList(),
      'parts': parts.map((x) => x.toMap()).toList(),
      'createdAt': createdAt,
      'statusLogs': statusLogs.map((x) => x.toMap()).toList(),
    };
  }

  factory JobCard.fromMap(Map<String, dynamic> map) {
    return JobCard(
      id: map['id'] ?? '',
      cardNo: map['cardNo'] ?? '',
      customerId: map['customerId'] ?? '',
      vehicleId: map['vehicleId'] ?? '',
      complaint: map['complaint'] ?? '',
      odometer: map['odometer'] ?? 0,
      status: map['status'] ?? 'New',
      tasks: List<JobTask>.from((map['tasks'] as List? ?? []).map((x) => JobTask.fromMap(x))),
      parts: List<JobPart>.from((map['parts'] as List? ?? []).map((x) => JobPart.fromMap(x))),
      createdAt: map['createdAt'] ?? '',
      statusLogs: List<StatusLog>.from((map['statusLogs'] as List? ?? []).map((x) => StatusLog.fromMap(x))),
    );
  }
}

class Invoice {
  final String id;
  final String invoiceNo;
  final String jobCardId;
  final String customerId;
  final String vehicleId;
  final double laborTotal;
  final double partsTotal;
  final double discount;
  final double tax;
  final double netTotal;
  final String status; // 'pending_accounting', 'posted'
  final String paymentMethod; // 'cash', 'card', 'transfer', 'credit'
  final String createdAt;

  Invoice({
    required this.id,
    required this.invoiceNo,
    required this.jobCardId,
    required this.customerId,
    required this.vehicleId,
    required this.laborTotal,
    required this.partsTotal,
    required this.discount,
    required this.tax,
    required this.netTotal,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
  });

  Invoice copyWith({
    String? id,
    String? invoiceNo,
    String? jobCardId,
    String? customerId,
    String? vehicleId,
    double? laborTotal,
    double? partsTotal,
    double? discount,
    double? tax,
    double? netTotal,
    String? status,
    String? paymentMethod,
    String? createdAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      jobCardId: jobCardId ?? this.jobCardId,
      customerId: customerId ?? this.customerId,
      vehicleId: vehicleId ?? this.vehicleId,
      laborTotal: laborTotal ?? this.laborTotal,
      partsTotal: partsTotal ?? this.partsTotal,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      netTotal: netTotal ?? this.netTotal,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNo': invoiceNo,
      'jobCardId': jobCardId,
      'customerId': customerId,
      'vehicleId': vehicleId,
      'laborTotal': laborTotal,
      'partsTotal': partsTotal,
      'discount': discount,
      'tax': tax,
      'netTotal': netTotal,
      'status': status,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] ?? '',
      invoiceNo: map['invoiceNo'] ?? '',
      jobCardId: map['jobCardId'] ?? '',
      customerId: map['customerId'] ?? '',
      vehicleId: map['vehicleId'] ?? '',
      laborTotal: (map['laborTotal'] as num?)?.toDouble() ?? 0.0,
      partsTotal: (map['partsTotal'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0.0,
      netTotal: (map['netTotal'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'pending_accounting',
      paymentMethod: map['paymentMethod'] ?? 'cash',
      createdAt: map['createdAt'] ?? '',
    );
  }
}

class LedgerEntry {
  final String id;
  final String partyId; // Customer or Supplier ID
  final String partyType; // 'customer' or 'supplier'
  final String type; // 'invoice', 'payment', 'discount', 'adjustment'
  final String date;
  final String referenceNo;
  final double debit;
  final double credit;
  final double balance;

  LedgerEntry({
    required this.id,
    required this.partyId,
    required this.partyType,
    required this.type,
    required this.date,
    required this.referenceNo,
    required this.debit,
    required this.credit,
    required this.balance,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'partyId': partyId,
      'partyType': partyType,
      'type': type,
      'date': date,
      'referenceNo': referenceNo,
      'debit': debit,
      'credit': credit,
      'balance': balance,
    };
  }

  factory LedgerEntry.fromMap(Map<String, dynamic> map) {
    return LedgerEntry(
      id: map['id'] ?? '',
      partyId: map['partyId'] ?? '',
      partyType: map['partyType'] ?? 'customer',
      type: map['type'] ?? '',
      date: map['date'] ?? '',
      referenceNo: map['referenceNo'] ?? '',
      debit: (map['debit'] as num?)?.toDouble() ?? 0.0,
      credit: (map['credit'] as num?)?.toDouble() ?? 0.0,
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Appointment {
  final String id;
  final String customerId;
  final String vehicleId;
  final String dateTime;
  final String serviceType;
  final String status; // 'confirmed', 'arrived', 'cancelled'
  final String assignedBay;

  Appointment({
    required this.id,
    required this.customerId,
    required this.vehicleId,
    required this.dateTime,
    required this.serviceType,
    required this.status,
    required this.assignedBay,
  });

  Appointment copyWith({
    String? id,
    String? customerId,
    String? vehicleId,
    String? dateTime,
    String? serviceType,
    String? status,
    String? assignedBay,
  }) {
    return Appointment(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      vehicleId: vehicleId ?? this.vehicleId,
      dateTime: dateTime ?? this.dateTime,
      serviceType: serviceType ?? this.serviceType,
      status: status ?? this.status,
      assignedBay: assignedBay ?? this.assignedBay,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'vehicleId': vehicleId,
      'dateTime': dateTime,
      'serviceType': serviceType,
      'status': status,
      'assignedBay': assignedBay,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'] ?? '',
      customerId: map['customerId'] ?? '',
      vehicleId: map['vehicleId'] ?? '',
      dateTime: map['dateTime'] ?? '',
      serviceType: map['serviceType'] ?? '',
      status: map['status'] ?? 'confirmed',
      assignedBay: map['assignedBay'] ?? '',
    );
  }
}

class AuditLog {
  final String id;
  final String timestamp;
  final String userRole;
  final String action;
  final String details;

  AuditLog({
    required this.id,
    required this.timestamp,
    required this.userRole,
    required this.action,
    required this.details,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp,
      'userRole': userRole,
      'action': action,
      'details': details,
    };
  }

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      id: map['id'] ?? '',
      timestamp: map['timestamp'] ?? '',
      userRole: map['userRole'] ?? '',
      action: map['action'] ?? '',
      details: map['details'] ?? '',
    );
  }
}
