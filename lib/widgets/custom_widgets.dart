import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TonalCard extends StatelessWidget {
  final Widget child;
  final double padding;
  final Color? color;
  final VoidCallback? onTap;

  const TonalCard({
    super.key,
    required this.child,
    this.padding = 16.0,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      decoration: BoxDecoration(
        color: color ?? AppColors.surfaceLowest,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(padding),
      child: child,
    );

    if (onTap != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: card,
        ),
      );
    }
    return card;
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.surfaceLow;
    Color fg = AppColors.textMuted;

    switch (status) {
      case 'New':
      case 'جديد':
      case 'confirmed':
      case 'مؤكد':
        bg = AppColors.primary.withOpacity(0.1);
        fg = AppColors.primary;
        break;
      case 'Under Inspection':
      case 'قيد الفحص والتشخيص':
      case 'arrived':
      case 'وصل الورشة':
        bg = AppColors.secondary.withOpacity(0.15);
        fg = AppColors.secondary;
        break;
      case 'Waiting Customer Approval':
      case 'بانتظار موافقة العميل':
        bg = AppColors.warning.withOpacity(0.15);
        fg = AppColors.tertiary;
        break;
      case 'In Progress':
      case 'قيد الإصلاح':
      case 'active':
        bg = Colors.blue.withOpacity(0.1);
        fg = Colors.blue.shade800;
        break;
      case 'Waiting Parts':
      case 'بانتظار قطع الغيار':
        bg = Colors.deepOrange.withOpacity(0.1);
        fg = Colors.deepOrange.shade800;
        break;
      case 'Completed':
      case 'تم الانتهاء':
      case 'completed':
      case 'posted':
      case 'تم الترحيل والمحاسبة':
        bg = AppColors.success.withOpacity(0.1);
        fg = AppColors.success;
        break;
      case 'Delivered':
      case 'تم التسليم للعميل':
        bg = AppColors.textMuted.withOpacity(0.1);
        fg = AppColors.textMain;
        break;
      case 'cancelled':
      case 'ملغي':
        bg = AppColors.error.withOpacity(0.1);
        fg = AppColors.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class FormFieldLabel extends StatelessWidget {
  final String label;

  const FormFieldLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, top: 8.0),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMain,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class ScrollableTableWrapper extends StatelessWidget {
  final Widget child;

  const ScrollableTableWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      child: Container(
        color: AppColors.surfaceLow.withOpacity(0.5),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: child,
        ),
      ),
    );
  }
}
