import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/services/database_service.dart';
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

// ── Models ───────────────────────────────────────────
class AdminUser {
  final String id;
  final String name;
  final String email;
  final String role; // 'System Admin', 'HR Manager', 'Project Manager', 'Finance Manager'
  final String status; // 'Active', 'Inactive'
  final String lastActive;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.lastActive,
  });

  AdminUser copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? status,
    String? lastActive,
  }) {
    return AdminUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      lastActive: lastActive ?? this.lastActive,
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
  final List<AdminBackup> backups;
  final List<AuditLog> logs;
  final AdminUser? currentUser;
  final bool isAuthenticated;
  
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

  const AdminState({
    required this.users,
    required this.roles,
    required this.backups,
    required this.logs,
    this.currentUser,
    this.isAuthenticated = false,
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
  });

  AdminState copyWith({
    List<AdminUser>? users,
    List<AdminRole>? roles,
    List<AdminBackup>? backups,
    List<AuditLog>? logs,
    AdminUser? currentUser,
    bool? isAuthenticated,
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
  }) {
    return AdminState(
      users: users ?? this.users,
      roles: roles ?? this.roles,
      backups: backups ?? this.backups,
      logs: logs ?? this.logs,
      currentUser: currentUser ?? this.currentUser,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
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
    );
  }

  List<AuditLog> get filteredLogs {
    return logs.where((log) {
      final matchesSearch = log.user.toLowerCase().contains(searchQuery.toLowerCase()) ||
          log.action.toLowerCase().contains(searchQuery.toLowerCase()) ||
          log.ipAddress.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesModule = moduleFilter == 'All' || log.module == moduleFilter;

      return matchesSearch && matchesModule;
    }).toList();
  }
}

// ── Notifier ─────────────────────────────────────────
class AdminNotifier extends Notifier<AdminState> {
  @override
  AdminState build() {
    return AdminState(
      users: const [
        AdminUser(
          id: 'USR-001',
          name: 'System Admin',
          email: 'admin@hhtech.com',
          role: 'System Admin',
          status: 'Active',
          lastActive: '2026-06-03 10:05 PM',
        ),
        AdminUser(
          id: 'USR-002',
          name: 'Sarah Malik (HR)',
          email: 'sarah.hr@hhtech.com',
          role: 'HR Manager',
          status: 'Active',
          lastActive: '2026-06-03 04:30 PM',
        ),
        AdminUser(
          id: 'USR-003',
          name: 'Ali Khan (Finance)',
          email: 'ali.fin@hhtech.com',
          role: 'Finance Manager',
          status: 'Active',
          lastActive: '2026-06-03 09:12 PM',
        ),
        AdminUser(
          id: 'USR-004',
          name: 'Farhan Saeed (PM)',
          email: 'farhan.pm@hhtech.com',
          role: 'Project Manager',
          status: 'Inactive',
          lastActive: '2026-06-01 11:00 AM',
        ),
      ],
      roles: const [
        AdminRole(
          roleName: 'System Admin',
          permissions: {
            'Manage HR': true,
            'Manage Projects': true,
            'Manage Finance': true,
            'Run Backups': true,
            'Configure System': true,
          },
        ),
        AdminRole(
          roleName: 'HR Manager',
          permissions: {
            'Manage HR': true,
            'Manage Projects': false,
            'Manage Finance': false,
            'Run Backups': false,
            'Configure System': false,
          },
        ),
        AdminRole(
          roleName: 'Finance Manager',
          permissions: {
            'Manage HR': false,
            'Manage Projects': false,
            'Manage Finance': true,
            'Run Backups': false,
            'Configure System': false,
          },
        ),
        AdminRole(
          roleName: 'Project Manager',
          permissions: {
            'Manage HR': false,
            'Manage Projects': true,
            'Manage Finance': false,
            'Run Backups': false,
            'Configure System': false,
          },
        ),
      ],
      backups: const [
        AdminBackup(
          id: 'BCK-001',
          filename: 'hhtech_erp_backup_20260530.db',
          size: '14.2 MB',
          date: '2026-05-30 02:00 AM',
          status: 'Completed',
          createdBy: 'Auto Backup System',
        ),
        AdminBackup(
          id: 'BCK-002',
          filename: 'hhtech_erp_backup_20260601.db',
          size: '14.5 MB',
          date: '2026-06-01 02:00 AM',
          status: 'Completed',
          createdBy: 'Auto Backup System',
        ),
        AdminBackup(
          id: 'BCK-003',
          filename: 'hhtech_erp_backup_manual_20260602.db',
          size: '14.6 MB',
          date: '2026-06-02 11:30 PM',
          status: 'Completed',
          createdBy: 'System Admin',
        ),
      ],
      logs: const [],
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
    );
  }

