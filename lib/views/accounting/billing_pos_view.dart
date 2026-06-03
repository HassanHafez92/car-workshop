import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/role_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import '../../models/workshop_models.dart';
import '../../services/pdf_invoice_helper.dart';

class BillingPosView extends ConsumerStatefulWidget {
  const BillingPosView({super.key});

  @override
  ConsumerState<BillingPosView> createState() => _BillingPosViewState();
}

class _BillingPosViewState extends ConsumerState<BillingPosView> {
  Invoice? _selectedInvoice;
  String _paymentMethod = 'cash';
  final _receiptRefCtrl = TextEditingController();
  final _receiptAmountCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final activeRole = ref.watch(roleProvider).nameEn;

    // Filter unposted invoices
    final pendingInvoices = state.invoices.where((i) => i.status == 'pending_accounting').toList();
    final postedInvoices = state.invoices.where((i) => i.status == 'posted').toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Pending / Posted Invoices Queue (45% width)
        Expanded(
          flex: 4,
          child: TonalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'الفواتير المستحقة وقيد الانتظار',
                  subtitle: 'العمليات المكتملة المرفوعة لقسم الحسابات للمراجعة والتحصيل',
                ),
                const SizedBox(height: 12),
                const Text('فواتير معلقة بانتظار الترحيل (Pending):', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
                const SizedBox(height: 6),
                if (pendingInvoices.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: Text('لا توجد فواتير معلقة بانتظار الترحيل.')),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pendingInvoices.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final inv = pendingInvoices[index];
                      final cust = state.customers.firstWhere((x) => x.id == inv.customerId);
                      final isSelected = _selectedInvoice?.id == inv.id;

                      return ListTile(
                        dense: true,
                        title: Text(inv.invoiceNo, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('العميل: ${cust.name}\nالقيمة: ${inv.netTotal.toStringAsFixed(2)} ج.م'),
                        trailing: StatusBadge(status: inv.status),
                        selected: isSelected,
                        selectedTileColor: AppColors.primary.withOpacity(0.05),
                        onTap: () {
                          setState(() {
                            _selectedInvoice = inv;
                          });
                        },
                      );
                    },
                  ),
                const Divider(height: 24),
                const Text('آخر الفواتير التي تم ترحيلها وتحصيلها (Posted):', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
                const SizedBox(height: 6),
                Expanded(
                  child: postedInvoices.isEmpty
                      ? const Center(child: Text('لا توجد فواتير مرحلة سابقة.'))
                      : ListView.separated(
                          itemCount: postedInvoices.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final inv = postedInvoices[index];
                            final cust = state.customers.firstWhere((x) => x.id == inv.customerId);
                            final isSelected = _selectedInvoice?.id == inv.id;

                            return ListTile(
                              dense: true,
                              title: Text(inv.invoiceNo, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('العميل: ${cust.name}\nالقيمة: ${inv.netTotal.toStringAsFixed(2)} ج.م'),
                              trailing: StatusBadge(status: inv.status),
                              selected: isSelected,
                              selectedTileColor: AppColors.primary.withOpacity(0.05),
                              onTap: () {
                                setState(() {
                                  _selectedInvoice = inv;
                                });
                              },
                            );
                          },
                        ),
                )
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Right Column: Invoice Viewer & Reconciliation actions (55% width)
        Expanded(
          flex: 6,
          child: _selectedInvoice == null
              ? const TonalCard(
                  child: Center(
                    child: Text('اختر فاتورة من القائمة اليسرى لعرض تفاصيلها التفصيلية وتسوية الدفعات.'),
                  ),
                )
              : _buildInvoiceReconciliationPanel(state, activeRole),
        ),
      ],
    );
  }

  Widget _buildInvoiceReconciliationPanel(AppState state, String activeRole) {
    // Reload state instance of invoice
    final inv = state.invoices.firstWhere((i) => i.id == _selectedInvoice!.id);
    final customer = state.customers.firstWhere((c) => c.id == inv.customerId);
    final vehicle = state.vehicles.firstWhere((v) => v.id == inv.vehicleId);
    final jc = state.jobCards.firstWhere((j) => j.id == inv.jobCardId);

    final isPending = inv.status == 'pending_accounting';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Detail card styled like a paper bill
          TonalCard(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('فاتورة صيانة مركبة', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        const SizedBox(height: 4),
                        Text(inv.invoiceNo, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Row(
                      children: [
                        if (!isPending) ...[
                          IconButton(
                            tooltip: 'طباعة الفاتورة (PDF)',
                            icon: const Icon(Icons.print_outlined, color: AppColors.primary),
                            onPressed: () {
                              PdfInvoiceHelper.printInvoice(
                                invoice: inv,
                                customer: customer,
                                vehicle: vehicle,
                                jobCard: jc,
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                        StatusBadge(status: inv.status),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('تاريخ الفاتورة: ${inv.createdAt}'),
                const Divider(),
                
                // Customer details
                const Text('بيانات العميل والسيارة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Text('اسم العميل: ${customer.name} (${customer.type == 'credit' ? 'آجل' : 'نقدي'})'),
                Text('السيارة: ${vehicle.make} ${vehicle.model} | رقم اللوحة: ${vehicle.plateNumber}'),
                Text('العداد الحالي للسيارة: ${inv.laborTotal > 0 ? jc.odometer : vehicle.odometer} كم'),
                const Divider(),
                
                // Items Table
                const Text('بنود الخدمات والأجور ومواد الصرف:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted)),
                const SizedBox(height: 6),
                
                // Print tasks
                ...jc.tasks.map((task) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('أجور: ${task.description} (${task.technicianName})'),
                        Text('${task.price.toStringAsFixed(2)} ج.م'),
                      ],
                    ),
                  );
                }),
                
                // Print parts
                ...jc.parts.map((part) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('قطع غيار: ${part.name} (عدد ${part.quantity})'),
                        Text('${(part.price * part.quantity).toStringAsFixed(2)} ج.م'),
                      ],
                    ),
                  );
                }),
                
                const Divider(),
                
                // Summary Totals
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('إجمالي أجور الفنيين:'),
                    Text('${inv.laborTotal.toStringAsFixed(2)} ج.م'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('إجمالي قطع الغيار:'),
                    Text('${inv.partsTotal.toStringAsFixed(2)} ج.م'),
                  ],
                ),
                if (inv.discount > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الخصم التجاري الممنوح:', style: TextStyle(color: AppColors.error)),
                      Text('- ${inv.discount.toStringAsFixed(2)} ج.م', style: const TextStyle(color: AppColors.error)),
                    ],
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ضريبة القيمة المضافة (15%):'),
                    Text('${inv.tax.toStringAsFixed(2)} ج.م'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('الصافي المستحق النهائي:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${inv.netTotal.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Accountant Post & Payment Reconciliation Forms
          if (isPending)
            TonalCard(
              child: StatefulBuilder(
                builder: (context, setDialogState) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        title: 'الترحيل والتسوية المالية للحسابات',
                        subtitle: 'مراجعة وتأكيد قيود المبيعات والذمم والضريبة الخاصة بالفاتورة',
                      ),
                      const Text('طريقة تحصيل الفاتورة للتسوية المباشرة:'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Radio<String>(
                            value: 'cash',
                            groupValue: _paymentMethod,
                            onChanged: (val) {
                              setDialogState(() {
                                _paymentMethod = val!;
                              });
                            },
                          ),
                          const Text('كاش'),
                          const SizedBox(width: 12),
                          Radio<String>(
                            value: 'card',
                            groupValue: _paymentMethod,
                            onChanged: (val) {
                              setDialogState(() {
                                _paymentMethod = val!;
                              });
                            },
                          ),
                          const Text('شبكة / بطاقة مدى'),
                          const SizedBox(width: 12),
                          Radio<String>(
                            value: 'transfer',
                            groupValue: _paymentMethod,
                            onChanged: (val) {
                              setDialogState(() {
                                _paymentMethod = val!;
                              });
                            },
                          ),
                          const Text('حوالة بنكية'),
                          const SizedBox(width: 12),
                          Radio<String>(
                            value: 'credit',
                            groupValue: _paymentMethod,
                            onChanged: (val) {
                              setDialogState(() {
                                _paymentMethod = val!;
                              });
                            },
                          ),
                          const Text('على الحساب (آجل)'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              ref.read(appStateProvider.notifier).postInvoice(inv.id, _paymentMethod, activeRole);
                              setState(() {
                                _selectedInvoice = null;
                              });
                            },
                            icon: const Icon(Icons.post_add_outlined),
                            label: const Text('ترحيل وتوليد قيود الحسابات'),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            )
          else ...[
            // Posted actions (e.g. log on-account payments if it is a credit customer)
            if (inv.paymentMethod == 'credit')
              TonalCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'سداد جزئي أو كلي للذمة الآجلة',
                      subtitle: 'تسجيل سند قبض لحساب العميل لتقليل إجمالي الذمم المستحقة',
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FormFieldLabel(label: 'المبلغ المسدد (ج.م)'),
                              TextField(controller: _receiptAmountCtrl, keyboardType: TextInputType.number),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FormFieldLabel(label: 'رقم مرجع السند / شيك'),
                              TextField(controller: _receiptRefCtrl),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            final amount = double.tryParse(_receiptAmountCtrl.text.trim()) ?? 0.0;
                            final refNo = _receiptRefCtrl.text.trim();
                            if (amount <= 0 || refNo.isEmpty) return;

                            ref.read(appStateProvider.notifier).recordCustomerPayment(
                                  customerId: inv.customerId,
                                  amount: amount,
                                  referenceNo: refNo,
                                  activeRole: activeRole,
                                );

                            _receiptAmountCtrl.clear();
                            _receiptRefCtrl.clear();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم تسجيل دفعة العميل وتخفيض رصيده الجاري!')),
                            );
                            setState(() {
                              _selectedInvoice = null;
                            });
                          },
                          icon: const Icon(Icons.receipt_outlined),
                          label: const Text('ترحيل سند القبض'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            TonalCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('النسخة المطبوعة من الفاتورة:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      PdfInvoiceHelper.printInvoice(
                        invoice: inv,
                        customer: customer,
                        vehicle: vehicle,
                        jobCard: jc,
                      );
                    },
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('طباعة الفاتورة (PDF)'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
