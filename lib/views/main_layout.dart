import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/role_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';

import '../services/notification_service.dart';

// Import Views
import 'dashboard_view.dart';
import 'crm/customers_vehicles_view.dart';
import 'purchases/suppliers_purchases_view.dart';
import 'jobs/job_cards_view.dart';
import 'jobs/technician_board_view.dart';
import 'calendar/calendar_view.dart';
import 'inventory/inventory_view.dart';
import 'accounting/billing_pos_view.dart';
import 'accounting/ledgers_view.dart';
import 'admin/staff_management_view.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _selectedIndex = 0;

  // Global Page Map
  Widget _getPage(int index, UserRole role) {
    final pages = _getAccessiblePages(role);
    if (index >= pages.length) {
      return pages[0]['view'] as Widget;
    }
    return pages[index]['view'] as Widget;
  }

  List<Map<String, dynamic>> _getAccessiblePages(UserRole role) {
    final List<Map<String, dynamic>> allPages = [
      {
        'title': 'لوحة التحكم',
        'icon': Icons.dashboard_outlined,
        'view': const DashboardView(),
        'roles': [UserRole.admin, UserRole.receptionist, UserRole.technician, UserRole.storekeeper, UserRole.accountant]
      },
      {
        'title': 'العملاء والسيارات',
        'icon': Icons.people_outline,
        'view': const CustomersVehiclesView(),
        'roles': [UserRole.admin, UserRole.receptionist]
      },
      {
        'title': 'الموردين والمشتريات',
        'icon': Icons.local_shipping_outlined,
        'view': const SuppliersPurchasesView(),
        'roles': [UserRole.admin, UserRole.storekeeper, UserRole.accountant]
      },
      {
        'title': 'بطاقات العمل',
        'icon': Icons.assignment_outlined,
        'view': const JobCardsView(),
        'roles': [UserRole.admin, UserRole.receptionist]
      },
      {
        'title': 'لوحة مهام الفني',
        'icon': Icons.build_circle_outlined,
        'view': const TechnicianBoardView(),
        'roles': [UserRole.admin, UserRole.technician]
      },
      {
        'title': 'مواعيد الورشة',
        'icon': Icons.calendar_month_outlined,
        'view': const CalendarView(),
        'roles': [UserRole.admin, UserRole.receptionist]
      },
      {
        'title': 'المستودع وقطع الغيار',
        'icon': Icons.inventory_2_outlined,
        'view': const InventoryView(),
        'roles': [UserRole.admin, UserRole.storekeeper]
      },
      {
        'title': 'الفواتير والـ POS',
        'icon': Icons.receipt_long_outlined,
        'view': const BillingPosView(),
        'roles': [UserRole.admin, UserRole.accountant, UserRole.receptionist]
      },
      {
        'title': 'الحسابات والذمم (AR/AP)',
        'icon': Icons.account_balance_wallet_outlined,
        'view': const LedgersView(),
        'roles': [UserRole.admin, UserRole.accountant]
      },
      {
        'title': 'إدارة الموظفين والأمان',
        'icon': Icons.security_outlined,
        'view': const StaffManagementView(),
        'roles': [UserRole.admin]
      },
    ];

    return allPages.where((page) => (page['roles'] as List<UserRole>).contains(role)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).currentUser;
    final activeRole = currentUser?.role ?? UserRole.admin;
    final appState = ref.watch(appStateProvider);
    final accessiblePages = _getAccessiblePages(activeRole);

    // Keep selected index within bounds when switching roles
    if (_selectedIndex >= accessiblePages.length) {
      _selectedIndex = 0;
    }

    return Directionality(
      textDirection: TextDirection.rtl, // Forces RTL Globally
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceLowest,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Row(
            children: [
              const Icon(Icons.minor_crash_outlined, color: AppColors.primary, size: 28),
              const SizedBox(width: 8),
              Text(
                'نظام إدارة ورش السيارات',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              
              // Localized Role Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                ),
                child: Text(
                  activeRole.nameAr,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Notification Alert Popover
              _NotificationBadge(notifications: appState.notificationLogs),
              const SizedBox(width: 16),
              
              // Active User Info
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      currentUser != null && currentUser.name.isNotEmpty
                          ? currentUser.name.substring(0, 1)
                          : 'ح',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currentUser?.name ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.logout_outlined, color: AppColors.error),
                    tooltip: 'تسجيل الخروج',
                    onPressed: () {
                      ref.read(authProvider.notifier).logout();
                    },
                  ),
                ],
              )
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(
              color: AppColors.surfaceContainerHigh,
              height: 1.0,
            ),
          ),
        ),
        body: Row(
          children: [
            // Collapsible / Responsive Sidebar Navigation (Right Aligned in RTL)
            Container(
              width: 250,
              color: AppColors.surfaceLowest,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: accessiblePages.length,
                      itemBuilder: (context, index) {
                        final item = accessiblePages[index];
                        final isSelected = index == _selectedIndex;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedIndex = index;
                              });
                            },
                            borderRadius: const BorderRadius.all(Radius.circular(8)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
                                borderRadius: const BorderRadius.all(Radius.circular(8)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    item['icon'] as IconData,
                                    color: isSelected ? AppColors.primary : AppColors.textMuted,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    item['title'] as String,
                                    style: TextStyle(
                                      color: isSelected ? AppColors.primary : AppColors.textMain,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    alignment: Alignment.center,
                    child: Text(
                      'نسخة تجريبية v1.0.0',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            
            // Vertical Divider
            Container(
              width: 1,
              color: AppColors.surfaceContainerHigh,
            ),
            
            // Main Content Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: _getPage(_selectedIndex, activeRole),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationBadge extends StatelessWidget {
  final List<NotificationLog> notifications;

  const _NotificationBadge({required this.notifications});

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.length;
    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_none_outlined, size: 26, color: AppColors.textMain),
          if (unreadCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.message_outlined, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('سجل التنبيهات والاتصالات التلقائية'),
                  ],
                ),
                content: SizedBox(
                  width: 500,
                  height: 400,
                  child: notifications.isEmpty
                      ? const Center(child: Text('لا توجد تنبيهات مرسلة حالياً.'))
                      : ListView.separated(
                          itemCount: notifications.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final notif = notifications[index];
                            IconData icon = Icons.chat_bubble_outline;
                            Color color = AppColors.primary;
                            String channelName = '';

                            if (notif.type == 'sms') {
                              icon = Icons.sms_outlined;
                              color = Colors.blue;
                              channelName = 'رسالة SMS للعميل';
                            } else if (notif.type == 'whatsapp') {
                              icon = Icons.wechat_outlined;
                              color = AppColors.success;
                              channelName = 'واتساب للعميل';
                            } else {
                              icon = Icons.campaign_outlined;
                              color = AppColors.tertiary;
                              channelName = 'تنبيه داخلي للورشة';
                            }

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: color.withOpacity(0.1),
                                child: Icon(icon, color: color),
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(channelName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text(notif.timestamp, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('إلى: ${notif.recipient}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                    const SizedBox(height: 2),
                                    Text(notif.message, style: const TextStyle(color: AppColors.textMain, fontSize: 12)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إغلاق'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