  // ── Operations ─────────────────────────────────────
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setModuleFilter(String filter) {
    state = state.copyWith(moduleFilter: filter);
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

  Future<void> addUser(AdminUser user, {String? password}) async {
    if (Supabase.instance.client.auth.currentSession != null && password != null) {
      state = state.copyWith(isLoading: true);
      try {
        await Supabase.instance.client.rpc('admin_create_user', params: {
          'user_email': user.email,
          'user_password': password,
          'user_name': user.name,
          'user_role': user.role,
        });
        await fetchSystemUsers();
        state = state.copyWith(isLoading: false);
        _logAction('admin@hhtech.com', 'Created new system user: ${user.email}', 'System');
      } catch (e) {
        state = state.copyWith(isLoading: false);
        _logAction('admin@hhtech.com', 'Failed to create user: $e', 'System');
        rethrow;
      }
    } else {
      final list = List<AdminUser>.from(state.users)..add(user);
      state = state.copyWith(users: list);
      _logAction('admin@hhtech.com', 'Created new system user (Offline): ${user.email}', 'System');
    }
  }

  Future<void> updateUser(AdminUser user) async {
    if (Supabase.instance.client.auth.currentSession != null) {
      state = state.copyWith(isLoading: true);
      try {
        await Supabase.instance.client.rpc('admin_update_user', params: {
          'target_user_id': user.id,
          'new_email': user.email,
          'new_name': user.name,
          'new_role': user.role,
          'new_status': user.status,
        });
        await fetchSystemUsers();
        state = state.copyWith(isLoading: false);
        _logAction('admin@hhtech.com', 'Updated user details/status: ${user.email}', 'System');
      } catch (e) {
        state = state.copyWith(isLoading: false);
        _logAction('admin@hhtech.com', 'Failed to update user: $e', 'System');
        rethrow;
      }
    } else {
      final list = List<AdminUser>.from(state.users);
      final idx = list.indexWhere((u) => u.id == user.id);
      if (idx != -1) {
        list[idx] = user;
        state = state.copyWith(users: list);
        _logAction('admin@hhtech.com', 'Updated user details/status (Offline): ${user.email}', 'System');
      }
    }
  }

  Future<void> deleteUser(String id) async {
    if (Supabase.instance.client.auth.currentSession != null) {
      state = state.copyWith(isLoading: true);
      try {
        await Supabase.instance.client.rpc('admin_delete_user', params: {
          'target_user_id': id,
        });
        await fetchSystemUsers();
        state = state.copyWith(isLoading: false);
        _logAction('admin@hhtech.com', 'Deleted system user: $id', 'System');
      } catch (e) {
        state = state.copyWith(isLoading: false);
        _logAction('admin@hhtech.com', 'Failed to delete user: $e', 'System');
        rethrow;
      }
    } else {
      final list = List<AdminUser>.from(state.users);
      final idx = list.indexWhere((u) => u.id == id);
      if (idx != -1) {
        final user = list[idx];
        list.removeAt(idx);
        state = state.copyWith(users: list);
        _logAction('admin@hhtech.com', 'Deleted system user (Offline): ${user.email}', 'System');
      }
    }
  }

  Future<void> togglePermission(String roleName, String permissionKey) async {
    final targetRole = state.roles.firstWhere((role) => role.roleName == roleName);
    final currentValue = targetRole.permissions[permissionKey] ?? false;
    final newValue = !currentValue;

    if (Supabase.instance.client.auth.currentSession != null) {
      try {
        await Supabase.instance.client
            .from('role_permissions')
            .upsert({
              'role_name': roleName,
              'permission_key': permissionKey,
              'is_enabled': newValue,
            });
        
        final rolesList = state.roles.map((role) {
          if (role.roleName == roleName) {
            final updatedPermissions = Map<String, bool>.from(role.permissions);
            updatedPermissions[permissionKey] = newValue;
            return role.copyWith(permissions: updatedPermissions);
          }
          return role;
        }).toList();

        state = state.copyWith(roles: rolesList);
        _logAction('admin@hhtech.com', 'Modified permissions for role: $roleName ($permissionKey -> $newValue)', 'System');
      } catch (e) {
        _logAction('admin@hhtech.com', 'Failed to update permissions in DB for $roleName: $e', 'System');
        rethrow;
      }
    } else {
      final rolesList = state.roles.map((role) {
        if (role.roleName == roleName) {
          final updatedPermissions = Map<String, bool>.from(role.permissions);
          updatedPermissions[permissionKey] = newValue;
          return role.copyWith(permissions: updatedPermissions);
        }
        return role;
      }).toList();

      state = state.copyWith(roles: rolesList);
      _logAction('admin@hhtech.com', 'Modified permissions offline for role: $roleName ($permissionKey -> $newValue)', 'System');
    }
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
      final dbFile = await getDatabaseFile();
      final backupDir = await getBackupsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      
      final dbFilename = 'hhtech_erp_backup_$timestamp.db';
      final dbBackupPath = p.join(backupDir.path, dbFilename);
      final dbBackupFile = File(dbBackupPath);
      
      if (await dbFile.exists()) {
        await dbFile.copy(dbBackupFile.path);
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
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-Command',
        '''
        Add-Type -AssemblyName System.Windows.Forms;
        \$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog;
        \$FileBrowser.Filter = "Backup Files (*.json;*.db)|*.json;*.db|All Files (*.*)|*.*";
        \$FileBrowser.Title = "Select ERP Backup File";
        \$Show = \$FileBrowser.ShowDialog();
        If (\$Show -eq "OK") {
            Write-Host \$FileBrowser.FileName
        }
        '''
      ]);

      final filePath = result.stdout.toString().trim();
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
    ref.invalidate(appDatabaseProvider);
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

  void _logAction(String user, String action, String module) {
    final newLog = AuditLog(
      id: 'LOG-${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now().toIso8601String().substring(0, 16).replaceAll('T', ' ') + 
          (DateTime.now().hour >= 12 ? ' PM' : ' AM'),
      user: user,
      action: action,
      module: module,
      ipAddress: '192.168.1.1',
    );
    final list = List<AuditLog>.from(state.logs)..insert(0, newLog);
    state = state.copyWith(logs: list);
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      final user = response.user;
      if (user != null) {
        String role = 'Project Manager';
        String name = user.userMetadata?['name']?.toString() ?? user.email!.split('@')[0];
        String status = 'Active';

        try {
          // Query the profiles table to get official role and status
          final profileData = await Supabase.instance.client
              .from('profiles')
              .select()
              .eq('id', user.id)
              .single();
          
          role = profileData['role']?.toString() ?? 'Project Manager';
          name = profileData['full_name']?.toString() ?? name;
          status = profileData['status']?.toString() ?? 'Active';
        } catch (e) {
          // Fallback if profiles fetch fails or table is not populated yet
          final metadataRole = user.userMetadata?['role'];
          if (metadataRole != null) {
            role = metadataRole.toString();
          } else {
            if (email.contains('admin')) role = 'System Admin';
            else if (email.contains('hr')) role = 'HR Manager';
            else if (email.contains('fin')) role = 'Finance Manager';
          }
          _logAction(user.email!, 'Warning: Profile fetch failed, using fallback. Details: $e', 'System');
        }

        if (status == 'Inactive') {
          await logout();
          throw Exception('Aapka account active nahi hai. Administrator se rabta karein.');
        }

        final adminUser = AdminUser(
          id: user.id,
          name: name,
          email: user.email!,
          role: role,
          status: status,
          lastActive: DateTime.now().toLocal().toString().substring(0, 16),
        );

        state = state.copyWith(
          currentUser: adminUser,
          isAuthenticated: true,
          isLoading: false,
        );
        _logAction(user.email!, 'User logged in successfully via Supabase', 'System');
        await fetchSystemUsers();
        await fetchRolePermissions();
        return true;
      }
      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      _logAction(email, 'Login failed: $e', 'System');
      rethrow;
    }
  }

