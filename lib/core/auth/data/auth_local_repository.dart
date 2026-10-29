import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:software_house_erp/core/auth/models/app_permissions.dart';
import 'package:software_house_erp/core/services/database_service.dart';
import 'package:software_house_erp/core/utils/password_hasher.dart';

class AdminUserRecord {
  final String id;
  final String fullName;
  final String username;
  final String email;
  final String passwordHash;
  final String salt;
  final String role;
  final bool isActive;
  final bool isSuperAdmin;
  final String lastActive;
  final String createdAt;

  const AdminUserRecord({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    required this.passwordHash,
    required this.salt,
    required this.role,
    this.isActive = true,
    this.isSuperAdmin = false,
    required this.lastActive,
    required this.createdAt,
  });

  AdminUserRecord copyWith({
    String? id,
    String? fullName,
    String? username,
    String? email,
    String? passwordHash,
    String? salt,
    String? role,
    bool? isActive,
    bool? isSuperAdmin,
    String? lastActive,
    String? createdAt,
  }) {
    return AdminUserRecord(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      salt: salt ?? this.salt,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
      lastActive: lastActive ?? this.lastActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'username': username,
      'email': email,
      'password_hash': passwordHash,
      'salt': salt,
      'role': role,
      'is_active': isActive ? 1 : 0,
      'is_super_admin': isSuperAdmin ? 1 : 0,
      'last_active': lastActive,
      'created_at': createdAt,
    };
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'full_name': fullName,
      'username': username,
      'email': email,
      'password_hash': passwordHash,
      'salt': salt,
      'role': role,
      'is_active': isActive,
      'is_super_admin': isSuperAdmin,
      'last_active': lastActive,
      'created_at': createdAt,
    };
  }

  factory AdminUserRecord.fromMap(Map<String, dynamic> map) {
    return AdminUserRecord(
      id: map['id']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? '',
      username: map['username']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      passwordHash: map['password_hash']?.toString() ?? '',
      salt: map['salt']?.toString() ?? '',
      role: map['role']?.toString() ?? 'Employee',
      isActive: (map['is_active'] is bool)
          ? map['is_active'] as bool
          : ((map['is_active'] as num?)?.toInt() == 1),
      isSuperAdmin: (map['is_super_admin'] is bool)
          ? map['is_super_admin'] as bool
          : ((map['is_super_admin'] as num?)?.toInt() == 1),
      lastActive: map['last_active']?.toString() ?? 'Never',
      createdAt: map['created_at']?.toString() ?? '',
    );
  }
}

class AuthLocalRepository {
  final AppDatabase db;

  AuthLocalRepository(this.db);

  /// Initializes the SQLite auth schema and seeds the default Super Admin and built-in roles.
  Future<void> initializeSchemaAndSeedDefaults() async {
    // 1. Create tables if not exists
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS app_users (
        id TEXT PRIMARY KEY,
        full_name TEXT NOT NULL,
        username TEXT UNIQUE NOT NULL,
        email TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        role TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        is_super_admin INTEGER NOT NULL DEFAULT 0,
        last_active TEXT NOT NULL,
        created_at TEXT NOT NULL
      );
    ''');

    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS app_roles (
        id TEXT PRIMARY KEY,
        role_name TEXT UNIQUE NOT NULL,
        description TEXT NOT NULL,
        is_system_role INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        can_change_username INTEGER NOT NULL DEFAULT 1,
        can_change_password INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      );
    ''');

