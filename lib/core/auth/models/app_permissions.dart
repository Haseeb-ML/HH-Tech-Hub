import 'package:flutter/material.dart';

/// All recognizable modules and granular sub-modules within HH Tech Hub ERP.
enum AppModule {
  dashboard,

  // Finance & Accounts (Header)
  finance,
  ledger,
  accounts,
  income,
  expenses,
  loans,
  personalAccounts,
  financeReports,

  // HR & Employees (Header)
  hr,
  employees,
  attendance,
  payroll,
  advances,
  employeeHistory,

  // Inventory & Assets (Header)
  inventory,
  officeInventory,
  assets,

  // Reports & Analytics (Header)
  reports,
  generalReports,

  // Operations
  clients,
  projects,
  projectsList,
  tasks,
  timesheets,

  // Administration & Security (Header)
  administration,
  systemSettings,
  databaseBackup,
  auditLogs,
}

extension AppModuleExtension on AppModule {
  String get key => name;

  String get displayName {
    switch (this) {
      case AppModule.dashboard:
        return 'Dashboard';
      case AppModule.finance:
        return 'Finance & Accounts';
      case AppModule.ledger:
        return 'General Ledger';
      case AppModule.accounts:
        return 'Accounts';
      case AppModule.income:
        return 'Income';
      case AppModule.expenses:
        return 'Expenses';
      case AppModule.loans:
        return 'Loans';
      case AppModule.personalAccounts:
        return 'Personal Accounts';
      case AppModule.financeReports:
        return 'Finance Reports';
      case AppModule.hr:
        return 'HR & Employees';
      case AppModule.employees:
        return 'Employees';
      case AppModule.attendance:
        return 'Attendance';
      case AppModule.payroll:
        return 'Salaries';
      case AppModule.advances:
        return 'Advances';
      case AppModule.employeeHistory:
        return 'Employee History';
      case AppModule.inventory:
        return 'Inventory & Assets';
      case AppModule.officeInventory:
        return 'Office Inventory';
      case AppModule.assets:
        return 'Assets Management';
      case AppModule.reports:
        return 'Reports & Analytics';
      case AppModule.generalReports:
        return 'Reports & Analytics';
      case AppModule.clients:
        return 'Clients & Relations';
      case AppModule.projects:
        return 'Projects & Operations';
      case AppModule.projectsList:
        return 'Projects';
      case AppModule.tasks:
        return 'Tasks';
      case AppModule.timesheets:
        return 'Timesheets';
      case AppModule.administration:
        return 'Administration & Security';
      case AppModule.systemSettings:
        return 'System Settings';
      case AppModule.databaseBackup:
        return 'Database Backup';
      case AppModule.auditLogs:
        return 'Audit Logs';
    }
  }

  IconData get icon {
    switch (this) {
      case AppModule.dashboard:
        return Icons.dashboard_outlined;
      case AppModule.finance:
        return Icons.account_balance_wallet_outlined;
      case AppModule.ledger:
        return Icons.account_balance_outlined;
      case AppModule.accounts:
        return Icons.wallet_outlined;
      case AppModule.income:
        return Icons.trending_up_rounded;
      case AppModule.expenses:
        return Icons.trending_down_rounded;
      case AppModule.loans:
        return Icons.real_estate_agent_outlined;
      case AppModule.personalAccounts:
        return Icons.person_outline;
      case AppModule.financeReports:
        return Icons.analytics_outlined;
      case AppModule.hr:
        return Icons.people_outline;
      case AppModule.employees:
        return Icons.badge_outlined;
      case AppModule.attendance:
        return Icons.calendar_month_outlined;
      case AppModule.payroll:
        return Icons.payments_outlined;
      case AppModule.advances:
        return Icons.receipt_long_outlined;
      case AppModule.employeeHistory:
        return Icons.history_outlined;
      case AppModule.inventory:
        return Icons.inventory_2_outlined;
      case AppModule.officeInventory:
        return Icons.inventory_2_outlined;
      case AppModule.assets:
        return Icons.devices_other_outlined;
      case AppModule.reports:
        return Icons.bar_chart_outlined;
      case AppModule.generalReports:
        return Icons.bar_chart_outlined;
      case AppModule.clients:
        return Icons.business_center_outlined;
      case AppModule.projects:
        return Icons.assignment_outlined;
      case AppModule.projectsList:
        return Icons.assignment_outlined;
      case AppModule.tasks:
        return Icons.task_alt_outlined;
      case AppModule.timesheets:
        return Icons.more_time_outlined;
      case AppModule.administration:
        return Icons.security_outlined;
      case AppModule.systemSettings:
        return Icons.settings_outlined;
      case AppModule.databaseBackup:
        return Icons.backup_outlined;
      case AppModule.auditLogs:
        return Icons.history_toggle_off_outlined;
    }
  }

