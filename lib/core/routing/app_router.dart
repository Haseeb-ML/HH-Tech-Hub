import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/administration/shared/providers/admin_provider.dart';

// Screens imports
import '../../features/shell/presentation/screens/shell_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/finance/ledger/presentation/screens/ledger_screen.dart';
import '../../features/finance/accounts/presentation/screens/accounts_screen.dart';
import '../../features/finance/accounts/presentation/screens/company_account_detail_screen.dart';
import '../../features/finance/income/presentation/screens/income_screen.dart';
import '../../features/finance/expenses/presentation/screens/expenses_screen.dart';
import '../../features/finance/loans/presentation/screens/loans_screen.dart';
import '../../features/finance/wallet/presentation/screens/personal_wallet_screen.dart';
import '../../features/finance/wallet/presentation/screens/personal_wallet_detail_screen.dart';
import '../../features/finance/reports/presentation/screens/financial_reports_screen.dart';
import '../../features/clients/clients/presentation/screens/clients_screen.dart';
import '../../features/clients/vendors/presentation/screens/vendors_screen.dart';
import '../../features/projects/projects/presentation/screens/projects_screen.dart';
import '../../features/projects/tasks/presentation/screens/tasks_screen.dart';
import '../../features/projects/timesheets/presentation/screens/timesheets_screen.dart';
import '../../features/hr/employees/presentation/screens/employees_screen.dart';
import '../../features/hr/employees/presentation/screens/employee_history_screen.dart';
import '../../features/hr/attendance/presentation/screens/attendance_screen.dart';
import '../../features/hr/salaries/presentation/screens/salaries_screen.dart';
import '../../features/hr/advances/presentation/screens/advances_screen.dart';
import '../../features/inventory/inventory/presentation/screens/inventory_screen.dart';
import '../../features/inventory/assets/presentation/screens/assets_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/administration/settings/presentation/screens/settings_screen.dart';
import '../../features/administration/backup/presentation/screens/backup_screen.dart';
import '../../features/administration/audit_logs/presentation/screens/audit_logs_screen.dart';
import '../../features/administration/roles/presentation/screens/roles_screen.dart';
import '../../features/administration/users/presentation/screens/users_screen.dart';
import '../widgets/access_denied_screen.dart';
import '../auth/models/app_permissions.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

String _getDefaultAllowedPath(AdminState adminState) {
  if (adminState.hasPermission(AppModule.dashboard, PermissionAction.view)) {
    return '/dashboard';
  }
  final modulePaths = [
    (AppModule.hr, '/hr/employees'),
    (AppModule.employees, '/hr/employees'),
    (AppModule.attendance, '/hr/attendance'),
    (AppModule.payroll, '/hr/salaries'),
    (AppModule.advances, '/hr/advances'),
    (AppModule.employeeHistory, '/hr/history'),
    (AppModule.finance, '/finance/income'),
    (AppModule.ledger, '/finance/ledger'),
    (AppModule.accounts, '/finance/accounts'),
    (AppModule.personalAccounts, '/finance/wallet'),
    (AppModule.income, '/finance/income'),
    (AppModule.expenses, '/finance/expenses'),
    (AppModule.loans, '/finance/loans'),
    (AppModule.financeReports, '/finance/reports'),
    (AppModule.clients, '/clients/list'),
    (AppModule.projects, '/projects/list'),
    (AppModule.projectsList, '/projects/list'),
    (AppModule.tasks, '/projects/tasks'),
    (AppModule.timesheets, '/projects/timesheets'),
    (AppModule.inventory, '/inventory/list'),
    (AppModule.officeInventory, '/inventory/list'),
    (AppModule.assets, '/inventory/assets'),
    (AppModule.reports, '/reports'),
    (AppModule.generalReports, '/reports'),
    (AppModule.administration, '/administration/settings'),
    (AppModule.systemSettings, '/administration/settings'),
    (AppModule.databaseBackup, '/administration/backup'),
    (AppModule.auditLogs, '/administration/audit_logs'),
  ];
  for (final entry in modulePaths) {
    if (adminState.hasPermission(entry.$1, PermissionAction.view)) {
      return entry.$2;
    }
  }
  return '/dashboard';
}

/// Listens strictly to authentication and active user transitions to trigger route guards
/// without tearing down or rebuilding the GoRouter navigation tree when permissions or settings change.
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<bool>(
      adminProvider.select((s) => s.isAuthenticated),
      (prev, next) {
        if (prev != next) {
          notifyListeners();
        }
      },
    );
    _ref.listen<String?>(
      adminProvider.select((s) => s.currentUser?.id),
      (prev, next) {
        if (prev != next) {
          notifyListeners();
        }
      },
    );
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

