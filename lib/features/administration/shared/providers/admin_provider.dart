import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/services/database_service.dart';
import 'package:software_house_erp/core/services/cloud_sync_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:software_house_erp/features/projects/tasks/presentation/providers/tasks_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:software_house_erp/features/clients/clients/presentation/providers/clients_provider.dart';
import 'package:software_house_erp/features/projects/projects/presentation/providers/projects_provider.dart';
import 'package:software_house_erp/features/hr/employees/presentation/providers/employees_provider.dart';
import 'package:software_house_erp/features/finance/accounts/presentation/providers/accounts_provider.dart';
import 'package:software_house_erp/features/projects/projects/presentation/screens/projects_screen.dart';
import 'package:software_house_erp/features/sales/sales/presentation/providers/products_provider.dart';
import 'package:software_house_erp/features/sales/sales/presentation/providers/sales_invoices_provider.dart';
import 'package:software_house_erp/features/inventory/inventory/presentation/providers/inventory_provider.dart';
import 'package:software_house_erp/features/finance/income/presentation/providers/income_provider.dart';
import 'package:software_house_erp/features/finance/expenses/presentation/providers/expenses_provider.dart';
import 'package:software_house_erp/features/finance/ledger/presentation/providers/ledger_provider.dart';
import 'package:software_house_erp/features/inventory/assets/presentation/providers/assets_provider.dart';
import 'package:software_house_erp/features/finance/loans/presentation/providers/loans_provider.dart';
import 'package:software_house_erp/features/hr/salaries/presentation/providers/salaries_provider.dart';
import 'package:software_house_erp/features/hr/advances/presentation/providers/advances_provider.dart';
import 'package:software_house_erp/features/sales/purchases/presentation/providers/purchase_orders_provider.dart';
import 'package:software_house_erp/features/hr/attendance/presentation/providers/attendance_provider.dart';
import 'package:software_house_erp/features/projects/timesheets/presentation/providers/timesheets_provider.dart';
import 'package:software_house_erp/core/auth/models/app_permissions.dart';
import 'package:software_house_erp/core/auth/data/auth_local_repository.dart';
import 'package:software_house_erp/core/utils/password_hasher.dart';

// ── Models ───────────────────────────────────────────
class AdminUser {
  final String id;
  final String name;
  final String username;
  final String email;
  final String role; // 'Super Admin', 'HR Manager', 'Project Manager', 'Finance Manager', etc.
  final String status; // 'Active', 'Inactive'
  final String lastActive;
  final bool isSuperAdmin;

  const AdminUser({
    required this.id,
    required this.name,
    this.username = '',
    required this.email,
    required this.role,
    required this.status,
    required this.lastActive,
    this.isSuperAdmin = false,
  });

  bool get isActive => status == 'Active';

  AdminUser copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    String? role,
    String? status,
    String? lastActive,
    bool? isSuperAdmin,
  }) {
    return AdminUser(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      lastActive: lastActive ?? this.lastActive,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
    );
  }
}

class AdminRole {
  final String roleName;
  final Map<String, bool> permissions;

  const AdminRole({
    required this.roleName,
    required this.permissions,
  });

  AdminRole copyWith({
    String? roleName,
    Map<String, bool>? permissions,
  }) {
    return AdminRole(
      roleName: roleName ?? this.roleName,
      permissions: permissions ?? this.permissions,
    );
  }
}

class AdminBackup {
  final String id;
  final String filename;
  final String size;
  final String date;
  final String status; // 'Completed', 'Failed'
  final String createdBy;

  const AdminBackup({
    required this.id,
    required this.filename,
    required this.size,
    required this.date,
    required this.status,
    required this.createdBy,
  });
}

class AuditLog {
  final String id;
  final String timestamp;
  final String user;
  final String action;
  final String module; // 'HR', 'Finance', 'Projects', 'Inventory', 'System'
  final String ipAddress;

  const AuditLog({
    required this.id,
    required this.timestamp,
    required this.user,
    required this.action,
    required this.module,
    required this.ipAddress,
  });
}

// ── State ────────────────────────────────────────────
class AdminState {
  final List<AdminUser> users;
  final List<AdminRole> roles;
  final List<UserRole> userRoles;
  final List<AdminBackup> backups;
  final List<AuditLog> logs;
  final AdminUser? currentUser;
  final bool isAuthenticated;
  final String? authErrorMessage;
  
  // Settings
  final int sessionTimeout; // minutes
  final bool maintenanceMode;
  final String autoBackupInterval; // 'Daily', 'Weekly', 'Monthly'
  final bool emailNotifications;
  final bool developerSandbox;
  final String auditRetention;
  final String mfaPolicy;
  final String dataSyncSchedule;

  final bool isLoading;
  final String searchQuery;
  final String moduleFilter;
  final String userFilter;
  final String roleFilter;
  final DateTime? startDate;
  final DateTime? endDate;
  final String actionTypeFilter;

  const AdminState({
    required this.users,
    required this.roles,
    this.userRoles = const [],
    required this.backups,
    required this.logs,
    this.currentUser,
    this.isAuthenticated = false,
    this.authErrorMessage,
    required this.sessionTimeout,
    required this.maintenanceMode,
    required this.autoBackupInterval,
    required this.emailNotifications,
    required this.developerSandbox,
    required this.auditRetention,
    required this.mfaPolicy,
    required this.dataSyncSchedule,
    required this.isLoading,
    required this.searchQuery,
    required this.moduleFilter,
    this.userFilter = 'All',
    this.roleFilter = 'All',
    this.startDate,
    this.endDate,
    this.actionTypeFilter = 'All',
  });

  bool hasPermission(AppModule module, [PermissionAction action = PermissionAction.view]) {
    if (currentUser == null) return false;
    if (currentUser!.isSuperAdmin ||
        currentUser!.role.trim().toLowerCase() == 'super admin' ||
        currentUser!.role.trim().toLowerCase() == 'system admin') {
      return true; // Super Admin always has full access
    }

    if (!currentUser!.isActive) return false;

    final currentRoleLower = currentUser!.role.trim().toLowerCase();
    final role = userRoles.firstWhere(
      (r) => r.roleName.trim().toLowerCase() == currentRoleLower,
      orElse: () => userRoles.firstWhere(
        (r) => r.roleName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '') ==
            currentRoleLower.replaceAll(RegExp(r'\s+'), ''),
        orElse: () => UserRole(
          id: '',
          roleName: currentUser!.role,
          description: '',
          isActive: true,
          permissions: {},
        ),
      ),
    );

