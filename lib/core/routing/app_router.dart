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
import '../../features/administration/users/presentation/screens/users_screen.dart';
import '../../features/administration/roles/presentation/screens/roles_screen.dart';
import '../../features/administration/settings/presentation/screens/settings_screen.dart';
import '../../features/administration/backup/presentation/screens/backup_screen.dart';
import '../../features/administration/audit_logs/presentation/screens/audit_logs_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Provider for GoRouter to allow injection and easy testing
final routerProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(adminProvider.select((state) => state.isAuthenticated));

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }
      if (isAuthenticated && isLoggingIn) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
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
                path: '/administration/users',
                builder: (context, state) => const UsersScreen(),
              ),
              GoRoute(
                path: '/administration/roles',
                builder: (context, state) => const RolesScreen(),
              ),
              GoRoute(
                path: '/administration/settings',
                builder: (context, state) => const SettingsScreen(),
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