/// Provider for GoRouter to allow injection and easy testing
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.read(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: notifier,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final adminState = ref.read(adminProvider);
      final isAuthenticated = adminState.isAuthenticated;
      final currentUser = adminState.currentUser;
      final loc = state.matchedLocation;
      final isLoggingIn = loc == '/login';
      final isAccessDenied = loc == '/access-denied';

      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }
      if (isAuthenticated && isLoggingIn) {
        return _getDefaultAllowedPath(adminState);
      }
      if (!isAuthenticated || isAccessDenied) {
        return null;
      }

      // Check if user account was disabled
      if (currentUser != null && !currentUser.isActive) {
        return '/login';
      }

      // Super Admin bypasses all module restrictions
      final isSuper = currentUser != null &&
          (currentUser.isSuperAdmin ||
              currentUser.role.trim().toLowerCase() == 'super admin' ||
              currentUser.role.trim().toLowerCase() == 'system admin');
      if (isSuper) {
        return null;
      }

      // 1. Roles & Permissions, User management, and Audit Logs strictly require Super Admin
      if (loc.startsWith('/administration/roles') ||
          loc.startsWith('/administration/users') ||
          loc.startsWith('/administration/audit_logs')) {
        return '/access-denied?from=$loc';
      }

      // 2. Dashboard
      if (loc == '/dashboard') {
        if (!adminState.hasPermission(AppModule.dashboard, PermissionAction.view)) {
          final fallback = _getDefaultAllowedPath(adminState);
          if (fallback != '/dashboard') {
            return fallback;
          }
          return '/access-denied?from=$loc';
        }
      }

      // 3. Finance & Accounts sub-routes
      else if (loc.startsWith('/finance/ledger')) {
        if (!adminState.hasPermission(AppModule.ledger, PermissionAction.view) &&
            !adminState.hasPermission(AppModule.finance, PermissionAction.view)) {
          return '/access-denied?from=$loc';
        }
      } else if (loc.startsWith('/finance/wallet')) {
        if (!adminState.hasPermission(AppModule.personalAccounts, PermissionAction.view) &&
            !adminState.hasPermission(AppModule.accounts, PermissionAction.view) &&
            !adminState.hasPermission(AppModule.finance, PermissionAction.view)) {
          return '/access-denied?from=$loc';
        }
      } else if (loc.startsWith('/finance/income')) {
        if (!adminState.hasPermission(AppModule.income, PermissionAction.view) &&
            !adminState.hasPermission(AppModule.finance, PermissionAction.view)) {
          return '/access-denied?from=$loc';
        }
      } else if (loc.startsWith('/finance/expenses')) {
        if (!adminState.hasPermission(AppModule.expenses, PermissionAction.view) &&
            !adminState.hasPermission(AppModule.finance, PermissionAction.view)) {
          return '/access-denied?from=$loc';
        }
      } else if (loc.startsWith('/finance/loans')) {
        if (!adminState.hasPermission(AppModule.loans, PermissionAction.view) &&
            !adminState.hasPermission(AppModule.finance, PermissionAction.view)) {
          return '/access-denied?from=$loc';
        }
      } else if (loc.startsWith('/finance/accounts')) {
        if (!adminState.hasPermission(AppModule.accounts, PermissionAction.view) &&
            !adminState.hasPermission(AppModule.finance, PermissionAction.view)) {
          return '/access-denied?from=$loc';
        }
      } else if (loc.startsWith('/finance/reports')) {
        if (!adminState.hasPermission(AppModule.financeReports, PermissionAction.view) &&
            !adminState.hasPermission(AppModule.reports, PermissionAction.view) &&
            !adminState.hasPermission(AppModule.finance, PermissionAction.view)) {
          return '/access-denied?from=$loc';
        }
      } else if (loc.startsWith('/finance')) {
        if (!adminState.hasPermission(AppModule.finance, PermissionAction.view)) {
          if (adminState.hasPermission(AppModule.ledger, PermissionAction.view)) {
            return '/finance/ledger';
          } else if (adminState.hasPermission(AppModule.accounts, PermissionAction.view)) {
            return '/finance/accounts';
          } else if (adminState.hasPermission(AppModule.income, PermissionAction.view)) {
            return '/finance/income';
          } else if (adminState.hasPermission(AppModule.expenses, PermissionAction.view)) {
            return '/finance/expenses';
          } else if (adminState.hasPermission(AppModule.loans, PermissionAction.view)) {
            return '/finance/loans';
          } else if (adminState.hasPermission(AppModule.personalAccounts, PermissionAction.view)) {
            return '/finance/wallet';
          }
          return '/access-denied?from=$loc';
        }
      }

      // 4. Clients
      else if (loc.startsWith('/clients')) {
        if (!adminState.hasPermission(AppModule.clients, PermissionAction.view)) {
          return '/access-denied?from=$loc';
        }
      }

      // 5. Projects Sub-routes
      else if (loc.startsWith('/projects/tasks')) {
        if (!adminState.hasPermission(AppModule.tasks, PermissionAction.view) &&
            !adminState.hasPermission(AppModule.projects, PermissionAction.view)) {
          return '/access-denied?from=$loc';
        }
      } else if (loc.startsWith('/projects/timesheets')) {
        if (!adminState.hasPermission(AppModule.timesheets, PermissionAction.view) &&
            !adminState.hasPermission(AppModule.projects, PermissionAction.view)) {
          return '/access-denied?from=$loc';
        }
      } else if (loc.startsWith('/projects/list') || loc == '/projects') {
        if (!adminState.hasPermission(AppModule.projectsList, PermissionAction.view) &&
            !adminState.hasPermission(AppModule.projects, PermissionAction.view)) {
          if (adminState.hasPermission(AppModule.tasks, PermissionAction.view)) {
            return '/projects/tasks';
          } else if (adminState.hasPermission(AppModule.timesheets, PermissionAction.view)) {
            return '/projects/timesheets';
          }
          return '/access-denied?from=$loc';
        }
      }

      // 6. HR Sub-routes
      else if (loc.startsWith('/hr/advances')) {
        if (!adminState.hasPermission(AppModule.advances, PermissionAction.view) &&
            !adminState.hasPermission(AppModule.payroll, PermissionAction.view) &&
            !adminState.hasPermission(AppModule.hr, PermissionAction.view)) {
          return '/access-denied?from=$loc';
        }
      } else if (loc.startsWith('/hr/history')) {
        if (!adminState.hasPermission(AppModule.employeeHistory, PermissionAction.view) &&
            !adminState.hasPermission(AppModule.employees, PermissionAction.view) &&
            !adminState.hasPermission(AppModule.hr, PermissionAction.view)) {
          return '/access-denied?from=$loc';
        }
      } else if (loc.startsWith('/hr/employees')) {
        if (!adminState.hasPermission(AppModule.employees, PermissionAction.view) &&
            !adminState.hasPermission(AppModule.hr, PermissionAction.view)) {
          if (adminState.hasPermission(AppModule.attendance, PermissionAction.view)) {
            return '/hr/attendance';
          } else if (adminState.hasPermission(AppModule.payroll, PermissionAction.view)) {
            return '/hr/salaries';
          }
          return '/access-denied?from=$loc';
        }
      } else if (loc.startsWith('/hr/attendance')) {
        if (!adminState.hasPermission(AppModule.attendance, PermissionAction.view) &&
            !adminState.hasPermission(AppModule.hr, PermissionAction.view)) {
          return '/access-denied?from=$loc';
        }
      } else if (loc.startsWith('/hr/salaries')) {
        if (!adminState.hasPermission(AppModule.payroll, PermissionAction.view) &&
            !adminState.hasPermission(AppModule.hr, PermissionAction.view)) {
          return '/access-denied?from=$loc';
        }
      } else if (loc.startsWith('/hr')) {
        if (!adminState.hasPermission(AppModule.hr, PermissionAction.view)) {
          if (adminState.hasPermission(AppModule.employees, PermissionAction.view)) {
            return '/hr/employees';
          } else if (adminState.hasPermission(AppModule.attendance, PermissionAction.view)) {
            return '/hr/attendance';
          } else if (adminState.hasPermission(AppModule.payroll, PermissionAction.view)) {
            return '/hr/salaries';
          } else if (adminState.hasPermission(AppModule.advances, PermissionAction.view)) {
            return '/hr/advances';
          }
          return '/access-denied?from=$loc';
        }
      }

      // 7. Inventory & Assets
      else if (loc.startsWith('/inventory/assets')) {
        if (!adminState.hasPermission(AppModule.assets, PermissionAction.view) &&
            !adminState.hasPermission(AppModule.inventory, PermissionAction.view)) {
          return '/access-denied?from=$loc';
        }
      } else if (loc.startsWith('/inventory')) {
        if (!adminState.hasPermission(AppModule.officeInventory, PermissionAction.view) &&
            !adminState.hasPermission(AppModule.inventory, PermissionAction.view)) {
          return '/access-denied?from=$loc';
        }
      }

      // 8. Reports
      else if (loc.startsWith('/reports')) {
        if (!adminState.hasPermission(AppModule.generalReports, PermissionAction.view) &&
            !adminState.hasPermission(AppModule.reports, PermissionAction.view)) {
          return '/access-denied?from=$loc';
        }
      }

      // 9. Administration
      else if (loc.startsWith('/administration/backup')) {
        if (!adminState.hasPermission(AppModule.databaseBackup, PermissionAction.view)) {
          return '/access-denied?from=$loc';
        }
      } else if (loc.startsWith('/administration/audit_logs')) {
        if (!adminState.hasPermission(AppModule.auditLogs, PermissionAction.view)) {
          return '/access-denied?from=$loc';
        }
      } else if (loc.startsWith('/administration/settings') || loc.startsWith('/administration')) {
        if (!adminState.hasPermission(AppModule.systemSettings, PermissionAction.view) &&
            !adminState.hasPermission(AppModule.administration, PermissionAction.view)) {
          if (adminState.hasPermission(AppModule.databaseBackup, PermissionAction.view)) {
            return '/administration/backup';
          } else if (adminState.hasPermission(AppModule.auditLogs, PermissionAction.view)) {
            return '/administration/audit_logs';
          }
          return '/access-denied?from=$loc';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/access-denied',
        builder: (context, state) {
          final from = state.uri.queryParameters['from'];
          return AccessDeniedScreen(attemptedPath: from);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ShellScreen(navigationShell: navigationShell);
        },
        branches: [
          // 1. Dashboard Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          
          // 2. Finance & Accounts Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/finance/ledger',
                builder: (context, state) => const LedgerScreen(),
              ),
              GoRoute(
                path: '/finance/accounts',
                builder: (context, state) => const AccountsScreen(),
              ),
              GoRoute(
                path: '/finance/accounts/details/:id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return CompanyAccountDetailScreen(accountId: id);
                },
              ),
              GoRoute(
                path: '/finance/income',
                builder: (context, state) => const IncomeScreen(),
              ),
              GoRoute(
                path: '/finance/expenses',
                builder: (context, state) => const ExpensesScreen(),
              ),
              GoRoute(
                path: '/finance/loans',
                builder: (context, state) => const LoansScreen(),
              ),
              GoRoute(
                path: '/finance/wallet',
                builder: (context, state) => const PersonalWalletScreen(),
              ),
              GoRoute(
                path: '/finance/wallet/details/:id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return PersonalWalletDetailScreen(accountId: id);
                },
              ),
            ],
          ),
          
          // 3. Clients & Business Relations Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/clients/list',
                builder: (context, state) => const ClientsScreen(),
              ),
              GoRoute(
                path: '/clients/vendors',
                builder: (context, state) => const VendorsScreen(),
              ),
            ],
          ),
          
          // 4. Projects & Operations Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/projects/list',
                builder: (context, state) => const ProjectsScreen(),
              ),
              GoRoute(
                path: '/projects/tasks',
                builder: (context, state) => const TasksScreen(),
              ),
              GoRoute(
                path: '/projects/timesheets',
                builder: (context, state) => const TimesheetsScreen(),
              ),
            ],
          ),
          
          // 5. HR & Employee Management Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/hr/employees',
                builder: (context, state) => const EmployeesScreen(),
              ),
              GoRoute(
                path: '/hr/attendance',
                builder: (context, state) => const AttendanceScreen(),
              ),
              GoRoute(
                path: '/hr/salaries',
                builder: (context, state) => const SalariesScreen(),
              ),
              GoRoute(
                path: '/hr/advances',
                builder: (context, state) => const AdvancesScreen(),
              ),
              GoRoute(
                path: '/hr/history',
                builder: (context, state) => const EmployeeHistoryScreen(),
              ),
            ],
          ),
          
          // 6. Inventory & Assets Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inventory/list',
                builder: (context, state) => const InventoryScreen(),
              ),
              GoRoute(
                path: '/inventory/assets',
                builder: (context, state) => const AssetsScreen(),
              ),
            ],
          ),

          // 7. Finance Reports Branch (Right after Inventory & Assets)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/finance/reports',
                builder: (context, state) => const FinancialReportsScreen(),
              ),
            ],
          ),
          
          // 8. Reports & Analytics Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                builder: (context, state) => const ReportsScreen(),
              ),
            ],
          ),
          
          // 8. Administration & Security Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/administration/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
              GoRoute(
                path: '/administration/roles',
                builder: (context, state) => const RolesScreen(),
              ),
              GoRoute(
                path: '/administration/users',
                builder: (context, state) => const UsersScreen(),
              ),
              GoRoute(
                path: '/administration/backup',
                builder: (context, state) => const BackupScreen(),
              ),
              GoRoute(
                path: '/administration/audit_logs',
                builder: (context, state) => const AuditlogsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
