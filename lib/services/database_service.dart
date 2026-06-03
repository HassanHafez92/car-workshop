import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseService {
  static const String _dbKey = 'car_workshop_database_v1';

  Future<void> saveState(Map<String, dynamic> stateData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dbKey, json.encode(stateData));
  }

  Future<Map<String, dynamic>?> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_dbKey);
    if (jsonStr == null) return null;
    try {
      return json.decode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<void> clearDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dbKey);
  }

  Map<String, dynamic> getMockInitialData() {
    final now = DateTime.now().toIso8601String().substring(0, 10);
    
    return {
      'users': [
        {
          'id': 'user_admin',
          'name': 'حسن شعبان (المدير)',
          'username': 'admin',
          'password': 'admin123',
          'role': 0, // admin
          'isActive': true,
        },
        {
          'id': 'user_reception',
          'name': 'علي عثمان (الاستقبال)',
          'username': 'reception',
          'password': 'rec123',
          'role': 1, // receptionist
          'isActive': true,
        },
        {
          'id': 'user_tech',
          'name': 'م. محمود علي (الفني)',
          'username': 'tech',
          'password': 'tech123',
          'role': 2, // technician
          'isActive': true,
        },
        {
          'id': 'user_store',
          'name': 'سامي محمود (أمين المستودع)',
          'username': 'store',
          'password': 'store123',
          'role': 3, // storekeeper
          'isActive': true,
        },
        {
          'id': 'user_accountant',
          'name': 'ممدوح رأفت (المحاسب)',
          'username': 'accountant',
          'password': 'acc123',
          'role': 4, // accountant
          'isActive': true,
        },
      ],
      'customers': [
        {
          'id': 'cust_1',
          'name': 'أحمد محمد الخطيب',
          'phone': '01012345678',
          'email': 'ahmed@example.com',
          'address': 'الدقي، الجيزة، مصر',
          'type': 'cash',
          'creditLimit': 0.0,
          'isActive': true,
        },
        {
          'id': 'cust_2',
          'name': 'شركة النقل اللوجستي السريع',
          'phone': '0229876543',
          'email': 'info@logistic-transport.com',
          'address': 'مصر الجديدة، القاهرة',
          'type': 'credit',
          'creditLimit': 50000.0,
          'isActive': true,
        }
      ],
      'vehicles': [
        {
          'id': 'veh_1',
          'customerId': 'cust_1',
          'plateNumber': 'أ ب ج 1234',
          'chassisNumber': 'MRH53G12345678',
          'make': 'تويوتا',
          'model': 'كورولا',
          'year': '2021',
          'color': 'فضي ميتاليك',
          'odometer': 65400,
          'notes': 'صيانات دورية منتظمة',
        },
        {
          'id': 'veh_2',
          'customerId': 'cust_2',
          'plateNumber': 'ط ي ر 9876',
          'chassisNumber': 'KMH84F87654321',
          'make': 'هيونداي',
          'model': 'إلنترا',
          'year': '2020',
          'color': 'أبيض لؤلؤي',
          'odometer': 120500,
          'notes': 'سيارة تشغيل يومي للشركة',
        }
      ],
      'suppliers': [
        {
          'id': 'supp_1',
          'name': 'الشركة الوطنية لقطع غيار السيارات',
          'phone': '01234567890',
          'address': 'وسط البلد، القاهرة',
          'paymentTerms': 'credit',
          'isActive': true,
        },
        {
          'id': 'supp_2',
          'name': 'موزع فلاتر وزيوت الأمل الدائري',
          'phone': '01123456789',
          'address': 'المعادي، القاهرة',
          'paymentTerms': 'cash',
          'isActive': true,
        }
      ],
      'parts': [
        {
          'id': 'part_1',
          'code': 'OIL-5W30-SYN',
          'name': 'زيت محرك تخليقي بالكامل 5W30 (4 لتر)',
          'category': 'زيوت ومواد تزييت',
          'brand': 'موبيل 1',
          'compatibleModels': 'جميع الموديلات الحديثة',
          'minStock': 10,
          'unit': 'عبوة',
          'defaultPurchasePrice': 450.0,
          'defaultSellingPrice': 650.0,
          'targetMargin': 44.4,
          'location': 'مستودع رئيسي - الرف أ3',
          'stockCount': 25,
        },
        {
          'id': 'part_2',
          'code': 'BRK-TOY-COR-F',
          'name': 'فحمات فرامل أمامية كورولا',
          'category': 'نظام الفرامل',
          'brand': 'تويوتا أصلي',
          'compatibleModels': 'تويوتا كورولا 2019-2023',
          'minStock': 5,
          'unit': 'طقم',
          'defaultPurchasePrice': 350.0,
          'defaultSellingPrice': 550.0,
          'targetMargin': 57.1,
          'location': 'مستودع رئيسي - الرف ب12',
          'stockCount': 3, // Low Stock Alert active!
        },
        {
          'id': 'part_3',
          'code': 'FLT-OIL-TOY-01',
          'name': 'فلتر زيت محرك كورولا',
          'category': 'فلاتر',
          'brand': 'تويوتا أصلي',
          'compatibleModels': 'تويوتا كورولا ويارس وبيلتا',
          'minStock': 15,
          'unit': 'حبة',
          'defaultPurchasePrice': 60.0,
          'defaultSellingPrice': 100.0,
          'targetMargin': 66.6,
          'location': 'مستودع فرعي - درج الفلاتر',
          'stockCount': 40,
        }
      ],
      'stock_movements': [
        {
          'id': 'mov_1',
          'partId': 'part_1',
          'type': 'receipt',
          'quantity': 25,
          'referenceId': 'PINV-1002',
          'date': now,
          'notes': 'رصيد بداية المدة الافتراضي للمخزن',
        },
        {
          'id': 'mov_2',
          'partId': 'part_2',
          'type': 'receipt',
          'quantity': 3,
          'referenceId': 'PINV-1002',
          'date': now,
          'notes': 'شراء رصيد افتتاحي للمخزن',
        },
        {
          'id': 'mov_3',
          'partId': 'part_3',
          'type': 'receipt',
          'quantity': 40,
          'referenceId': 'PINV-1003',
          'date': now,
          'notes': 'استلام فلاتر من مورد الزيوت',
        }
      ],
      'appointments': [
        {
          'id': 'app_1',
          'customerId': 'cust_1',
          'vehicleId': 'veh_1',
          'dateTime': '$now 10:00',
          'serviceType': 'صيانة دورية 60 ألف كم',
          'status': 'confirmed',
          'assignedBay': 'مجرى رقم 1',
        },
        {
          'id': 'app_2',
          'customerId': 'cust_2',
          'vehicleId': 'veh_2',
          'dateTime': '$now 13:00',
          'serviceType': 'فحص أصوات في نظام التعليق والفرامل',
          'status': 'arrived',
          'assignedBay': 'مجرى رقم 3 - فحص هيدروليك',
        }
      ],
      'job_cards': [
        {
          'id': 'job_1',
          'cardNo': 'JC-2026-0001',
          'customerId': 'cust_1',
          'vehicleId': 'veh_1',
          'complaint': 'تغيير زيت المحرك والفلتر وصيانة الفرامل الخلفية',
          'odometer': 65400,
          'status': 'In Progress',
          'tasks': [
            {
              'id': 'task_1_1',
              'description': 'تغيير زيت وفلتر زيت المحرك',
              'type': 'mechanical',
              'technicianName': 'م. محمود علي',
              'estimatedHours': 0.5,
              'price': 100.0,
              'status': 'active',
              'timeLogs': [
                {
                  'start': DateTime.now().subtract(const Duration(minutes: 20)).toIso8601String(),
                  'end': null,
                }
              ],
            },
            {
              'id': 'task_1_2',
              'description': 'فحص وتنظيف نظام الفرامل الخلفية والمحور',
              'type': 'mechanical',
              'technicianName': 'م. محمود علي',
              'estimatedHours': 1.0,
              'price': 150.0,
              'status': 'pending',
              'timeLogs': [],
            }
          ],
          'parts': [
            {
              'id': 'jpart_1_1',
              'partId': 'part_1',
              'code': 'OIL-5W30-SYN',
              'name': 'زيت محرك تخليقي بالكامل 5W30 (4 لتر)',
              'quantity': 1,
              'price': 650.0,
            },
            {
              'id': 'jpart_1_2',
              'partId': 'part_3',
              'code': 'FLT-OIL-TOY-01',
              'name': 'فلتر زيت محرك كورولا',
              'quantity': 1,
              'price': 100.0,
            }
          ],
          'createdAt': '$now 08:30',
          'statusLogs': [
            {
              'status': 'New',
              'timestamp': '$now 08:30',
              'userRole': 'Receptionist',
            },
            {
              'status': 'Under Inspection',
              'timestamp': '$now 08:45',
              'userRole': 'Receptionist',
            },
            {
              'status': 'In Progress',
              'timestamp': '$now 09:10',
              'userRole': 'Technician',
            }
          ],
        }
      ],
      'invoices': [],
      'ledger_entries': [],
      'audit_logs': [
        {
          'id': 'aud_1',
          'timestamp': '$now 08:00',
          'userRole': 'Admin',
          'action': 'تهيئة النظام',
          'details': 'بدء النظام وتهيئة مستودع قطع الغيار والبيانات الافتراضية بنجاح.',
        },
        {
          'id': 'aud_2',
          'timestamp': '$now 08:30',
          'userRole': 'Receptionist',
          'action': 'فتح كرت صيانة جديد',
          'details': 'تم إنشاء كرت العمل رقم JC-2026-0001 للعميل أحمد محمد الخطيب.',
        }
      ]
    };
  }
}
