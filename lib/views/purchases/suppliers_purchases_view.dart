import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/role_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import '../../models/workshop_models.dart';

class SuppliersPurchasesView extends ConsumerStatefulWidget {
  const SuppliersPurchasesView({super.key});

  @override
  ConsumerState<SuppliersPurchasesView> createState() => _SuppliersPurchasesViewState();
}

class _SuppliersPurchasesViewState extends ConsumerState<SuppliersPurchasesView> {
  Supplier? _selectedSupplier;
  final _searchQuery = '';

  final _suppNameCtrl = TextEditingController();
  final _suppPhoneCtrl = TextEditingController();
  final _suppAddressCtrl = TextEditingController();
  String _suppTerms = 'cash';

  final _invoiceNoCtrl = TextEditingController();
  final List<Map<String, dynamic>> _invoiceItems = []; // [{'partId': x, 'qty': y, 'cost': z}]

  final _paymentAmountCtrl = TextEditingController();
  final _paymentRefCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final activeRole = ref.watch(roleProvider).nameEn;

    final filteredSuppliers = state.suppliers.where((s) {
      return s.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Supplier List (40% width)
        Expanded(
          flex: 4,
          child: TonalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'الموردين والمستودع',
                  trailing: ElevatedButton.icon(
                    onPressed: () => _showAddSupplierDialog(context, activeRole),
                    icon: const Icon(Icons.add),
                    label: const Text('مورد جديد'),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: filteredSuppliers.isEmpty
                      ? const Center(child: Text('لم يتم العثور على موردين.'))
                      : ListView.separated(
                          itemCount: filteredSuppliers.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final supplier = filteredSuppliers[index];
                            final isSelected = _selectedSupplier?.id == supplier.id;

                            // Calculate outstanding balance
                            double balance = 0.0;
                            final ledger = state.ledgerEntries.where((e) => e.partyId == supplier.id && e.partyType == 'supplier');
                            if (ledger.isNotEmpty) {
                              balance = ledger.last.balance;
                            }

                            return ListTile(
                              title: Text(supplier.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(supplier.phone),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Chip(
                                    label: Text(supplier.paymentTerms == 'credit' ? 'آجل' : 'نقدي'),
                                    backgroundColor: supplier.paymentTerms == 'credit' ? AppColors.tertiary.withOpacity(0.08) : AppColors.primary.withOpacity(0.08),
                                    side: BorderSide.none,
                                    padding: EdgeInsets.zero,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${balance.toStringAsFixed(0)} ج.م',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: balance > 0 ? AppColors.error : AppColors.success,
                                      fontSize: 12,
                                    ),
                                  )
                                ],
                              ),
                              selected: isSelected,
                              selectedTileColor: AppColors.primary.withOpacity(0.05),
                              onTap: () {
                                setState(() {
                                  _selectedSupplier = supplier;
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

        // Right Column: Purchases & Ledger Statement (60% width)
        Expanded(
          flex: 6,
          child: _selectedSupplier == null
              ? TonalCard(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_long, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 16),
                      const Text('اختر مورداً لعرض كشف المعاملات، أو قم بتسجيل فاتورة شراء جديدة له.'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: state.suppliers.isEmpty ? null : () => _showNewPurchaseInvoiceDialog(context, state.parts, activeRole),
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('تسجيل فاتورة شراء واردة'),
                      ),
                    ],
                  ),
                )
              : _buildSupplierDetailsPanel(state, activeRole),
        ),
      ],
    );
  }

  Widget _buildSupplierDetailsPanel(AppState state, String activeRole) {
    final supplier = state.suppliers.firstWhere((s) => s.id == _selectedSupplier!.id);
    final ledger = state.ledgerEntries.where((e) => e.partyId == supplier.id && e.partyType == 'supplier').toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Supplier Details Card
          TonalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: supplier.name,
                  subtitle: 'شروط الدفع المتفق عليها: ${supplier.paymentTerms == 'credit' ? 'حساب آجل (30 يوم)' : 'دفع نقدي مباشر'}',
                  trailing: Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _showNewPurchaseInvoiceDialog(context, state.parts, activeRole, supplier.id),
                        icon: const Icon(Icons.shopping_bag_outlined),
                        label: const Text('فاتورة شراء'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _showPaymentDialog(context, supplier.id, activeRole),
                        icon: const Icon(Icons.payment),
                        label: const Text('دفع للمورد'),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('الهاتف: ${supplier.phone}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('العنوان: ${supplier.address}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Chronological Statement Ledger Card
          TonalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'كشف حساب المورد (AP Ledger)',
                  subtitle: 'كشف تاريخي بالدفعات والمشتريات المستلمة ورصيد الحساب',
                ),
                if (ledger.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 36.0),
                    child: Center(child: Text('لا توجد معاملات مالية مسجلة لهذا المورد بعد.')),
                  )
                else
                  ScrollableTableWrapper(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('تاريخ المعاملة')),
                        DataColumn(label: Text('البيان والنوع')),
                        DataColumn(label: Text('رقم المرجع')),
                        DataColumn(label: Text('مدين (دفعات ج.م)')),
                        DataColumn(label: Text('دائن (مشتريات ج.م)')),
                        DataColumn(label: Text('الرصيد الجاري ج.م')),
                      ],
                      rows: ledger.map((entry) {
                        final isPayment = entry.type == 'payment';
                        return DataRow(
                          cells: [
                            DataCell(Text(entry.date)),
                            DataCell(Text(isPayment ? 'سند سداد دفعة للمورد' : 'فاتورة شراء بضاعة')),
                            DataCell(Text(entry.referenceNo)),
                            DataCell(Text(entry.debit > 0 ? entry.debit.toStringAsFixed(2) : '-')),
                            DataCell(Text(entry.credit > 0 ? entry.credit.toStringAsFixed(2) : '-')),
                            DataCell(
                              Text(
                                '${entry.balance.toStringAsFixed(2)} ج.م',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSupplierDialog(BuildContext context, String activeRole) {
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
                    Icon(Icons.business_outlined, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('إضافة مورد جديد لقطع الغيار'),
                  ],
                ),
                content: SizedBox(
                  width: 450,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FormFieldLabel(label: 'اسم المورد / الشركة'),
                      TextField(
                        controller: _suppNameCtrl,
                        decoration: const InputDecoration(hintText: 'مثال: شركة النيل لقطع الغيار'),
                      ),
                      const FormFieldLabel(label: 'رقم هاتف مسؤول المبيعات'),
                      TextField(
                        controller: _suppPhoneCtrl,
                        decoration: const InputDecoration(hintText: 'مثال: 01200000000'),
                      ),
                      const FormFieldLabel(label: 'العنوان الجغرافي للشركة'),
                      TextField(
                        controller: _suppAddressCtrl,
                        decoration: const InputDecoration(hintText: 'القاهرة، مصر'),
                      ),
                      const FormFieldLabel(label: 'طريقة السداد المتفق عليها'),
                      Row(
                        children: [
                          Radio<String>(
                            value: 'cash',
                            groupValue: _suppTerms,
                            onChanged: (val) {
                              setDialogState(() {
                                _suppTerms = val!;
                              });
                            },
                          ),
                          const Text('نقدي مباشر'),
                          const SizedBox(width: 24),
                          Radio<String>(
                            value: 'credit',
                            groupValue: _suppTerms,
                            onChanged: (val) {
                              setDialogState(() {
                                _suppTerms = val!;
                              });
                            },
                          ),
                          const Text('حساب آجل'),
                        ],
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
                      final name = _suppNameCtrl.text.trim();
                      if (name.isEmpty) return;

                      ref.read(appStateProvider.notifier).addSupplier(
                            name: name,
                            phone: _suppPhoneCtrl.text.trim(),
                            address: _suppAddressCtrl.text.trim(),
                            paymentTerms: _suppTerms,
                            activeRole: activeRole,
                          );

                      _suppNameCtrl.clear();
                      _suppPhoneCtrl.clear();
                      _suppAddressCtrl.clear();
                      _suppTerms = 'cash';
                      Navigator.pop(context);
                    },
                    child: const Text('تسجيل المورد'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showNewPurchaseInvoiceDialog(BuildContext context, List<Part> parts, String activeRole, [String? targetSupplierId]) {
    _invoiceItems.clear();
    _invoiceNoCtrl.text = 'PINV-100' + DateTime.now().millisecondsSinceEpoch.toString().substring(10);
    final appState = ref.read(appStateProvider);
    String? selectedSuppId = targetSupplierId ?? (appState.suppliers.isNotEmpty ? appState.suppliers.first.id : null);
    String? activePartId = parts.isNotEmpty ? parts.first.id : null;
    final qtyCtrl = TextEditingController(text: '10');
    final costCtrl = TextEditingController(text: '100');

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
                    Icon(Icons.playlist_add_check, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('تسجيل فاتورة شراء بضاعة واردة للمستودع'),
                  ],
                ),
                content: SingleChildScrollView(
                  child: SizedBox(
                    width: 550,
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
                                  const FormFieldLabel(label: 'المورد'),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: const BoxDecoration(
                                      color: AppColors.surfaceLow,
                                      borderRadius: BorderRadius.all(Radius.circular(8)),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: selectedSuppId,
                                        isExpanded: true,
                                        items: ref.read(appStateProvider).suppliers.map((s) {
                                          return DropdownMenuItem<String>(
                                            value: s.id,
                                            child: Text(s.name),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          setDialogState(() {
                                            selectedSuppId = val;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const FormFieldLabel(label: 'رقم الفاتورة الخارجي'),
                                  TextField(
                                    controller: _invoiceNoCtrl,
                                    decoration: const InputDecoration(hintText: 'PINV-987'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        const Text('إضافة بنود قطع الغيار المشتراة للفاتورة:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const FormFieldLabel(label: 'المادة'),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: const BoxDecoration(
                                      color: AppColors.surfaceLow,
                                      borderRadius: BorderRadius.all(Radius.circular(8)),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: activePartId,
                                        isExpanded: true,
                                        items: parts.map((p) {
                                          return DropdownMenuItem<String>(
                                            value: p.id,
                                            child: Text(p.name, overflow: TextOverflow.ellipsis),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          setDialogState(() {
                                            activePartId = val;
                                            final part = parts.firstWhere((x) => x.id == val);
                                            costCtrl.text = part.defaultPurchasePrice.toString();
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const FormFieldLabel(label: 'الكمية'),
                                  TextField(
                                    controller: qtyCtrl,
                                    keyboardType: TextInputType.number,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const FormFieldLabel(label: 'سعر التكلفة'),
                                  TextField(
                                    controller: costCtrl,
                                    keyboardType: TextInputType.number,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                final qty = int.tryParse(qtyCtrl.text) ?? 1;
                                final cost = double.tryParse(costCtrl.text) ?? 0.0;
                                if (activePartId == null) return;
                                final part = parts.firstWhere((x) => x.id == activePartId);

                                setDialogState(() {
                                  _invoiceItems.add({
                                    'partId': activePartId,
                                    'name': part.name,
                                    'qty': qty,
                                    'cost': cost,
                                  });
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                backgroundColor: AppColors.primaryContainer,
                              ),
                              child: const Icon(Icons.add_shopping_cart, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Items List Table
                        if (_invoiceItems.isNotEmpty) ...[
                          const Text('البنود المسجلة حالياً في الفاتورة:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Container(
                            height: 150,
                            decoration: const BoxDecoration(
                              color: AppColors.surfaceLow,
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                            ),
                            child: ListView.builder(
                              itemCount: _invoiceItems.length,
                              itemBuilder: (context, index) {
                                final item = _invoiceItems[index];
                                return ListTile(
                                  dense: true,
                                  title: Text(item['name']),
                                  subtitle: Text('الكمية: ${item['qty']} | تكلفة الحبة: ${item['cost']} ج.م'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.remove_circle, color: AppColors.error),
                                    onPressed: () {
                                      setDialogState(() {
                                        _invoiceItems.removeAt(index);
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
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
                    onPressed: _invoiceItems.isEmpty || selectedSuppId == null
                        ? null
                        : () {
                            ref.read(appStateProvider.notifier).createSupplierInvoice(
                                  supplierId: selectedSuppId!,
                                  invoiceNo: _invoiceNoCtrl.text.trim(),
                                  items: _invoiceItems,
                                  activeRole: activeRole,
                                );
                            Navigator.pop(context);
                          },
                    child: const Text('حفظ وترحيل للمستودع والذمم'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPaymentDialog(BuildContext context, String supplierId, String activeRole) {
    _paymentAmountCtrl.clear();
    _paymentRefCtrl.text = 'PYMT-' + DateTime.now().millisecondsSinceEpoch.toString().substring(9);

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.payment, color: AppColors.primary),
                SizedBox(width: 8),
                Text('تسجيل سند صرف دفعة للمورد'),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FormFieldLabel(label: 'المبلغ المدفوع (ج.م)'),
                  TextField(
                    controller: _paymentAmountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'ج.م'),
                  ),
                  const FormFieldLabel(label: 'رقم المرجع / رقم الشيك أو الحوالة'),
                  TextField(
                    controller: _paymentRefCtrl,
                    decoration: const InputDecoration(hintText: 'سند صرف رقم...'),
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
                  final amount = double.tryParse(_paymentAmountCtrl.text.trim()) ?? 0.0;
                  final refNo = _paymentRefCtrl.text.trim();
                  if (amount <= 0 || refNo.isEmpty) return;

                  ref.read(appStateProvider.notifier).recordSupplierPayment(
                        supplierId: supplierId,
                        amount: amount,
                        referenceNo: refNo,
                        activeRole: activeRole,
                      );

                  Navigator.pop(context);
                },
                child: const Text('صرف وترحيل الحسابات'),
              ),
            ],
          ),
        );
      },
    );
  }
}
