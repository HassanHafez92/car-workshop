class NotificationLog {
  final String id;
  final String type; // 'sms', 'whatsapp', 'in_app'
  final String recipient; // Phone number or Staff Role
  final String message;
  final String timestamp;
  final bool isRead;

  NotificationLog({
    required this.id,
    required this.type,
    required this.recipient,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'recipient': recipient,
      'message': message,
      'timestamp': timestamp,
      'isRead': isRead,
    };
  }

  factory NotificationLog.fromMap(Map<String, dynamic> map) {
    return NotificationLog(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      recipient: map['recipient'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] ?? '',
      isRead: map['isRead'] ?? false,
    );
  }
}

class NotificationService {
  final List<NotificationLog> _logs = [];

  List<NotificationLog> get logs => List.unmodifiable(_logs);

  void addLog(NotificationLog log) {
    _logs.insert(0, log);
  }

  void triggerCustomerAlert({
    required String customerName,
    required String phone,
    required String vehicleInfo,
    required String status,
    double? invoiceAmount,
  }) {
    final now = DateTime.now().toIso8601String().substring(11, 16);
    String message = '';
    
    switch (status) {
      case 'Under Inspection':
        message = 'عزيزي $customerName، تم إدخال سيارتك ($vehicleInfo) للورشة وهي الآن قيد الفحص والتشخيص. سنوافيك بالتفاصيل قريباً.';
        break;
      case 'Waiting Customer Approval':
        message = 'عزيزي $customerName، تم الانتهاء من فحص سيارتك ($vehicleInfo). يرجى مراجعة وتأكيد خطة العمل وقطع الغيار المطلوبة للبدء بالإصلاح.';
        break;
      case 'In Progress':
        message = 'عزيزي $customerName، تمت الموافقة، وبدأ الفني المختص بالعمل على إصلاح سيارتك ($vehicleInfo) الآن.';
        break;
      case 'Completed':
        message = 'عزيزي $customerName، يسعدنا إبلاغك بانتهاء العمل على سيارتك ($vehicleInfo) بنجاح. السيارة جاهزة للاستلام الآن.';
        if (invoiceAmount != null) {
          message += ' الفاتورة التقريبية: ${invoiceAmount.toStringAsFixed(2)} ج.م.';
        }
        break;
      case 'Delivered':
        message = 'شكرًا لتعاملك معنا يا سيد $customerName. نأمل أن تكون راضياً عن الخدمة المقدمة لسيارتك ($vehicleInfo). رافقتك السلامة!';
        break;
      default:
        message = 'عزيزي $customerName، تم تحديث حالة كرت الصيانة لسيارتك ($vehicleInfo) إلى: $status.';
    }

    // Simulate SMS
    addLog(NotificationLog(
      id: 'sms_${DateTime.now().millisecondsSinceEpoch}',
      type: 'sms',
      recipient: phone,
      message: message,
      timestamp: now,
    ));

    // Simulate WhatsApp
    addLog(NotificationLog(
      id: 'wa_${DateTime.now().millisecondsSinceEpoch}',
      type: 'whatsapp',
      recipient: phone,
      message: '[رسالة واتساب تلقائية]:\n$message',
      timestamp: now,
    ));
  }

  void triggerStaffAlert({
    required String staffRole,
    required String message,
  }) {
    final now = DateTime.now().toIso8601String().substring(11, 16);
    addLog(NotificationLog(
      id: 'app_${DateTime.now().millisecondsSinceEpoch}',
      type: 'in_app',
      recipient: staffRole,
      message: message,
      timestamp: now,
    ));
  }

  void clearLogs() {
    _logs.clear();
  }
}
