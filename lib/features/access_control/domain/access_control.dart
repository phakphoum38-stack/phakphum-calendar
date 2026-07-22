enum StaffRole { staff, incharge, manager, admin }

enum Permission {
  viewOwnSchedule,
  viewDepartmentSchedule,
  requestShiftExchange,
  approveShiftExchange,
  manageDepartmentSchedule,
  manageOrganization,
  viewAuditLog,
}

class AccessPolicy {
  const AccessPolicy._();

  static final Map<StaffRole, Set<Permission>> _permissions = {
    StaffRole.staff: {
      Permission.viewOwnSchedule,
      Permission.requestShiftExchange,
    },
    StaffRole.incharge: {
      Permission.viewOwnSchedule,
      Permission.viewDepartmentSchedule,
      Permission.requestShiftExchange,
      Permission.approveShiftExchange,
    },
    StaffRole.manager: {
      Permission.viewOwnSchedule,
      Permission.viewDepartmentSchedule,
      Permission.requestShiftExchange,
      Permission.approveShiftExchange,
      Permission.manageDepartmentSchedule,
      Permission.viewAuditLog,
    },
    StaffRole.admin: Permission.values.toSet(),
  };

  static bool allows(StaffRole role, Permission permission) =>
      _permissions[role]?.contains(permission) ?? false;

  static Set<Permission> permissionsFor(StaffRole role) =>
      Set.unmodifiable(_permissions[role] ?? const <Permission>{});
}
