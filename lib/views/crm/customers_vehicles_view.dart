import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/role_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import '../../models/workshop_models.dart';

class CustomersVehiclesView extends ConsumerStatefulWidget {
  const CustomersVehiclesView({super.key});

  @override
  ConsumerState<CustomersVehiclesView> createState() => _CustomersVehiclesViewState();
}

class _CustomersVehiclesViewState extends ConsumerState<CustomersVehiclesView> {
  String _searchQuery = '';
  Customer? _selectedCustomer;

  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  final _customerEmailCtrl = TextEditingController();
  final _customerAddressCtrl = TextEditingController();
  String _customerType = 'cash';
  final _customerLimitCtrl = TextEditingController();

  final _vehiclePlateCtrl = TextEditingController();
  final _vehicleChassisCtrl = TextEditingController();
  final _vehicleMakeCtrl = TextEditingController();
  final _vehicleModelCtrl = TextEditingController();
  final _vehicleYearCtrl = TextEditingController();
  final _vehicleColorCtrl = TextEditingController();
  final _vehicleOdoCtrl = TextEditingController();
  final _vehicleNotesCtrl = TextEditingController();

  final _interactionNoteCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final activeRole = ref.watch(roleProvider).nameEn;

    // Filter customers
    final filteredCustomers = state.customers.where((c) {
      final query = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(query) || c.phone.contains(query);
    }).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Customer List (40% width)
        Expanded(
          flex: 4,
          child: TonalCard(
            padding: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'دليل العملاء',
                  trailing: ElevatedButton.icon(
                    onPressed: () => _showAddCustomerDialog(context, activeRole),
                    icon: const Icon(Icons.add),
                    label: const Text('عميل جديد'),
                  ),
                ),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'البحث باسم العميل أو رقم الهاتف...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: filteredCustomers.isEmpty
                      ? const Center(child: Text('لم يتم العثور على عملاء.'))
                      : ListView.separated(
                          itemCount: filteredCustomers.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final cust = filteredCustomers[index];
                            final isSelected = _selectedCustomer?.id == cust.id;

                            return ListTile(
                              title: Text(cust.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(cust.phone),
                              trailing: Chip(
                                label: Text(cust.type == 'credit' ? 'آجل' : 'نقدي'),
                                backgroundColor: cust.type == 'credit' ? AppColors.tertiary.withOpacity(0.08) : AppColors.primary.withOpacity(0.08),
                                side: BorderSide.none,
                              ),
                              selected: isSelected,
                              selectedTileColor: AppColors.primary.withOpacity(0.05),
                              onTap: () {
                                setState(() {
                                  _selectedCustomer = cust;
                                });
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        
        // Right Column: Customer & Vehicles Details (60% width)
        Expanded(
          flex: 6,
          child: _selectedCustomer == null
              ? const TonalCard(
                  child: Center(
                    child: Text('اختر عميلاً من القائمة لعرض تفاصيل سياراته وسجل الصيانة الخاص به.'),
                  ),
                )
              : _buildCustomerDetailsPanel(state, activeRole),
        ),
      ],
    );
  }

  Widget _buildCustomerDetailsPanel(AppState state, String activeRole) {
    final customer = state.customers.firstWhere((c) => c.id == _selectedCustomer!.id);
    final linkedVehicles = state.vehicles.where((v) => v.customerId == customer.id).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Card Details
          TonalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: customer.name,
                  subtitle: customer.type == 'credit' ? 'عميل ذو حساب آجل (الحد الائتماني: ${customer.creditLimit.toStringAsFixed(0)} ج.م)' : 'عميل دفع نقدي مباشر',
                ),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('الهاتف: ${customer.phone}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('العنوان: ${customer.address}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Linked Vehicles section
          TonalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'السيارات المسجلة (${linkedVehicles.length})',
                  trailing: TextButton.icon(
                    onPressed: () => _showAddVehicleDialog(context, customer.id, activeRole),
                    icon: const Icon(Icons.add_road),
                    label: const Text('إضافة سيارة جديدة للعميل'),
                  ),
                ),
                if (linkedVehicles.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(child: Text('لا توجد سيارات مسجلة لهذا العميل حالياً.')),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: linkedVehicles.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final vehicle = linkedVehicles[index];
                      // Find service history
                      final serviceJobs = state.jobCards.where((j) => j.vehicleId == vehicle.id).toList();

                      return ExpansionTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          child: Icon(Icons.directions_car),
                        ),
                        title: Text('${vehicle.make} ${vehicle.model} (${vehicle.year})'),
                        subtitle: Text('رقم اللوحة: ${vehicle.plateNumber} | العداد الحالي: ${vehicle.odometer} كم'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('رقم الشاصيه: ${vehicle.chassisNumber}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                Text('اللون: ${vehicle.color}', style: const TextStyle(fontSize: 12)),
                                Text('ملاحظات المركبة: ${vehicle.notes.isEmpty ? "لا يوجد" : vehicle.notes}', style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 12),
                                const Text('سجل بطاقات الصيانة للسيارة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                                const SizedBox(height: 6),
                                if (serviceJobs.isEmpty)
                                  const Text('لا يوجد تاريخ صيانة مسجل لهذه السيارة بعد.', style: TextStyle(fontSize: 12, color: AppColors.textMuted))
                                else
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: serviceJobs.length,
                                    itemBuilder: (context, jIndex) {
                                      final jc = serviceJobs[jIndex];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('${jc.cardNo} (${jc.createdAt.substring(0,10)})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                            Text(jc.complaint, style: const TextStyle(fontSize: 12)),
                                            StatusBadge(status: jc.status),
                                          ],
                                        ),
                                      );
                                    },
                                  )
                              ],
                            ),
                          )
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context, String activeRole) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.person_add_alt_1, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('إضافة عميل جديد'),
                  ],
                ),
                content: SingleChildScrollView(
                  child: SizedBox(
                    width: 450,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FormFieldLabel(label: 'اسم العميل المزدوج/الرباعي'),
                        TextField(
                          controller: _customerNameCtrl,
                          decoration: const InputDecoration(hintText: 'مثال: محمد أحمد علي'),
                        ),
                        const FormFieldLabel(label: 'رقم الهاتف المحمول'),
                        TextField(
                          controller: _customerPhoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(hintText: 'مثال: 01012345678'),
                        ),
                        const FormFieldLabel(label: 'البريد الإلكتروني (اختياري)'),
                        TextField(
                          controller: _customerEmailCtrl,
                          decoration: const InputDecoration(hintText: 'ahmed@example.com'),
                        ),
                        const FormFieldLabel(label: 'العنوان السكني / موقع الشركة'),
                        TextField(
                          controller: _customerAddressCtrl,
                          decoration: const InputDecoration(hintText: 'الجيزة، مصر'),
                        ),
                        const FormFieldLabel(label: 'نوع العميل الافتراضي'),
                        Row(
                          children: [
                            Radio<String>(
                              value: 'cash',
                              groupValue: _customerType,
                              onChanged: (val) {
                                setDialogState(() {
                                  _customerType = val!;
                                });
                              },
                            ),
                            const Text('نقدي مباشر'),
                            const SizedBox(width: 24),
                            Radio<String>(
                              value: 'credit',
                              groupValue: _customerType,
                              onChanged: (val) {
                                setDialogState(() {
                                  _customerType = val!;
                                });
                              },
                            ),
                            const Text('حساب آجل (للشركات)'),
                          ],
                        ),
                        if (_customerType == 'credit') ...[
                          const FormFieldLabel(label: 'الحد الائتماني للذمم (ج.م)'),
                          TextField(
                            controller: _customerLimitCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: 'مثال: 10000'),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final name = _customerNameCtrl.text.trim();
                      final phone = _customerPhoneCtrl.text.trim();
                      if (name.isEmpty || phone.isEmpty) return;

                      ref.read(appStateProvider.notifier).addCustomer(
                            name: name,
                            phone: phone,
                            email: _customerEmailCtrl.text.trim(),
                            address: _customerAddressCtrl.text.trim(),
                            type: _customerType,
                            creditLimit: double.tryParse(_customerLimitCtrl.text.trim()) ?? 0.0,
                            activeRole: activeRole,
                          );

                      // Clear
                      _customerNameCtrl.clear();
                      _customerPhoneCtrl.clear();
                      _customerEmailCtrl.clear();
                      _customerAddressCtrl.clear();
                      _customerLimitCtrl.clear();
                      _customerType = 'cash';

                      Navigator.pop(context);
                    },
                    child: const Text('تسجيل العميل'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddVehicleDialog(BuildContext context, String customerId, String activeRole) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.time_to_leave, color: AppColors.primary),
                SizedBox(width: 8),
                Text('تسجيل سيارة جديدة للعميل'),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 450,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FormFieldLabel(label: 'رقم لوحة المركبة'),
                              TextField(
                                controller: _vehiclePlateCtrl,
                                decoration: const InputDecoration(hintText: 'مثال: أ ب ج 1234'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FormFieldLabel(label: 'رقم الشاصيه (VIN)'),
                              TextField(
                                controller: _vehicleChassisCtrl,
                                decoration: const InputDecoration(hintText: '17 حرف/رقم'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FormFieldLabel(label: 'الشركة الصانعة (الماركة)'),
                              TextField(
                                controller: _vehicleMakeCtrl,
                                decoration: const InputDecoration(hintText: 'تويوتا / مرسيدس'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FormFieldLabel(label: 'الموديل (الطراز)'),
                              TextField(
                                controller: _vehicleModelCtrl,
                                decoration: const InputDecoration(hintText: 'كورولا / C200'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FormFieldLabel(label: 'سنة الصنع'),
                              TextField(
                                controller: _vehicleYearCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(hintText: '2022'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FormFieldLabel(label: 'اللون الخارجي'),
                              TextField(
                                controller: _vehicleColorCtrl,
                                decoration: const InputDecoration(hintText: 'أسود ميتاليك'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const FormFieldLabel(label: 'عداد الكيلومتر الحالي (Odometer)'),
                    TextField(
                      controller: _vehicleOdoCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: '60000 كم'),
                    ),
                    const FormFieldLabel(label: 'ملاحظات وحالة وصول السيارة'),
                    TextField(
                      controller: _vehicleNotesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(hintText: 'خدوش في المصد الخلفي...'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  final plate = _vehiclePlateCtrl.text.trim();
                  final make = _vehicleMakeCtrl.text.trim();
                  if (plate.isEmpty || make.isEmpty) return;

                  ref.read(appStateProvider.notifier).addVehicle(
                        customerId: customerId,
                        plateNumber: plate,
                        chassisNumber: _vehicleChassisCtrl.text.trim(),
                        make: make,
                        model: _vehicleModelCtrl.text.trim(),
                        year: _vehicleYearCtrl.text.trim(),
                        color: _vehicleColorCtrl.text.trim(),
                        odometer: int.tryParse(_vehicleOdoCtrl.text.trim()) ?? 0,
                        notes: _vehicleNotesCtrl.text.trim(),
                        activeRole: activeRole,
                      );

                  // Clear
                  _vehiclePlateCtrl.clear();
                  _vehicleChassisCtrl.clear();
                  _vehicleMakeCtrl.clear();
                  _vehicleModelCtrl.clear();
                  _vehicleYearCtrl.clear();
                  _vehicleColorCtrl.clear();
                  _vehicleOdoCtrl.clear();
                  _vehicleNotesCtrl.clear();

                  Navigator.pop(context);
                },
                child: const Text('تسجيل المركبة'),
              ),
            ],
          ),
        );
      },
    );
  }
}
