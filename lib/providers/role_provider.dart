import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UserRole {
  admin,
  receptionist,
  technician,
  storekeeper,
  accountant,
}

extension UserRoleExt on UserRole {
  String get nameAr {
    switch (this) {
      case UserRole.admin:
        return "المدير العام";
      case UserRole.receptionist:
        return "موظف الاستقبال";
      case UserRole.technician:
        return "الفني المختص";
      case UserRole.storekeeper:
        return "أمين المستودع";
      case UserRole.accountant:
        return "المحاسب المالي";
    }
  }

  String get nameEn {
    switch (this) {
      case UserRole.admin:
        return "Admin / Owner";
      case UserRole.receptionist:
        return "Receptionist";
      case UserRole.technician:
        return "Technician";
      case UserRole.storekeeper:
        return "Storekeeper";
      case UserRole.accountant:
        return "Accountant";
    }
  }
}

class RoleNotifier extends Notifier<UserRole> {
  @override
  UserRole build() {
    return UserRole.admin;
  }

  void setRole(UserRole role) {
    state = role;
  }
}

final roleProvider = NotifierProvider<RoleNotifier, UserRole>(RoleNotifier.new);
