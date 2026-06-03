import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class AuditLogsView extends ConsumerWidget {
  const AuditLogsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);

    return TonalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'سجل المراجعة والأمان (Audit Logs)',
            subtitle: 'سجل تاريخي بكافة الإجراءات والعمليات وتعديلات كروت الصيانة والترحيل المالي للحسابات',
          ),
          const SizedBox(height: 16),
          Expanded(
            child: state.auditLogs.isEmpty
                ? const Center(child: Text('سجل العمليات فارغ.'))
                : ScrollableTableWrapper(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('التاريخ والوقت')),
                        DataColumn(label: Text('المستخدم (دور المحاكاة)')),
                        DataColumn(label: Text('نوع العملية')),
                        DataColumn(label: Text('التفاصيل')),
                      ],
                      rows: state.auditLogs.map((log) {
                        Color roleColor = AppColors.primary;
                        if (log.userRole == 'Accountant' || log.userRole == 'المحاسب المالي') {
                          roleColor = AppColors.secondary;
                        } else if (log.userRole == 'Technician' || log.userRole == 'الفني المختص') {
                          roleColor = Colors.blue;
                        } else if (log.userRole == 'Storekeeper' || log.userRole == 'أمين المستودع') {
                          roleColor = AppColors.tertiary;
                        } else if (log.userRole == 'Admin' || log.userRole == 'المدير العام') {
                          roleColor = AppColors.error;
                        }

                        return DataRow(
                          cells: [
                            DataCell(Text(log.timestamp)),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: roleColor.withOpacity(0.08),
                                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                                ),
                                child: Text(
                                  log.userRole,
                                  style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ),
                            DataCell(Text(log.action, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text(log.details)),
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
