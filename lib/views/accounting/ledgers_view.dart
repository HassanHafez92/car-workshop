import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import '../../models/workshop_models.dart';

class LedgersView extends ConsumerStatefulWidget {
  const LedgersView({super.key});

  @override
  ConsumerState<LedgersView> createState() => _LedgersViewState();
}

class _LedgersViewState extends ConsumerState<LedgersView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Customer? _selectedCustomer;
  Supplier? _selectedSupplier;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);

    _selectedCustomer ??= state.customers.firstWhere((x) => x.type == 'credit', orElse: () => state.customers.first);
    _selectedSupplier ??= state.suppliers.firstWhere((x) => x.paymentTerms == 'credit', orElse: () => state.suppliers.first);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'الدفاتر المحاسبية الفرعية وكشوف الحسابات',
          subtitle: 'تتبع الحسابات المدينة والدائنة وجدولة أعمار الديون والمستحقات',
          trailing: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'كشف حساب عميل (AR)'),
              Tab(text: 'كشف حساب مورد (AP)'),
              Tab(text: 'أعمار ديون العملاء'),
              Tab(text: 'أعمار مستحقات الموردين'),
            ],
          ),
        ),
        
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Customer Ledger Statement (AR)
              _buildCustomerLedgerTab(state),

              // Tab 2: Supplier Ledger Statement (AP)
              _buildSupplierLedgerTab(state),

              // Tab 3: Customer Aging Report (AR)
              _buildCustomerAgingTab(state),

              // Tab 4: Supplier Aging Report (AP)
              _buildSupplierAgingTab(state),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerLedgerTab(AppState state) {
    final ledger = state.ledgerEntries.where((e) => e.partyId == _selectedCustomer?.id && e.partyType == 'customer').toList();
    final creditCustomers = state.customers; // Show all for ledger checking

    return TonalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('اختر العميل:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              if (creditCustomers.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceLow,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCustomer?.id,
                      items: creditCustomers.map((c) {
                        return DropdownMenuItem<String>(
                          value: c.id,
                          child: Text(c.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCustomer = state.customers.firstWhere((x) => x.id == val);
                        });
                      },
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ledger.isEmpty
                ? const Center(child: Text('لا توجد قيود مسجلة للعميل المحدّد.'))
                : ScrollableTableWrapper(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('تاريخ القيد')),
                        DataColumn(label: Text('نوع الحركة')),
                        DataColumn(label: Text('رقم المرجع')),
                        DataColumn(label: Text('مدين (فاتورة صيانة + ج.م)')),
                        DataColumn(label: Text('دائن (دفعة مستلمة - ج.م)')),
                        DataColumn(label: Text('الرصيد المتبقي (ج.م)')),
                      ],
                      rows: ledger.map((entry) {
                        final isInvoice = entry.type == 'invoice';
                        return DataRow(
                          cells: [
                            DataCell(Text(entry.date)),
                            DataCell(Text(isInvoice ? 'قيد فاتورة صيانة مرحلة' : 'سند تحصيل دفعة')),
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
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierLedgerTab(AppState state) {
    final ledger = state.ledgerEntries.where((e) => e.partyId == _selectedSupplier?.id && e.partyType == 'supplier').toList();
    final creditSuppliers = state.suppliers;

    return TonalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('اختر المورد:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              if (creditSuppliers.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceLow,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSupplier?.id,
                      items: creditSuppliers.map((s) {
                        return DropdownMenuItem<String>(
                          value: s.id,
                          child: Text(s.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedSupplier = state.suppliers.firstWhere((x) => x.id == val);
                        });
                      },
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ledger.isEmpty
                ? const Center(child: Text('لا توجد قيود مسجلة للمورد المحدّد.'))
                : ScrollableTableWrapper(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('تاريخ القيد')),
                        DataColumn(label: Text('نوع الحركة')),
                        DataColumn(label: Text('رقم المرجع')),
                        DataColumn(label: Text('مدين (دفعات صادرة - ج.م)')),
                        DataColumn(label: Text('دائن (فاتورة شراء + ج.م)')),
                        DataColumn(label: Text('الرصيد المتبقي للمورد ج.م')),
                      ],
                      rows: ledger.map((entry) {
                        final isPayment = entry.type == 'payment';
                        return DataRow(
                          cells: [
                            DataCell(Text(entry.date)),
                            DataCell(Text(isPayment ? 'سند صرف دفعة' : 'فاتورة مشتريات واردة')),
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
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerAgingTab(AppState state) {
    // Generate simulated Customer Aging Report
    final creditCustomers = state.customers.where((c) => c.type == 'credit').toList();

    return TonalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تحليل أعمار الديون وحسابات المستحقات الآجلة (AR Aging)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          const Text('فئات استحقاق الديون من تاريخ صدور الفواتير للشركات المتعاقدة:'),
          const SizedBox(height: 16),
          Expanded(
            child: creditCustomers.isEmpty
                ? const Center(child: Text('لا يوجد عملاء ذوي حسابات آجلة مسجلين.'))
                : ScrollableTableWrapper(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('اسم العميل')),
                        DataColumn(label: Text('إجمالي المديونية ج.م')),
                        DataColumn(label: Text('جاري (0-30 يوم)')),
                        DataColumn(label: Text('متأخر (31-60 يوم)')),
                        DataColumn(label: Text('حرج (61-90 يوم)')),
                        DataColumn(label: Text('متعثر (>90 يوم)')),
                      ],
                      rows: creditCustomers.map((cust) {
                        double totalBalance = 0.0;
                        final ledger = state.ledgerEntries.where((e) => e.partyId == cust.id && e.partyType == 'customer');
                        if (ledger.isNotEmpty) {
                          totalBalance = ledger.last.balance;
                        }

                        // Distribute balance for aging mockup
                        double bracket1 = 0.0; // 0-30
                        double bracket2 = 0.0; // 31-60
                        double bracket3 = 0.0; // 61-90
                        double bracket4 = 0.0; // >90

                        if (totalBalance > 0) {
                          bracket1 = totalBalance * 0.60;
                          bracket2 = totalBalance * 0.25;
                          bracket3 = totalBalance * 0.10;
                          bracket4 = totalBalance * 0.05;
                        }

                        return DataRow(
                          cells: [
                            DataCell(Text(cust.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text('${totalBalance.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
                            DataCell(Text(bracket1 > 0 ? '${bracket1.toStringAsFixed(0)} ج.م' : '-')),
                            DataCell(Text(bracket2 > 0 ? '${bracket2.toStringAsFixed(0)} ...' : '-')),
                            DataCell(Text(bracket3 > 0 ? '${bracket3.toStringAsFixed(0)} ...' : '-')),
                            DataCell(
                              Text(
                                bracket4 > 0 ? '${bracket4.toStringAsFixed(0)} ...' : '-',
                                style: TextStyle(color: bracket4 > 0 ? AppColors.error : AppColors.textMain, fontWeight: bracket4 > 0 ? FontWeight.bold : FontWeight.normal),
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
    );
  }

  Widget _buildSupplierAgingTab(AppState state) {
    final creditSuppliers = state.suppliers.where((s) => s.paymentTerms == 'credit').toList();

    return TonalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تحليل أعمار ذمم الموردين والمدفوعات الآجلة (AP Aging)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          const Text('فئات جدولة مستحقات الموردين لتنسيق التدفق النقدي بالمركز:'),
          const SizedBox(height: 16),
          Expanded(
            child: creditSuppliers.isEmpty
                ? const Center(child: Text('لا يوجد موردين ذوي حسابات آجلة مسجلين.'))
                : ScrollableTableWrapper(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('اسم المورد')),
                        DataColumn(label: Text('إجمالي المستحقات ج.م')),
                        DataColumn(label: Text('مستحق (0-30 يوم)')),
                        DataColumn(label: Text('متأخر (31-60 يوم)')),
                        DataColumn(label: Text('حرج (61-90 يوم)')),
                        DataColumn(label: Text('متأخر جداً (>90 يوم)')),
                      ],
                      rows: creditSuppliers.map((supp) {
                        double totalBalance = 0.0;
                        final ledger = state.ledgerEntries.where((e) => e.partyId == supp.id && e.partyType == 'supplier');
                        if (ledger.isNotEmpty) {
                          totalBalance = ledger.last.balance;
                        }

                        double bracket1 = 0.0;
                        double bracket2 = 0.0;
                        double bracket3 = 0.0;
                        double bracket4 = 0.0;

                        if (totalBalance > 0) {
                          bracket1 = totalBalance * 0.70;
                          bracket2 = totalBalance * 0.20;
                          bracket3 = totalBalance * 0.10;
                          bracket4 = 0.0;
                        }

                        return DataRow(
                          cells: [
                            DataCell(Text(supp.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text('${totalBalance.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.tertiary))),
                            DataCell(Text(bracket1 > 0 ? '${bracket1.toStringAsFixed(0)} ج.م' : '-')),
                            DataCell(Text(bracket2 > 0 ? '${bracket2.toStringAsFixed(0)} ...' : '-')),
                            DataCell(Text(bracket3 > 0 ? '${bracket3.toStringAsFixed(0)} ...' : '-')),
                            DataCell(Text(bracket4 > 0 ? '${bracket4.toStringAsFixed(0)} ...' : '-')),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
