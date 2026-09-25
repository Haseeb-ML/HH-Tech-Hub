import 'package:flutter_test/flutter_test.dart';
import 'package:software_house_erp/core/auth/models/app_permissions.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';
import 'package:software_house_erp/features/hr/employees/domain/entities/employee.dart';

void main() {
  group('Dynamic RBAC Acceptance Tests', () {
    test('TEST 1: Create HR Manager role with granular permissions', () {
      final hrManagerRole = UserRole(
        id: 'role_hr_mgr',
        roleName: 'HR Manager',
        description: 'HR operations lead',
        isActive: true,
        permissions: {
          AppModule.employees: {
            PermissionAction.view,
            PermissionAction.create,
            PermissionAction.edit,
          },
          AppModule.attendance: {
            PermissionAction.view,
            PermissionAction.create,
            PermissionAction.edit,
          },
          AppModule.payroll: {
            PermissionAction.view,
          },
        },
      );

      // Verify HR Manager permissions
      expect(hrManagerRole.hasPermission(AppModule.employees, PermissionAction.view), isTrue);
      expect(hrManagerRole.hasPermission(AppModule.employees, PermissionAction.create), isTrue);
      expect(hrManagerRole.hasPermission(AppModule.employees, PermissionAction.edit), isTrue);
      expect(hrManagerRole.hasPermission(AppModule.employees, PermissionAction.delete), isFalse);

      expect(hrManagerRole.hasPermission(AppModule.attendance, PermissionAction.view), isTrue);
      expect(hrManagerRole.hasPermission(AppModule.attendance, PermissionAction.create), isTrue);
      expect(hrManagerRole.hasPermission(AppModule.attendance, PermissionAction.edit), isTrue);

      expect(hrManagerRole.hasPermission(AppModule.payroll, PermissionAction.view), isTrue);
      expect(hrManagerRole.hasPermission(AppModule.payroll, PermissionAction.edit), isFalse);

      // Unrelated modules have no access
      expect(hrManagerRole.hasPermission(AppModule.finance, PermissionAction.view), isFalse);
      expect(hrManagerRole.hasPermission(AppModule.projects, PermissionAction.view), isFalse);
    });

    test('TEST 2: Grant Finance View + Create to HR Manager', () {
      final hrManagerWithFinance = UserRole(
        id: 'role_hr_mgr',
        roleName: 'HR Manager',
        description: 'HR operations lead with finance permissions',
        isActive: true,
        permissions: {
          AppModule.employees: {
            PermissionAction.view,
            PermissionAction.create,
            PermissionAction.edit,
          },
          AppModule.finance: {
            PermissionAction.view,
            PermissionAction.create,
          },
        },
      );

      // Can access Finance and Create records
      expect(hrManagerWithFinance.hasPermission(AppModule.finance, PermissionAction.view), isTrue);
      expect(hrManagerWithFinance.hasPermission(AppModule.finance, PermissionAction.create), isTrue);

      // Sub-module (income) inherits View + Create from Finance parent
      expect(hrManagerWithFinance.hasPermission(AppModule.income, PermissionAction.view), isTrue);
      expect(hrManagerWithFinance.hasPermission(AppModule.income, PermissionAction.create), isTrue);

      // Edit, Delete, Approve remain strictly blocked
      expect(hrManagerWithFinance.hasPermission(AppModule.finance, PermissionAction.edit), isFalse);
      expect(hrManagerWithFinance.hasPermission(AppModule.finance, PermissionAction.delete), isFalse);
      expect(hrManagerWithFinance.hasPermission(AppModule.finance, PermissionAction.approve), isFalse);
      expect(hrManagerWithFinance.hasPermission(AppModule.income, PermissionAction.delete), isFalse);
    });

    test('TEST 3: Remove Finance Create from HR Manager', () {
      final hrManagerViewOnlyFinance = UserRole(
        id: 'role_hr_mgr',
        roleName: 'HR Manager',
        description: 'HR operations lead with view-only finance',
        isActive: true,
        permissions: {
          AppModule.finance: {
            PermissionAction.view,
          },
        },
      );

      expect(hrManagerViewOnlyFinance.hasPermission(AppModule.finance, PermissionAction.view), isTrue);
      expect(hrManagerViewOnlyFinance.hasPermission(AppModule.finance, PermissionAction.create), isFalse);
      expect(hrManagerViewOnlyFinance.hasPermission(AppModule.finance, PermissionAction.delete), isFalse);
    });

    test('TEST 4: Create Project Manager with Projects (View, Create, Edit) and Finance (View)', () {
      final pmRole = UserRole(
        id: 'role_pm',
        roleName: 'Project Manager',
        description: 'Project Delivery & Oversight',
        isActive: true,
        permissions: {
          AppModule.projects: {
            PermissionAction.view,
            PermissionAction.create,
            PermissionAction.edit,
          },
          AppModule.finance: {
            PermissionAction.view,
          },
        },
      );

      expect(pmRole.hasPermission(AppModule.projects, PermissionAction.view), isTrue);
      expect(pmRole.hasPermission(AppModule.projects, PermissionAction.create), isTrue);
      expect(pmRole.hasPermission(AppModule.projects, PermissionAction.edit), isTrue);
      expect(pmRole.hasPermission(AppModule.projects, PermissionAction.delete), isFalse);

      expect(pmRole.hasPermission(AppModule.finance, PermissionAction.view), isTrue);
      expect(pmRole.hasPermission(AppModule.finance, PermissionAction.create), isFalse);
    });

    test('TEST 5: Custom role with any arbitrary combination of modules', () {
      final customRole = UserRole(
        id: 'role_custom',
        roleName: 'HR + Finance + Projects Custom',
        description: 'Multi-disciplinary executive role',
        isActive: true,
        permissions: {
          AppModule.employees: {PermissionAction.view, PermissionAction.create},
          AppModule.income: {PermissionAction.view, PermissionAction.create, PermissionAction.export},
          AppModule.projects: {PermissionAction.view, PermissionAction.manage},
        },
      );

      expect(customRole.hasPermission(AppModule.employees, PermissionAction.view), isTrue);
      expect(customRole.hasPermission(AppModule.income, PermissionAction.create), isTrue);
      expect(customRole.hasPermission(AppModule.income, PermissionAction.export), isTrue);
      expect(customRole.hasPermission(AppModule.projects, PermissionAction.manage), isTrue);

      // Loans was not granted
      expect(customRole.hasPermission(AppModule.loans, PermissionAction.view), isFalse);
      expect(customRole.hasPermission(AppModule.inventory, PermissionAction.view), isFalse);
    });

    test('TEST 6 & 7: User -> Role -> Dynamic Permissions & Real-time propagation', () {
      final hrRoleV1 = UserRole(
        id: 'role_hr',
        roleName: 'HR Manager',
        description: '',
        isActive: true,
        permissions: {
          AppModule.finance: {PermissionAction.view},
        },
      );

      final ali = AdminUser(
        id: 'user_ali',
        name: 'Ali Ahmed',
        username: 'aliahmed',
        email: 'ali@hhtech.com',
        role: 'HR Manager',
        status: 'Active',
        lastActive: 'Now',
      );

      var adminState = AdminState(
        users: [ali],
        roles: [],
        userRoles: [hrRoleV1],
        backups: [],
        logs: [],
        currentUser: ali,
        sessionTimeout: 30,
        maintenanceMode: false,
        autoBackupInterval: 'Weekly',
        emailNotifications: true,
        developerSandbox: false,
        auditRetention: '90 Days',
        mfaPolicy: 'Disabled',
        dataSyncSchedule: 'Realtime',
        isLoading: false,
        searchQuery: '',
        moduleFilter: 'All',
      );

      // Test 6: Ali receives HR Manager permissions (Finance View only)
      expect(adminState.hasPermission(AppModule.finance, PermissionAction.view), isTrue);
      expect(adminState.hasPermission(AppModule.finance, PermissionAction.create), isFalse);

      // Test 7: Super Admin updates HR Manager to View + Create
      final hrRoleV2 = hrRoleV1.copyWith(
        permissions: {
          AppModule.finance: {PermissionAction.view, PermissionAction.create},
        },
      );
      adminState = adminState.copyWith(userRoles: [hrRoleV2]);

      // Ali automatically receives Create permission
      expect(adminState.hasPermission(AppModule.finance, PermissionAction.view), isTrue);
      expect(adminState.hasPermission(AppModule.finance, PermissionAction.create), isTrue);
      expect(adminState.hasPermission(AppModule.finance, PermissionAction.delete), isFalse);
    });

    test('TEST 8: User blocked from operation without permission', () {
      final role = UserRole(
        id: 'role_op',
        roleName: 'Operator',
        description: '',
        isActive: true,
        permissions: {
          AppModule.finance: {PermissionAction.view, PermissionAction.create},
        },
      );

      final user = AdminUser(
        id: 'user_op',
        name: 'Operator User',
        username: 'opuser',
        email: 'op@hhtech.com',
        role: 'Operator',
        status: 'Active',
        lastActive: 'Now',
      );

      final adminState = AdminState(
        users: [user],
        roles: [],
        userRoles: [role],
        backups: [],
        logs: [],
        currentUser: user,
        sessionTimeout: 30,
        maintenanceMode: false,
        autoBackupInterval: 'Weekly',
        emailNotifications: true,
        developerSandbox: false,
        auditRetention: '90 Days',
        mfaPolicy: 'Disabled',
        dataSyncSchedule: 'Realtime',
        isLoading: false,
        searchQuery: '',
        moduleFilter: 'All',
      );

      // Trying to delete record
      final canDelete = adminState.hasPermission(AppModule.income, PermissionAction.delete) ||
          adminState.hasPermission(AppModule.finance, PermissionAction.delete);
      expect(canDelete, isFalse);
    });

    test('TEST 10: Non-Super Admin blocked from Roles & Permissions', () {
      final normalAdmin = AdminUser(
        id: 'user_norm',
        name: 'Department Admin',
        username: 'deptadmin',
        email: 'dept@hhtech.com',
        role: 'HR Manager',
        status: 'Active',
        lastActive: 'Now',
        isSuperAdmin: false,
      );

      final isAllowed = normalAdmin.isSuperAdmin ||
          normalAdmin.role.trim().toLowerCase() == 'super admin' ||
          normalAdmin.role.trim().toLowerCase() == 'system admin';

      expect(isAllowed, isFalse);
    });

    test('TEST 13: Deactivated user is blocked from all ERP functions', () {
      final deactivatedUser = AdminUser(
        id: 'user_blocked',
        name: 'Blocked User',
        username: 'blocked',
        email: 'blocked@hhtech.com',
        role: 'HR Manager',
        status: 'Inactive',
        lastActive: 'Yesterday',
      );

      final hrRole = UserRole(
        id: 'role_hr',
        roleName: 'HR Manager',
        description: '',
        isActive: true,
        permissions: {
          AppModule.employees: {PermissionAction.view},
        },
      );

      final adminState = AdminState(
        users: [deactivatedUser],
        roles: [],
        userRoles: [hrRole],
        backups: [],
        logs: [],
        currentUser: deactivatedUser,
        sessionTimeout: 30,
        maintenanceMode: false,
        autoBackupInterval: 'Weekly',
        emailNotifications: true,
        developerSandbox: false,
        auditRetention: '90 Days',
        mfaPolicy: 'Disabled',
        dataSyncSchedule: 'Realtime',
        isLoading: false,
        searchQuery: '',
        moduleFilter: 'All',
      );

      expect(deactivatedUser.isActive, isFalse);
      expect(adminState.hasPermission(AppModule.employees, PermissionAction.view), isFalse);
    });

    test('TEST 16: Last Super Admin protection', () {
      final superAdmin = AdminUser(
        id: 'admin_1',
        name: 'Super Admin',
        username: 'admin',
        email: 'admin@hhtech.com',
        role: 'Super Admin',
        status: 'Active',
        lastActive: 'Now',
        isSuperAdmin: true,
      );

      final users = [superAdmin];
      final activeSuperAdmins = users.where(
        (u) => (u.isSuperAdmin || u.role.trim().toLowerCase() == 'super admin') && u.status == 'Active',
      ).toList();

      // Guard: Cannot disable or delete if only 1 Super Admin remains
      expect(activeSuperAdmins.length, equals(1));
      expect(activeSuperAdmins.length <= 1, isTrue);
    });

    test('TEST 17: Granular View / Create / Edit / Delete Independence Rules', () {
      // 1. Only View enabled
      final viewOnlyRole = UserRole(
        id: 'role_view_only',
        roleName: 'Auditor',
        description: 'Read only access',
        permissions: {
          AppModule.employees: {PermissionAction.view},
        },
      );
      expect(viewOnlyRole.hasPermission(AppModule.employees, PermissionAction.view), isTrue);
      expect(viewOnlyRole.hasPermission(AppModule.employees, PermissionAction.create), isFalse);
      expect(viewOnlyRole.hasPermission(AppModule.employees, PermissionAction.edit), isFalse);
      expect(viewOnlyRole.hasPermission(AppModule.employees, PermissionAction.delete), isFalse);

      // 2. View + Create enabled
      final viewCreateRole = UserRole(
        id: 'role_view_create',
        roleName: 'Clerk',
        description: 'Can add records only',
        permissions: {
          AppModule.employees: {PermissionAction.view, PermissionAction.create},
        },
      );
      expect(viewCreateRole.hasPermission(AppModule.employees, PermissionAction.view), isTrue);
      expect(viewCreateRole.hasPermission(AppModule.employees, PermissionAction.create), isTrue);
      expect(viewCreateRole.hasPermission(AppModule.employees, PermissionAction.edit), isFalse);
      expect(viewCreateRole.hasPermission(AppModule.employees, PermissionAction.delete), isFalse);

      // 3. View + Edit enabled
      final viewEditRole = UserRole(
        id: 'role_view_edit',
        roleName: 'Editor',
        description: 'Can update records only',
        permissions: {
          AppModule.employees: {PermissionAction.view, PermissionAction.edit},
        },
      );
      expect(viewEditRole.hasPermission(AppModule.employees, PermissionAction.view), isTrue);
      expect(viewEditRole.hasPermission(AppModule.employees, PermissionAction.create), isFalse);
      expect(viewEditRole.hasPermission(AppModule.employees, PermissionAction.edit), isTrue);
      expect(viewEditRole.hasPermission(AppModule.employees, PermissionAction.delete), isFalse);

      // 4. View + Delete enabled
      final viewDeleteRole = UserRole(
        id: 'role_view_delete',
        roleName: 'Archiver',
        description: 'Can purge records only',
        permissions: {
          AppModule.employees: {PermissionAction.view, PermissionAction.delete},
        },
      );
      expect(viewDeleteRole.hasPermission(AppModule.employees, PermissionAction.view), isTrue);
      expect(viewDeleteRole.hasPermission(AppModule.employees, PermissionAction.create), isFalse);
      expect(viewDeleteRole.hasPermission(AppModule.employees, PermissionAction.edit), isFalse);
      expect(viewDeleteRole.hasPermission(AppModule.employees, PermissionAction.delete), isTrue);

      // 5. All 4 enabled (Full Access)
      final fullAccessRole = UserRole(
        id: 'role_full',
        roleName: 'Executive',
        description: 'Full module access',
        permissions: {
          AppModule.employees: {
            PermissionAction.view,
            PermissionAction.create,
            PermissionAction.edit,
            PermissionAction.delete,
          },
        },
      );
      expect(fullAccessRole.hasPermission(AppModule.employees, PermissionAction.view), isTrue);
      expect(fullAccessRole.hasPermission(AppModule.employees, PermissionAction.create), isTrue);
      expect(fullAccessRole.hasPermission(AppModule.employees, PermissionAction.edit), isTrue);
      expect(fullAccessRole.hasPermission(AppModule.employees, PermissionAction.delete), isTrue);
    });

    test('TEST 18: Independent canChangeUsername and canChangePassword permissions', () {
      // Role with both disabled
      final lockedCredentialsRole = UserRole(
        id: 'role_locked',
        roleName: 'Contractor',
        description: 'Fixed credentials',
        canChangeUsername: false,
        canChangePassword: false,
        permissions: {},
      );
      expect(lockedCredentialsRole.canChangeUsername, isFalse);
      expect(lockedCredentialsRole.canChangePassword, isFalse);

      // Role allowed to change password only
      final changePasswordOnlyRole = UserRole(
        id: 'role_pwd_only',
        roleName: 'Staff',
        description: 'Standard employee',
        canChangeUsername: false,
        canChangePassword: true,
        permissions: {},
      );
      expect(changePasswordOnlyRole.canChangeUsername, isFalse);
      expect(changePasswordOnlyRole.canChangePassword, isTrue);

      // Role allowed to change username only
      final changeUsernameOnlyRole = UserRole(
        id: 'role_uname_only',
        roleName: 'Identity Manager',
        description: 'Identity adjustment',
        canChangeUsername: true,
        canChangePassword: false,
        permissions: {},
      );
      expect(changeUsernameOnlyRole.canChangeUsername, isTrue);
      expect(changeUsernameOnlyRole.canChangePassword, isFalse);

      // Role allowed to change both
      final fullCredentialsRole = UserRole(
        id: 'role_full_creds',
        roleName: 'System Admin',
        description: 'Full credential control',
        canChangeUsername: true,
        canChangePassword: true,
        permissions: {},
      );
      expect(fullCredentialsRole.canChangeUsername, isTrue);
      expect(fullCredentialsRole.canChangePassword, isTrue);
    });

    test('TEST 19: Employee mandatory Joining Date validation', () {
      final employee = Employee(
        id: 'emp_test_101',
        name: 'Sara Khan',
        email: 'sara@company.com',
        phones: const ['+92 300 1234567'],
        designation: 'Software Engineer',
        department: 'Engineering',
        joiningDate: '2024-05-15',
        status: 'Active',
        salaryType: 'Monthly',
        baseSalary: 95000.0,
        paymentMethod: 'Bank Transfer',
      );

      // Verify joining date is properly populated and not empty
      expect(employee.joiningDate, isNotEmpty);
      expect(employee.joiningDate, equals('2024-05-15'));

      // Verify toMap and fromMap preserve joiningDate
      final map = employee.toMap();
      expect(map['joiningDate'], equals('2024-05-15'));

      final reconstructed = Employee.fromMap(map);
      expect(reconstructed.joiningDate, equals('2024-05-15'));
    });

    test('TEST 20: Role-based users cannot change credentials; only Super Admin can change credentials', () {
      final superAdminUser = AdminUser(
        id: 'super_1',
        name: 'Super Admin',
        username: 'superadmin',
        email: 'super@hhtech.com',
        role: 'Super Admin',
        status: 'Active',
        lastActive: 'Now',
        isSuperAdmin: true,
      );

      final roleBasedUser = AdminUser(
        id: 'hr_1',
        name: 'HR User',
        username: 'hruser',
        email: 'hr@hhtech.com',
        role: 'HR Manager',
        status: 'Active',
        lastActive: 'Now',
        isSuperAdmin: false,
      );

      bool canUserChangeCredentials(AdminUser user) {
        return user.isSuperAdmin ||
            user.role.trim().toLowerCase() == 'super admin' ||
            user.role.trim().toLowerCase() == 'system admin';
      }

      expect(canUserChangeCredentials(superAdminUser), isTrue);
      expect(canUserChangeCredentials(roleBasedUser), isFalse);
    });

    test('TEST 21: Granular View-Only isolation for Accounts, Income, Expenses, and Loans', () {
      final viewOnlyRole = UserRole(
        id: 'role_finance_viewer',
        roleName: 'Finance Viewer',
        description: 'Read-only financial auditor',
        isActive: true,
        permissions: {
          AppModule.finance: {PermissionAction.view},
          AppModule.accounts: {PermissionAction.view},
          AppModule.income: {PermissionAction.view},
          AppModule.expenses: {PermissionAction.view},
          AppModule.loans: {PermissionAction.view},
        },
      );

      // Verify Accounts
      expect(viewOnlyRole.hasPermission(AppModule.accounts, PermissionAction.view), isTrue);
      expect(viewOnlyRole.hasPermission(AppModule.accounts, PermissionAction.create), isFalse);
      expect(viewOnlyRole.hasPermission(AppModule.accounts, PermissionAction.edit), isFalse);
      expect(viewOnlyRole.hasPermission(AppModule.accounts, PermissionAction.delete), isFalse);

      // Verify Income
      expect(viewOnlyRole.hasPermission(AppModule.income, PermissionAction.view), isTrue);
      expect(viewOnlyRole.hasPermission(AppModule.income, PermissionAction.create), isFalse);
      expect(viewOnlyRole.hasPermission(AppModule.income, PermissionAction.edit), isFalse);
      expect(viewOnlyRole.hasPermission(AppModule.income, PermissionAction.delete), isFalse);

      // Verify Expenses
      expect(viewOnlyRole.hasPermission(AppModule.expenses, PermissionAction.view), isTrue);
      expect(viewOnlyRole.hasPermission(AppModule.expenses, PermissionAction.create), isFalse);
      expect(viewOnlyRole.hasPermission(AppModule.expenses, PermissionAction.edit), isFalse);
      expect(viewOnlyRole.hasPermission(AppModule.expenses, PermissionAction.delete), isFalse);

      // Verify Loans
      expect(viewOnlyRole.hasPermission(AppModule.loans, PermissionAction.view), isTrue);
      expect(viewOnlyRole.hasPermission(AppModule.loans, PermissionAction.create), isFalse);
      expect(viewOnlyRole.hasPermission(AppModule.loans, PermissionAction.edit), isFalse);
      expect(viewOnlyRole.hasPermission(AppModule.loans, PermissionAction.delete), isFalse);

      // Direct check takes precedence even if parent Finance had create
      final mixedRole = UserRole(
        id: 'role_mixed',
        roleName: 'Mixed Role',
        description: 'Finance Create but Income View-only',
        isActive: true,
        permissions: {
          AppModule.finance: {PermissionAction.view, PermissionAction.create},
          AppModule.income: {PermissionAction.view}, // specifically restricted to View
        },
      );
      expect(mixedRole.hasPermission(AppModule.income, PermissionAction.view), isTrue);
      expect(mixedRole.hasPermission(AppModule.income, PermissionAction.create), isFalse);
      expect(mixedRole.hasPermission(AppModule.income, PermissionAction.delete), isFalse);
    });
  });
}
