import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/role_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import '../../models/workshop_models.dart';

class TechnicianBoardView extends ConsumerStatefulWidget {
  const TechnicianBoardView({super.key});

  @override
  ConsumerState<TechnicianBoardView> createState() => _TechnicianBoardViewState();
}

class _TechnicianBoardViewState extends ConsumerState<TechnicianBoardView> {
  JobCard? _selectedJobCard;
  final _findingCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final activeRole = ref.watch(roleProvider).nameEn;

    // Filter job cards that are active for floor shop
    final techJobs = state.jobCards.where((jc) {
      return jc.status == 'New' ||
          jc.status == 'Under Inspection' ||
          jc.status == 'In Progress' ||
          jc.status == 'Waiting Parts';
    }).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Active Shop Tasks List (40% width)
        Expanded(
          flex: 4,
          child: TonalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'لوحة الأعمال الفنية بالورشة',
                  subtitle: 'السيارات المتاحة للعمل والتشخيص على الرافعات',
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: techJobs.isEmpty
                      ? const Center(child: Text('لا توجد مركبات في صالة الإصلاح حالياً.'))
                      : ListView.separated(
                          itemCount: techJobs.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final jc = techJobs[index];
                            final veh = state.vehicles.firstWhere((x) => x.id == jc.vehicleId);
                            final isSelected = _selectedJobCard?.id == jc.id;

                            return ListTile(
                              title: Text(jc.cardNo, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('السيارة: ${veh.make} ${veh.model} (${veh.plateNumber})\nالمهمة: ${jc.complaint}'),
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

        // Right Column: Technician Task Operations Sheet (60% width)
        Expanded(
          flex: 6,
          child: _selectedJobCard == null
              ? const TonalCard(
                  child: Center(
                    child: Text('اختر سيارة أو كرت عمل للبدء بتشغيل العداد وتسجيل العمل المنجز والملاحظات الفنية.'),
                  ),
                )
              : _buildTechnicianTaskPanel(state, activeRole),
        ),
      ],
    );
  }

  Widget _buildTechnicianTaskPanel(AppState state, String activeRole) {
    // Reload active state of job card
    final jc = state.jobCards.firstWhere((j) => j.id == _selectedJobCard!.id);
    final vehicle = state.vehicles.firstWhere((v) => v.id == jc.vehicleId);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          TonalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'فحص وإصلاح: ${jc.cardNo}',
                  subtitle: 'السيارة: ${vehicle.make} ${vehicle.model} (لوحة: ${vehicle.plateNumber}) | العداد: ${vehicle.odometer} كم',
                  trailing: StatusBadge(status: jc.status),
                ),
                const Divider(),
                const SizedBox(height: 8),
                const Text('المهمة المطلوبة وصك الشكوى:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Text(jc.complaint, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 16),
                
                // Status buttons for Technicians
                Row(
                  children: [
                    const Text('تحديث حالة العمل:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: jc.status == 'New' 
                          ? () => ref.read(appStateProvider.notifier).updateJobStatus(jc.id, 'Under Inspection', activeRole)
                          : null,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                      child: const Text('بدء الفحص'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: (jc.status == 'Under Inspection' || jc.status == 'Waiting Parts')
                          ? () => ref.read(appStateProvider.notifier).updateJobStatus(jc.id, 'In Progress', activeRole)
                          : null,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
                      child: const Text('بدء الإصلاح'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: jc.status == 'In Progress'
                          ? () => ref.read(appStateProvider.notifier).updateJobStatus(jc.id, 'Completed', activeRole)
                          : null,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                      child: const Text('إتمام كرت العمل'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Technical Tasks & Start/Stop Timers Card
          TonalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'البنود الموكلة إليك بالعمل وصالون التوقيت',
                  subtitle: 'سجل عداد الوقت لكل عملية لتحديد أجور الإنتاجية بدقة',
                ),
                if (jc.tasks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: Text('لا توجد بنود عمل مسندة. يرجى مراجعة موظف الاستقبال لتفصيل بنود العمل.')),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: jc.tasks.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final task = jc.tasks[index];
                      final isPending = task.status == 'pending';
                      final isActive = task.status == 'active';
                      final isCompleted = task.status == 'completed';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isCompleted 
                              ? AppColors.success.withOpacity(0.1) 
                              : (isActive ? Colors.blue.withOpacity(0.1) : AppColors.surfaceLow),
                          foregroundColor: isCompleted 
                              ? AppColors.success 
                              : (isActive ? Colors.blue : AppColors.textMuted),
                          child: Icon(isCompleted ? Icons.check : Icons.timer_outlined),
                        ),
                        title: Text(task.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('الفني: ${task.technicianName} | تصنيف: ${task.type}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Strict RBAC: No labor price displayed for Technician!
                            StatusBadge(status: task.status),
                            const SizedBox(width: 8),
                            if (isPending)
                              ElevatedButton(
                                onPressed: () {
                                  ref.read(appStateProvider.notifier).toggleTaskTimer(jc.id, task.id);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                ),
                                child: const Text('ابدأ الوقت'),
                              ),
                            if (isActive)
                              ElevatedButton(
                                onPressed: () {
                                  ref.read(appStateProvider.notifier).toggleTaskTimer(jc.id, task.id);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                ),
                                child: const Text('أنهِ العمل'),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Diagnostic Findings Card
          TonalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'النتائج الفنية وتقارير التشخيص',
                  subtitle: 'كتابة تقارير الفحص الفني للفرامل والمحرك لتظهر للعميل موظف الاستقبال',
                ),
                TextField(
                  controller: _findingCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'مثال: تم فحص الفرامل الأمامية وتبين تآكل الفحمات تماماً، تحتاج الفرامل الخلفية خرط هوبات وسفايف جديدة...',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        if (_findingCtrl.text.trim().isEmpty) return;
                        // Add finding note as interaction note or status detail
                        ref.read(appStateProvider.notifier).addVehicle(
                              customerId: jc.customerId,
                              plateNumber: vehicle.plateNumber,
                              chassisNumber: vehicle.chassisNumber,
                              make: vehicle.make,
                              model: vehicle.model,
                              year: vehicle.year,
                              color: vehicle.color,
                              odometer: vehicle.odometer,
                              notes: 'تقرير تشخيص فني (${DateTime.now().toIso8601String().substring(11,16)}): ' + _findingCtrl.text.trim(),
                              activeRole: activeRole,
                            );
                        _findingCtrl.clear();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم تسجيل تقرير التشخيص الفني وإرساله بنجاح!')),
                        );
                      },
                      child: const Text('حفظ وإرسال التقرير للمكتب'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
