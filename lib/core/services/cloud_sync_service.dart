import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import '../config/supabase_config.dart';
import '../../features/finance/accounts/data/repositories/accounts_repository_impl.dart';
import '../../features/clients/clients/presentation/providers/clients_provider.dart';
import '../../features/projects/projects/presentation/providers/projects_provider.dart';
import '../../features/hr/employees/presentation/providers/employees_provider.dart';
import '../../features/finance/accounts/presentation/providers/accounts_provider.dart';
import '../../features/sales/sales/presentation/providers/products_provider.dart';
import '../../features/sales/sales/presentation/providers/sales_invoices_provider.dart';
import '../../features/inventory/inventory/presentation/providers/inventory_provider.dart';
import '../../features/finance/income/presentation/providers/income_provider.dart';
import '../../features/finance/expenses/presentation/providers/expenses_provider.dart';
import '../../features/finance/ledger/presentation/providers/ledger_provider.dart';
import '../../features/inventory/assets/presentation/providers/assets_provider.dart';
import '../../features/finance/loans/presentation/providers/loans_provider.dart';
import '../../features/hr/salaries/presentation/providers/salaries_provider.dart';
import '../../features/hr/advances/presentation/providers/advances_provider.dart';
import '../../features/sales/purchases/presentation/providers/purchase_orders_provider.dart';
import '../../features/hr/attendance/presentation/providers/attendance_provider.dart';
import '../../features/projects/timesheets/presentation/providers/timesheets_provider.dart';
import '../../features/projects/tasks/presentation/providers/tasks_provider.dart';
import '../../features/administration/shared/providers/admin_provider.dart';
import '../auth/data/auth_local_repository.dart';
import '../auth/models/app_permissions.dart';

enum SyncStatus { idle, syncing, success, offline, error }

class SyncState {
  final SyncStatus status;
  final DateTime? lastSyncedAt;
  final String? message;
  final int syncedCount;
  final bool isOnline;
  final bool isAutoSync;

  const SyncState({
    this.status = SyncStatus.idle,
    this.lastSyncedAt,
    this.message,
    this.syncedCount = 0,
    this.isOnline = true,
    this.isAutoSync = false,
  });

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncedAt,
    String? message,
    int? syncedCount,
    bool? isOnline,
    bool? isAutoSync,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      message: message ?? this.message,
      syncedCount: syncedCount ?? this.syncedCount,
      isOnline: isOnline ?? this.isOnline,
      isAutoSync: isAutoSync ?? this.isAutoSync,
    );
  }
}

class CloudSyncService {
  final AppDatabase db;
  Timer? _timer;
  bool _isSyncing = false;
  void Function(SyncState)? onStatusChanged;
  SyncState _currentState = const SyncState();

  // Cache to track hashes of records that have already been synced with Supabase.
  final Map<String, int> _lastSyncedHashes = {};
  static const String _hashesPreferenceKey = 'cloud_sync_hashes_v1';
  bool _hashesLoaded = false;
  bool _syncHadError = false;
  String? _lastSyncError;

  bool _isAutoSyncEnabled = false;
  bool get isAutoSyncEnabled => _isAutoSyncEnabled;

  static bool? _bankAccountsSupportsExtendedColumns;

  Future<bool> _checkBankAccountsSchema() async {
    if (_bankAccountsSupportsExtendedColumns != null) {
      return _bankAccountsSupportsExtendedColumns!;
    }
    try {
      final testUrl = Uri.parse('${SupabaseConfig.url}/rest/v1/bank_accounts?select=openingBalance&limit=1');
      final res = await _httpClient.get(testUrl, headers: {
        'apikey': SupabaseConfig.anonKey,
        'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
      }).timeout(const Duration(seconds: 4));
      _bankAccountsSupportsExtendedColumns = (res.statusCode == 200);
    } catch (_) {
      _bankAccountsSupportsExtendedColumns = false;
    }
    return _bankAccountsSupportsExtendedColumns!;
  }

  final http.Client _httpClient = http.Client();
  StreamSubscription? _dbUpdatesSub;
  Timer? _localDebounce;

  CloudSyncService(this.db);

  SyncState get currentState => _currentState;

  Future<void> _loadSyncedHashes() async {
    if (_hashesLoaded) return;
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(_hashesPreferenceKey);
    if (stored != null && stored.isNotEmpty) {
      final decoded = jsonDecode(stored) as Map<String, dynamic>;
      _lastSyncedHashes.addAll(
        decoded.map((key, value) => MapEntry(key, (value as num).toInt())),
      );
    }
    _isAutoSyncEnabled = false;
    _currentState = _currentState.copyWith(isAutoSync: false);
    _hashesLoaded = true;
  }