  void loginBypass(String role) {
    String name = 'Demo Admin';
    String email = 'admin@hhtech.com';
    if (role == 'HR Manager') {
      name = 'Demo HR';
      email = 'hr@hhtech.com';
    } else if (role == 'Finance Manager') {
      name = 'Demo Finance';
      email = 'finance@hhtech.com';
    } else if (role == 'Project Manager') {
      name = 'Demo PM';
      email = 'pm@hhtech.com';
    }

    final adminUser = AdminUser(
      id: 'USR-MOCK-${role.replaceAll(" ", "")}',
      name: name,
      email: email,
      role: role,
      status: 'Active',
      lastActive: DateTime.now().toLocal().toString().substring(0, 16),
    );

    state = state.copyWith(
      currentUser: adminUser,
      isAuthenticated: true,
    );
    _logAction(email, 'User logged in successfully via Demo Bypass ($role)', 'System');
  }

  Future<void> logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    state = state.copyWith(
      currentUser: null,
      isAuthenticated: false,
    );
  }

  Future<void> clearAllDatabaseData() async {
    state = state.copyWith(isLoading: true);
    try {
      final db = ref.read(appDatabaseProvider);
      await db.close();

      final dbFile = await getDatabaseFile();
      if (await dbFile.exists()) {
        await dbFile.delete();
      }

      for (final suffix in ['-wal', '-shm']) {
        final sidecar = File('${dbFile.path}$suffix');
        if (await sidecar.exists()) {
          await sidecar.delete();
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await prefs.setBool('is_seeded_data_cleared', true);

      _invalidateAllDataProviders();

      state = state.copyWith(isLoading: false);
      _logAction('admin@hhtech.com', 'Database and preference storage cleared completely.', 'System');
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
