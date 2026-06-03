import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/role_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import '../../models/workshop_models.dart';

class InventoryView extends ConsumerStatefulWidget {
  const InventoryView({super.key});

  @override
  ConsumerState<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends ConsumerState<InventoryView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  final _partCodeCtrl = TextEditingController();
  final _partNameCtrl = TextEditingController();
  final _partCategoryCtrl = TextEditingController();
  final _partBrandCtrl = TextEditingController();
  final _partCompatibleCtrl = TextEditingController();
  final _partMinStockCtrl = TextEditingController(text: '5');
  final _partUnitCtrl = TextEditingController(text: 'pcs');
  final _partBuyPriceCtrl = TextEditingController();
  final _partSellPriceCtrl = TextEditingController();
  final _partLocationCtrl = TextEditingController(text: 'مستودع رئيسي - الرف ');

  final _adjQtyCtrl = TextEditingController();
  final _adjReasonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final activeRole = ref.watch(roleProvider).nameEn;

    final filteredParts = state.parts.where((p) {
      final query = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(query) || p.code.toLowerCase().contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'إدارة المستودع والمخزن',
          subtitle: 'مراقبة كميات قطع الغيار، نواقص المخزون، وخطوط الصرف الوارد',
          trailing: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'دليل قطع الغيار (Master Parts)'),
              Tab(text: 'سجل حركة حركة المخازن (Movements)'),
            ],
          ),
        ),
        
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Parts Master Directory
              TonalCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'البحث باسم المادة أو كود البارت نمبر...',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => _showAddPartDialog(context, activeRole),
                          icon: const Icon(Icons.add),
                          label: const Text('تعريف مادة جديدة'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: filteredParts.isEmpty
                          ? const Center(child: Text('لم يتم العثور على مواد مخزنية مطابقة.'))
                          : ScrollableTableWrapper(
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('الكود والرمز')),
                                  DataColumn(label: Text('اسم قطعة الغيار')),
                                  DataColumn(label: Text('التصنيف والماركة')),
                                  DataColumn(label: Text('المكان بالمخزن')),
                                  DataColumn(label: Text('الحد الأدنى')),
                                  DataColumn(label: Text('الرصيد الحالي')),
                                  DataColumn(label: Text('سعر البيع')),
                                  DataColumn(label: Text('إجراءات')),
                                ],
                                rows: filteredParts.map((part) {
                                  final isLow = part.stockCount <= part.minStock;
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(part.code, style: const TextStyle(fontWeight: FontWeight.bold))),
                                      DataCell(Text(part.name)),
                                      DataCell(Text('${part.category} (${part.brand})')),
                                      DataCell(Text(part.location)),
                                      DataCell(Text('${part.minStock} ${part.unit}')),
                                      DataCell(
                                        Row(
                                          children: [
                                            Text(
                                              '${part.stockCount} ${part.unit}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: isLow ? AppColors.error : AppColors.success,
                                              ),
                                            ),
                                            if (isLow) ...[
                                              const SizedBox(width: 4),
                                              const Icon(Icons.warning, color: AppColors.error, size: 16),
                                            ]
                                          ],
                                        ),
                                      ),
                                      DataCell(Text('${part.defaultSellingPrice.toStringAsFixed(2)} ج.م')),
                                      DataCell(
                                        IconButton(
                                          icon: const Icon(Icons.edit_note, color: AppColors.primary),
                                          onPressed: () => _showAdjustStockDialog(context, part.id, activeRole),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                    ),
                  ],
                ),
              ),

              // Tab 2: Stock Movements History Log
              TonalCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('تتبع كشف حركات المخزون والوارد والصرف والتعديل للقطع:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Expanded(
                      child: state.stockMovements.isEmpty
                          ? const Center(child: Text('لا توجد حركات مخزنية مسجلة بعد.'))
                          : ScrollableTableWrapper(
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('تاريخ الحركة')),
                                  DataColumn(label: Text('قطعة الغيار')),
                                  DataColumn(label: Text('نوع الحركة')),
                                  DataColumn(label: Text('الكمية (وارد/صرف)')),
                                  DataColumn(label: Text('رقم المرجع')),
                                  DataColumn(label: Text('ملاحظات وتفاصيل')),
                                ],
                                rows: state.stockMovements.map((mov) {
                                  // Find part name
                                  String partName = 'مادة محذوفة';
                                  try {
                                    partName = state.parts.firstWhere((p) => p.id == mov.partId).name;
                                  } catch (e) {
                                    partName = 'مادة غير معرفة';
                                  }

                                  Color typeColor = Colors.grey;
                                  String typeAr = mov.type;
                                  if (mov.type == 'receipt') {
                                    typeColor = AppColors.success;
                                    typeAr = 'فاتورة شراء (وارد)';
                                  } else if (mov.type == 'issue') {
                                    typeColor = Colors.blue;
                                    typeAr = 'صرف لكرت عمل (صادر)';
                                  } else if (mov.type == 'return') {
                                    typeColor = Colors.orange;
                                    typeAr = 'إرجاع للمستودع';
                                  } else if (mov.type == 'adjustment') {
                                    typeColor = AppColors.tertiary;
                                    typeAr = 'تعديل جرد يدوي';
                                  }

                                  return DataRow(
                                    cells: [
                                      DataCell(Text(mov.date)),
                                      DataCell(Text(partName, style: const TextStyle(fontWeight: FontWeight.bold))),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: typeColor.withOpacity(0.1),
                                            borderRadius: const BorderRadius.all(Radius.circular(4)),
                                          ),
                                          child: Text(typeAr, style: TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 11)),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          mov.quantity > 0 ? '+${mov.quantity}' : '${mov.quantity}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: mov.quantity > 0 ? AppColors.success : AppColors.error,
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(mov.referenceId)),
                                      DataCell(Text(mov.notes)),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddPartDialog(BuildContext context, String activeRole) {
    _partCodeCtrl.clear();
    _partNameCtrl.clear();
    _partCategoryCtrl.clear();
    _partBrandCtrl.clear();
    _partCompatibleCtrl.clear();
    _partBuyPriceCtrl.clear();
    _partSellPriceCtrl.clear();

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.inventory, color: AppColors.primary),
                SizedBox(width: 8),
                Text('تعريف مادة مخزنية جديدة في النظام'),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 480,
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
                              const FormFieldLabel(label: 'رقم القطعة / كود المصنع (Part No)'),
                              TextField(controller: _partCodeCtrl, decoration: const InputDecoration(hintText: 'OIL-10W40')),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FormFieldLabel(label: 'اسم قطعة الغيار'),
                              TextField(controller: _partNameCtrl, decoration: const InputDecoration(hintText: 'مساعدين فرملة كورولا')),
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
                              const FormFieldLabel(label: 'التصنيف'),
                              TextField(controller: _partCategoryCtrl, decoration: const InputDecoration(hintText: 'الفرامل / زيوت')),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FormFieldLabel(label: 'الماركة / المورد المصنع'),
                              TextField(controller: _partBrandCtrl, decoration: const InputDecoration(hintText: 'موبيل / أصلي')),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const FormFieldLabel(label: 'السيارات المتوافقة مع قطعة الغيار'),
                    TextField(controller: _partCompatibleCtrl, decoration: const InputDecoration(hintText: 'تويوتا كورولا 2020-2023')),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FormFieldLabel(label: 'حد الطلب الأدنى للتنبيه'),
                              TextField(controller: _partMinStockCtrl, keyboardType: TextInputType.number),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FormFieldLabel(label: 'وحدة القياس للمخزن'),
                              TextField(controller: _partUnitCtrl, decoration: const InputDecoration(hintText: 'حبة / طقم')),
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
                              const FormFieldLabel(label: 'سعر الشراء التقريبي (ج.م)'),
                              TextField(controller: _partBuyPriceCtrl, keyboardType: TextInputType.number),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FormFieldLabel(label: 'سعر البيع المقترح (ج.م)'),
                              TextField(controller: _partSellPriceCtrl, keyboardType: TextInputType.number),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const FormFieldLabel(label: 'موقع القطعة في الرفوف'),
                    TextField(controller: _partLocationCtrl),
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
                  final code = _partCodeCtrl.text.trim();
                  final name = _partNameCtrl.text.trim();
                  final buy = double.tryParse(_partBuyPriceCtrl.text.trim()) ?? 0.0;
                  final sell = double.tryParse(_partSellPriceCtrl.text.trim()) ?? 0.0;
                  if (code.isEmpty || name.isEmpty) return;

                  ref.read(appStateProvider.notifier).addPart(
                        code: code,
                        name: name,
                        category: _partCategoryCtrl.text.trim(),
                        brand: _partBrandCtrl.text.trim(),
                        compatibleModels: _partCompatibleCtrl.text.trim(),
                        minStock: int.tryParse(_partMinStockCtrl.text.trim()) ?? 5,
                        unit: _partUnitCtrl.text.trim(),
                        defaultPurchasePrice: buy,
                        defaultSellingPrice: sell,
                        location: _partLocationCtrl.text.trim(),
                        activeRole: activeRole,
                      );

                  Navigator.pop(context);
                },
                child: const Text('حفظ المادة'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAdjustStockDialog(BuildContext context, String partId, String activeRole) {
    _adjQtyCtrl.clear();
    _adjReasonCtrl.clear();

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تعديل مخزون جرد يدوي (تعديل رصيد بضاعة)'),
            content: SizedBox(
              width: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FormFieldLabel(label: 'كمية التعديل للمستودع (+ للموجب، - للسالب)'),
                  TextField(
                    controller: _adjQtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(signed: true),
                    decoration: const InputDecoration(hintText: 'مثال: 5 أو -3'),
                  ),
                  const FormFieldLabel(label: 'سبب التعديل والتسوية الجردية'),
                  TextField(
                    controller: _adjReasonCtrl,
                    decoration: const InputDecoration(hintText: 'تلف بضاعة، زيادة تسوية سنوية...'),
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
                  final change = int.tryParse(_adjQtyCtrl.text.trim()) ?? 0;
                  final reason = _adjReasonCtrl.text.trim();
                  if (change == 0 || reason.isEmpty) return;

                  ref.read(appStateProvider.notifier).adjustStock(partId, change, reason, activeRole);
                  Navigator.pop(context);
                },
                child: const Text('ترحيل التسوية للمستودع'),
              ),
            ],
          ),
        );
      },
    );
  }
}
