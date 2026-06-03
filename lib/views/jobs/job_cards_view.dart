import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/role_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import '../../models/workshop_models.dart';

class JobCardsView extends ConsumerStatefulWidget {
  const JobCardsView({super.key});

  @override
  ConsumerState<JobCardsView> createState() => _JobCardsViewState();
}

class _JobCardsViewState extends ConsumerState<JobCardsView> {
  String _searchQuery = '';
  JobCard? _selectedJobCard;

  // New Job Controllers
  String? _selectedCustId;
  String? _selectedVehId;
  final _complaintCtrl = TextEditingController();
  final _odometerCtrl = TextEditingController();
  
  // Quick Customer/Vehicle Controllers
  final _custNameCtrl = TextEditingController();
  final _custPhoneCtrl = TextEditingController();
  final _vehPlateCtrl = TextEditingController();
  final _vehMakeCtrl = TextEditingController();
  final _vehModelCtrl = TextEditingController();

  // Task Controllers
  final _taskDescCtrl = TextEditingController();
  final _taskTechNameCtrl = TextEditingController();
  final _taskHoursCtrl = TextEditingController(text: '1.0');
  final _taskPriceCtrl = TextEditingController(text: '150');
  String _taskType = 'mechanical';

  // Parts Controller
  String? _selectedPartId;
  final _partQtyCtrl = TextEditingController(text: '1');

  // Invoice Discount
  final _discountCtrl = TextEditingController(text: '0');

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final activeRole = ref.watch(roleProvider).nameEn;