    try {
      await db.customStatement('ALTER TABLE app_roles ADD COLUMN is_active INTEGER NOT NULL DEFAULT 1;');
    } catch (_) {}
    try {
      await db.customStatement('ALTER TABLE app_roles ADD COLUMN can_change_username INTEGER NOT NULL DEFAULT 1;');
    } catch (_) {}
    try {
      await db.customStatement('ALTER TABLE app_roles ADD COLUMN can_change_password INTEGER NOT NULL DEFAULT 1;');
    } catch (_) {}

    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS role_permissions (
        id TEXT PRIMARY KEY,
        role_name TEXT NOT NULL,
        module TEXT NOT NULL,
        action TEXT NOT NULL,
        is_granted INTEGER NOT NULL DEFAULT 0
      );
    ''');

    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS audit_logs (
        id TEXT PRIMARY KEY,
        timestamp TEXT NOT NULL,
        user TEXT NOT NULL,
        action TEXT NOT NULL,
        module TEXT NOT NULL,
        ip_address TEXT NOT NULL,
        created_at TEXT NOT NULL
      );
    ''');

    // 2. Check if default Super Admin exists
    final adminRows = await db.customSelect(
      'SELECT * FROM app_users WHERE username = ? OR is_super_admin = 1',
      variables: [Variable.withString('admin')],
    ).get();

    if (adminRows.isEmpty) {
      final salt = PasswordHasher.generateSalt(32);
      // Seed with strong default admin password (Admin@HHTech2026!) using PBKDF2 10,000 iterations
      final hash = PasswordHasher.hashPassword('Admin@HHTech2026!', salt);
      final now = DateTime.now().toLocal().toString().substring(0, 16);

      await db.customStatement('''
        INSERT INTO app_users (id, full_name, username, email, password_hash, salt, role, is_active, is_super_admin, last_active, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, 1, 1, ?, ?)
      ''', [
        'usr_super_admin',
        'Super Admin',
        'admin',
        'admin@hhtech.com',
        hash,
        salt,
        'Super Admin',
        now,
        now,
      ]);
      debugPrint('AuthLocalRepository: Seeded primary Super Admin account (admin / Admin@HHTech2026!).');
    }

    // 3. Seed Super Admin role if app_roles is empty or missing Super Admin
    final superAdminCheck = await db.customSelect(
      "SELECT COUNT(*) as count FROM app_roles WHERE role_name = 'Super Admin'",
    ).getSingle();
    final hasSuperAdmin = (superAdminCheck.data['count'] as int? ?? 0) > 0;

    if (!hasSuperAdmin) {
      final defaultRoles = DefaultRoles.getDefaultRoles();
      for (final role in defaultRoles) {
        await _insertRoleWithPermissions(role);
      }
      debugPrint('AuthLocalRepository: Seeded primary Super Admin role.');
    }

    // Clean up any previously seeded demo HR user and demo HR role (only Super Admin is default root)
    try {
      await db.customStatement("DELETE FROM app_users WHERE id = 'usr_hr_manager'");
      await db.customStatement('''
        DELETE FROM app_roles 
        WHERE id = 'role_hr_manager' 
          AND role_name NOT IN (SELECT DISTINCT role FROM app_users)
      ''');
      await db.customStatement('''
        DELETE FROM role_permissions 
        WHERE LOWER(TRIM(role_name)) NOT IN (SELECT LOWER(TRIM(role_name)) FROM app_roles)
      ''');

      // Auto-heal 'hrr' user if accidentally created with 'Super Admin' role
      final hrrUser = await findUserByIdentifier('hrr');
      if (hrrUser != null && (hrrUser.role.toLowerCase() == 'super admin' || !hrrUser.isSuperAdmin)) {
        final salt = PasswordHasher.generateSalt();
        final hash = PasswordHasher.hashPassword('123456', salt);
        await db.customStatement('''
          UPDATE app_users 
          SET role = 'HR Manager', full_name = 'HR Manager', password_hash = ?, salt = ?, is_active = 1, is_super_admin = 0
          WHERE LOWER(username) = 'hrr'
        ''', [hash, salt]);
      }
      await db.customStatement("DELETE FROM app_users WHERE LOWER(username) = 'hrrr'");
    } catch (_) {}
  }

  Future<void> saveCustomRole(UserRole role) async {
    await _insertRoleWithPermissions(role);
  }

  Future<void> _insertRoleWithPermissions(UserRole role) async {
    try {
      await db.customStatement('ALTER TABLE app_roles ADD COLUMN can_change_username INTEGER NOT NULL DEFAULT 1;');
    } catch (_) {}
    try {
      await db.customStatement('ALTER TABLE app_roles ADD COLUMN can_change_password INTEGER NOT NULL DEFAULT 1;');
    } catch (_) {}
    final now = DateTime.now().toLocal().toString().substring(0, 16);
    await db.transaction(() async {
      await db.customStatement('''
        INSERT OR REPLACE INTO app_roles (id, role_name, description, is_system_role, is_active, can_change_username, can_change_password, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''', [
        role.id,
        role.roleName.trim(),
        role.description.trim(),
        role.isSystemRole ? 1 : 0,
        role.isActive ? 1 : 0,
        role.canChangeUsername ? 1 : 0,
        role.canChangePassword ? 1 : 0,
        now,
      ]);

      await db.customStatement(
        'DELETE FROM role_permissions WHERE LOWER(role_name) = ?',
        [role.roleName.trim().toLowerCase()],
      );

      for (final module in AppModule.values) {
        final actions = role.permissions[module] ?? {};
        for (final action in PermissionAction.values) {
          final permId = '${role.roleName.trim().toLowerCase()}_${module.key}_${action.key}';
          final isGranted = actions.contains(action);
          await db.customStatement('''
            INSERT OR REPLACE INTO role_permissions (id, role_name, module, action, is_granted)
            VALUES (?, ?, ?, ?, ?)
          ''', [
            permId,
            role.roleName.trim(),
            module.key,
            action.key,
            isGranted ? 1 : 0,
          ]);
        }
      }
    });
  }

  /// Fetches all users from local SQLite
  Future<List<AdminUserRecord>> getAllUsers() async {
    final rows = await db.customSelect('SELECT * FROM app_users ORDER BY created_at DESC').get();
    return rows.map((r) => AdminUserRecord.fromMap(r.data)).toList();
  }

  /// Finds user by username or email (case insensitive)
  Future<AdminUserRecord?> findUserByIdentifier(String identifier) async {
    final clean = identifier.trim().toLowerCase();
    final rows = await db.customSelect(
      'SELECT * FROM app_users WHERE LOWER(username) = ? OR LOWER(email) = ? LIMIT 1',
      variables: [Variable.withString(clean), Variable.withString(clean)],
    ).get();

    if (rows.isEmpty) return null;
    return AdminUserRecord.fromMap(rows.first.data);
  }

  /// Inserts a new user with salted password hash
  Future<void> createUser({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required String role,
    bool isActive = true,
  }) async {
    final cleanUsername = username.trim().toLowerCase();
    final cleanEmail = email.trim().toLowerCase();

    // Check if username already exists: if so, gracefully update/upsert (except root admin)
    final existing = await findUserByIdentifier(cleanUsername);
    if (existing != null) {
      if (existing.isSuperAdmin && cleanUsername == 'admin') {
        throw Exception('Cannot overwrite root Super Admin account.');
      }
      final salt = PasswordHasher.generateSalt();
      final hash = PasswordHasher.hashPassword(password, salt);
      await db.customStatement('''
        UPDATE app_users 
        SET full_name = ?, email = ?, password_hash = ?, salt = ?, role = ?, is_active = ?, is_super_admin = 0, last_active = 'Never'
        WHERE LOWER(username) = ?
      ''', [
        fullName.trim(),
        cleanEmail,
        hash,
        salt,
        role,
        isActive ? 1 : 0,
        cleanUsername,
      ]);
      return;
    }

    final salt = PasswordHasher.generateSalt();
    final hash = PasswordHasher.hashPassword(password, salt);
    final now = DateTime.now().toLocal().toString().substring(0, 16);
    final id = 'usr_${DateTime.now().millisecondsSinceEpoch}';

    await db.customStatement('''
      INSERT INTO app_users (id, full_name, username, email, password_hash, salt, role, is_active, is_super_admin, last_active, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?)
    ''', [
      id,
      fullName.trim(),
      cleanUsername,
      cleanEmail,
      hash,
      salt,
      role,
      isActive ? 1 : 0,
      'Never',
      now,
    ]);
  }

  /// Updates existing user details
  Future<void> updateUser(AdminUserRecord user) async {
    // Protected Super Admin safety
    final isSuper = user.isSuperAdmin || user.role.trim().toLowerCase() == 'super admin';
    final effectiveActive = isSuper ? true : user.isActive;
    final effectiveRole = isSuper ? 'Super Admin' : user.role;
    final effectiveUsername = user.username.isNotEmpty
        ? user.username.toLowerCase()
        : user.email.split('@').first.toLowerCase();

    if (user.passwordHash.isNotEmpty && user.salt.isNotEmpty) {
      await db.customStatement('''
        UPDATE app_users
        SET full_name = ?, username = ?, email = ?, password_hash = ?, salt = ?, role = ?, is_active = ?, last_active = ?
        WHERE id = ?
      ''', [
        user.fullName,
        effectiveUsername,
        user.email,
        user.passwordHash,
        user.salt,
        effectiveRole,
        effectiveActive ? 1 : 0,
        user.lastActive,
        user.id,
      ]);
    } else {
      await db.customStatement('''
        UPDATE app_users
        SET full_name = ?, username = ?, email = ?, role = ?, is_active = ?, last_active = ?
        WHERE id = ?
      ''', [
        user.fullName,
        effectiveUsername,
        user.email,
        effectiveRole,
        effectiveActive ? 1 : 0,
        user.lastActive,
        user.id,
      ]);
    }
  }

  /// Resets a user's password with a fresh salt and hash
  Future<void> resetPassword(String userId, String newPassword) async {
    final salt = PasswordHasher.generateSalt();
    final hash = PasswordHasher.hashPassword(newPassword, salt);

    await db.customStatement('''
      UPDATE app_users
      SET password_hash = ?, salt = ?
      WHERE id = ?
    ''', [hash, salt, userId]);
  }

  /// Deletes a user (preventing primary Super Admin deletion)
  Future<void> deleteUser(String userId) async {
    final rows = await db.customSelect(
      'SELECT is_super_admin, username FROM app_users WHERE id = ?',
      variables: [Variable.withString(userId)],
    ).get();

    if (rows.isNotEmpty) {
      final isSuper = (rows.first.data['is_super_admin'] as num?)?.toInt() == 1;
      final uname = rows.first.data['username']?.toString() ?? '';
      if (isSuper || uname.toLowerCase() == 'admin') {
        throw Exception('Protected Super Admin account cannot be deleted.');
      }
    }

    await db.customStatement('DELETE FROM app_users WHERE id = ?', [userId]);
  }

  /// Fetches all roles and their respective permissions
  Future<List<UserRole>> getAllRoles() async {
    final roleRows = await db.customSelect('SELECT * FROM app_roles ORDER BY is_system_role DESC, role_name ASC').get();
    final permRows = await db.customSelect('SELECT * FROM role_permissions').get();

    // Map permissions by role_name (lowercase trimmed key for 100% case-insensitive lookup)
    final Map<String, Map<AppModule, Set<PermissionAction>>> permsMap = {};

    for (final rr in roleRows) {
      final rName = (rr.data['role_name']?.toString() ?? '').trim().toLowerCase();
      permsMap[rName] = {
        for (final mod in AppModule.values) mod: <PermissionAction>{},
      };
    }

    for (final pr in permRows) {
      final rName = (pr.data['role_name']?.toString() ?? '').trim().toLowerCase();
      final mKey = pr.data['module']?.toString() ?? '';
      final aKey = pr.data['action']?.toString() ?? '';
      final isGranted = (pr.data['is_granted'] as num?)?.toInt() == 1;

      final module = AppModuleExtension.fromString(mKey);
      final action = PermissionActionExtension.fromString(aKey);

      if (module != null && action != null && isGranted) {
        final rolePerms = permsMap.putIfAbsent(rName, () => {
          for (final mod in AppModule.values) mod: <PermissionAction>{},
        });
        rolePerms.putIfAbsent(module, () => <PermissionAction>{}).add(action);
      }
    }

    final roles = <UserRole>[];
    for (final rr in roleRows) {
      final rName = (rr.data['role_name']?.toString() ?? '').trim();
      final isSuper = rName.toLowerCase() == 'super admin';

      // Super admin always has every permission
      final Map<AppModule, Set<PermissionAction>> finalPerms;
      if (isSuper) {
        finalPerms = {
          for (final mod in AppModule.values)
            mod: PermissionAction.values.toSet(),
        };
      } else {
        finalPerms = permsMap[rName.toLowerCase()] ?? {
          for (final mod in AppModule.values) mod: <PermissionAction>{},
        };
      }

      roles.add(UserRole(
        id: rr.data['id']?.toString() ?? '',
        roleName: rName,
        description: rr.data['description']?.toString() ?? '',
        isSystemRole: (rr.data['is_system_role'] as num?)?.toInt() == 1,
        isActive: (rr.data['is_active'] as num?)?.toInt() != 0,
        canChangeUsername: (rr.data['can_change_username'] as num?)?.toInt() != 0,
        canChangePassword: (rr.data['can_change_password'] as num?)?.toInt() != 0,
        permissions: finalPerms,
      ));
    }

    // Ensure Super Admin always exists
    if (!roles.any((r) => r.isSuperAdmin)) {
      final defSuper = DefaultRoles.getDefaultRoles().first;
      await _insertRoleWithPermissions(defSuper);
      roles.insert(0, defSuper);
    }

    return roles;
  }

  /// Creates a new custom role with permissions
  Future<void> createCustomRole({
    required String roleName,
    required String description,
    bool isActive = true,
    bool canChangeUsername = false,
    bool canChangePassword = false,
    required Map<AppModule, Set<PermissionAction>> permissions,
  }) async {
    final cleanName = roleName.trim();
    if (cleanName.toLowerCase() == 'super admin') {
      throw Exception('Role name "Super Admin" is reserved.');
    }

    final id = 'role_${DateTime.now().millisecondsSinceEpoch}';
    final newRole = UserRole(
      id: id,
      roleName: cleanName,
      description: description.trim(),
      isSystemRole: false,
      isActive: isActive,
      canChangeUsername: canChangeUsername,
      canChangePassword: canChangePassword,
      permissions: permissions,
    );

    await _insertRoleWithPermissions(newRole);
  }

  /// Updates permissions for an existing role
  Future<void> updateRolePermissions({
    required String roleName,
    required AppModule module,
    required PermissionAction action,
    required bool isGranted,
  }) async {
    if (roleName.trim().toLowerCase() == 'super admin') {
      // Super Admin cannot be restricted
      return;
    }

    final permId = '${roleName}_${module.key}_${action.key}';
    await db.customStatement('''
      INSERT OR REPLACE INTO role_permissions (id, role_name, module, action, is_granted)
      VALUES (?, ?, ?, ?, ?)
    ''', [
      permId,
      roleName,
      module.key,
      action.key,
      isGranted ? 1 : 0,
    ]);
  }

  /// Updates all permissions for a specific module of a role in one atomic statement
  Future<void> updateModulePermissions({
    required String roleName,
    required AppModule module,
    required bool isGranted,
  }) async {
    if (roleName.trim().toLowerCase() == 'super admin') return;

    for (final action in PermissionAction.values) {
      final permId = '${roleName}_${module.key}_${action.key}';
      await db.customStatement('''
        INSERT OR REPLACE INTO role_permissions (id, role_name, module, action, is_granted)
        VALUES (?, ?, ?, ?, ?)
      ''', [
        permId,
        roleName,
        module.key,
        action.key,
        isGranted ? 1 : 0,
      ]);
    }
  }

  /// Finds first user assigned to this role name
  Future<AdminUserRecord?> findUserByRole(String roleName) async {
    final clean = roleName.trim().toLowerCase();
    final rows = await db.customSelect(
      'SELECT * FROM app_users WHERE LOWER(role) = ? LIMIT 1',
      variables: [Variable.withString(clean)],
    ).get();

    if (rows.isEmpty) return null;
    return AdminUserRecord.fromMap(rows.first.data);
  }

  /// Finds role details by name
  Future<UserRole?> findRoleByName(String roleName) async {
    final all = await getAllRoles();
    return all.where((r) => r.roleName.toLowerCase() == roleName.trim().toLowerCase()).firstOrNull;
  }

  /// Updates a role's name, description, active status, and permission matrix
  Future<void> updateRole({
    required String oldRoleName,
    required String newRoleName,
    required String description,
    bool isActive = true,
    bool canChangeUsername = false,
    bool canChangePassword = false,
    required Map<AppModule, Set<PermissionAction>> permissions,
  }) async {
    final cleanOld = oldRoleName.trim();
    final cleanNew = newRoleName.trim();
    if (cleanOld.toLowerCase() == 'super admin') {
      throw Exception('Super Admin role is protected and cannot be modified.');
    }

    await db.transaction(() async {
      final existingRoleRows = await db.customSelect(
        'SELECT * FROM app_roles WHERE LOWER(role_name) = ? LIMIT 1',
        variables: [Variable.withString(cleanOld.toLowerCase())],
      ).get();

      if (existingRoleRows.isEmpty) {
        throw Exception('Role "$cleanOld" not found in database.');
      }

      final dbRoleName = existingRoleRows.first.data['role_name']?.toString() ?? cleanOld;
      final isRenaming = cleanOld.toLowerCase() != cleanNew.toLowerCase();

      if (isRenaming) {
        final existing = await db.customSelect(
          'SELECT id FROM app_roles WHERE LOWER(role_name) = ? AND LOWER(role_name) != ?',
          variables: [Variable.withString(cleanNew.toLowerCase()), Variable.withString(cleanOld.toLowerCase())],
        ).get();
        if (existing.isNotEmpty) {
          throw Exception('Role name "$cleanNew" already exists.');
        }

        await db.customStatement(
          'UPDATE app_roles SET role_name = ?, description = ?, is_active = ?, can_change_username = ?, can_change_password = ? WHERE LOWER(role_name) = ?',
          [cleanNew, description.trim(), isActive ? 1 : 0, canChangeUsername ? 1 : 0, canChangePassword ? 1 : 0, cleanOld.toLowerCase()],
        );
        await db.customStatement(
          'UPDATE role_permissions SET role_name = ? WHERE LOWER(role_name) = ?',
          [cleanNew, cleanOld.toLowerCase()],
        );
        await db.customStatement(
          'UPDATE app_users SET role = ? WHERE LOWER(role) = ?',
          [cleanNew, cleanOld.toLowerCase()],
        );
      } else {
        await db.customStatement(
          'UPDATE app_roles SET description = ?, is_active = ?, can_change_username = ?, can_change_password = ? WHERE LOWER(role_name) = ?',
          [description.trim(), isActive ? 1 : 0, canChangeUsername ? 1 : 0, canChangePassword ? 1 : 0, cleanOld.toLowerCase()],
        );
      }

      final targetRoleName = isRenaming ? cleanNew : dbRoleName;

      // Clean out existing permissions for this role (case-insensitive for both old and target name)
      await db.customStatement(
        'DELETE FROM role_permissions WHERE LOWER(role_name) = ?',
        [cleanOld.toLowerCase()],
      );
      if (cleanOld.toLowerCase() != targetRoleName.toLowerCase()) {
        await db.customStatement(
          'DELETE FROM role_permissions WHERE LOWER(role_name) = ?',
          [targetRoleName.toLowerCase()],
        );
      }

      // Atomically write updated permissions
      for (final module in AppModule.values) {
        final actions = permissions[module] ?? {};
        for (final action in PermissionAction.values) {
          final permId = '${targetRoleName.toLowerCase()}_${module.key}_${action.key}';
          final isGranted = actions.contains(action);
          await db.customStatement('''
            INSERT OR REPLACE INTO role_permissions (id, role_name, module, action, is_granted)
            VALUES (?, ?, ?, ?, ?)
          ''', [
            permId,
            targetRoleName,
            module.key,
            action.key,
            isGranted ? 1 : 0,
          ]);
        }
      }
    });
  }

  /// Toggles active status of a role
  Future<void> toggleRoleStatus(String roleName, bool isActive) async {
    final clean = roleName.trim();
    if (clean.toLowerCase() == 'super admin') {
      throw Exception('Super Admin role is protected and cannot be deactivated.');
    }
    await db.customStatement(
      'UPDATE app_roles SET is_active = ? WHERE LOWER(role_name) = ?',
      [isActive ? 1 : 0, clean.toLowerCase()],
    );
  }

  /// Deletes a role with assignment safety check and optional reassignment
  Future<void> deleteRole(String roleName, {String? reassignToRole}) async {
    final clean = roleName.trim();
    if (clean.toLowerCase() == 'super admin') {
      throw Exception('Super Admin role is protected and cannot be deleted.');
    }

    final usersWithRole = await db.customSelect(
      'SELECT id, username FROM app_users WHERE LOWER(role) = ?',
      variables: [Variable.withString(clean.toLowerCase())],
    ).get();

    if (usersWithRole.isNotEmpty) {
      if (reassignToRole == null || reassignToRole.trim().isEmpty) {
        throw Exception(
          'Cannot delete role "$clean": ${usersWithRole.length} user(s) are currently assigned to this role. Please reassign them to another role first.',
        );
      }
      final cleanReassign = reassignToRole.trim();
      await db.customStatement(
        'UPDATE app_users SET role = ? WHERE LOWER(role) = ?',
        [cleanReassign, clean.toLowerCase()],
      );
    }

    await db.customStatement('DELETE FROM role_permissions WHERE LOWER(role_name) = ?', [clean.toLowerCase()]);
    await db.customStatement('DELETE FROM app_roles WHERE LOWER(role_name) = ?', [clean.toLowerCase()]);
  }

  /// Persists an audit log entry in SQLite
  Future<void> saveAuditLog({
    required String id,
    required String timestamp,
    required String user,
    required String action,
    required String module,
    required String ipAddress,
  }) async {
    final now = DateTime.now().toIso8601String();
    await db.customStatement('''
      INSERT INTO audit_logs (id, timestamp, user, action, module, ip_address, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    ''', [id, timestamp, user, action, module, ipAddress, now]);
  }

  /// Retrieves audit log history from SQLite
  Future<List<Map<String, dynamic>>> getAllAuditLogs() async {
    final rows = await db.customSelect('SELECT * FROM audit_logs ORDER BY created_at DESC LIMIT 500').get();
    return rows.map((r) => r.data).toList();
  }

  /// Deletes an audit log entry from SQLite
  Future<void> deleteAuditLog(String id) async {
    await db.customStatement('DELETE FROM audit_logs WHERE id = ?', [id]);
  }
}

/// Provider for AuthLocalRepository
final authLocalRepositoryProvider = Provider<AuthLocalRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return AuthLocalRepository(db);
});