    if (!role.isActive) return false;
    return role.hasPermission(module, action);
  }

  static const Object _sentinel = Object();

  AdminState copyWith({
    List<AdminUser>? users,
    List<AdminRole>? roles,
    List<UserRole>? userRoles,
    List<AdminBackup>? backups,
    List<AuditLog>? logs,
    AdminUser? currentUser,
    bool? isAuthenticated,
    Object? authErrorMessage = _sentinel,
    int? sessionTimeout,
    bool? maintenanceMode,
    String? autoBackupInterval,
    bool? emailNotifications,
    bool? developerSandbox,
    String? auditRetention,
    String? mfaPolicy,
    String? dataSyncSchedule,
    bool? isLoading,
    String? searchQuery,
    String? moduleFilter,
    String? userFilter,
    String? roleFilter,
    Object? startDate = _sentinel,
    Object? endDate = _sentinel,
    String? actionTypeFilter,
  }) {
    return AdminState(
      users: users ?? this.users,
      roles: roles ?? this.roles,
      userRoles: userRoles ?? this.userRoles,
      backups: backups ?? this.backups,
      logs: logs ?? this.logs,
      currentUser: currentUser ?? this.currentUser,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      authErrorMessage: identical(authErrorMessage, _sentinel)
          ? this.authErrorMessage
          : authErrorMessage as String?,
      sessionTimeout: sessionTimeout ?? this.sessionTimeout,
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      autoBackupInterval: autoBackupInterval ?? this.autoBackupInterval,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      developerSandbox: developerSandbox ?? this.developerSandbox,
      auditRetention: auditRetention ?? this.auditRetention,
      mfaPolicy: mfaPolicy ?? this.mfaPolicy,
      dataSyncSchedule: dataSyncSchedule ?? this.dataSyncSchedule,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      moduleFilter: moduleFilter ?? this.moduleFilter,
      userFilter: userFilter ?? this.userFilter,
      roleFilter: roleFilter ?? this.roleFilter,
      startDate: identical(startDate, _sentinel) ? this.startDate : startDate as DateTime?,
      endDate: identical(endDate, _sentinel) ? this.endDate : endDate as DateTime?,
      actionTypeFilter: actionTypeFilter ?? this.actionTypeFilter,
    );
  }

  List<AuditLog> get filteredLogs {
    final q = searchQuery.trim().toLowerCase();
    final hasSearch = q.isNotEmpty;
    final hasModule = moduleFilter != 'All';
    final modLower = moduleFilter.toLowerCase();
    final hasUser = userFilter != 'All';
    final userLower = userFilter.toLowerCase();
    final hasRole = roleFilter != 'All';
    final rfLower = roleFilter.toLowerCase();

    final matchingUsernames = hasRole
        ? users
            .where((u) => u.role.trim().toLowerCase() == rfLower)
            .expand((u) => [u.username.trim().toLowerCase(), u.name.trim().toLowerCase()])
            .where((s) => s.isNotEmpty)
            .toList()
        : const <String>[];

    final hasActionType = actionTypeFilter != 'All';

    final start = startDate != null
        ? DateTime(startDate!.year, startDate!.month, startDate!.day)
        : null;
    final end = endDate != null
        ? DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59)
        : null;
    final hasDate = start != null || end != null;

    return logs.where((log) {
      if (hasSearch) {
        final u = log.user.toLowerCase();
        final a = log.action.toLowerCase();
        final m = log.module.toLowerCase();
        final ip = log.ipAddress.toLowerCase();
        if (!u.contains(q) && !a.contains(q) && !m.contains(q) && !ip.contains(q)) {
          return false;
        }
      }

      if (hasModule) {
        final lm = log.module.toLowerCase();
        final matchesModule = lm == modLower ||
            (moduleFilter == 'HR' && (log.module == 'HR' || log.module == 'Payroll' || log.module == 'Attendance')) ||
            (moduleFilter == 'Administration' && (log.module == 'Administration' || log.module == 'System' || log.module == 'Security'));
        if (!matchesModule) return false;
      }

      if (hasUser) {
        if (!log.user.toLowerCase().contains(userLower)) return false;
      }

      if (hasRole) {
        final lu = log.user.toLowerCase();
        final la = log.action.toLowerCase();
        final roleMatch = lu.contains(rfLower) ||
            la.contains(rfLower) ||
            matchingUsernames.any((un) => lu.contains(un));
        if (!roleMatch) return false;
      }

      if (hasActionType) {
        final a = log.action.toLowerCase();
        bool actionMatch = false;
        switch (actionTypeFilter) {
          case 'Create':
            actionMatch = a.contains('created') || a.contains('added') || a.contains('check-in');
            break;
          case 'Update':
            actionMatch = a.contains('updated') || a.contains('edited') || a.contains('modified') || a.contains('disburs') || a.contains('repay');
            break;
          case 'Delete':
            actionMatch = a.contains('deleted') || a.contains('removed');
            break;
          case 'Auth':
            actionMatch = a.contains('logged in') || a.contains('signed out') || a.contains('login');
            break;
          default:
            actionMatch = true;
        }
        if (!actionMatch) return false;
      }

      if (hasDate) {
        final parsedDate = _parseLogDate(log.timestamp);
        if (parsedDate != null) {
          if (start != null && parsedDate.isBefore(start)) return false;
          if (end != null && parsedDate.isAfter(end)) return false;
        }
      }

      return true;
    }).toList();
  }

  static DateTime? _parseLogDate(String timestamp) {
    try {
      if (timestamp.isEmpty) return null;
      final firstPart = timestamp.trim().split(' ').first;
      if (firstPart.contains('-')) {
        final parts = firstPart.split('-');
        if (parts.length >= 3) {
          final year = int.tryParse(parts[0]);
          final month = int.tryParse(parts[1]);
          final day = int.tryParse(parts[2]);
          if (year != null && month != null && day != null) {
            return DateTime(year, month, day);
          }
        }
      }
      return DateTime.tryParse(timestamp);
    } catch (_) {
      return null;
    }
  }
}

// ── Notifier ─────────────────────────────────────────
class AdminNotifier extends Notifier<AdminState> {
  @override
  AdminState build() {
    Future.microtask(() async {
      await _initializeAuthAndLoadData();
      await _loadBackups();
    });
    return const AdminState(
      users: [],
      roles: [],
      userRoles: [],
      backups: [],
      logs: [],
      sessionTimeout: 30,
      maintenanceMode: false,
      autoBackupInterval: 'Weekly',
      emailNotifications: true,
      developerSandbox: false,
      auditRetention: '90 Days',
      mfaPolicy: 'Disabled',
      dataSyncSchedule: 'Real-time stream',
      isLoading: false,
      searchQuery: '',
      moduleFilter: 'All',
      currentUser: null,
      isAuthenticated: false,
      authErrorMessage: null,
    );
  }

  Future<void> _initializeAuthAndLoadData() async {
    try {
      final authRepo = ref.read(authLocalRepositoryProvider);
      await authRepo.initializeSchemaAndSeedDefaults();

      final dbUsers = await authRepo.getAllUsers();
      final mappedUsers = dbUsers.map((u) => AdminUser(
        id: u.id,
        name: u.fullName,
        username: u.username,
        email: u.email,
        role: u.role,
        status: u.isActive ? 'Active' : 'Inactive',
        lastActive: u.lastActive,
        isSuperAdmin: u.isSuperAdmin,
      )).toList();

      final dbRoles = await authRepo.getAllRoles();
      final legacyRoles = dbRoles.map((r) => AdminRole(
        roleName: r.roleName,
        permissions: {
          for (final mod in AppModule.values)
            'Manage ${mod.displayName}': r.hasPermission(mod, PermissionAction.manage),
        },
      )).toList();

      // On app launch or refresh, always start on the login page (unauthenticated).
      // If already authenticated during the current running session, preserve active user.
      AdminUser? activeUser;
      bool authenticated = false;

      if (state.isAuthenticated && state.currentUser != null) {
        final found = mappedUsers.where((u) => u.id == state.currentUser!.id).firstOrNull;
        if (found != null && found.isActive) {
          activeUser = found;
          authenticated = true;
        }
      } else {
        // Clear any old saved session tokens so refresh/restart always lands on login page
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('saved_session_user_id');
      }

      List<AuditLog> persistedLogs = state.logs;
      try {
        final dbLogs = await authRepo.getAllAuditLogs();
        if (dbLogs.isNotEmpty) {
          persistedLogs = dbLogs.map((l) => AuditLog(
            id: l['id']?.toString() ?? '',
            timestamp: l['timestamp']?.toString() ?? '',
            user: l['user']?.toString() ?? '',
            action: l['action']?.toString() ?? '',
            module: l['module']?.toString() ?? '',
            ipAddress: l['ip_address']?.toString() ?? '192.168.1.1',
          )).toList();
        }
      } catch (_) {}

      state = state.copyWith(
        users: mappedUsers,
        roles: legacyRoles,
        userRoles: dbRoles,
        logs: persistedLogs,
        currentUser: activeUser,
        isAuthenticated: authenticated,
      );
    } catch (e) {
      debugPrint('AdminProvider _initializeAuthAndLoadData error: $e');
    }
  }

  Future<void> reloadData() async {
    await _initializeAuthAndLoadData();
  }

  Future<void> _loadBackups() async {
    try {
      final backupDir = await getBackupsDirectory();
      final files = await backupDir.list().where((entity) => entity is File).cast<File>().toList();
      final backups = <AdminBackup>[];

      for (final file in files) {
        final filename = p.basename(file.path);
        if (!filename.endsWith('.json')) continue;
        final dbFile = File(p.join(backupDir.path, filename.replaceAll('.json', '.db')));
        final sizeBytes = await file.length() + (await dbFile.exists() ? await dbFile.length() : 0);
        final modified = await file.lastModified();
        backups.add(AdminBackup(
          id: 'BCK-${filename.hashCode}',
          filename: filename,
          size: '${(sizeBytes / (1024 * 1024)).toStringAsFixed(3)} MB',
          date: modified.toLocal().toString().substring(0, 16),
          status: 'Completed',
          createdBy: 'System Admin',
        ));
      }

      backups.sort((a, b) => a.date.compareTo(b.date));
      state = state.copyWith(backups: backups);
    } catch (e) {
      _logAction('admin@hhtech.com', 'Could not load backup history: $e', 'System');
    }
  }

  // ── Operations ─────────────────────────────────────
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setModuleFilter(String filter) {
    state = state.copyWith(moduleFilter: filter);
  }

  void setUserFilter(String user) {
    state = state.copyWith(userFilter: user);
  }

  void setRoleFilter(String role) {
    state = state.copyWith(roleFilter: role);
  }

  void setDateFilter({DateTime? start, DateTime? end}) {
    state = state.copyWith(startDate: start, endDate: end);
  }

  void setActionTypeFilter(String actionType) {
    state = state.copyWith(actionTypeFilter: actionType);
  }

  void clearAuditFilters() {
    state = state.copyWith(
      searchQuery: '',
      moduleFilter: 'All',
      userFilter: 'All',
      roleFilter: 'All',
      startDate: null,
      endDate: null,
      actionTypeFilter: 'All',
    );
  }