    final filteredJobCards = state.jobCards.where((jc) {
      final customer = state.customers.firstWhere((c) => c.id == jc.customerId);
      return jc.cardNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          customer.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: List of Job Cards (40% width)
        Expanded(
          flex: 4,
          child: TonalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'بطاقات العمل الجارية',
                  trailing: ElevatedButton.icon(
                    onPressed: () => _showCreateJobCardDialog(context, state, activeRole),
                    icon: const Icon(Icons.note_add_outlined),
                    label: const Text('بطاقة جديدة'),
                  ),
                ),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'البحث برقم البطاقة أو اسم العميل...',
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
                  child: filteredJobCards.isEmpty
                      ? const Center(child: Text('لا توجد بطاقات عمل مطابقة للبحث.'))
                      : ListView.separated(
                          itemCount: filteredJobCards.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final jc = filteredJobCards[index];
                            final cust = state.customers.firstWhere((x) => x.id == jc.customerId);
                            final isSelected = _selectedJobCard?.id == jc.id;

                            return ListTile(
                              title: Text(jc.cardNo, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('العميل: ${cust.name}\nبتاريخ: ${jc.createdAt}'),
                              trailing: StatusBadge(status: jc.status),
                              selected: isSelected,
                              selectedTileColor: AppColors.primary.withOpacity(0.05),
                              onTap: () {
                                setState(() {
                                  _selectedJobCard = jc;
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

        // Right Column: Active Job Card Details & Editor (60% width)
        Expanded(
          flex: 6,
          child: _selectedJobCard == null
              ? const TonalCard(
                  child: Center(
                    child: Text('اختر كرت عمل من القائمة لتعديله، إضافة فني، صرف قطع غيار أو ترحيل فاتورة.'),
                  ),
                )
              : _buildJobCardDetailsPanel(state, activeRole),
        ),
      ],
    );
  }

  Widget _buildJobCardDetailsPanel(AppState state, String activeRole) {
    // Reload state instance to reflect additions
    final jc = state.jobCards.firstWhere((j) => j.id == _selectedJobCard!.id);
    final customer = state.customers.firstWhere((c) => c.id == jc.customerId);
    final vehicle = state.vehicles.firstWhere((v) => v.id == jc.vehicleId);

    final double laborTotal = jc.tasks.fold(0.0, (sum, t) => sum + t.price);
    final double partsTotal = jc.parts.fold(0.0, (sum, p) => sum + (p.price * p.quantity));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          TonalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'بطاقة رقم: ${jc.cardNo}',
                  subtitle: 'العميل: ${customer.name} | السيارة: ${vehicle.make} ${vehicle.model} (لوحة ${vehicle.plateNumber})',
                  trailing: StatusBadge(status: jc.status),
                ),
                const Divider(),
                const SizedBox(height: 8),
                Text('الشكوى / الطلب: ${jc.complaint}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('قراءة العداد عند الوصول: ${jc.odometer} كم'),
                const SizedBox(height: 12),
                
                // Status Slider/Dropdown selector
                const Text('تغيير حالة كرت العمل:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      'New',
                      'Under Inspection',
                      'Waiting Customer Approval',
                      'In Progress',
                      'Waiting Parts',
                      'Completed',
                    ].map((status) {
                      final isCurrent = jc.status == status;
                      return Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: ChoiceChip(
                          label: Text(status),
                          selected: isCurrent,
                          onSelected: (selected) {
                            if (selected) {
                              ref.read(appStateProvider.notifier).updateJobStatus(jc.id, status, activeRole);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Billing quick actions
                if (jc.status == 'Completed')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _showGenerateInvoiceDialog(context, jc.id, activeRole),
                        icon: const Icon(Icons.point_of_sale),
                        label: const Text('إصدار الفاتورة المبدئية'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tasks Section Card
          TonalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'العمليات الفنية والأجور (إجمالي: ${laborTotal.toStringAsFixed(2)} ج.م)',
                  trailing: TextButton.icon(
                    onPressed: () => _showAddTaskDialog(context, jc.id, activeRole),
                    icon: const Icon(Icons.add_task),
                    label: const Text('إضافة عملية'),
                  ),
                ),
                if (jc.tasks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: Text('لم يتم إسناد عمليات فنية لكرت الصيانة بعد.')),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: jc.tasks.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final task = jc.tasks[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: task.status == 'completed' ? AppColors.success.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                          foregroundColor: task.status == 'completed' ? AppColors.success : AppColors.primary,
                          child: const Icon(Icons.settings),
                        ),
                        title: Text(task.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('الفني: ${task.technicianName} | الزمن المقدر: ${task.estimatedHours} س'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${task.price.toStringAsFixed(0)} ج.م',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            StatusBadge(status: task.status),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Parts Section Card
          TonalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'قطع الغيار المصروفة (إجمالي: ${partsTotal.toStringAsFixed(2)} ج.م)',
                  trailing: TextButton.icon(
                    onPressed: () => _showAddPartsDialog(context, jc.id, state.parts, activeRole),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('صرف قطع غيار'),
                  ),
                ),
                if (jc.parts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: Text('لم يتم صرف قطع غيار لكرت الصيانة بعد.')),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: jc.parts.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final part = jc.parts[index];
                      return ListTile(
                        title: Text(part.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('الكود: ${part.code} | الكمية: ${part.quantity} حبة'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(part.price * part.quantity).toStringAsFixed(0)} ج.م',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.error),
                              onPressed: () {
                                ref.read(appStateProvider.notifier).removeJobPart(jc.id, part.id, activeRole);
                              },
                            )
                          ],
                        ),
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

  void _showCreateJobCardDialog(BuildContext context, AppState state, String activeRole) {
    _complaintCtrl.clear();
    _odometerCtrl.clear();
    final initialAppState = ref.read(appStateProvider);
    _selectedCustId = initialAppState.customers.isNotEmpty ? initialAppState.customers.first.id : null;
    _selectedVehId = _selectedCustId != null 
        ? (initialAppState.vehicles.where((v) => v.customerId == _selectedCustId).isNotEmpty 
            ? initialAppState.vehicles.where((v) => v.customerId == _selectedCustId).first.id 
            : null)
        : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final latestState = ref.read(appStateProvider);
            final customerVehicles = _selectedCustId != null 
                ? latestState.vehicles.where((v) => v.customerId == _selectedCustId).toList()
                : <Vehicle>[];

            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.assignment_ind, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('فتح بطاقة عمل صيانة جديدة'),
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
                        const FormFieldLabel(label: 'اختيار العميل'),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: const BoxDecoration(
                                  color: AppColors.surfaceLow,
                                  borderRadius: BorderRadius.all(Radius.circular(8)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedCustId,
                                    isExpanded: true,
                                    items: latestState.customers.map((c) {
                                      return DropdownMenuItem<String>(
                                        value: c.id,
                                        child: Text(c.name),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setDialogState(() {
                                        _selectedCustId = val;
                                        final list = latestState.vehicles.where((v) => v.customerId == val).toList();
                                        _selectedVehId = list.isNotEmpty ? list.first.id : null;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.person_add_alt, color: AppColors.primary),
                              onPressed: () => _showQuickRegisterDialog(context, latestState, setDialogState),
                            )
                          ],
                        ),
                        
                        // Vehicle Selection
                        const FormFieldLabel(label: 'سيارة العميل المحددة'),
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

                        const FormFieldLabel(label: 'قراءة العداد الحالية (كم)'),
                        TextField(
                          controller: _odometerCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: 'أدخل قراءة عداد الكيلومتر الحالية للسيارة'),
                        ),

                        const FormFieldLabel(label: 'شكوى العميل الفنية وأعراض العطل بالكامل'),
                        TextField(
                          controller: _complaintCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(hintText: 'تغيير زيت، أصوات طقطقة في المساعدين، فحص فرامل...'),
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
                            ref.read(appStateProvider.notifier).createJobCard(
                                  customerId: _selectedCustId!,
                                  vehicleId: _selectedVehId!,
                                  complaint: _complaintCtrl.text.trim(),
                                  odometer: int.tryParse(_odometerCtrl.text.trim()) ?? 0,
                                  activeRole: activeRole,
                                );
                            Navigator.pop(context);
                          },
                    child: const Text('بدء وفتح كرت الصيانة'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showQuickRegisterDialog(BuildContext context, AppState state, StateSetter parentSetState) {
    _custNameCtrl.clear();
    _custPhoneCtrl.clear();
    _vehPlateCtrl.clear();
    _vehMakeCtrl.clear();
    _vehModelCtrl.clear();

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تسجيل سريع لعميل وسيارة بنفس اللحظة'),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 400,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FormFieldLabel(label: 'اسم العميل'),
                    TextField(controller: _custNameCtrl),
                    const FormFieldLabel(label: 'رقم الهاتف'),
                    TextField(controller: _custPhoneCtrl, keyboardType: TextInputType.phone),
                    const Divider(height: 24),
                    const FormFieldLabel(label: 'رقم اللوحة للسيارة'),
                    TextField(controller: _vehPlateCtrl),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FormFieldLabel(label: 'الماركة'),
                              TextField(controller: _vehMakeCtrl, decoration: const InputDecoration(hintText: 'مثال: تويوتا')),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FormFieldLabel(label: 'الموديل'),
                              TextField(controller: _vehModelCtrl, decoration: const InputDecoration(hintText: 'مثال: كورولا')),
                            ],
                          ),
                        ),
                      ],
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
                  final name = _custNameCtrl.text.trim();
                  final phone = _custPhoneCtrl.text.trim();
                  final plate = _vehPlateCtrl.text.trim();
                  final make = _vehMakeCtrl.text.trim();
                  if (name.isEmpty || phone.isEmpty || plate.isEmpty || make.isEmpty) return;

                  // Create IDs
                  final cId = 'cust_${DateTime.now().millisecondsSinceEpoch}';
                  final vId = 'veh_${DateTime.now().millisecondsSinceEpoch}';

                  // Directly inject in notifier to keep states atomic
                  ref.read(appStateProvider.notifier).addCustomer(
                    name: name,
                    phone: phone,
                    email: '',
                    address: '',
                    type: 'cash',
                    creditLimit: 0.0,
                    activeRole: 'Receptionist',
                  );

                  ref.read(appStateProvider.notifier).addVehicle(
                    customerId: ref.read(appStateProvider).customers.last.id,
                    plateNumber: plate,
                    chassisNumber: '',
                    make: make,
                    model: _vehModelCtrl.text.trim(),
                    year: '2020',
                    color: '',
                    odometer: 0,
                    notes: '',
                    activeRole: 'Receptionist',
                  );

                  // Update parent modal selectors
                  parentSetState(() {
                    final updatedState = ref.read(appStateProvider);
                    _selectedCustId = updatedState.customers.last.id;
                    _selectedVehId = updatedState.vehicles.last.id;
                  });

                  Navigator.pop(context);
                },
                child: const Text('إنشاء وتطبيق'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddTaskDialog(BuildContext context, String jobCardId, String activeRole) {
    _taskDescCtrl.clear();
    _taskTechNameCtrl.clear();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text('إضافة عملية عمل لكرت الصيانة'),
                content: SizedBox(
                  width: 450,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FormFieldLabel(label: 'بيان العملية الفنية (مثال: فحص وتغيير المساعدين خلفي)'),
                      TextField(controller: _taskDescCtrl),
                      
                      const FormFieldLabel(label: 'الفني المختص المسند إليه العمل'),
                      TextField(controller: _taskTechNameCtrl, decoration: const InputDecoration(hintText: 'اسم فني الميكانيكا/الكهرباء')),
                      
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const FormFieldLabel(label: 'الزمن المقدر (ساعات)'),
                                TextField(controller: _taskHoursCtrl, keyboardType: TextInputType.number),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const FormFieldLabel(label: 'تكلفة العمليات الميكانيكية (ج.م)'),
                                TextField(controller: _taskPriceCtrl, keyboardType: TextInputType.number),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const FormFieldLabel(label: 'تصنيف العمل الفني'),
                      Row(
                        children: [
                          Radio<String>(
                            value: 'mechanical',
                            groupValue: _taskType,
                            onChanged: (val) {
                              setDialogState(() {
                                _taskType = val!;
                              });
                            },
                          ),
                          const Text('ميكانيكا'),
                          const SizedBox(width: 8),
                          Radio<String>(
                            value: 'electrical',
                            groupValue: _taskType,
                            onChanged: (val) {
                              setDialogState(() {
                                _taskType = val!;
                              });
                            },
                          ),
                          const Text('كهرباء'),
                          const SizedBox(width: 8),
                          Radio<String>(
                            value: 'ac',
                            groupValue: _taskType,
                            onChanged: (val) {
                              setDialogState(() {
                                _taskType = val!;
                              });
                            },
                          ),
                          const Text('تكييف'),
                        ],
                      )
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
                      final desc = _taskDescCtrl.text.trim();
                      final techName = _taskTechNameCtrl.text.trim();
                      final hours = double.tryParse(_taskHoursCtrl.text.trim()) ?? 1.0;
                      final price = double.tryParse(_taskPriceCtrl.text.trim()) ?? 0.0;
                      if (desc.isEmpty || techName.isEmpty) return;

                      ref.read(appStateProvider.notifier).addJobTask(
                            jobCardId,
                            desc,
                            _taskType,
                            techName,
                            hours,
                            price,
                            activeRole,
                          );

                      Navigator.pop(context);
                    },
                    child: const Text('إسناد وإضافة'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddPartsDialog(BuildContext context, String jobCardId, List<Part> parts, String activeRole) {
    _selectedPartId = parts.isNotEmpty ? parts.first.id : null;
    _partQtyCtrl.text = '1';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text('صرف قطع غيار لكرت الصيانة من المستودع'),
                content: SizedBox(
                  width: 450,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FormFieldLabel(label: 'اختر قطعة الغيار المتوفرة بالمخزن'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceLow,
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedPartId,
                            isExpanded: true,
                            items: parts.map((p) {
                              return DropdownMenuItem<String>(
                                value: p.id,
                                child: Text('${p.name} (المتوفر: ${p.stockCount} ${p.unit})'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setDialogState(() {
                                _selectedPartId = val;
                              });
                            },
                          ),
                        ),
                      ),
                      const FormFieldLabel(label: 'الكمية المطلوبة للصرف للسيارة'),
                      TextField(
                        controller: _partQtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'عدد الوحدات المصروفة'),
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
                    onPressed: _selectedPartId == null
                        ? null
                        : () {
                            final qty = int.tryParse(_partQtyCtrl.text.trim()) ?? 1;
                            ref.read(appStateProvider.notifier).addJobPart(jobCardId, _selectedPartId!, qty, activeRole);
                            Navigator.pop(context);
                          },
                    child: const Text('تأكيد الصرف وتخفيض المخزن'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showGenerateInvoiceDialog(BuildContext context, String jobCardId, String activeRole) {
    _discountCtrl.text = '0';
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إصدار الفاتورة المبدئية والتحصيل'),
            content: SizedBox(
              width: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('الرجاء مراجعة كرت الصيانة قبل إرسال الفاتورة لقسم الحسابات للمراجعة والتحصيل والترحيل النهائي.'),
                  const SizedBox(height: 12),
                  const FormFieldLabel(label: 'قيمة الخصم التجاري الممنوح للعميل (ج.م)'),
                  TextField(
                    controller: _discountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'مثال: 50 ج.م'),
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
                  final discount = double.tryParse(_discountCtrl.text.trim()) ?? 0.0;
                  ref.read(appStateProvider.notifier).generateInvoiceFromJobCard(
                        jobCardId: jobCardId,
                        discount: discount,
                        activeRole: activeRole,
                      );
                  Navigator.pop(context);
                  setState(() {
                    _selectedJobCard = null;
                  });
                },
                child: const Text('ترحيل مسودة الفاتورة للحسابات'),
              ),
            ],
          ),
        );
      },
    );
  }
}