  Future<void> _saveSyncedHashes() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_hashesPreferenceKey, jsonEncode(_lastSyncedHashes));
  }

  Future<void> setAutoSyncEnabled(bool enabled) async {
    _isAutoSyncEnabled = false;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('cloud_sync_auto_mode', false);
    _updateState(_currentState.copyWith(isAutoSync: false));
  }

  void _updateState(SyncState newState) {
    _currentState = newState;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onStatusChanged?.call(newState);
    });
  }


  void startAutoSync({Duration interval = const Duration(seconds: 8)}) {
    _timer?.cancel();
    _timer = null;
    _localDebounce?.cancel();
    _dbUpdatesSub?.cancel();

    // Automatically push dirty local changes to Supabase whenever any local entry is added, updated, or deleted
    try {
      _dbUpdatesSub = db.tableUpdates().listen((_) {
        if (_isSyncing) return;
        _localDebounce?.cancel();
        _localDebounce = Timer(const Duration(milliseconds: 600), () {
          pushChangesOnly();
        });
      });
    } catch (_) {}
  }

  void stopAutoSync() {
    _timer?.cancel();
    _timer = null;
    _localDebounce?.cancel();
    _localDebounce = null;
    _dbUpdatesSub?.cancel();
    _dbUpdatesSub = null;
  }

  Future<void> deleteRemote(String collection, String id) async {
    try {
      final uri = Uri.parse('${SupabaseConfig.url}/rest/v1/$collection?id=eq.$id');
      await _httpClient.delete(
        uri,
        headers: {
          'apikey': SupabaseConfig.anonKey,
          'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
        },
      ).timeout(const Duration(seconds: 6));
      _lastSyncedHashes.remove('$collection:$id');
    } catch (e) {
      debugPrint('CloudSync: Delete remote error: $e');
    }
  }

  Future<void> _touchSyncMeta() async {
    try {
      final metaTouchUrl = Uri.parse('${SupabaseConfig.url}/rest/v1/sync_meta');
      await _httpClient.post(
        metaTouchUrl,
        headers: {
          'apikey': SupabaseConfig.anonKey,
          'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
          'Prefer': 'resolution=merge-duplicates',
          'Content-Type': 'application/json',
        },
        body: jsonEncode([
          {
            'id': 'status',
            'updatedAt': DateTime.now().toIso8601String(),
          }
        ]),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  Future<void> wipeCloud() async {
    final collections = [
      'clients', 'bank_accounts', 'income_records', 'expense_records', 'ledger_entries',
      'app_goals', 'loan_records', 'advance_records', 'attendance_records',
      'employees', 'salary_records', 'assets', 'inventory_items',
      'projects', 'project_tasks', 'timesheet_entries', 'purchase_orders',
      'products', 'sales_invoices'
    ];

    try {
      final headers = {
        'apikey': SupabaseConfig.anonKey,
        'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
      };
      for (final collection in collections) {
        final response = await _httpClient.get(
          Uri.parse('${SupabaseConfig.url}/rest/v1/$collection?select=id&limit=1000'),
          headers: headers,
        ).timeout(const Duration(seconds: 15));
        if (response.statusCode != 200) continue;

        final rows = jsonDecode(response.body) as List<dynamic>;
        for (final row in rows) {
          final id = row['id']?.toString();
          if (id != null && id.isNotEmpty) {
            await deleteRemote(collection, id);
          }
        }
      }
      _lastSyncedHashes.clear();
      await _saveSyncedHashes();
    } catch (e) {
      debugPrint('CloudSync: Wipe cloud error: $e');
    }
  }

  /// Lightweight push of only dirty local records to cloud.
  /// Does NOT pull remote data and does NOT perform any SQLite writes,
  /// preventing recursive tableUpdates triggers and avoiding any app UI lag.
  Future<int> pushChangesOnly() async {
    if (_isSyncing) return 0;

    _isSyncing = true;
    try {
      await _loadSyncedHashes();
      final accountMetaMap = await AccountsRepositoryImpl.getGlobalMetaMap();

      final pushTasks = <Future<int> Function()>[
        // 1. Clients
        () => _pushTableOnly<ClientsTableData>(
          collection: 'clients',
          table: db.clientsTable,
          getAllLocal: () => db.select(db.clientsTable).get(),
          getId: (c) => c.id,
          toJson: (c) => c.toJson(),
        ),

        // 2. Bank Accounts
        () => _pushTableOnly<BankAccountsTableData>(
          collection: 'bank_accounts',
          table: db.bankAccountsTable,
          getAllLocal: () => db.select(db.bankAccountsTable).get(),
          getId: (a) => a.id,
          toJson: (a) {
            final json = a.toJson();
            final meta = (accountMetaMap[a.id] as Map<String, dynamic>?) ?? {};
            json['accountScope'] = meta['accountScope'] ?? 'Company';
            json['openingBalance'] = (meta['openingBalance'] as num?)?.toDouble() ?? 0.0;
            json['openingBalanceDate'] = meta['openingBalanceDate'] ?? '';
            json['ownerName'] = meta['ownerName'] ?? '';
            return json;
          },
        ),

        // 3. Expense Records
        () => _pushTableOnly<ExpenseRecordsTableData>(
          collection: 'expense_records',
          table: db.expenseRecordsTable,
          getAllLocal: () => db.select(db.expenseRecordsTable).get(),
          getId: (e) => e.id,
          toJson: (e) => e.toJson(),
        ),

        // 4. Income Records
        () => _pushTableOnly<IncomeRecordsTableData>(
          collection: 'income_records',
          table: db.incomeRecordsTable,
          getAllLocal: () => db.select(db.incomeRecordsTable).get(),
          getId: (i) => i.id,
          toJson: (i) => i.toJson(),
        ),

        // 5. Ledger Entries
        () => _pushTableOnly<LedgerEntriesTableData>(
          collection: 'ledger_entries',
          table: db.ledgerEntriesTable,
          getAllLocal: () => db.select(db.ledgerEntriesTable).get(),
          getId: (l) => l.id,
          toJson: (l) => l.toJson(),
        ),

        // 6. Loan Records
        () => _pushTableOnly<LoanRecordsTableData>(
          collection: 'loan_records',
          table: db.loanRecordsTable,
          getAllLocal: () => db.select(db.loanRecordsTable).get(),
          getId: (l) => l.id,
          toJson: (l) => l.toJson(),
        ),

        // 7. Advance Records
        () => _pushTableOnly<AdvanceRecordsTableData>(
          collection: 'advance_records',
          table: db.advanceRecordsTable,
          getAllLocal: () => db.select(db.advanceRecordsTable).get(),
          getId: (a) => a.id,
          toJson: (a) => a.toJson(),
        ),

        // 8. Attendance Records
        () => _pushTableOnly<AttendanceRecordsTableData>(
          collection: 'attendance_records',
          table: db.attendanceRecordsTable,
          getAllLocal: () => db.select(db.attendanceRecordsTable).get(),
          getId: (a) => a.id,
          toJson: (a) => a.toJson(),
        ),

        // 9. Employees
        () => _pushTableOnly<EmployeesTableData>(
          collection: 'employees',
          table: db.employeesTable,
          getAllLocal: () => db.select(db.employeesTable).get(),
          getId: (e) => e.id,
          toJson: (e) => e.toJson(),
        ),

        // 10. Salary Records
        () => _pushTableOnly<SalaryRecordsTableData>(
          collection: 'salary_records',
          table: db.salaryRecordsTable,
          getAllLocal: () => db.select(db.salaryRecordsTable).get(),
          getId: (s) => s.id,
          toJson: (s) => s.toJson(),
        ),

        // 11. Assets
        () => _pushTableOnly<AssetsTableData>(
          collection: 'assets',
          table: db.assetsTable,
          getAllLocal: () => db.select(db.assetsTable).get(),
          getId: (a) => a.id,
          toJson: (a) => a.toJson(),
        ),

        // 12. Inventory Items
        () => _pushTableOnly<InventoryItemsTableData>(
          collection: 'inventory_items',
          table: db.inventoryItemsTable,
          getAllLocal: () => db.select(db.inventoryItemsTable).get(),
          getId: (i) => i.id,
          toJson: (i) => i.toJson(),
        ),

        // 13. Projects
        () => _pushTableOnly<ProjectsTableData>(
          collection: 'projects',
          table: db.projectsTable,
          getAllLocal: () => db.select(db.projectsTable).get(),
          getId: (p) => p.id,
          toJson: (p) => p.toJson(),
        ),

        // 14. Project Tasks
        () => _pushTableOnly<ProjectTasksTableData>(
          collection: 'project_tasks',
          table: db.projectTasksTable,
          getAllLocal: () => db.select(db.projectTasksTable).get(),
          getId: (t) => t.id,
          toJson: (t) => t.toJson(),
        ),

        // 15. Timesheet Entries
        () => _pushTableOnly<TimesheetEntriesTableData>(
          collection: 'timesheet_entries',
          table: db.timesheetEntriesTable,
          getAllLocal: () => db.select(db.timesheetEntriesTable).get(),
          getId: (t) => t.id,
          toJson: (t) => t.toJson(),
        ),

        // 16. Purchase Orders
        () => _pushTableOnly<PurchaseOrdersTableData>(
          collection: 'purchase_orders',
          table: db.purchaseOrdersTable,
          getAllLocal: () => db.select(db.purchaseOrdersTable).get(),
          getId: (p) => p.id,
          toJson: (p) => p.toJson(),
        ),

        // 17. Products
        () => _pushTableOnly<ProductsTableData>(
          collection: 'products',
          table: db.productsTable,
          getAllLocal: () => db.select(db.productsTable).get(),
          getId: (p) => p.id,
          toJson: (p) => p.toJson(),
        ),

        // 18. Sales Invoices
        () => _pushTableOnly<SalesInvoicesTableData>(
          collection: 'sales_invoices',
          table: db.salesInvoicesTable,
          getAllLocal: () => db.select(db.salesInvoicesTable).get(),
          getId: (s) => s.id,
          toJson: (s) => s.toJson(),
        ),

        // 19. App Users
        () => _syncAppUsers(forcePush: false),

        // 20. App Roles
        () => _syncAppRoles(forcePush: false),
      ];

      int totalPushed = 0;
      for (final task in pushTasks) {
        if (!_isSyncing) break;
        try {
          final count = await task();
          totalPushed += count;
        } catch (e) {
          debugPrint('CloudSync push task error: $e');
        }
        await Future.delayed(const Duration(milliseconds: 5));
      }

      if (totalPushed > 0) {
        await _saveSyncedHashes();
        await _touchSyncMeta();
        debugPrint('CloudSync: Auto-pushed $totalPushed local changes to cloud.');
      }
      return totalPushed;
    } catch (e) {
      debugPrint('CloudSync: Auto push failed: $e');
      return 0;
    } finally {
      _isSyncing = false;
    }
  }

  /// Convenience alias to push dirty records to Supabase
  Future<void> syncToCloud() async {
    await pushChangesOnly();
  }

  Future<void> syncAll({bool forcePush = false}) async {
    if (_isSyncing) return;

    _isSyncing = true;
    Timer? syncTimeout;
    await _loadSyncedHashes();
    _syncHadError = false;
    _lastSyncError = null;

    _updateState(_currentState.copyWith(
      status: SyncStatus.syncing,
      message: 'Syncing with Supabase Cloud...',
    ));

    syncTimeout = Timer(const Duration(seconds: 40), () {
      if (_isSyncing) {
        _isSyncing = false;
        _updateState(_currentState.copyWith(
          status: SyncStatus.offline,
          message: 'Cloud sync timed out. Operating safely in local mode.',
          isOnline: false,
        ));
      }
    });

    try {
      int totalSynced = 0;
      final accountMetaMap = await AccountsRepositoryImpl.getGlobalMetaMap();

      // Sequential synchronization with strict type-safety across all tables
      final syncTasks = <Future<int> Function()>[
        // 1. Clients
        () => _syncTable<ClientsTableData>(
          collection: 'clients',
          table: db.clientsTable,
          getAllLocal: () => db.select(db.clientsTable).get(),
          getId: (c) => c.id,
          toJson: (c) => c.toJson(),
          fromJson: (m) {
            m['notes'] = m['notes']?.toString();
            return ClientsTableData.fromJson(m);
          },
          forcePush: forcePush,
        ),

        // 2. Bank Accounts
        () => _syncTable<BankAccountsTableData>(
          collection: 'bank_accounts',
          table: db.bankAccountsTable,
          getAllLocal: () => db.select(db.bankAccountsTable).get(),
          getId: (a) => a.id,
          toJson: (a) {
            final json = a.toJson();
            final meta = (accountMetaMap[a.id] as Map<String, dynamic>?) ?? {};
            json['accountScope'] = meta['accountScope'] ?? 'Company';
            json['openingBalance'] = (meta['openingBalance'] as num?)?.toDouble() ?? 0.0;
            json['openingBalanceDate'] = meta['openingBalanceDate'] ?? '';
            json['ownerName'] = meta['ownerName'] ?? '';
            return json;
          },
          fromJson: (m) {
            m['balance'] = (m['balance'] as num?)?.toDouble() ?? 0.0;
            return BankAccountsTableData.fromJson(m);
          },
          onItemPulled: (m) async {
            final id = m['id']?.toString() ?? '';
            if (id.isNotEmpty) {
              final currentMeta = await AccountsRepositoryImpl.getGlobalMetaMap();
              final existing = (currentMeta[id] as Map<String, dynamic>?) ?? {};
              final name = m['name']?.toString() ?? '';
              final isPersonal = (existing['accountScope']?.toString().toLowerCase() == 'personal') ||
                  (m['accountScope']?.toString().toLowerCase() == 'personal') ||
                  id.toLowerCase().contains('personal') ||
                  name.toLowerCase().contains('personal');
              final balance = (m['balance'] as num?)?.toDouble() ?? 0.0;
              final opening = (m['openingBalance'] as num?)?.toDouble() ??
                  (existing['openingBalance'] as num?)?.toDouble() ??
                  (balance > 0 ? balance : 0.0);
              final rawOwner = m['ownerName']?.toString() ?? existing['ownerName']?.toString() ?? '';
              final owner = rawOwner.isNotEmpty
                  ? rawOwner
                  : (isPersonal ? name.replaceAll(RegExp(r'Personal\s*Account', caseSensitive: false), '').trim() : '');

              currentMeta[id] = {
                'accountScope': isPersonal ? 'Personal' : 'Company',
                'openingBalance': opening,
                'openingBalanceDate': m['openingBalanceDate'] ?? existing['openingBalanceDate'] ?? '',
                'ownerName': owner,
              };
              await AccountsRepositoryImpl.saveGlobalMetaMap(currentMeta);
            }
          },
          forcePush: forcePush,
        ),

        // 3. Expense Records
        () => _syncTable<ExpenseRecordsTableData>(
          collection: 'expense_records',
          table: db.expenseRecordsTable,
          getAllLocal: () => db.select(db.expenseRecordsTable).get(),
          getId: (e) => e.id,
          toJson: (e) => e.toJson(),
          fromJson: (m) {
            m['amount'] = (m['amount'] as num?)?.toDouble() ?? 0.0;
            m['isPersonalExpense'] = m['isPersonalExpense'] == true;
            return ExpenseRecordsTableData.fromJson(m);
          },
          forcePush: forcePush,
        ),

        // 4. Income Records
        () => _syncTable<IncomeRecordsTableData>(
          collection: 'income_records',
          table: db.incomeRecordsTable,
          getAllLocal: () => db.select(db.incomeRecordsTable).get(),
          getId: (i) => i.id,
          toJson: (i) => i.toJson(),
          fromJson: (m) {
            m['amount'] = (m['amount'] as num?)?.toDouble() ?? 0.0;
            return IncomeRecordsTableData.fromJson(m);
          },
          forcePush: forcePush,
        ),

        // 5. Ledger Entries
        () => _syncTable<LedgerEntriesTableData>(
          collection: 'ledger_entries',
          table: db.ledgerEntriesTable,
          getAllLocal: () => db.select(db.ledgerEntriesTable).get(),
          getId: (l) => l.id,
          toJson: (l) => l.toJson(),
          fromJson: (m) {
            m['amount'] = (m['amount'] as num?)?.toDouble() ?? 0.0;
            return LedgerEntriesTableData.fromJson(m);
          },
          forcePush: forcePush,
        ),

        // 6. Loan Records
        () => _syncTable<LoanRecordsTableData>(
          collection: 'loan_records',
          table: db.loanRecordsTable,
          getAllLocal: () => db.select(db.loanRecordsTable).get(),
          getId: (l) => l.id,
          toJson: (l) => l.toJson(),
          fromJson: (m) {
            m['amount'] = (m['amount'] as num?)?.toDouble() ?? 0.0;
            m['remainingBalance'] = (m['remainingBalance'] as num?)?.toDouble() ?? 0.0;
            if (m['repayments'] is List) {
              m['repayments'] = (m['repayments'] as List)
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList();
            } else {
              m['repayments'] = <Map<String, dynamic>>[];
            }
            return LoanRecordsTableData.fromJson(m);
          },
          forcePush: forcePush,
        ),

        // 7. Advance Records
        () => _syncTable<AdvanceRecordsTableData>(
          collection: 'advance_records',
          table: db.advanceRecordsTable,
          getAllLocal: () => db.select(db.advanceRecordsTable).get(),
          getId: (a) => a.id,
          toJson: (a) => a.toJson(),
          fromJson: (m) {
            m['amount'] = (m['amount'] as num?)?.toDouble() ?? 0.0;
            m['amountRepaid'] = (m['amountRepaid'] as num?)?.toDouble() ?? 0.0;
            m['repaymentMonths'] = (m['repaymentMonths'] as num?)?.toInt() ?? 1;
            return AdvanceRecordsTableData.fromJson(m);
          },
          forcePush: forcePush,
        ),

        // 8. Attendance Records
        () => _syncTable<AttendanceRecordsTableData>(
          collection: 'attendance_records',
          table: db.attendanceRecordsTable,
          getAllLocal: () => db.select(db.attendanceRecordsTable).get(),
          getId: (a) => a.id,
          toJson: (a) => a.toJson(),
          fromJson: (m) {
            m['checkIn'] = m['checkIn']?.toString();
            m['checkOut'] = m['checkOut']?.toString();
            m['notes'] = m['notes']?.toString();
            return AttendanceRecordsTableData.fromJson(m);
          },
          forcePush: forcePush,
        ),

        // 9. Employees
        () => _syncTable<EmployeesTableData>(
          collection: 'employees',
          table: db.employeesTable,
          getAllLocal: () => db.select(db.employeesTable).get(),
          getId: (e) => e.id,
          toJson: (e) => e.toJson(),
          fromJson: (m) {
            if (m['phones'] is List) {
              m['phones'] = (m['phones'] as List).map((e) => e.toString()).toList();
            } else if (m['phones'] is String && (m['phones'] as String).isNotEmpty) {
              m['phones'] = [m['phones'].toString()];
            } else {
              m['phones'] = <String>[];
            }
            m['baseSalary'] = (m['baseSalary'] as num?)?.toDouble() ?? 0.0;
            m['leavingDate'] = m['leavingDate']?.toString();
            return EmployeesTableData.fromJson(m);
          },
          forcePush: forcePush,
        ),

        // 10. Salary Records
        () => _syncTable<SalaryRecordsTableData>(
          collection: 'salary_records',
          table: db.salaryRecordsTable,
          getAllLocal: () => db.select(db.salaryRecordsTable).get(),
          getId: (s) => s.id,
          toJson: (s) => s.toJson(),
          fromJson: (m) {
            m['baseSalary'] = (m['baseSalary'] as num?)?.toDouble() ?? 0.0;
            m['allowances'] = (m['allowances'] as num?)?.toDouble() ?? 0.0;
            m['deductions'] = (m['deductions'] as num?)?.toDouble() ?? 0.0;
            m['netPaid'] = (m['netPaid'] as num?)?.toDouble() ?? 0.0;
            return SalaryRecordsTableData.fromJson(m);
          },
          forcePush: forcePush,
        ),

        // 11. Assets
        () => _syncTable<AssetsTableData>(
          collection: 'assets',
          table: db.assetsTable,
          getAllLocal: () => db.select(db.assetsTable).get(),
          getId: (a) => a.id,
          toJson: (a) => a.toJson(),
          fromJson: (m) {
            m['cost'] = (m['cost'] as num?)?.toDouble() ?? 0.0;
            m['assignedToId'] = m['assignedToId']?.toString();
            m['assignedToName'] = m['assignedToName']?.toString();
            return AssetsTableData.fromJson(m);
          },
          forcePush: forcePush,
        ),

        // 12. Inventory Items
        () => _syncTable<InventoryItemsTableData>(
          collection: 'inventory_items',
          table: db.inventoryItemsTable,
          getAllLocal: () => db.select(db.inventoryItemsTable).get(),
          getId: (i) => i.id,
          toJson: (i) => i.toJson(),
          fromJson: (m) {
            m['quantity'] = (m['quantity'] as num?)?.toInt() ?? 0;
            m['minQuantity'] = (m['minQuantity'] as num?)?.toInt() ?? 0;
            m['pricePerUnit'] = (m['pricePerUnit'] as num?)?.toDouble() ?? 0.0;
            return InventoryItemsTableData.fromJson(m);
          },
          forcePush: forcePush,
        ),

        // 13. Projects
        () => _syncTable<ProjectsTableData>(
          collection: 'projects',
          table: db.projectsTable,
          getAllLocal: () => db.select(db.projectsTable).get(),
          getId: (p) => p.id,
          toJson: (p) => p.toJson(),
          fromJson: (m) {
            m['budget'] = (m['budget'] as num?)?.toDouble() ?? 0.0;
            m['advancedPayment'] = (m['advancedPayment'] as num?)?.toDouble() ?? 0.0;
            m['partialPayments'] = (m['partialPayments'] as num?)?.toDouble() ?? 0.0;
            m['finalPayment'] = (m['finalPayment'] as num?)?.toDouble() ?? 0.0;
            if (m['teamMembers'] is List) {
              m['teamMembers'] = (m['teamMembers'] as List).map((e) => e.toString()).toList();
            } else {
              m['teamMembers'] = <String>[];
            }
            return ProjectsTableData.fromJson(m);
          },
          forcePush: forcePush,
        ),

        // 14. Project Tasks
        () => _syncTable<ProjectTasksTableData>(
          collection: 'project_tasks',
          table: db.projectTasksTable,
          getAllLocal: () => db.select(db.projectTasksTable).get(),
          getId: (t) => t.id,
          toJson: (t) => t.toJson(),
          fromJson: (m) => ProjectTasksTableData.fromJson(m),
          forcePush: forcePush,
        ),

        // 15. Timesheet Entries
        () => _syncTable<TimesheetEntriesTableData>(
          collection: 'timesheet_entries',
          table: db.timesheetEntriesTable,
          getAllLocal: () => db.select(db.timesheetEntriesTable).get(),
          getId: (t) => t.id,
          toJson: (t) => t.toJson(),
          fromJson: (m) {
            m['hours'] = (m['hours'] as num?)?.toDouble() ?? 0.0;
            return TimesheetEntriesTableData.fromJson(m);
          },
          forcePush: forcePush,
        ),

        // 16. Purchase Orders
        () => _syncTable<PurchaseOrdersTableData>(
          collection: 'purchase_orders',
          table: db.purchaseOrdersTable,
          getAllLocal: () => db.select(db.purchaseOrdersTable).get(),
          getId: (p) => p.id,
          toJson: (p) => p.toJson(),
          fromJson: (m) {
            m['subtotal'] = (m['subtotal'] as num?)?.toDouble() ?? 0.0;
            m['tax'] = (m['tax'] as num?)?.toDouble() ?? 0.0;
            m['total'] = (m['total'] as num?)?.toDouble() ?? 0.0;
            if (m['items'] is List) {
              m['items'] = (m['items'] as List)
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList();
            } else {
              m['items'] = <Map<String, dynamic>>[];
            }
            return PurchaseOrdersTableData.fromJson(m);
          },
          forcePush: forcePush,
        ),

        // 17. Products
        () => _syncTable<ProductsTableData>(
          collection: 'products',
          table: db.productsTable,
          getAllLocal: () => db.select(db.productsTable).get(),
          getId: (p) => p.id,
          toJson: (p) => p.toJson(),
          fromJson: (m) {
            m['price'] = (m['price'] as num?)?.toDouble() ?? 0.0;
            return ProductsTableData.fromJson(m);
          },
          forcePush: forcePush,
        ),

        // 18. Sales Invoices
        () => _syncTable<SalesInvoicesTableData>(
          collection: 'sales_invoices',
          table: db.salesInvoicesTable,
          getAllLocal: () => db.select(db.salesInvoicesTable).get(),
          getId: (s) => s.id,
          toJson: (s) => s.toJson(),
          fromJson: (m) {
            m['subtotal'] = (m['subtotal'] as num?)?.toDouble() ?? 0.0;
            m['tax'] = (m['tax'] as num?)?.toDouble() ?? 0.0;
            m['total'] = (m['total'] as num?)?.toDouble() ?? 0.0;
            if (m['items'] is List) {
              m['items'] = (m['items'] as List)
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList();
            } else {
              m['items'] = <Map<String, dynamic>>[];
            }
            return SalesInvoicesTableData.fromJson(m);
          },
          forcePush: forcePush,
        ),

        // 19. App Users
        () => _syncAppUsers(forcePush: forcePush),

        // 20. App Roles
        () => _syncAppRoles(forcePush: forcePush),
      ];

      for (final task in syncTasks) {
        if (!_isSyncing) break;
        try {
          final count = await task();
          totalSynced += count;
        } catch (e) {
          debugPrint('CloudSync table task error: $e');
        }
        await Future.delayed(const Duration(milliseconds: 10));
      }

      await _saveSyncedHashes();
      if (totalSynced > 0 || forcePush) {
        await _touchSyncMeta();
      }

      if (_syncHadError) {
        _updateState(_currentState.copyWith(
          status: SyncStatus.offline,
          lastSyncedAt: DateTime.now(),
          message: _lastSyncError ?? 'Cloud sync paused. Using local storage.',
          syncedCount: totalSynced,
          isOnline: false,
        ));
      } else {
        _updateState(_currentState.copyWith(
          status: SyncStatus.success,
          lastSyncedAt: DateTime.now(),
          message: 'Synchronized with Supabase Cloud',
          syncedCount: totalSynced,
          isOnline: true,
        ));
      }
    } catch (e) {
      debugPrint('CloudSync Error: $e');
      if (e.toString().contains('database after closing') ||
          e.toString().contains("Can't re-open a database")) {
        stopAutoSync();
      }
      _updateState(_currentState.copyWith(
        status: SyncStatus.offline,
        message: 'Cloud Sync paused (Offline mode active)',
        isOnline: false,
      ));
    } finally {
      syncTimeout.cancel();
      _isSyncing = false;
    }
  }

  Future<int> _syncAppUsers({bool forcePush = false}) async {
    final authRepo = AuthLocalRepository(db);
    final headers = {
      'apikey': SupabaseConfig.anonKey,
      'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
      'Content-Type': 'application/json',
    };
    int count = 0;
    try {
      final localUsers = await authRepo.getAllUsers();
      final localMap = {for (var u in localUsers) u.id: u};

      // 1. Pull remote users from Supabase if online (skipped on force push)
      if (!forcePush) {
        try {
          final getUrl = Uri.parse('${SupabaseConfig.url}/rest/v1/app_users?select=*');
          final res = await _httpClient.get(getUrl, headers: headers).timeout(const Duration(seconds: 8));
          if (res.statusCode == 200) {
            final remoteList = jsonDecode(res.body) as List<dynamic>;
            for (final item in remoteList) {
              final map = item as Map<String, dynamic>;
              final id = map['id']?.toString() ?? '';
              if (id.isEmpty) continue;
              final remoteRecord = AdminUserRecord.fromMap(map);
              final local = localMap[id];
              if (local == null) {
                await db.customStatement('''
                  INSERT OR REPLACE INTO app_users (id, full_name, username, email, password_hash, salt, role, is_active, is_super_admin, last_active, created_at)
                  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ''', [
                  remoteRecord.id,
                  remoteRecord.fullName,
                  remoteRecord.username,
                  remoteRecord.email,
                  remoteRecord.passwordHash,
                  remoteRecord.salt,
                  remoteRecord.role,
                  remoteRecord.isActive ? 1 : 0,
                  remoteRecord.isSuperAdmin ? 1 : 0,
                  remoteRecord.lastActive,
                  remoteRecord.createdAt,
                ]);
                count++;
              }
            }
          }
        } catch (_) {}
      }

      // 2. Push local users to Supabase
      final updatedLocal = await authRepo.getAllUsers();
      if (updatedLocal.isNotEmpty) {
        final pushUrl = Uri.parse('${SupabaseConfig.url}/rest/v1/app_users');
        final rowsToPush = updatedLocal.map((u) => u.toSupabaseMap()).toList();
        final pushRes = await _httpClient.post(
          pushUrl,
          headers: {
            ...headers,
            'Prefer': 'resolution=merge-duplicates',
          },
          body: jsonEncode(rowsToPush),
        ).timeout(const Duration(seconds: 8));

        if (pushRes.statusCode == 200 || pushRes.statusCode == 201) {
          count += rowsToPush.length;
        }
      }
    } catch (e) {
      debugPrint('CloudSync: app_users sync notice: $e');
    }
    return count;
  }

  Future<int> _syncAppRoles({bool forcePush = false}) async {
    final authRepo = AuthLocalRepository(db);
    final headers = {
      'apikey': SupabaseConfig.anonKey,
      'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
      'Content-Type': 'application/json',
    };
    int count = 0;
    try {
      // 1. Pull remote roles from Supabase if online (skipped on force push)
      if (!forcePush) {
        try {
          final getUrl = Uri.parse('${SupabaseConfig.url}/rest/v1/app_roles?select=*');
          final res = await _httpClient.get(getUrl, headers: headers).timeout(const Duration(seconds: 8));
          if (res.statusCode == 200) {
            final remoteList = jsonDecode(res.body) as List<dynamic>;
            for (final item in remoteList) {
              final map = item as Map<String, dynamic>;
              final id = map['id']?.toString() ?? '';
              if (id.isEmpty) continue;
              final remoteRole = UserRole.fromMap(map);
              await authRepo.saveCustomRole(remoteRole);
              count++;
            }
          }
        } catch (_) {}
      }

      // 2. Push local roles to Supabase
      final updatedRoles = await authRepo.getAllRoles();
      if (updatedRoles.isNotEmpty) {
        final pushUrl = Uri.parse('${SupabaseConfig.url}/rest/v1/app_roles');
        var rowsToPush = updatedRoles.map((r) => r.toSupabaseMap(includeExtended: true)).toList();
        var pushRes = await _httpClient.post(
          pushUrl,
          headers: {
            ...headers,
            'Prefer': 'resolution=merge-duplicates',
          },
          body: jsonEncode(rowsToPush),
        ).timeout(const Duration(seconds: 8));

        // If Supabase table doesn't have extended columns, fallback to base columns
        if (pushRes.statusCode != 200 && pushRes.statusCode != 201) {
          rowsToPush = updatedRoles.map((r) => r.toSupabaseMap(includeExtended: false)).toList();
          pushRes = await _httpClient.post(
            pushUrl,
            headers: {
              ...headers,
              'Prefer': 'resolution=merge-duplicates',
            },
            body: jsonEncode(rowsToPush),
          ).timeout(const Duration(seconds: 8));
        }

        if (pushRes.statusCode == 200 || pushRes.statusCode == 201) {
          count += rowsToPush.length;
        }
      }
    } catch (e) {
      debugPrint('CloudSync: app_roles sync notice: $e');
    }
    return count;
  }

  Future<int> _pushTableOnly<T>({
    required String collection,
    required dynamic table,
    required Future<List<T>> Function() getAllLocal,
    required String Function(T) getId,
    required Map<String, dynamic> Function(T) toJson,
  }) async {
    return await _pushTableSupabase<T>(
      tableName: collection,
      getAllLocal: getAllLocal,
      getId: getId,
      toJson: toJson,
    );
  }

  Future<int> _pushTableSupabase<T>({
    required String tableName,
    required Future<List<T>> Function() getAllLocal,
    required String Function(T) getId,
    required Map<String, dynamic> Function(T) toJson,
  }) async {
    int syncedCount = 0;
    final headers = {
      'apikey': SupabaseConfig.anonKey,
      'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
      'Content-Type': 'application/json',
    };

    try {
      final localRows = await getAllLocal();
      final rowsToPush = <Map<String, dynamic>>[];
      final newHashes = <String, int>{};
      final localIds = <String>{};

      final bool bankAccountsHasExtended = (tableName == 'bank_accounts')
          ? await _checkBankAccountsSchema()
          : false;

      for (final item in localRows) {
        final id = getId(item);
        if (id.isEmpty) continue;
        localIds.add(id);

        final rawMap = Map<String, dynamic>.from(toJson(item));

        if (tableName == 'bank_accounts' && !bankAccountsHasExtended) {
          rawMap.remove('accountScope');
          rawMap.remove('openingBalance');
          rawMap.remove('openingBalanceDate');
          rawMap.remove('ownerName');
        }

        for (final key in ['phones', 'teamMembers', 'items', 'repayments']) {
          if (rawMap[key] is String && (rawMap[key] as String).startsWith('[')) {
            try {
              rawMap[key] = jsonDecode(rawMap[key] as String);
            } catch (_) {}
          }
        }

        final localHash = jsonEncode(rawMap).hashCode;
        final lastHash = _lastSyncedHashes['$tableName:$id'];

        if (lastHash == null || lastHash != localHash) {
          rowsToPush.add(rawMap);
          newHashes['$tableName:$id'] = localHash;
        }
      }

      if (rowsToPush.isNotEmpty) {
        final pushUrl = Uri.parse('${SupabaseConfig.url}/rest/v1/$tableName');
        for (var i = 0; i < rowsToPush.length; i += 100) {
          final chunk = rowsToPush.sublist(
            i,
            (i + 100 > rowsToPush.length) ? rowsToPush.length : i + 100,
          );
          final pushRes = await _httpClient.post(
            pushUrl,
            headers: {
              ...headers,
              'Prefer': 'resolution=merge-duplicates',
            },
            body: jsonEncode(chunk),
          ).timeout(const Duration(seconds: 8));

          if (pushRes.statusCode == 200 || pushRes.statusCode == 201) {
            syncedCount += chunk.length;
            _lastSyncedHashes.addAll(newHashes);
          } else {
            debugPrint('Supabase auto-push warning on $tableName: ${pushRes.statusCode}');
          }
        }
      }

      // Propagate locally deleted rows that were previously synced
      final deletedKeys = <String>[];
      for (final entry in _lastSyncedHashes.entries) {
        if (entry.key.startsWith('$tableName:')) {
          final id = entry.key.substring('$tableName:'.length);
          if (!localIds.contains(id)) {
            deletedKeys.add(entry.key);
            await deleteRemote(tableName, id);
          }
        }
      }
      for (final k in deletedKeys) {
        _lastSyncedHashes.remove(k);
      }
    } catch (e) {
      debugPrint('CloudSync: Auto push table error on $tableName: $e');
    }

    return syncedCount;
  }

  Future<int> _syncTable<T>({
    required String collection,
    required dynamic table,
    required Future<List<T>> Function() getAllLocal,
    required String Function(T) getId,
    required Map<String, dynamic> Function(T) toJson,
    required T Function(Map<String, dynamic>) fromJson,
    Future<void> Function(Map<String, dynamic>)? onItemPulled,
    bool forcePush = false,
  }) async {
    return await _syncTableSupabase<T>(
      tableName: collection,
      table: table,
      getAllLocal: getAllLocal,
      getId: getId,
      toJson: toJson,
      fromJson: fromJson,
      onItemPulled: onItemPulled,
      forcePush: forcePush,
    );
  }

  Future<int> _syncTableSupabase<T>({
    required String tableName,
    required dynamic table,
    required Future<List<T>> Function() getAllLocal,
    required String Function(T) getId,
    required Map<String, dynamic> Function(T) toJson,
    required T Function(Map<String, dynamic>) fromJson,
    Future<void> Function(Map<String, dynamic>)? onItemPulled,
    bool forcePush = false,
  }) async {
    int syncedCount = 0;
    final headers = {
      'apikey': SupabaseConfig.anonKey,
      'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
      'Content-Type': 'application/json',
    };

    try {
      // 1. PUSH local rows to Supabase FIRST
      final localRows = await getAllLocal();
      final rowsToPush = <Map<String, dynamic>>[];
      final dirtyLocalIds = <String>{};
      final newHashes = <String, int>{};

      final bool bankAccountsHasExtended = (tableName == 'bank_accounts')
          ? await _checkBankAccountsSchema()
          : false;

      for (final item in localRows) {
        final id = getId(item);
        if (id.isEmpty) continue;

        final rawMap = Map<String, dynamic>.from(toJson(item));

        // For bank_accounts, strip client-only metadata fields only if schema does not support them yet
        if (tableName == 'bank_accounts' && !bankAccountsHasExtended) {
          rawMap.remove('accountScope');
          rawMap.remove('openingBalance');
          rawMap.remove('openingBalanceDate');
          rawMap.remove('ownerName');
        }

        // Ensure lists aren't string-encoded for JSONB columns
        for (final key in ['phones', 'teamMembers', 'items', 'repayments']) {
          if (rawMap[key] is String && (rawMap[key] as String).startsWith('[')) {
            try {
              rawMap[key] = jsonDecode(rawMap[key] as String);
            } catch (_) {}
          }
        }

        final localHash = jsonEncode(rawMap).hashCode;
        final lastHash = _lastSyncedHashes['$tableName:$id'];

        if (forcePush || lastHash == null || lastHash != localHash) {
          rowsToPush.add(rawMap);
          dirtyLocalIds.add(id);
          newHashes['$tableName:$id'] = localHash;
        }
      }

      if (rowsToPush.isNotEmpty) {
        final pushUrl = Uri.parse('${SupabaseConfig.url}/rest/v1/$tableName');
        for (var i = 0; i < rowsToPush.length; i += 100) {
          final chunk = rowsToPush.sublist(
            i,
            (i + 100 > rowsToPush.length) ? rowsToPush.length : i + 100,
          );
          final pushRes = await _httpClient.post(
            pushUrl,
            headers: {
              ...headers,
              'Prefer': 'resolution=merge-duplicates',
            },
            body: jsonEncode(chunk),
          ).timeout(const Duration(seconds: 8));

          if (pushRes.statusCode == 200 || pushRes.statusCode == 201) {
            syncedCount += chunk.length;
            _lastSyncedHashes.addAll(newHashes);
          } else {
            debugPrint('Supabase push error on $tableName: ${pushRes.statusCode} - ${pushRes.body}');
            _syncHadError = true;
            _lastSyncError = 'Supabase sync warning on $tableName';
          }
        }
      }

      // 2. PULL from Supabase SECOND (skipped during Force Push to avoid heavy SQLite locks and freezing)
      if (!forcePush) {
        final pullUrl = Uri.parse('${SupabaseConfig.url}/rest/v1/$tableName?select=*');
        final res = await _httpClient.get(pullUrl, headers: headers).timeout(const Duration(seconds: 8));

        final remoteDocIds = <String>{};
        if (res.statusCode == 200) {
          final remoteRows = jsonDecode(res.body) as List<dynamic>;
          for (final row in remoteRows) {
            final map = Map<String, dynamic>.from(row as Map);
            final id = map['id']?.toString() ?? '';
            if (id.isEmpty) continue;
            remoteDocIds.add(id);

            // If this record was just modified locally and pushed in this pass, do not overwrite with stale remote data
            if (dirtyLocalIds.contains(id)) {
              continue;
            }

            final remoteHash = jsonEncode(map).hashCode;
            final lastHash = _lastSyncedHashes['$tableName:$id'];

            if (lastHash == null || lastHash != remoteHash) {
              try {
                final entity = fromJson(map);
                await db.upsert(table, entity as dynamic);
                _lastSyncedHashes['$tableName:$id'] = remoteHash;
                syncedCount++;
                if (onItemPulled != null) {
                  await onItemPulled(map);
                }
              } catch (e) {
                debugPrint('Supabase insert error on $tableName: $e');
              }
            }
          }
        }

        // 3. Delete propagation
        if (remoteDocIds.isNotEmpty) {
          for (final item in localRows) {
            final id = getId(item);
            final lastHash = _lastSyncedHashes['$tableName:$id'];
            if (lastHash != null && !remoteDocIds.contains(id)) {
              try {
                await (db.delete(table)..where((tbl) => (tbl as dynamic).id.equals(id))).go();
                _lastSyncedHashes.remove('$tableName:$id');
                syncedCount++;
              } catch (_) {}
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Supabase _syncTable error on $tableName: $e');
      _syncHadError = true;
      _lastSyncError = 'Supabase sync error: $e';
    }

    return syncedCount;
  }
}

class CloudSyncNotifier extends Notifier<SyncState> {
  void _refreshAllDataProviders() {
    ref.read(adminProvider.notifier).reloadData();
    ref.invalidate(clientsProvider);
    ref.invalidate(projectsProvider);
    ref.invalidate(employeesProvider);
    ref.invalidate(accountsProvider);
    ref.invalidate(productsProvider);
    ref.invalidate(salesInvoicesProvider);
    ref.invalidate(inventoryProvider);
    ref.invalidate(incomeProvider);
    ref.invalidate(expensesProvider);
    ref.invalidate(ledgerProvider);
    ref.invalidate(assetsProvider);
    ref.invalidate(loansProvider);
    ref.invalidate(salariesProvider);
    ref.invalidate(advancesProvider);
    ref.invalidate(purchaseOrdersProvider);
    ref.invalidate(attendanceProvider);
    ref.invalidate(timesheetsProvider);
    ref.invalidate(tasksProvider);
  }

  @override
  SyncState build() {
    final service = ref.watch(cloudSyncServiceProvider);
    service.onStatusChanged = (newState) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        state = newState;
        if (newState.status == SyncStatus.success) {
          _refreshAllDataProviders();
        }
      });
    };
    return service.currentState;
  }

  Future<void> pushChangesOnly() async {
    final service = ref.read(cloudSyncServiceProvider);
    await service.pushChangesOnly();
  }

  Future<void> syncNow() async {
    final service = ref.read(cloudSyncServiceProvider);
    await service.syncAll();
  }

  Future<void> sync() => syncNow();

  Future<void> forceSync() async {
    final service = ref.read(cloudSyncServiceProvider);
    await service.syncAll(forcePush: true);
  }

  Future<void> setAutoSyncEnabled(bool enabled) async {
    final service = ref.read(cloudSyncServiceProvider);
    await service.setAutoSyncEnabled(enabled);
  }
}

final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  final service = CloudSyncService(dbService.db);
  service.startAutoSync();
  ref.onDispose(() {
    service.stopAutoSync();
  });
  return service;
});

final cloudSyncStateProvider =
    NotifierProvider<CloudSyncNotifier, SyncState>(CloudSyncNotifier.new);