  bool get isCategoryHeader {
    switch (this) {
      case AppModule.finance:
      case AppModule.projects:
      case AppModule.hr:
      case AppModule.inventory:
      case AppModule.reports:
      case AppModule.administration:
        return true;
      default:
        return false;
    }
  }

  AppModule? get parentModule {
    switch (this) {
      case AppModule.ledger:
      case AppModule.accounts:
      case AppModule.income:
      case AppModule.expenses:
      case AppModule.loans:
      case AppModule.personalAccounts:
        return AppModule.finance;
      case AppModule.projectsList:
      case AppModule.tasks:
      case AppModule.timesheets:
        return AppModule.projects;
      case AppModule.employees:
      case AppModule.attendance:
      case AppModule.payroll:
      case AppModule.advances:
      case AppModule.employeeHistory:
        return AppModule.hr;
      case AppModule.officeInventory:
      case AppModule.assets:
        return AppModule.inventory;
      case AppModule.generalReports:
        return AppModule.reports;
      case AppModule.systemSettings:
      case AppModule.databaseBackup:
      case AppModule.auditLogs:
        return AppModule.administration;
      default:
        return null;
    }
  }

  bool get isSubModule => parentModule != null;

  List<AppModule> get subModules {
    switch (this) {
      case AppModule.finance:
        return const [
          AppModule.ledger,
          AppModule.accounts,
          AppModule.income,
          AppModule.expenses,
          AppModule.loans,
          AppModule.personalAccounts,
        ];
      case AppModule.projects:
        return const [
          AppModule.projectsList,
          AppModule.tasks,
          AppModule.timesheets,
        ];
      case AppModule.hr:
        return const [
          AppModule.employees,
          AppModule.attendance,
          AppModule.payroll,
          AppModule.advances,
          AppModule.employeeHistory,
        ];
      case AppModule.inventory:
        return const [
          AppModule.officeInventory,
          AppModule.assets,
        ];
      case AppModule.reports:
        return const [
          AppModule.generalReports,
        ];
      case AppModule.administration:
        return const [
          AppModule.systemSettings,
          AppModule.databaseBackup,
          AppModule.auditLogs,
        ];
      default:
        return const [];
    }
  }

  String get category {
    if (parentModule != null) {
      return parentModule!.displayName;
    }
    return displayName;
  }

  static AppModule? fromString(String str) {
    final clean = str.trim().toLowerCase().replaceAll('_', '').replaceAll(' ', '');
    for (final val in AppModule.values) {
      final vClean = val.name.toLowerCase();
      if (vClean == clean || clean == val.displayName.toLowerCase().replaceAll(' ', '')) {
        return val;
      }
    }
    // Specific aliases
    if (clean == 'generalledger' || clean == 'ledger') return AppModule.ledger;
    if (clean == 'personalaccount' || clean == 'personalaccounts' || clean == 'wallet') return AppModule.personalAccounts;
    if (clean == 'financereport' || clean == 'financereports') return AppModule.financeReports;
    if (clean == 'salary' || clean == 'salaries') return AppModule.payroll;
    if (clean == 'advance' || clean == 'advances') return AppModule.advances;
    if (clean == 'employeehistory' || clean == 'history') return AppModule.employeeHistory;
    if (clean == 'officeinventory' || clean == 'inventorylist') return AppModule.officeInventory;
    if (clean == 'generalreports' || clean == 'reportsanalytics') return AppModule.generalReports;
    if (clean == 'projectslist' || clean == 'projectlist' || clean == 'projectsmanagement') return AppModule.projectsList;
    if (clean == 'tasks' || clean == 'task' || clean == 'taskmanagement') return AppModule.tasks;
    if (clean == 'timesheets' || clean == 'timesheet' || clean == 'worklogs') return AppModule.timesheets;
    if (clean == 'auditlogs' || clean == 'auditlog' || clean == 'audit') return AppModule.auditLogs;
    if (clean == 'databasebackup' || clean == 'backup') return AppModule.databaseBackup;
    if (clean == 'systemsettings' || clean == 'settings') return AppModule.systemSettings;
    return null;
  }
}