  Future<void> fetchSystemUsers() async {
    if (Supabase.instance.client.auth.currentSession == null) return;
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select();
      
      final list = (response as List).map((p) => AdminUser(
        id: p['id'] ?? '',
        name: p['full_name'] ?? '',
        email: p['email'] ?? '',
        role: p['role'] ?? 'Project Manager',
        status: p['status'] ?? 'Active',
        lastActive: p['updated_at']?.toString().substring(0, 10) ?? 'Just Active',
      )).toList();
      
      state = state.copyWith(users: list);
    } catch (e) {
      _logAction('System', 'Failed to fetch users: $e', 'System');
    }
  }

  Future<void> fetchRolePermissions() async {
    if (Supabase.instance.client.auth.currentSession == null) return;
    try {
      final response = await Supabase.instance.client
          .from('role_permissions')
          .select();
      
      final List<dynamic> rows = response as List<dynamic>;
      final Map<String, Map<String, bool>> roleMap = {};
      for (final row in rows) {
        final roleName = row['role_name'] as String;
        final permissionKey = row['permission_key'] as String;
        final isEnabled = row['is_enabled'] as bool;
        roleMap.putIfAbsent(roleName, () => {})[permissionKey] = isEnabled;
      }

      final updatedRoles = state.roles.map((role) {
        final dbPermissions = roleMap[role.roleName];
        if (dbPermissions != null) {
          final mergedPermissions = Map<String, bool>.from(role.permissions);
          mergedPermissions.addAll(dbPermissions);
          return role.copyWith(permissions: mergedPermissions);
        }
        return role;
      }).toList();

      state = state.copyWith(roles: updatedRoles);
    } catch (e) {
      _logAction('System', 'Failed to fetch role permissions: $e', 'System');
    }
  }

  Future<void> addUser(AdminUser user, {required String password}) async {
    state = state.copyWith(isLoading: true);
    try {
      final authRepo = ref.read(authLocalRepositoryProvider);
      final uname = user.username.trim().isNotEmpty
          ? user.username.trim()
          : user.email.split('@').first.trim();

      await authRepo.createUser(
        fullName: user.name,
        username: uname,
        email: user.email,
        password: password,
        role: user.role,
        isActive: user.status == 'Active',
      );

      await _initializeAuthAndLoadData();
      state = state.copyWith(isLoading: false);
      _logAction(state.currentUser?.username ?? 'Admin', 'Created user: "${user.name}" ($uname) with role "${user.role}"', 'Security');
    } catch (e) {
      state = state.copyWith(isLoading: false);
      _logAction(state.currentUser?.username ?? 'Admin', 'Failed to create user: $e', 'Security');
      rethrow;
    }
  }

  Future<void> updateUser(AdminUser user) async {
    state = state.copyWith(isLoading: true);
    try {
      final authRepo = ref.read(authLocalRepositoryProvider);
      final record = AdminUserRecord(
        id: user.id,
        fullName: user.name,
        username: user.username,
        email: user.email,
        passwordHash: '',
        salt: '',
        role: user.role,
        isActive: user.status == 'Active',
        isSuperAdmin: user.isSuperAdmin,
        lastActive: user.lastActive,
        createdAt: '',
      );

      await authRepo.updateUser(record);
      try {
        ref.read(cloudSyncServiceProvider).syncToCloud();
      } catch (_) {}
      await _initializeAuthAndLoadData();
      state = state.copyWith(isLoading: false);
      _logAction(state.currentUser?.username ?? 'Admin', 'Updated user: "${user.name}" (Status: ${user.status}, Role: ${user.role})', 'Security');
    } catch (e) {
      state = state.copyWith(isLoading: false);
      _logAction(state.currentUser?.username ?? 'Admin', 'Failed to update user: $e', 'Security');
      rethrow;
    }
  }

  Future<void> deleteUser(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      final target = state.users.where((u) => u.id == id).firstOrNull;
      if (target != null && (target.isSuperAdmin || target.role.trim().toLowerCase() == 'super admin')) {
        final superAdmins = state.users.where((u) => u.isSuperAdmin || u.role.trim().toLowerCase() == 'super admin').toList();
        if (superAdmins.length <= 1) {
          throw Exception('Security Warning: Cannot delete the last remaining Super Admin account.');
        }
      }

      final authRepo = ref.read(authLocalRepositoryProvider);
      await authRepo.deleteUser(id);
      try {
        ref.read(cloudSyncServiceProvider).syncToCloud();
      } catch (_) {}
      await _initializeAuthAndLoadData();
      state = state.copyWith(isLoading: false);
      _logAction(state.currentUser?.username ?? 'Super Admin', 'USER_DELETED: Deleted user account "${target?.username ?? id}"', 'Administration');
    } catch (e) {
      state = state.copyWith(isLoading: false);
      _logAction(state.currentUser?.username ?? 'Super Admin', 'Failed to delete user: $e', 'Administration');
      rethrow;
    }
  }

  /// Toggles active/inactive status of a user with last Super Admin protection and session invalidation
  Future<void> toggleUserStatus(String id) async {
    final target = state.users.where((u) => u.id == id).firstOrNull;
    if (target == null) return;

    final isSuper = target.isSuperAdmin || target.role.trim().toLowerCase() == 'super admin';
    if (isSuper && target.status == 'Active') {
      final activeSuperAdmins = state.users.where((u) => (u.isSuperAdmin || u.role.trim().toLowerCase() == 'super admin') && u.status == 'Active').toList();
      if (activeSuperAdmins.length <= 1) {
        throw Exception('Security Warning: Cannot disable the last active Super Admin account.');
      }
    }

    final newStatus = target.status == 'Active' ? 'Inactive' : 'Active';
    await updateUser(target.copyWith(status: newStatus));

    _logAction(
      state.currentUser?.username ?? 'Super Admin',
      newStatus == 'Inactive'
          ? 'USER_DISABLED: Disabled user "${target.username}"'
          : 'USER_ENABLED: Enabled user "${target.username}"',
      'Administration',
    );

    // If currently logged-in user was deactivated, log them out immediately
    if (state.currentUser?.id == id && newStatus == 'Inactive') {
      await logout();
    }
  }

  /// Reassigns a user to a new role
  Future<void> assignRoleToUser(String userId, String newRole) async {
    final target = state.users.where((u) => u.id == userId).firstOrNull;
    if (target == null) return;

    await updateUser(target.copyWith(role: newRole.trim()));
    _logAction(
      state.currentUser?.username ?? 'Super Admin',
      'ROLE_ASSIGNED: Changed role of "${target.username}" to "$newRole"',
      'Administration',
    );
  }

  Future<void> resetUserPassword(String userId, String newPassword) async {
    state = state.copyWith(isLoading: true);
    try {
      final authRepo = ref.read(authLocalRepositoryProvider);
      await authRepo.resetPassword(userId, newPassword);

      if (state.currentUser?.id == userId) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('admin_password', newPassword);
      }
      try {
        ref.read(cloudSyncServiceProvider).syncToCloud();
      } catch (_) {}

      state = state.copyWith(isLoading: false);
      _logAction(state.currentUser?.username ?? 'Admin', 'Reset password for user ID: $userId', 'Security');
    } catch (e) {
      state = state.copyWith(isLoading: false);
      _logAction(state.currentUser?.username ?? 'Admin', 'Failed to reset password: $e', 'Security');
      rethrow;
    }
  }

  Future<void> createCustomRole({
    required String roleName,
    required String description,
    required Map<AppModule, Set<PermissionAction>> permissions,
    bool isActive = true,
    bool canChangeUsername = false,
    bool canChangePassword = false,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final authRepo = ref.read(authLocalRepositoryProvider);
      await authRepo.createCustomRole(
        roleName: roleName,
        description: description,
        permissions: permissions,
        isActive: isActive,
        canChangeUsername: canChangeUsername,
        canChangePassword: canChangePassword,
      );
      await _initializeAuthAndLoadData();
      state = state.copyWith(isLoading: false);
      _logAction(
        state.currentUser?.username ?? 'Super Admin',
        'ROLE_CREATED: Created role "$roleName"',
        'Administration',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      _logAction(state.currentUser?.username ?? 'Super Admin', 'Failed to create role: $e', 'Administration');
      rethrow;
    }
  }

  Future<void> updateRolePermissionsMatrix({
    required String roleName,
    String? newRoleName,
    required String description,
    required bool isActive,
    bool canChangeUsername = false,
    bool canChangePassword = false,
    required Map<AppModule, Set<PermissionAction>> permissions,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final authRepo = ref.read(authLocalRepositoryProvider);
      final cleanOld = roleName.trim();
      final cleanNew = (newRoleName != null && newRoleName.trim().isNotEmpty) ? newRoleName.trim() : cleanOld;

      await authRepo.updateRole(
        oldRoleName: cleanOld,
        newRoleName: cleanNew,
        description: description,
        isActive: isActive,
        canChangeUsername: canChangeUsername,
        canChangePassword: canChangePassword,
        permissions: permissions,
      );
      await _initializeAuthAndLoadData();
      state = state.copyWith(isLoading: false);
      _logAction(
        state.currentUser?.username ?? 'Super Admin',
        'ROLE_UPDATED: Updated permissions and settings for role "$cleanNew"',
        'Administration',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      _logAction(state.currentUser?.username ?? 'Super Admin', 'Failed to update role $roleName: $e', 'Administration');
      rethrow;
    }
  }

  Future<void> toggleRoleStatus(String roleName, bool isActive) async {
    state = state.copyWith(isLoading: true);
    try {
      if (roleName.trim().toLowerCase() == 'super admin') {
        throw Exception('Security Warning: Cannot deactivate the Super Admin role.');
      }
      final authRepo = ref.read(authLocalRepositoryProvider);
      await authRepo.toggleRoleStatus(roleName, isActive);
      await _initializeAuthAndLoadData();
      state = state.copyWith(isLoading: false);
      _logAction(
        state.currentUser?.username ?? 'Super Admin',
        isActive ? 'ROLE_ACTIVATED: Activated role "$roleName"' : 'ROLE_DEACTIVATED: Deactivated role "$roleName"',
        'Administration',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      _logAction(state.currentUser?.username ?? 'Super Admin', 'Failed to toggle role status: $e', 'Administration');
      rethrow;
    }
  }

  /// Creates a custom role along with its dedicated user credentials in a single atomic step
  Future<void> createRoleWithUser({
    required String roleName,
    required String username,
    required String password,
    String? description,
    required Map<AppModule, Set<PermissionAction>> permissions,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final authRepo = ref.read(authLocalRepositoryProvider);
      final cleanRoleName = roleName.trim();
      final cleanUsername = username.trim().toLowerCase();

      // 1. Create the custom role with permissions
      await authRepo.createCustomRole(
        roleName: cleanRoleName,
        description: description?.isNotEmpty == true ? description!.trim() : 'Custom ERP operational role',
        permissions: permissions,
      );

      // 2. Create the associated user account
      await authRepo.createUser(
        fullName: cleanRoleName,
        username: cleanUsername,
        email: '$cleanUsername@hhtech.com',
        password: password.trim(),
        role: cleanRoleName,
        isActive: true,
      );

      try {
        ref.read(cloudSyncServiceProvider).syncToCloud();
      } catch (_) {}

      await _initializeAuthAndLoadData();
      state = state.copyWith(isLoading: false);
      _logAction(state.currentUser?.username ?? 'Super Admin', 'ROLE_CREATED: Created role "$cleanRoleName" with user login "$cleanUsername"', 'Administration');
    } catch (e) {
      state = state.copyWith(isLoading: false);
      _logAction(state.currentUser?.username ?? 'Super Admin', 'Failed to create role with user: $e', 'Administration');
      rethrow;
    }
  }

  /// Updates an existing role (such as HR Manager or custom role) and its assigned user credentials
  Future<void> updateRoleWithUser({
    required String oldRoleName,
    required String newRoleName,
    required String username,
    String? newPassword,
    String? description,
    required Map<AppModule, Set<PermissionAction>> permissions,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final authRepo = ref.read(authLocalRepositoryProvider);
      final cleanOld = oldRoleName.trim();
      final cleanNew = newRoleName.trim();
      final cleanUsername = username.trim().toLowerCase();

      // 1. Update the role details and permissions in DB
      await authRepo.updateRole(
        oldRoleName: cleanOld,
        newRoleName: cleanNew,
        description: description?.isNotEmpty == true ? description!.trim() : 'Custom ERP operational role',
        permissions: permissions,
      );

      // 2. Update or provision the associated user credentials
      final existingUser = await authRepo.findUserByRole(cleanOld) ?? 
                           await authRepo.findUserByRole(cleanNew) ??
                           await authRepo.findUserByIdentifier(cleanUsername);

      if (existingUser != null) {
        final updatedRecord = existingUser.copyWith(
          fullName: cleanNew,
          username: cleanUsername,
          role: cleanNew,
        );
        await authRepo.updateUser(updatedRecord);

        // Update password if a new one was provided
        if (newPassword != null && newPassword.trim().isNotEmpty) {
          await authRepo.resetPassword(existingUser.id, newPassword.trim());
        }
      } else {
        // No user existed yet for this role, create one
        await authRepo.createUser(
          fullName: cleanNew,
          username: cleanUsername,
          email: '$cleanUsername@hhtech.com',
          password: (newPassword != null && newPassword.trim().isNotEmpty) ? newPassword.trim() : '123456',
          role: cleanNew,
          isActive: true,
        );
      }

      try {
        ref.read(cloudSyncServiceProvider).syncToCloud();
      } catch (_) {}

      await _initializeAuthAndLoadData();
      state = state.copyWith(isLoading: false);
      _logAction(state.currentUser?.username ?? 'Super Admin', 'ROLE_UPDATED: Updated role "$cleanNew" and user credentials for "$cleanUsername"', 'Administration');
    } catch (e) {
      state = state.copyWith(isLoading: false);
      _logAction(state.currentUser?.username ?? 'Super Admin', 'Failed to update role: $e', 'Administration');
      rethrow;
    }
  }

  Future<void> deleteRole(String roleName, {String? reassignToRole}) async {
    state = state.copyWith(isLoading: true);
    try {
      if (roleName.trim().toLowerCase() == 'super admin') {
        throw Exception('Security Warning: Cannot delete the Super Admin role.');
      }
      final authRepo = ref.read(authLocalRepositoryProvider);
      await authRepo.deleteRole(roleName, reassignToRole: reassignToRole);
      await _initializeAuthAndLoadData();
      state = state.copyWith(isLoading: false);
      _logAction(
        state.currentUser?.username ?? 'Super Admin',
        'ROLE_DELETED: Deleted role "$roleName"' + (reassignToRole != null ? ' (Users reassigned to "$reassignToRole")' : ''),
        'Administration',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      _logAction(state.currentUser?.username ?? 'Super Admin', 'Failed to delete role: $e', 'Administration');
      rethrow;
    }
  }

  Future<void> toggleGranularPermission({
    required String roleName,
    required AppModule module,
    required PermissionAction action,
    required bool isGranted,
  }) async {
    try {
      final authRepo = ref.read(authLocalRepositoryProvider);
      await authRepo.updateRolePermissions(
        roleName: roleName,
        module: module,
        action: action,
        isGranted: isGranted,
      );
      await _initializeAuthAndLoadData();
      _logAction(
        state.currentUser?.username ?? 'Admin',
        'Changed permission for "$roleName": ${module.displayName} [${action.displayName}] -> $isGranted',
        'Security',
      );
    } catch (e) {
      _logAction(state.currentUser?.username ?? 'Admin', 'Failed to update permission: $e', 'Security');
      rethrow;
    }
  }

  Future<void> toggleModulePermissions({
    required String roleName,
    required AppModule module,
    required bool isGranted,
  }) async {
    try {
      final authRepo = ref.read(authLocalRepositoryProvider);
      await authRepo.updateModulePermissions(
        roleName: roleName,
        module: module,
        isGranted: isGranted,
      );
      await _initializeAuthAndLoadData();
      _logAction(
        state.currentUser?.username ?? 'Admin',
        'Changed all permissions for "$roleName" on module ${module.displayName} -> $isGranted',
        'Security',
      );
    } catch (e) {
      _logAction(state.currentUser?.username ?? 'Admin', 'Failed to update module permissions: $e', 'Security');
      rethrow;
    }
  }

  Future<void> togglePermission(String roleName, String permissionKey) async {
    // Legacy support
    final targetRole = state.roles.firstWhere((role) => role.roleName == roleName, orElse: () => state.roles.first);
    final currentValue = targetRole.permissions[permissionKey] ?? false;
    final newValue = !currentValue;

    final rolesList = state.roles.map((role) {
      if (role.roleName == roleName) {
        final updatedPermissions = Map<String, bool>.from(role.permissions);
        updatedPermissions[permissionKey] = newValue;
        return role.copyWith(permissions: updatedPermissions);
      }
      return role;
    }).toList();

    state = state.copyWith(roles: rolesList);
    _logAction(state.currentUser?.username ?? 'Admin', 'Modified legacy permission for $roleName ($permissionKey -> $newValue)', 'Security');
  }

  void updateSettings({
    int? sessionTimeout,
    bool? maintenanceMode,
    String? autoBackupInterval,
    bool? emailNotifications,
    bool? developerSandbox,
    String? auditRetention,
    String? mfaPolicy,
    String? dataSyncSchedule,
  }) {
    state = state.copyWith(
      sessionTimeout: sessionTimeout ?? state.sessionTimeout,
      maintenanceMode: maintenanceMode ?? state.maintenanceMode,
      autoBackupInterval: autoBackupInterval ?? state.autoBackupInterval,
      emailNotifications: emailNotifications ?? state.emailNotifications,
      developerSandbox: developerSandbox ?? state.developerSandbox,
      auditRetention: auditRetention ?? state.auditRetention,
      mfaPolicy: mfaPolicy ?? state.mfaPolicy,
      dataSyncSchedule: dataSyncSchedule ?? state.dataSyncSchedule,
    );
    _logAction('admin@hhtech.com', 'Updated system configurations', 'System');
  }

  Future<void> triggerBackup() async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(appDatabaseProvider).customStatement('PRAGMA wal_checkpoint(FULL);');
      final dbFile = await getDatabaseFile();
      final backupDir = await getBackupsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      
      final dbFilename = 'hhtech_erp_backup_$timestamp.db';
      final dbBackupPath = p.join(backupDir.path, dbFilename);
      final dbBackupFile = File(dbBackupPath);
      
      if (await dbFile.exists()) {
        await dbFile.copy(dbBackupFile.path);
      } else {
        throw Exception('Local database file was not found.');
      }

      // Backup SharedPreferences data
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> prefsData = {};
      for (String key in prefs.getKeys()) {
        prefsData[key] = prefs.get(key);
      }
      
      final jsonFilename = 'hhtech_erp_backup_$timestamp.json';
      final jsonBackupPath = p.join(backupDir.path, jsonFilename);
      final jsonBackupFile = File(jsonBackupPath);
      await jsonBackupFile.writeAsString(jsonEncode(prefsData));
      
      final sizeBytes = await jsonBackupFile.length() + (await dbBackupFile.exists() ? await dbBackupFile.length() : 0);
      final sizeMB = (sizeBytes / (1024 * 1024)).toStringAsFixed(3);
      
      final newBackup = AdminBackup(
        id: 'BCK-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        filename: jsonFilename,
        size: '$sizeMB MB',
        date: DateTime.now().toIso8601String().substring(0, 16).replaceAll('T', ' '),
        status: 'Completed',
        createdBy: 'System Admin',
      );

      final list = List<AdminBackup>.from(state.backups)..add(newBackup);
      state = state.copyWith(backups: list, isLoading: false);
      _logAction('admin@hhtech.com', 'Manual database backup created: $jsonFilename', 'System');
    } catch (e) {
      state = state.copyWith(isLoading: false);
      _logAction('admin@hhtech.com', 'Backup failed: $e', 'System');
      rethrow;
    }
  }

  Future<void> triggerCloudBackup() async {
    if (Supabase.instance.client.auth.currentSession == null) {
      throw Exception('Supabase connection is not active.');
    }
    state = state.copyWith(isLoading: true);
    try {
      final client = Supabase.instance.client;
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      final filename = 'hhtech_cloud_backup_$timestamp.json';
      
      final tables = [
        'profiles',
        'role_permissions',
        'bank_accounts',
        'employees',
        'clients',
        'projects',
        'project_tasks',
        'timesheets',
        'income_records',
        'expense_records',
        'ledger_entries',
        'attendance_records',
        'salaries',
        'salary_records',
        'loan_records',
        'advance_records',
        'assets',
        'inventory_items',
        'purchase_orders',
        'products',
        'sales_invoices',
        'audit_logs'
      ];
      
      final Map<String, dynamic> backupData = {
        'backupVersion': '1.0',
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'tables': {}
      };
      
      for (final table in tables) {
        try {
          final res = await client.from(table).select();
          backupData['tables'][table] = res;
        } catch (e) {
          backupData['tables'][table] = [];
        }
      }
      
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      final backupDir = await getBackupsDirectory();
      final backupFilePath = p.join(backupDir.path, filename);
      final backupFile = File(backupFilePath);
      
      await backupFile.writeAsString(jsonString);
      
      final sizeBytes = await backupFile.length();
      final sizeKB = (sizeBytes / 1024).toStringAsFixed(1);
      final sizeMB = (sizeBytes / (1024 * 1024)).toStringAsFixed(3);
      final displaySize = sizeBytes > 1024 * 1024 ? '$sizeMB MB' : '$sizeKB KB';
      
      final newBackup = AdminBackup(
        id: 'BCK-CLOUD-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        filename: filename,
        size: displaySize,
        date: DateTime.now().toIso8601String().substring(0, 16).replaceAll('T', ' '),
        status: 'Completed',
        createdBy: 'Cloud Sync System',
      );

      final list = List<AdminBackup>.from(state.backups)..add(newBackup);
      state = state.copyWith(backups: list, isLoading: false);
      _logAction('admin@hhtech.com', 'Cloud database backup created: $filename', 'System');
    } catch (e) {
      state = state.copyWith(isLoading: false);
      _logAction('admin@hhtech.com', 'Cloud backup failed: $e', 'System');
      rethrow;
    }
  }

  Future<void> triggerRestore(String filename) async {
    state = state.copyWith(isLoading: true);
    try {
      final backupDir = await getBackupsDirectory();
      final backupFilePath = p.join(backupDir.path, filename);
      final backupFile = File(backupFilePath);

      if (await backupFile.exists()) {
        final ext = p.extension(filename).toLowerCase();

        if (ext == '.db') {
          final db = ref.read(appDatabaseProvider);
          await db.close();

          final dbFile = await getDatabaseFile();
          if (await dbFile.exists()) {
            await dbFile.delete();
          }
          await backupFile.copy(dbFile.path);
            _resetDatabaseProviders();
        } else if (ext == '.json') {
          try {
            final jsonData = await backupFile.readAsString();
            final Map<String, dynamic> map = jsonDecode(jsonData);
            final prefs = await SharedPreferences.getInstance();
            for (var entry in map.entries) {
              final value = entry.value;
              if (value is String) {
                await prefs.setString(entry.key, value);
              } else if (value is int) {
                await prefs.setInt(entry.key, value);
              } else if (value is double) {
                await prefs.setDouble(entry.key, value);
              } else if (value is bool) {
                await prefs.setBool(entry.key, value);
              } else if (value is List) {
                await prefs.setStringList(entry.key, List<String>.from(value));
              }
            }
          } catch (_) {}

          final dbFilename = filename.replaceAll('.json', '.db');
          final dbBackupFile = File(p.join(backupDir.path, dbFilename));
          if (await dbBackupFile.exists()) {
            final db = ref.read(appDatabaseProvider);
            await db.close();

            final dbFile = await getDatabaseFile();
            if (await dbFile.exists()) {
              await dbFile.delete();
            }
            await dbBackupFile.copy(dbFile.path);
            _resetDatabaseProviders();
          }
        }

        _invalidateAllDataProviders();

        state = state.copyWith(isLoading: false);
        _logAction('admin@hhtech.com', 'System database restored from: $filename', 'System');
      } else {
        throw Exception('Backup file does not exist.');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      _logAction('admin@hhtech.com', 'Restore failed: $e', 'System');
      rethrow;
    }
  }

  Future<void> openBackupsFolder() async {
    try {
      final backupDir = await getBackupsDirectory();
      if (Platform.isWindows) {
        await Process.run('explorer.exe', [backupDir.path]);
      } else {
        final entities = await backupDir.list().toList();
        final backupFiles = entities.whereType<File>().where((f) => f.path.endsWith('.json') || f.path.endsWith('.db')).toList();
        if (backupFiles.isNotEmpty) {
          backupFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
          await Share.shareXFiles([XFile(backupFiles.first.path)], text: 'ERP Backup');
        } else {
          _logAction('admin@hhtech.com', 'Backups directory location: ${backupDir.path}', 'System');
        }
      }
    } catch (e) {
      _logAction('admin@hhtech.com', 'Failed to open backups folder: $e', 'System');
    }
  }

  Future<void> exportBackupFile(String filename) async {
    state = state.copyWith(isLoading: true);
    try {
      final backupDir = await getBackupsDirectory();
      final sourcePath = p.join(backupDir.path, filename);
      final sourceFile = File(sourcePath);

      if (!await sourceFile.exists()) {
        throw Exception('Backup file does not exist.');
      }

      if (Platform.isWindows) {
        final ext = p.extension(filename);
        final filterStr = ext.toLowerCase() == '.db'
            ? "SQLite Database (*.db)|*.db"
            : "JSON Backup (*.json)|*.json";

        final result = await Process.run('powershell', [
          '-NoProfile',
          '-Command',
          '''
          Add-Type -AssemblyName System.Windows.Forms;
          \$FileSaver = New-Object System.Windows.Forms.SaveFileDialog;
          \$FileSaver.Filter = "$filterStr";
          \$FileSaver.Title = "Save Backup File As";
          \$FileSaver.FileName = "$filename";
          \$Show = \$FileSaver.ShowDialog();
          If (\$Show -eq "OK") {
              Write-Host \$FileSaver.FileName
          }
          '''
        ]);

        final savePath = result.stdout.toString().trim();
        if (savePath.isNotEmpty) {
          await sourceFile.copy(savePath);
          _logAction('admin@hhtech.com', 'Backup exported to: $savePath', 'System');
        }
      } else {
        // Mobile / Android fallback: copy to available downloads/documents directory
        final downloadsDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
        final targetPath = p.join(downloadsDir.path, filename);
        await sourceFile.copy(targetPath);
        _logAction('admin@hhtech.com', 'Backup exported to: $targetPath', 'System');
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      _logAction('admin@hhtech.com', 'Export backup failed: $e', 'System');
      rethrow;
    }
  }

  Future<void> deleteBackupFile(String id, String filename) async {
    state = state.copyWith(isLoading: true);
    try {
      final backupDir = await getBackupsDirectory();
      final filePath = p.join(backupDir.path, filename);
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
      final dbPairPath = filePath.replaceAll('.json', '.db');
      final dbPairFile = File(dbPairPath);
      if (await dbPairFile.exists()) {
        await dbPairFile.delete();
      }

      final list = state.backups.where((b) => b.id != id && b.filename != filename).toList();
      state = state.copyWith(backups: list, isLoading: false);
      _logAction('admin@hhtech.com', 'Deleted backup file: $filename', 'System');
    } catch (e) {
      state = state.copyWith(isLoading: false);
      _logAction('admin@hhtech.com', 'Delete backup failed: $e', 'System');
      rethrow;
    }
  }

  Future<void> importBackup() async {
    state = state.copyWith(isLoading: true);
    try {
      String filePath = '';
      
      final PlatformFile? result = await FilePicker.pickFile(
        type: FileType.any, 
      );

      if (result != null && result.path != null) {
        filePath = result.path!;
      }

      if (filePath.isEmpty) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final selectedFile = File(filePath);
      if (await selectedFile.exists()) {
        final ext = p.extension(filePath).toLowerCase();

        if (ext == '.db') {
          final db = ref.read(appDatabaseProvider);
          await db.close();

          final dbFile = await getDatabaseFile();
          if (await dbFile.exists()) {
            await dbFile.delete();
          }
          await selectedFile.copy(dbFile.path);
          _resetDatabaseProviders();

          // Force push the new DB to cloud
          await ref.read(cloudSyncServiceProvider).wipeCloud();
          await ref.read(cloudSyncServiceProvider).syncAll(forcePush: true);
        } else if (ext == '.json') {
          try {
            final jsonData = await selectedFile.readAsString();
            final Map<String, dynamic> map = jsonDecode(jsonData);
            final prefs = await SharedPreferences.getInstance();
            for (var entry in map.entries) {
              final value = entry.value;
              if (value is String) {
                await prefs.setString(entry.key, value);
              } else if (value is int) {
                await prefs.setInt(entry.key, value);
              } else if (value is double) {
                await prefs.setDouble(entry.key, value);
              } else if (value is bool) {
                await prefs.setBool(entry.key, value);
              } else if (value is List) {
                await prefs.setStringList(entry.key, List<String>.from(value));
              }
            }
          } catch (_) {}

          final dbFilename = p.basename(filePath).replaceAll('.json', '.db');
          final dbBackupFile = File(p.join(p.dirname(filePath), dbFilename));
          if (await dbBackupFile.exists()) {
            final db = ref.read(appDatabaseProvider);
            await db.close();

            final dbFile = await getDatabaseFile();
            if (await dbFile.exists()) {
              await dbFile.delete();
            }
            await dbBackupFile.copy(dbFile.path);
            _resetDatabaseProviders();

            // Force push the new DB to cloud
            await ref.read(cloudSyncServiceProvider).wipeCloud();
            await ref.read(cloudSyncServiceProvider).syncAll(forcePush: true);
          }
        }

        _invalidateAllDataProviders();

        final filename = p.basename(filePath);
        final sizeBytes = await selectedFile.length();
        final sizeMB = (sizeBytes / (1024 * 1024)).toStringAsFixed(3);
        final newBackup = AdminBackup(
          id: 'BCK-IMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
          filename: filename,
          size: '$sizeMB MB',
          date: DateTime.now().toIso8601String().substring(0, 16).replaceAll('T', ' '),
          status: 'Imported',
          createdBy: 'User Import',
        );

        final list = List<AdminBackup>.from(state.backups)..add(newBackup);
        state = state.copyWith(backups: list, isLoading: false);
        _logAction('admin@hhtech.com', 'Database imported from: $filename', 'System');
      } else {
        throw Exception('Selected file does not exist.');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      _logAction('admin@hhtech.com', 'Import failed: $e', 'System');
      rethrow;
    }
  }

  void _invalidateAllDataProviders() {
    ref.invalidate(tasksProvider);
    ref.invalidate(tasksRepositoryProvider);
    ref.invalidate(clientsProvider);
    ref.invalidate(clientsRepositoryProvider);
    ref.invalidate(projectsProvider);
    ref.invalidate(projectsRepositoryProvider);
    ref.invalidate(employeesProvider);
    ref.invalidate(employeesRepositoryProvider);
    ref.invalidate(accountsProvider);
    ref.invalidate(accountsRepositoryProvider);
    ref.invalidate(clientAccountsProvider);
    ref.invalidate(productsProvider);
    ref.invalidate(productsRepositoryProvider);
    ref.invalidate(salesInvoicesProvider);
    ref.invalidate(salesInvoicesRepositoryProvider);
    ref.invalidate(inventoryProvider);
    ref.invalidate(inventoryRepositoryProvider);
    ref.invalidate(incomeProvider);
    ref.invalidate(incomeRepositoryProvider);
    ref.invalidate(expensesProvider);
    ref.invalidate(expenseRepositoryProvider);
    ref.invalidate(ledgerProvider);
    ref.invalidate(ledgerRepositoryProvider);
    ref.invalidate(assetsProvider);
    ref.invalidate(assetsRepositoryProvider);
    ref.invalidate(loansProvider);
    ref.invalidate(loansRepositoryProvider);
    ref.invalidate(salariesProvider);
    ref.invalidate(salariesRepositoryProvider);
    ref.invalidate(advancesProvider);
    ref.invalidate(advancesRepositoryProvider);
    ref.invalidate(purchaseOrdersProvider);
    ref.invalidate(purchaseOrdersRepositoryProvider);
    ref.invalidate(attendanceProvider);
    ref.invalidate(attendanceRepositoryProvider);
    ref.invalidate(timesheetsProvider);
    ref.invalidate(timesheetsRepositoryProvider);
  }

  void _resetDatabaseProviders() {
    ref.invalidate(cloudSyncServiceProvider);
    ref.invalidate(databaseServiceProvider);
    ref.invalidate(appDatabaseProvider);
  }

  void logAction({
    required String action,
    required String module,
    String? user,
  }) {
    final now = DateTime.now();
    final timeStr = now.toIso8601String().substring(0, 16).replaceAll('T', ' ') + 
        (now.hour >= 12 ? ' PM' : ' AM');
    final logId = 'LOG-${now.millisecondsSinceEpoch}';

    final currentUser = state.currentUser;
    final actor = user ?? (currentUser != null
        ? '${currentUser.name} (${currentUser.role})'
        : 'System');

    final newLog = AuditLog(
      id: logId,
      timestamp: timeStr,
      user: actor,
      action: action,
      module: module,
      ipAddress: '192.168.1.1',
    );
    final list = List<AuditLog>.from(state.logs)..insert(0, newLog);
    state = state.copyWith(logs: list);

    // Persist to local SQLite audit_logs table
    try {
      final authRepo = ref.read(authLocalRepositoryProvider);
      authRepo.saveAuditLog(
        id: logId,
        timestamp: timeStr,
        user: actor,
        action: action,
        module: module,
        ipAddress: '192.168.1.1',
      );
    } catch (_) {}
  }

  void _logAction(String user, String action, String module) {
    logAction(user: user, action: action, module: module);
  }

  Future<String> getAdminUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('admin_username') ?? 'admin';
  }

  Future<bool> verifyCurrentPassword(String currentPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final storedPassword = prefs.getString('admin_password') ?? '123456';
    if (currentPassword == storedPassword || currentPassword == '123456' || currentPassword == 'admin') {
      return true;
    }
    // Also verify against the current logged in user in authRepo
    try {
      final authRepo = ref.read(authLocalRepositoryProvider);
      final currentUserName = state.currentUser?.username ?? 'admin';
      final user = await authRepo.findUserByIdentifier(currentUserName);
      if (user != null) {
        return PasswordHasher.verifyPassword(
          password: currentPassword,
          salt: user.salt,
          expectedHash: user.passwordHash,
        );
      }
    } catch (_) {}
    return false;
  }

  bool canCurrentUserChangeUsername() {
    final user = state.currentUser;
    if (user == null) return false;
    final isSuper = user.isSuperAdmin ||
        user.role.trim().toLowerCase() == 'super admin' ||
        user.role.trim().toLowerCase() == 'system admin';
    return isSuper;
  }

  bool canCurrentUserChangePassword() {
    final user = state.currentUser;
    if (user == null) return false;
    final isSuper = user.isSuperAdmin ||
        user.role.trim().toLowerCase() == 'super admin' ||
        user.role.trim().toLowerCase() == 'system admin';
    return isSuper;
  }

  Future<bool> changeCredentials({
    required String currentPassword,
    required String newUsername,
    String? newPassword,
  }) async {
    final user = state.currentUser;
    final isSuper = user != null &&
        (user.isSuperAdmin ||
            user.role.trim().toLowerCase() == 'super admin' ||
            user.role.trim().toLowerCase() == 'system admin');
    if (!isSuper) {
      _logAction(
        user?.name ?? 'User',
        'Credential change blocked: Role-based users cannot change credentials. Only Super Admin has authority.',
        'Security',
      );
      return false;
    }

    final isValid = await verifyCurrentPassword(currentPassword);
    if (!isValid) {
      _logAction(state.currentUser?.name ?? 'admin', 'Failed credential change: incorrect current password', 'System');
      return false;
    }

    final trimmedUser = newUsername.trim();
    final currentUserName = state.currentUser?.username ?? 'admin';
    final isChangingUsername = trimmedUser.isNotEmpty && trimmedUser.toLowerCase() != currentUserName.toLowerCase();
    if (isChangingUsername && !canCurrentUserChangeUsername()) {
      _logAction(state.currentUser?.name ?? 'admin', 'Failed credential change: role is not permitted to change username', 'Security');
      return false;
    }

    final isChangingPassword = newPassword != null && newPassword.trim().isNotEmpty;
    if (isChangingPassword && !canCurrentUserChangePassword()) {
      _logAction(state.currentUser?.name ?? 'admin', 'Failed credential change: role is not permitted to change password', 'Security');
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    if (trimmedUser.isNotEmpty && canCurrentUserChangeUsername()) {
      await prefs.setString('admin_username', trimmedUser);
    }
    if (isChangingPassword && canCurrentUserChangePassword()) {
      await prefs.setString('admin_password', newPassword);
    }

    // Update SQLite app_users table & Supabase sync
    try {
      final authRepo = ref.read(authLocalRepositoryProvider);
      final currentId = state.currentUser?.id;
      final currentUserName = state.currentUser?.username ?? 'admin';
      final allUsers = await authRepo.getAllUsers();
      AdminUserRecord? userRec;
      if (currentId != null) {
        for (final u in allUsers) {
          if (u.id == currentId) {
            userRec = u;
            break;
          }
        }
      }
      if (userRec == null) {
        for (final u in allUsers) {
          if (u.isSuperAdmin || u.username == 'admin' || u.username == currentUserName) {
            userRec = u;
            break;
          }
        }
      }

      if (userRec != null) {
        String newHash = userRec.passwordHash;
        String newSalt = userRec.salt;
        if (newPassword != null && newPassword.isNotEmpty) {
          newSalt = PasswordHasher.generateSalt();
          newHash = PasswordHasher.hashPassword(newPassword, newSalt);
        }
        final updatedRec = userRec.copyWith(
          username: trimmedUser.isNotEmpty ? trimmedUser : userRec.username,
          passwordHash: newHash,
          salt: newSalt,
        );
        await authRepo.updateUser(updatedRec);

        // Sync to cloud
        try {
          ref.read(cloudSyncServiceProvider).syncToCloud();
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Error updating user record in authRepo: $e');
    }

    if (state.currentUser != null) {
      state = state.copyWith(
        currentUser: state.currentUser!.copyWith(
          name: trimmedUser.isNotEmpty ? trimmedUser : state.currentUser!.name,
          username: trimmedUser.isNotEmpty ? trimmedUser : state.currentUser!.username,
          email: trimmedUser.isNotEmpty && trimmedUser.contains('@') ? trimmedUser : state.currentUser!.email,
        ),
      );
    }

    _logAction(trimmedUser.isNotEmpty ? trimmedUser : 'admin', 'Admin credentials updated successfully', 'System');
    await _initializeAuthAndLoadData();
    return true;
  }

  Future<bool> login(
    String usernameOrEmail,
    String password, {
    bool rememberMe = false,
    String? selectedRole,
  }) async {
    state = state.copyWith(isLoading: true, authErrorMessage: null);
    try {
      final authRepo = ref.read(authLocalRepositoryProvider);
      await authRepo.initializeSchemaAndSeedDefaults();

      final user = await authRepo.findUserByIdentifier(usernameOrEmail);
      if (user == null) {
        // Backward-compatibility fallback check
        final prefs = await SharedPreferences.getInstance();
        final storedUsername = prefs.getString('admin_username') ?? 'admin';
        final storedPassword = prefs.getString('admin_password') ?? '123456';
        final cleanIdentifier = usernameOrEmail.trim().toLowerCase();
        final isKnownAdmin = cleanIdentifier == storedUsername.trim().toLowerCase() ||
            cleanIdentifier == 'admin' ||
            cleanIdentifier == 'admin@hhtech.com';

        final isPasswordMatch = password == storedPassword ||
            password == '123456' ||
            password == 'admin';

        if (isKnownAdmin && isPasswordMatch) {
          if (selectedRole != null && selectedRole.isNotEmpty) {
            final normSelected = selectedRole.trim().toLowerCase();
            final isSelectedAdmin = normSelected == 'super admin' || normSelected == 'admin' || normSelected == 'administrator';
            if (!isSelectedAdmin) {
              state = state.copyWith(
                isLoading: false,
                authErrorMessage: 'Role Mismatch: Account "admin" has role "Super Admin". To log in with admin credentials, please select "Super Admin" in the role dropdown.',
              );
              _logAction(usernameOrEmail, 'Login rejected: Super Admin credentials used under non-admin role "$selectedRole"', 'Security');
              return false;
            }
          }

          final now = DateTime.now().toLocal().toString().substring(0, 16);
          await authRepo.createUser(
            fullName: 'Super Admin',
            username: 'admin',
            email: 'admin@hhtech.com',
            password: password,
            role: 'Super Admin',
            isActive: true,
          );
          final adminRec = await authRepo.findUserByIdentifier('admin');
          if (adminRec != null) {
            final adminUser = AdminUser(
              id: adminRec.id,
              name: adminRec.fullName,
              username: adminRec.username,
              email: adminRec.email,
              role: adminRec.role,
              status: 'Active',
              lastActive: now,
              isSuperAdmin: true,
            );
            await prefs.remove('saved_session_user_id');
            state = state.copyWith(
              currentUser: adminUser,
              isAuthenticated: true,
              isLoading: false,
              authErrorMessage: null,
            );
            _logAction(adminUser.username, 'User logged in successfully (Super Admin recovered)', 'Security');
            await _initializeAuthAndLoadData();
            return true;
          }
        }

        state = state.copyWith(isLoading: false, authErrorMessage: 'Invalid username/email or password.');
        _logAction(usernameOrEmail, 'Login failed: Account not found', 'Security');
        return false;
      }

      if (!user.isActive) {
        state = state.copyWith(
          isLoading: false,
          authErrorMessage: 'Your account is BLOCKED or inactive. Please contact the Super Administrator.',
        );
        _logAction(user.username, 'Login rejected: Blocked/Disabled account attempted access', 'Security');
        throw Exception('Your account is BLOCKED or inactive. Please contact the Super Administrator.');
      }

      final roleRec = await authRepo.findRoleByName(user.role);
      if (roleRec != null && !roleRec.isActive && !user.isSuperAdmin && user.role.trim().toLowerCase() != 'super admin') {
        state = state.copyWith(
          isLoading: false,
          authErrorMessage: 'Your assigned role "${user.role}" is currently DEACTIVATED. Please contact the Super Administrator.',
        );
        _logAction(user.username, 'Login rejected: Deactivated role "${user.role}" attempted access', 'Security');
        throw Exception('Your assigned role "${user.role}" is currently DEACTIVATED. Please contact the Super Administrator.');
      }

      // Check role mismatch if selectedRole was provided
      if (selectedRole != null && selectedRole.isNotEmpty) {
        final normSelected = selectedRole.trim().toLowerCase();
        final userRole = user.role.trim().toLowerCase();
        final isSelectedAdmin = normSelected == 'super admin' || normSelected == 'admin' || normSelected == 'administrator';
        final isUserAdmin = user.isSuperAdmin ||
            userRole == 'super admin' ||
            userRole == 'admin' ||
            userRole == 'administrator' ||
            user.username.trim().toLowerCase() == 'admin';

        if (isSelectedAdmin && !isUserAdmin) {
          // Dropdown selected Super Admin, but account is a non-admin role
          state = state.copyWith(
            isLoading: false,
            authErrorMessage: 'Access Denied: Account "${user.username}" is not authorized as $selectedRole. Please select "${user.role}" in the role dropdown.',
          );
          _logAction(user.username, 'Login rejected: Role mismatch ($selectedRole required, user is ${user.role})', 'Security');
          return false;
        } else if (!isSelectedAdmin && isUserAdmin) {
          // Dropdown selected a non-admin role (e.g. HR Manager), but account is Super Admin!
          state = state.copyWith(
            isLoading: false,
            authErrorMessage: 'Role Mismatch: Account "${user.username}" has role "Super Admin". To log in with admin credentials, please select "Super Admin" in the role dropdown.',
          );
          _logAction(user.username, 'Login rejected: Super Admin credentials used under role "$selectedRole"', 'Security');
          return false;
        } else if (!isSelectedAdmin && !isUserAdmin) {
          // Both are non-admin: verify role match
          final isBothHr = normSelected.contains('hr') && userRole.contains('hr');
          final isBothFinance = normSelected.contains('finance') && userRole.contains('finance');
          final isBothProject = (normSelected.contains('project') || normSelected.contains('pm')) &&
                                (userRole.contains('project') || userRole.contains('pm'));
          final isBothInventory = normSelected.contains('inventory') && userRole.contains('inventory');

          final isRoleMatch = normSelected == userRole ||
              normSelected.replaceAll(RegExp(r'\s+'), '') == userRole.replaceAll(RegExp(r'\s+'), '') ||
              isBothHr ||
              isBothFinance ||
              isBothProject ||
              isBothInventory;

          if (!isRoleMatch) {
            state = state.copyWith(
              isLoading: false,
              authErrorMessage: 'Role Mismatch: Account "${user.username}" has role "${user.role}", not "$selectedRole". Please select "${user.role}" in the role dropdown.',
            );
            _logAction(user.username, 'Login rejected: Role mismatch ($selectedRole vs ${user.role})', 'Security');
            return false;
          }
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final storedAdminPassword = prefs.getString('admin_password') ?? '123456';

      // 1. Regular cryptographic salted hash verification
      bool isMatch = PasswordHasher.verifyPassword(
        password: password,
        salt: user.salt,
        expectedHash: user.passwordHash,
      );

      // 2. Super Admin backward-compatibility / fallback check:
      if (!isMatch && (user.isSuperAdmin || user.username.toLowerCase() == 'admin')) {
        if (password == '123456' || password == 'admin' || password == storedAdminPassword) {
          isMatch = true;
          // Immediately upgrade to salted hash with this password
          final newSalt = PasswordHasher.generateSalt();
          final newHash = PasswordHasher.hashPassword(password, newSalt);
          await authRepo.updateUser(user.copyWith(passwordHash: newHash, salt: newSalt));
          await prefs.setString('admin_password', password);
        }
      }

      if (!isMatch) {
        state = state.copyWith(isLoading: false, authErrorMessage: 'Invalid username/email or password.');
        _logAction(user.username, 'Login failed: Invalid credentials', 'Security');
        return false;
      }

      // Update last active in database
      final now = DateTime.now().toLocal().toString().substring(0, 16);
      await authRepo.updateUser(user.copyWith(lastActive: now));

      final adminUser = AdminUser(
        id: user.id,
        name: user.fullName,
        username: user.username,
        email: user.email,
        role: user.role,
        status: user.isActive ? 'Active' : 'Inactive',
        lastActive: now,
        isSuperAdmin: user.isSuperAdmin,
      );

      await prefs.remove('saved_session_user_id');

      _logAction(user.username, 'User logged in successfully (${user.role})', 'Security');

      state = state.copyWith(
        currentUser: adminUser,
        isAuthenticated: true,
        isLoading: false,
        authErrorMessage: null,
      );

      await _initializeAuthAndLoadData();
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, authErrorMessage: msg);
      rethrow;
    }
  }

  Future<void> logout() async {
    final user = state.currentUser;
    if (user != null) {
      _logAction(user.username.isNotEmpty ? user.username : user.name, 'User signed out', 'Security');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_session_user_id');
    state = state.copyWith(
      currentUser: null,
      isAuthenticated: false,
      authErrorMessage: null,
    );
  }

  Future<void> seedInitialDemoData() async {
    state = state.copyWith(isLoading: true);
    try {
      final db = ref.read(appDatabaseProvider);

      // Seed Bank Accounts
      final acc1 = BankAccountsTableCompanion.insert(
        id: 'acc_demo_meezan',
        name: 'Meezan Bank - Main Operations',
        type: 'Business',
        accountNumber: '02010108923412',
        bankName: 'Meezan Bank',
        balance: 450000.0,
        status: 'Active',
      );
      final acc2 = BankAccountsTableCompanion.insert(
        id: 'acc_demo_cash',
        name: 'Office Petty Cash',
        type: 'Cash',
        accountNumber: 'CASH-OFFICE-01',
        bankName: 'Petty Cash',
        balance: 75000.0,
        status: 'Active',
      );
      await db.into(db.bankAccountsTable).insertOnConflictUpdate(acc1);
      await db.into(db.bankAccountsTable).insertOnConflictUpdate(acc2);

      // Seed Clients
      final cl1 = ClientsTableCompanion.insert(
        id: 'client_demo_1',
        name: 'Apex Digital Solutions',
        contactPerson: 'David Miller',
        email: 'david@apexdigital.com',
        phone: '+1 415 555 2671',
        status: 'Active',
        industry: 'Software & Cloud',
        totalProjects: 1,
        advancedPayment: 200000.0,
        fullPayment: 650000.0,
      );
      final cl2 = ClientsTableCompanion.insert(
        id: 'client_demo_2',
        name: 'BlueWave Enterprises',
        contactPerson: 'Sarah Jenkins',
        email: 'sarah@bluewave.io',
        phone: '+44 20 7946 0991',
        status: 'Active',
        industry: 'FinTech',
        totalProjects: 1,
        advancedPayment: 150000.0,
        fullPayment: 400000.0,
      );
      await db.into(db.clientsTable).insertOnConflictUpdate(cl1);
      await db.into(db.clientsTable).insertOnConflictUpdate(cl2);

      // Seed Employees
      final emp1 = EmployeesTableCompanion.insert(
        id: 'emp_demo_1',
        name: 'Muhammad Haseeb',
        email: 'haseeb@hhtech.com',
        phones: const ['Personal: +92 300 1234567'],
        designation: 'Tech Lead / Mobile Architect',
        department: 'Mobile Apps',
        joiningDate: '2024-01-15',
        status: 'Active',
        salaryType: 'Monthly',
        baseSalary: 120000.0,
        paymentMethod: 'Bank Transfer',
      );
      final emp2 = EmployeesTableCompanion.insert(
        id: 'emp_demo_2',
        name: 'Ahmed Khan',
        email: 'ahmed.khan@hhtech.com',
        phones: const ['Personal: +92 301 9876543'],
        designation: 'Senior Flutter Developer',
        department: 'Mobile Apps',
        joiningDate: '2024-03-01',
        status: 'Active',
        salaryType: 'Monthly',
        baseSalary: 85000.0,
        paymentMethod: 'Bank Transfer',
      );
      final emp3 = EmployeesTableCompanion.insert(
        id: 'emp_demo_3',
        name: 'Fatima Noor',
        email: 'fatima@hhtech.com',
        phones: const ['Personal: +92 321 4567890'],
        designation: 'UI/UX Lead Designer',
        department: 'Design',
        joiningDate: '2024-02-10',
        status: 'Active',
        salaryType: 'Monthly',
        baseSalary: 75000.0,
        paymentMethod: 'Bank Transfer',
      );
      final emp4 = EmployeesTableCompanion.insert(
        id: 'emp_demo_4',
        name: 'Zain Ali',
        email: 'zain.ali@hhtech.com',
        phones: const ['Personal: +92 333 1122334'],
        designation: 'QA Automation Engineer',
        department: 'Quality Assurance',
        joiningDate: '2024-04-01',
        status: 'Active',
        salaryType: 'Monthly',
        baseSalary: 60000.0,
        paymentMethod: 'Cash',
      );
      await db.into(db.employeesTable).insertOnConflictUpdate(emp1);
      await db.into(db.employeesTable).insertOnConflictUpdate(emp2);
      await db.into(db.employeesTable).insertOnConflictUpdate(emp3);
      await db.into(db.employeesTable).insertOnConflictUpdate(emp4);

      // Seed Projects
      final prj1 = ProjectsTableCompanion.insert(
        id: 'prj_demo_1',
        name: 'HH Tech Hub ERP Mobile & Desktop',
        description: 'Cross-platform enterprise ERP system with realtime sync.',
        clientId: 'client_demo_1',
        clientName: 'Apex Digital Solutions',
        startDate: '2025-01-01',
        endDate: '2025-12-31',
        status: 'In Progress',
        budget: 650000.0,
        advancedPayment: 200000.0,
        partialPayments: 150000.0,
        finalPayment: 300000.0,
        paymentStatus: 'Partial',
        bankAccountId: 'acc_demo_meezan',
        bankAccountName: 'Meezan Bank - Main Operations',
        accountHolder: 'HH Tech',
        teamMembers: const ['Muhammad Haseeb', 'Ahmed Khan', 'Fatima Noor'],
        clientPaymentSource: 'Wire Transfer',
      );
      await db.into(db.projectsTable).insertOnConflictUpdate(prj1);

      // Seed Products
      final p1 = ProductsTableCompanion.insert(
        id: 'prod_demo_1',
        name: 'Enterprise ERP License (Annual)',
        description: 'Complete suite ERP for SME software houses.',
        category: 'Software License',
        price: 150000.0,
        status: 'Active',
      );
      await db.into(db.productsTable).insertOnConflictUpdate(p1);

      _invalidateAllDataProviders();
      state = state.copyWith(isLoading: false);
      _logAction('admin@hhtech.com', 'Demo/Sample data loaded for testing.', 'System');
    } catch (e) {
      state = state.copyWith(isLoading: false);
      _logAction('admin@hhtech.com', 'Loading demo data failed: $e', 'System');
      rethrow;
    }
  }

  Future<void> clearAllDatabaseData() async {
    state = state.copyWith(isLoading: true);
    try {
      // 1. First wipe the cloud data (all collections including income_records)
      await ref.read(cloudSyncServiceProvider).wipeCloud();
      
      // 2. Clear all local SQLite tables cleanly via transaction (no file locking or closed DB issues)
      final db = ref.read(appDatabaseProvider);
      await db.transaction(() async {
        await db.customStatement('PRAGMA foreign_keys = OFF;');
        for (final table in db.allTables) {
          await db.delete(table).go();
        }
        await db.customStatement('PRAGMA foreign_keys = ON;');
      });

      // 3. Clear stored preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await prefs.setBool('is_seeded_data_cleared', true);

      // 4. Invalidate all data providers to immediately refresh UI with empty data
      _invalidateAllDataProviders();

      state = state.copyWith(isLoading: false);
      _logAction('admin@hhtech.com', 'Database tables and cloud storage cleared completely.', 'System');
    } catch (e) {
      state = state.copyWith(isLoading: false);
      _logAction('admin@hhtech.com', 'Database clearing failed: $e', 'System');
      rethrow;
    }
  }
}

final adminProvider = NotifierProvider<AdminNotifier, AdminState>(() {
  return AdminNotifier();
});
