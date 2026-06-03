import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/role_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import '../../models/workshop_models.dart';

class CalendarView extends ConsumerStatefulWidget {
  const CalendarView({super.key});

  @override
  ConsumerState<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView> {
  String? _selectedCustId;
  String? _selectedVehId;
  final _serviceTypeCtrl = TextEditingController();
  final _bayCtrl = TextEditingController(text: 'مجرى رقم 1');
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);

  final _checkInOdoCtrl = TextEditingController();
  final _checkInComplaintCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final activeRole = ref.watch(roleProvider).nameEn;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Calendar List & Appointments Scheduling Timeline (60% width)
        Expanded(
          flex: 6,
          child: TonalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'جدول حجز مواعيد الورشة',
                  subtitle: 'تتبع مواعيد الحجز المسبق للمركبات لتفادي ازدحام الممرات',
                  trailing: ElevatedButton.icon(
                    onPressed: () => _showAddAppointmentDialog(context, state, activeRole),
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('حجز موعد صيانة'),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: state.appointments.isEmpty
                      ? const Center(child: Text('لا توجد مواعيد محجوزة في الجدول حالياً.'))
                      : ListView.separated(
                          itemCount: state.appointments.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final app = state.appointments[index];
                            final cust = state.customers.firstWhere((x) => x.id == app.customerId);
                            final veh = state.vehicles.firstWhere((x) => x.id == app.vehicleId);

                            final isConfirmed = app.status == 'confirmed';

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isConfirmed ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceLow,
                                child: const Icon(Icons.access_time_filled, color: AppColors.primary),
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${veh.make} ${veh.model} - لوحة ${veh.plateNumber}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(app.dateTime, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text('العميل: ${cust.name} | البند: ${app.serviceType}\nالمسار: ${app.assignedBay}'),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  StatusBadge(status: app.status),
                                  const SizedBox(width: 8),
                                  if (isConfirmed) ...[
                                    ElevatedButton(
                                      onPressed: () => _showCheckInDialog(context, app, activeRole),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                      ),
                                      child: const Text('تسجيل دخول'),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
                                      onPressed: () {
                                        ref.read(appStateProvider.notifier).updateAppointmentStatus(app.id, 'cancelled', activeRole);
                                      },
                                    )
                                  ]
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Right Column: Diagnostic status or visual guidelines card (40% width)
        const Expanded(
          flex: 4,
          child: TonalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'إرشادات الاستقبال والجدولة',
                  subtitle: 'ضوابط توزيع الممرات والرافعات المعتمدة بالمركز',
                ),
                Text(
                  '1. يرجى توجيه العميل إلى الممر المناسب بناءً على طبيعة الخدمة (ميكانيكا، فرامل، تشخيص).\n\n'
                  '2. عملية تسجيل الدخول بنقرة واحدة (1-Click Check-in) تقوم فوراً بتوليد كرت صيانة وحفظ قراءة العداد لتفادي التأخير.\n\n'
                  '3. في حال رغبة العميل بالإلغاء، يرجى تدوين السبب في سجل الملاحظات للعميل للرجوع إليه لاحقاً.',
                  style: TextStyle(height: 1.8),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddAppointmentDialog(BuildContext context, AppState state, String activeRole) {
    _selectedCustId = state.customers.isNotEmpty ? state.customers.first.id : null;
    _selectedVehId = _selectedCustId != null
        ? (state.vehicles.where((v) => v.customerId == _selectedCustId).isNotEmpty
            ? state.vehicles.where((v) => v.customerId == _selectedCustId).first.id
            : null)
        : null;
    _serviceTypeCtrl.clear();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final customerVehicles = _selectedCustId != null
                ? state.vehicles.where((v) => v.customerId == _selectedCustId).toList()
                : <Vehicle>[];

            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.calendar_today, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('حجز موعد صيانة جديد'),
                  ],
                ),
                content: SingleChildScrollView(
                  child: SizedBox(
                    width: 480,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Customer selection
                        const FormFieldLabel(label: 'اسم العميل'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceLow,
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCustId,
                              isExpanded: true,
                              items: state.customers.map((c) {
                                return DropdownMenuItem<String>(
                                  value: c.id,
                                  child: Text(c.name),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setDialogState(() {
                                  _selectedCustId = val;
                                  final list = state.vehicles.where((v) => v.customerId == val).toList();
                                  _selectedVehId = list.isNotEmpty ? list.first.id : null;
                                });
                              },
                            ),
                          ),
                        ),

                        // Vehicle Selection
                        const FormFieldLabel(label: 'سيارة العميل'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceLow,
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedVehId,
                              isExpanded: true,
                              hint: const Text('لم يتم تسجيل مركبات لهذا العميل'),
                              items: customerVehicles.map((v) {
                                return DropdownMenuItem<String>(
                                  value: v.id,
                                  child: Text('${v.make} ${v.model} (${v.plateNumber})'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setDialogState(() {
                                  _selectedVehId = val;
                                });
                              },
                            ),
                          ),
                        ),

                        // Date & Time Picker triggers
                        const FormFieldLabel(label: 'تاريخ ووقت الموعد'),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 90)),
                                  );
                                  if (picked != null) {
                                    setDialogState(() {
                                      _selectedDate = picked;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.date_range),
                                label: Text('${_selectedDate.toIso8601String().substring(0, 10)}'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: _selectedTime,
                                  );
                                  if (picked != null) {
                                    setDialogState(() {
                                      _selectedTime = picked;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.access_time),
                                label: Text('${_selectedTime.format(context)}'),
                              ),
                            ),
                          ],
                        ),

                        const FormFieldLabel(label: 'نوع الصيانة والخدمة المطلوبة'),
                        TextField(
                          controller: _serviceTypeCtrl,
                          decoration: const InputDecoration(hintText: 'صيانة دورية 40ألف كم، فحص تسريب زيت...'),
                        ),

                        const FormFieldLabel(label: 'ممر الصيانة المسند إليه (Bay)'),
                        TextField(
                          controller: _bayCtrl,
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
                    onPressed: _selectedCustId == null || _selectedVehId == null
                        ? null
                        : () {
                            final hoursStr = _selectedTime.hour.toString().padLeft(2, '0');
                            final minsStr = _selectedTime.minute.toString().padLeft(2, '0');
                            final dateTimeStr = '${_selectedDate.toIso8601String().substring(0, 10)} $hoursStr:$minsStr';

                            ref.read(appStateProvider.notifier).addAppointment(
                                  customerId: _selectedCustId!,
                                  vehicleId: _selectedVehId!,
                                  dateTime: dateTimeStr,
                                  serviceType: _serviceTypeCtrl.text.trim(),
                                  assignedBay: _bayCtrl.text.trim(),
                                  activeRole: activeRole,
                                );
                            Navigator.pop(context);
                          },
                    child: const Text('تأكيد الحجز المسبق'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCheckInDialog(BuildContext context, Appointment app, String activeRole) {
    _checkInOdoCtrl.clear();
    _checkInComplaintCtrl.text = app.serviceType;

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تسجيل دخول المركبة وفتح كرت صيانة'),
            content: SizedBox(
              width: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('تم وصول العميل للورشة في الموعد المحدّد. يرجى ملء التفاصيل المتبقية للبدء فورا:'),
                  const SizedBox(height: 12),
                  const FormFieldLabel(label: 'قراءة عداد الكيلومتر عند الدخول'),
                  TextField(
                    controller: _checkInOdoCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'مثال: 65400 كم'),
                  ),
                  const FormFieldLabel(label: 'تأكيد الشكوى / متطلبات العمل'),
                  TextField(
                    controller: _checkInComplaintCtrl,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  final odometer = int.tryParse(_checkInOdoCtrl.text.trim()) ?? 0;
                  final complaint = _checkInComplaintCtrl.text.trim();

                  ref.read(appStateProvider.notifier).checkInAppointment(
                        app.id,
                        complaint,
                        odometer,
                        activeRole,
                      );

                  Navigator.pop(context);
                },
                child: const Text('تأكيد الدخول وفتح كرت الصيانة'),
              ),
            ],
          ),
        );
      },
    );
  }
}
