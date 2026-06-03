import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_widgets.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);

    // Compute KPIs
    final activeJobsCount = state.jobCards.where((j) => j.status != 'Delivered' && j.status != 'Completed').length;
    final lowStockCount = state.parts.where((p) => p.stockCount <= p.minStock).length;
    final pendingInvoicesCount = state.invoices.where((i) => i.status == 'pending_accounting').length;

    // Calculate Accounts Receivable (AR) Total
    double totalAR = 0.0;
    for (var cust in state.customers) {
      final entries = state.ledgerEntries.where((e) => e.partyId == cust.id && e.partyType == 'customer');
      if (entries.isNotEmpty) {
        totalAR += entries.last.balance;
      }
    }

    // Calculate Accounts Payable (AP) Total
    double totalAP = 0.0;
    for (var supp in state.suppliers) {
      final entries = state.ledgerEntries.where((e) => e.partyId == supp.id && e.partyType == 'supplier');
      if (entries.isNotEmpty) {
        totalAP += entries.last.balance;
      }
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'نظرة عامة على الورشة',
            subtitle: 'مؤشرات الأداء التشغيلية والمالية الفورية للعمليات',
          ),
          
          // KPI Grid Row
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 48) / 5;
              final isDesktop = constraints.maxWidth > 900;
              
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildKpiCard(
                    context, 
                    title: 'بطاقات عمل نشطة', 
                    value: '$activeJobsCount', 
                    icon: Icons.car_repair_outlined, 
                    color: AppColors.primary,
                    width: isDesktop ? cardWidth : (constraints.maxWidth - 12) / 2
                  ),
                  _buildKpiCard(
                    context, 
                    title: 'نواقص قطع الغيار', 
                    value: '$lowStockCount', 
                    icon: Icons.warning_amber_outlined, 
                    color: lowStockCount > 0 ? AppColors.error : AppColors.success,
                    width: isDesktop ? cardWidth : (constraints.maxWidth - 12) / 2
                  ),
                  _buildKpiCard(
                    context, 
                    title: 'فواتير تحت المراجعة', 
                    value: '$pendingInvoicesCount', 
                    icon: Icons.rate_review_outlined, 
                    color: AppColors.secondary,
                    width: isDesktop ? cardWidth : (constraints.maxWidth - 12) / 2
                  ),
                  _buildKpiCard(
                    context, 
                    title: 'المستحقات للورشة (AR)', 
                    value: '${totalAR.toStringAsFixed(0)} ج.م', 
                    icon: Icons.trending_up_outlined, 
                    color: AppColors.success,
                    width: isDesktop ? cardWidth : (constraints.maxWidth - 12) / 2
                  ),
                  _buildKpiCard(
                    context, 
                    title: 'الذمم للموردين (AP)', 
                    value: '${totalAP.toStringAsFixed(0)} ج.م', 
                    icon: Icons.trending_down_outlined, 
                    color: AppColors.tertiary,
                    width: isDesktop ? cardWidth : (constraints.maxWidth - 12) / 2
                  ),
                ],
              );
            }
          ),
          const SizedBox(height: 24),

          // Charts & Lists Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chart area (60%)
              Expanded(
                flex: 3,
                child: TonalCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'منحنى المبيعات والإيرادات (أسبوعي)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 240,
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: FlTitlesData(
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    const days = ['أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت'];
                                    if (value.toInt() >= 0 && value.toInt() < days.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(days[value.toInt()], style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: const [
                                  FlSpot(0, 1200),
                                  FlSpot(1, 2300),
                                  FlSpot(2, 1800),
                                  FlSpot(3, 3400),
                                  FlSpot(4, 4100),
                                  FlSpot(5, 500),
                                  FlSpot(6, 2900),
                                ],
                                isCurved: true,
                                color: AppColors.primary,
                                barWidth: 4,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: AppColors.primary.withOpacity(0.08),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Feed area (40%)
              Expanded(
                flex: 2,
                child: TonalCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'آخر العمليات وبطاقات العمل المفتوحة',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                      ),
                      const SizedBox(height: 16),
                      if (state.jobCards.isEmpty)
                        const SizedBox(
                          height: 200,
                          child: Center(child: Text('لا توجد بطاقات عمل مفتوحة حالياً.')),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.jobCards.take(4).length,
                          separatorBuilder: (context, index) => const Divider(height: 12),
                          itemBuilder: (context, index) {
                            final jc = state.jobCards[index];
                            final cust = state.customers.firstWhere((x) => x.id == jc.customerId);
                            final veh = state.vehicles.firstWhere((x) => x.id == jc.vehicleId);

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(jc.cardNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  StatusBadge(status: jc.status),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'العميل: ${cust.name} | السيارة: ${veh.make} ${veh.model}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.bold),
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withOpacity(0.08),
                child: Icon(icon, color: color, size: 20),
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          )
        ],
      ),
    );
  }
}
