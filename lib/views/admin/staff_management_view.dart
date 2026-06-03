import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/role_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import '../../models/user_model.dart';
import '../../models/workshop_models.dart';

class StaffManagementView extends ConsumerStatefulWidget {
  const StaffManagementView({super.key});

  @override
  ConsumerState<StaffManagementView> createState() => _StaffManagementViewState();
}

class _StaffManagementViewState extends ConsumerState<StaffManagementView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Add User form controllers
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.receptionist;

  // Filter selection for Audit Logs
  String _selectedAuditFilter = 'الكل';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final activeRole = ref.watch(roleProvider).nameEn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(icon: Icon(Icons.people_outline), text: 'إدارة حسابات الموظفين'),
            Tab(icon: Icon(Icons.security_outlined), text: 'سجل العمليات والأمان'),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildStaffManagementTab(state, activeRole),
              _buildAuditLogsTab(state),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStaffManagementTab(AppState state, String activeRole) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Form: Add Staff (40% width)
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            child: TonalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: 'تسجيل موظف جديد',
                    subtitle: 'إنشاء حساب مستخدم جديد وتعيين صلاحيات الدور الوظيفي المناسب له في النظام',
                  ),
                  const FormFieldLabel(label: 'الاسم الكامل للموظف'),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'مثال: أحمد محمد عبد العزيز',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const FormFieldLabel(label: 'اسم المستخدم للولوج (Username)'),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      hintText: 'مثال: ahmed_reception',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const FormFieldLabel(label: 'كلمة مرور الدخول'),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: '••••••••',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const FormFieldLabel(label: 'الدور الوظيفي والصلاحيات'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceLow,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<UserRole>(
                        value: _selectedRole,
                        isExpanded: true,
                        dropdownColor: AppColors.surfaceLowest,
                        onChanged: (UserRole? newRole) {
                          if (newRole != null) {
                            setState(() {
                              _selectedRole = newRole;
                            });
                          }
                        },
                        items: UserRole.values.map((role) {
                          return DropdownMenuItem<UserRole>(
                            value: role,
                            child: Text(role.nameAr),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final name = _nameController.text.trim();
                        final username = _usernameController.text.trim();
                        final password = _passwordController.text.trim();

                        if (name.isEmpty || username.isEmpty || password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('يرجى ملء جميع الحقول أولاً!')),
                          );
                          return;
                        }

                        // Check if username is taken
                        final exists = state.users.any(
                          (u) => u.username.toLowerCase() == username.toLowerCase(),
                        );
                        if (exists) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('اسم المستخدم هذا محجوز مسبقاً! يرجى اختيار اسم آخر.')),
                          );
                          return;
                        }

                        final newUser = UserAccount(
                          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
                          name: name,
                          username: username,
                          password: password,
                          role: _selectedRole,
                          isActive: true,
                        );

                        ref.read(appStateProvider.notifier).registerUser(newUser, activeRole);

                        _nameController.clear();
                        _usernameController.clear();
                        _passwordController.clear();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم تسجيل حساب الموظف الجديد بنجاح!')),
                        );
                      },
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                      label: const Text('تسجيل وحفظ الموظف'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // List: Staff Directory (60% width)
        Expanded(
          flex: 6,
          child: TonalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'دليل وحسابات الموظفين',
                  subtitle: 'مراقبة حسابات الكادر الحالي، صلاحياتهم، وإمكانية تعطيل أو تفعيل الحساب فوراً',
                ),
                Expanded(
                  child: state.users.isEmpty
                      ? const Center(child: Text('لا يوجد موظفون مسجلون حالياً.'))
                      : ScrollableTableWrapper(
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('الموظف')),
                              DataColumn(label: Text('اسم المستخدم')),
                              DataColumn(label: Text('الدور الوظيفي')),
                              DataColumn(label: Text('حالة الحساب')),
                              DataColumn(label: Text('التحكم')),
                            ],
                            rows: state.users.map((user) {
                              final roleBadgeColor = _getRoleBadgeColor(user.role);
                              
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      user.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  DataCell(Text(user.username)),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: roleBadgeColor.withOpacity(0.08),
                                        borderRadius: const BorderRadius.all(Radius.circular(4)),
                                      ),
                                      child: Text(
                                        user.role.nameAr,
                                        style: TextStyle(color: roleBadgeColor, fontWeight: FontWeight.bold, fontSize: 11),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    StatusBadge(
                                      status: user.isActive ? 'Completed' : 'cancelled',
                                    ),
                                  ),
                                  DataCell(
                                    user.id == 'user_admin'
                                        ? const Text('محمي (المدير)', style: TextStyle(color: AppColors.textMuted, fontSize: 11))
                                        : Switch(
                                            value: user.isActive,
                                            activeColor: AppColors.success,
                                            inactiveTrackColor: AppColors.error.withOpacity(0.1),
                                            onChanged: (bool val) {
                                              ref.read(appStateProvider.notifier).toggleUserActive(user.id, val, activeRole);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    val
                                                        ? 'تم تفعيل حساب الموظف ${user.name} بنجاح!'
                                                        : 'تم تعطيل حساب الموظف ${user.name} بنجاح!',
                                                  ),
                                                ),
                                              );
                                            },
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
        ),
      ],
    );
  }

  Widget _buildAuditLogsTab(AppState state) {
    // Dynamically query all unique userRoles (or user names/roles) logged in audit trail
    final uniqueLoggers = <String>{'الكل'};
    for (var log in state.auditLogs) {
      if (log.userRole.isNotEmpty) {
        uniqueLoggers.add(log.userRole);
      }
    }

    // Filter audit logs based on the selected dropdown value
    final filteredLogs = _selectedAuditFilter == 'الكل'
        ? state.auditLogs
        : state.auditLogs.where((l) => l.userRole == _selectedAuditFilter).toList();

    return TonalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: SectionHeader(
                  title: 'سجل المراجعة والعمليات والأمان (Audit Trail)',
                  subtitle: 'تتبع الحركات والعمليات والقيود المالية المنجزة مصنفة ومؤرخة بالثانية',
                ),
              ),
              // Dropdown filter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                width: 250,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedAuditFilter,
                    isExpanded: true,
                    dropdownColor: AppColors.surfaceLowest,
                    onChanged: (String? val) {
                      if (val != null) {
                        setState(() {
                          _selectedAuditFilter = val;
                        });
                      }
                    },
                    items: uniqueLoggers.map((logger) {
                      return DropdownMenuItem<String>(
                        value: logger,
                        child: Text(
                          logger == 'الكل' ? 'تصفية: جميع المستخدمين' : 'المستخدم: $logger',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filteredLogs.isEmpty
                ? const Center(child: Text('لا توجد عمليات مسجلة لهذا التصفية.'))
                : ScrollableTableWrapper(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('الوقت والتاريخ')),
                        DataColumn(label: Text('المسؤول / الدور')),
                        DataColumn(label: Text('نوع الحركة')),
                        DataColumn(label: Text('تفاصيل العملية')),
                      ],
                      rows: filteredLogs.map((log) {
                        Color roleColor = AppColors.primary;
                        if (log.userRole == 'Accountant' || log.userRole == 'المحاسب المالي' || log.userRole.contains('المحاسب')) {
                          roleColor = AppColors.secondary;
                        } else if (log.userRole == 'Technician' || log.userRole == 'الفني المختص' || log.userRole.contains('الفني')) {
                          roleColor = Colors.blue;
                        } else if (log.userRole == 'Storekeeper' || log.userRole == 'أمين المستودع' || log.userRole.contains('أمين')) {
                          roleColor = AppColors.tertiary;
                        } else if (log.userRole == 'Admin' || log.userRole == 'المدير العام' || log.userRole.contains('المدير')) {
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
                                  style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 11),
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

  Color _getRoleBadgeColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return AppColors.error;
      case UserRole.receptionist:
        return AppColors.primary;
      case UserRole.technician:
        return Colors.blue.shade700;
      case UserRole.storekeeper:
        return AppColors.tertiary;
      case UserRole.accountant:
        return AppColors.secondary;
    }
  }
}