/// Operations / Actions allowed on any module.
enum PermissionAction {
  view,
  create,
  edit,
  delete,
  approve,
  export,
  manage,
}

extension PermissionActionExtension on PermissionAction {
  String get key => name;

  String get displayName {
    switch (this) {
      case PermissionAction.view:
        return 'View';
      case PermissionAction.create:
        return 'Add / Create';
      case PermissionAction.edit:
        return 'Edit / Update';
      case PermissionAction.delete:
        return 'Delete';
      case PermissionAction.approve:
        return 'Approve';
      case PermissionAction.export:
        return 'Export';
      case PermissionAction.manage:
        return 'Full Manage';
    }
  }

  static PermissionAction? fromString(String str) {
    final clean = str.trim().toLowerCase().replaceAll(' ', '').replaceAll('_', '').replaceAll('/', '');
    for (final val in PermissionAction.values) {
      if (val.name.toLowerCase() == clean) return val;
    }
    if (clean == 'add' || clean == 'create' || clean == 'addcreate') return PermissionAction.create;
    if (clean == 'edit' || clean == 'update' || clean == 'editupdate') return PermissionAction.edit;
    return null;
  }
}

/// Comprehensive Role Model supporting granular module-action permissions
class UserRole {
  final String id;
  final String roleName;
  final String description;
  final bool isSystemRole;
  final bool isActive;
  final bool canChangeUsername;
  final bool canChangePassword;
  final Map<AppModule, Set<PermissionAction>> permissions;

  const UserRole({
    required this.id,
    required this.roleName,
    required this.description,
    this.isSystemRole = false,
    this.isActive = true,
    this.canChangeUsername = false,
    this.canChangePassword = false,
    required this.permissions,
  });

  bool get isSuperAdmin =>
      roleName.trim().toLowerCase() == 'super admin' ||
      roleName.trim().toLowerCase() == 'system admin';

  /// Evaluates whether this role has permission for a specific module and action.
  bool hasPermission(AppModule module, PermissionAction action) {
    if (isSuperAdmin) return true; // Super Admin has non-restrictable full ERP access
    if (!isActive) return false; // Inactive roles grant no permissions

    // 1. Direct permission check: if this module is explicitly configured in permissions map
    if (permissions.containsKey(module)) {
      final modulePerms = permissions[module]!;
      if (modulePerms.contains(PermissionAction.manage)) return true;
      return modulePerms.contains(action);
    }

    // 2. Hierarchical fallback: ONLY if sub-module is NOT explicitly defined in permissions,
    // fallback to parent module's grant.
    final parent = module.parentModule;
    if (parent != null && permissions.containsKey(parent)) {
      final parentPerms = permissions[parent]!;
      if (parentPerms.contains(PermissionAction.manage)) return true;
      return parentPerms.contains(action);
    }

    // 3. Fallback compatibility with legacy role strings
    if (module == AppModule.ledger && permissions.containsKey(AppModule.finance)) {
      return permissions[AppModule.finance]!.contains(action);
    }
    if (module == AppModule.personalAccounts && permissions.containsKey(AppModule.accounts)) {
      return permissions[AppModule.accounts]!.contains(action);
    }
    if (module == AppModule.financeReports &&
        (permissions.containsKey(AppModule.reports) || permissions.containsKey(AppModule.finance))) {
      return (permissions[AppModule.reports]?.contains(action) ?? false) ||
          (permissions[AppModule.finance]?.contains(action) ?? false);
    }
    if (module == AppModule.advances && permissions.containsKey(AppModule.payroll)) {
      return permissions[AppModule.payroll]!.contains(action);
    }
    if (module == AppModule.employeeHistory && permissions.containsKey(AppModule.employees)) {
      return permissions[AppModule.employees]!.contains(action);
    }
    if (module == AppModule.officeInventory && permissions.containsKey(AppModule.inventory)) {
      return permissions[AppModule.inventory]!.contains(action);
    }
    if (module == AppModule.generalReports && permissions.containsKey(AppModule.reports)) {
      return permissions[AppModule.reports]!.contains(action);
    }
    if ((module == AppModule.projectsList || module == AppModule.tasks || module == AppModule.timesheets) &&
        permissions.containsKey(AppModule.projects)) {
      return permissions[AppModule.projects]!.contains(action);
    }
    if (module == AppModule.projects) {
      if (hasPermission(AppModule.projectsList, action) ||
          hasPermission(AppModule.tasks, action) ||
          hasPermission(AppModule.timesheets, action)) {
        return true;
      }
    }

    return false;
  }

  UserRole copyWith({
    String? id,
    String? roleName,
    String? description,
    bool? isSystemRole,
    bool? isActive,
    bool? canChangeUsername,
    bool? canChangePassword,
    Map<AppModule, Set<PermissionAction>>? permissions,
  }) {
    return UserRole(
      id: id ?? this.id,
      roleName: roleName ?? this.roleName,
      description: description ?? this.description,
      isSystemRole: isSystemRole ?? this.isSystemRole,
      isActive: isActive ?? this.isActive,
      canChangeUsername: canChangeUsername ?? this.canChangeUsername,
      canChangePassword: canChangePassword ?? this.canChangePassword,
      permissions: permissions ?? this.permissions,
    );
  }

  Map<String, dynamic> toMap() {
    final permsMap = <String, List<String>>{};
    permissions.forEach((mod, acts) {
      permsMap[mod.name] = acts.map((a) => a.name).toList();
    });
    return {
      'id': id,
      'role_name': roleName,
      'description': description,
      'is_system_role': isSystemRole,
      'is_active': isActive ? 1 : 0,
      'can_change_username': canChangeUsername ? 1 : 0,
      'can_change_password': canChangePassword ? 1 : 0,
      'permissions': permsMap,
    };
  }

  Map<String, dynamic> toSupabaseMap({bool includeExtended = false}) {
    final permsMap = <String, List<String>>{};
    permissions.forEach((mod, acts) {
      permsMap[mod.name] = acts.map((a) => a.name).toList();
    });
    final map = <String, dynamic>{
      'id': id,
      'role_name': roleName,
      'description': description,
      'is_system_role': isSystemRole,
      'permissions': permsMap,
    };
    if (includeExtended) {
      map['is_active'] = isActive;
      map['can_change_username'] = canChangeUsername;
      map['can_change_password'] = canChangePassword;
    }
    return map;
  }

  factory UserRole.fromMap(Map<String, dynamic> map) {
    final rawPerms = map['permissions'];
    final parsedPerms = <AppModule, Set<PermissionAction>>{};
    if (rawPerms is Map) {
      rawPerms.forEach((k, v) {
        final mod = AppModuleExtension.fromString(k.toString());
        if (mod != null && v is List) {
          final acts = v
              .map((a) => PermissionActionExtension.fromString(a.toString()))
              .whereType<PermissionAction>()
              .toSet();
          parsedPerms[mod] = acts;
        }
      });
    }
    return UserRole(
      id: map['id']?.toString() ?? '',
      roleName: map['role_name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      isSystemRole: (map['is_system_role'] is bool)
          ? map['is_system_role'] as bool
          : ((map['is_system_role'] as num?)?.toInt() == 1),
      isActive: (map['is_active'] is bool)
          ? map['is_active'] as bool
          : ((map['is_active'] as num?)?.toInt() != 0),
      canChangeUsername: (map['can_change_username'] is bool)
          ? map['can_change_username'] as bool
          : ((map['can_change_username'] as num?)?.toInt() != 0),
      canChangePassword: (map['can_change_password'] is bool)
          ? map['can_change_password'] as bool
          : ((map['can_change_password'] as num?)?.toInt() != 0),
      permissions: parsedPerms,
    );
  }
}

/// Standard Seed Roles
class DefaultRoles {
  static const String superAdmin = 'Super Admin';
  static const String hrManager = 'HR Manager';
  static const String financeManager = 'Finance Manager';
  static const String projectManager = 'Project Manager';
  static const String operator = 'Operator';
  static const String employee = 'Employee';

  static List<UserRole> getDefaultRoles() {
    return [
      // 1. Super Admin: full unrestricted access
      UserRole(
        id: 'role_super_admin',
        roleName: superAdmin,
        description: 'Complete unrestricted access across all ERP systems, security, and data.',
        isSystemRole: true,
        isActive: true,
        canChangeUsername: true,
        canChangePassword: true,
        permissions: {
          for (final mod in AppModule.values)
            mod: PermissionAction.values.toSet(),
        },
      ),
    ];
  }
}
