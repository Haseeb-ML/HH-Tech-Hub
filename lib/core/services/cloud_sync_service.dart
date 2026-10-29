import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import '../config/supabase_config.dart';
import '../../features/finance/accounts/data/repositories/accounts_repository_impl.dart';
import '../../features/clients/clients/presentation/providers/clients_provider.dart';
import '../../features/projects/projects/presentation/providers/projects_provider.dart';
import '../../features/hr/employees/presentation/providers/employees_provider.dart';
import '../../features/finance/accounts/presentation/providers/accounts_provider.dart';
import '../../features/finance/accounts/domain/entities/bank_account.dart';
import '../../features/finance/income/domain/entities/income_record.dart';
import '../../features/finance/expenses/domain/entities/expense_record.dart';
import '../../features/finance/loans/domain/entities/loan_record.dart';
import '../../features/finance/ledger/domain/entities/ledger_entry.dart';
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
import '../../features/administration/recovery/presentation/providers/recovery_provider.dart';
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

  SupabaseClient? get _supabaseClient {
    try {
      if (SupabaseConfig.isConfigured) {
        return Supabase.instance.client;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> _checkBankAccountsSchema() async {
    if (_bankAccountsSupportsExtendedColumns != null) {
      return _bankAccountsSupportsExtendedColumns!;
    }
    try {
      final client = _supabaseClient;
      if (client != null) {
        await client.from('bank_accounts').select('openingBalance').limit(1);
        _bankAccountsSupportsExtendedColumns = true;
      } else {
        final testUrl = Uri.parse('${SupabaseConfig.url}/rest/v1/bank_accounts?select=openingBalance&limit=1');
        final res = await _httpClient.get(testUrl, headers: {
          'apikey': SupabaseConfig.anonKey,
          'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
        }).timeout(const Duration(seconds: 4));
        _bankAccountsSupportsExtendedColumns = (res.statusCode == 200);
      }
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


  Timer? _hourlySyncTimer;

  void startAutoSync({Duration interval = const Duration(hours: 1)}) {
    _timer?.cancel();
    _timer = null;
    _hourlySyncTimer?.cancel();
    _hourlySyncTimer = null;
    _localDebounce?.cancel();
    _dbUpdatesSub?.cancel();

    // Automatically push dirty local changes to Supabase whenever any local entry is added, updated, or deleted
    try {
      _dbUpdatesSub = db.tableUpdates().listen((_) {
        if (_isSyncing) return;
        _localDebounce?.cancel();
        _localDebounce = Timer(const Duration(milliseconds: 2000), () {
          pushChangesOnly();
        });
      });
    } catch (_) {}

    // Periodic 1-Hour Auto Sync (Pull & Push all tables every 1 hour)
    _hourlySyncTimer = Timer.periodic(interval, (_) {
      if (!_isSyncing) {
        debugPrint('CloudSync: Periodic 1-hour auto sync triggering...');
        syncAll();
      }
    });

    // Check on startup if >= 1 hour has elapsed since last sync
    _checkInitialHourlySync();
  }

  void stopAutoSync() {
    _timer?.cancel();
    _timer = null;
    _hourlySyncTimer?.cancel();
    _hourlySyncTimer = null;
    _localDebounce?.cancel();
    _localDebounce = null;
    _dbUpdatesSub?.cancel();
    _dbUpdatesSub = null;
  }

  Future<void> _checkInitialHourlySync() async {
    try {
      await _loadSyncedHashes();
      final preferences = await SharedPreferences.getInstance();
      final lastSyncEpoch = preferences.getInt('cloud_sync_last_timestamp');
      if (lastSyncEpoch == null) {
        Future.delayed(const Duration(seconds: 4), () {
          if (!_isSyncing) syncAll();
        });
      } else {
        final lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSyncEpoch);
        final elapsed = DateTime.now().difference(lastSyncTime);
        if (elapsed.inHours >= 1) {
          debugPrint('CloudSync: Last sync was ${elapsed.inMinutes} mins ago (>= 1hr). Triggering background sync...');
          Future.delayed(const Duration(seconds: 4), () {
            if (!_isSyncing) syncAll();
          });
        }
      }
    } catch (e) {
      debugPrint('CloudSync: Initial hourly check error: $e');
    }
  }

  Future<void> deleteRemote(String collection, String id) async {
    try {
      final client = _supabaseClient;
      if (client != null) {
        await client.from(collection).delete().eq('id', id);
      } else {
        final uri = Uri.parse('${SupabaseConfig.url}/rest/v1/$collection?id=eq.$id');
        await _httpClient.delete(
          uri,
          headers: {
            'apikey': SupabaseConfig.anonKey,
            'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
          },
        ).timeout(const Duration(seconds: 6));
      }
      _lastSyncedHashes.remove('$collection:$id');
    } catch (e) {
      debugPrint('CloudSync: Delete remote error: $e');
    }
  }

  Future<void> _touchSyncMeta() async {
    try {
      final client = _supabaseClient;
      if (client != null) {
        await client.from('sync_meta').upsert({
          'id': 'status',
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } else {
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
      }
    } catch (_) {}
  }

  Future<void> wipeCloud() async {
    final collections = [
      'clients', 'bank_accounts', 'income_records', 'expense_records', 'ledger_entries',
      'app_goals', 'loan_records', 'advance_records', 'attendance_records',
      'employees', 'salary_records', 'assets', 'inventory_items',
      'projects', 'project_tasks', 'timesheet_entries', 'purchase_orders',
      'products', 'sales_invoices', 'recycle_bin'
    ];

    try {
      final client = _supabaseClient;
      if (client != null) {
        for (final collection in collections) {
          try {
            await client.from(collection).delete().neq('id', '');
          } catch (e) {
            debugPrint('CloudSync: Wipe collection error ($collection): $e');
          }
        }
      } else {
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
      }
      _lastSyncedHashes.clear();
      await _saveSyncedHashes();
    } catch (e) {
      debugPrint('CloudSync: Wipe cloud error: $e');
    }
  }

  Future<void> clearSyncHashes() async {
    _lastSyncedHashes.clear();
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_hashesPreferenceKey);
      await preferences.remove('cloud_sync_last_timestamp');
    } catch (_) {}
  }

  /// Lightweight push of only dirty local records to cloud.
  /// Does NOT pull remote data and does NOT perform any SQLite writes,
  /// preventing recursive tableUpdates triggers and avoiding any app UI lag.
  Future<int> pushChangesOnly() async {
    if (_isSyncing) return 0;

    _isSyncing = true;
    try {
      await _loadSyncedHashes();

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
          toJson: (a) => a.toJson(),
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

        // 19. App Users (Force push latest local users)
        () => _syncAppUsers(forcePush: true),

        // 20. App Roles (Force push latest local roles)
        () => _syncAppRoles(forcePush: true),

        // 21. Audit Logs (Force push audit logs)
        () => _syncAuditLogs(forcePush: true),

        // 22. Recycle Bin
        () => _pushTableOnly<RecycleBinTableData>(
          collection: 'recycle_bin',
          table: db.recycleBinTable,
          getAllLocal: () => db.select(db.recycleBinTable).get(),
          getId: (r) => r.id,
          toJson: (r) {
            final json = r.toJson();
            // Decode jsonData from string to Map for JSONB column
            if (json['jsonData'] is String) {
              try {
                json['jsonData'] = jsonDecode(json['jsonData'] as String);
              } catch (_) {}
            }
            return json;
          },
        ),
      ];

      int totalPushed = 0;
      const batchSize = 5;
      for (var i = 0; i < pushTasks.length; i += batchSize) {
        if (!_isSyncing) break;
        final end = (i + batchSize < pushTasks.length) ? i + batchSize : pushTasks.length;
        final currentBatch = pushTasks.sublist(i, end);

        final results = await Future.wait(currentBatch.map((task) async {
          try {
            return await task();
          } catch (e) {
            debugPrint('CloudSync push task error: $e');
            return 0;
          }
        }));

        totalPushed += results.fold(0, (sum, count) => sum + count);
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

  Future<bool> checkInternetConnection() async {
    try {
      final res = await _httpClient.get(
        Uri.parse('${SupabaseConfig.url}/rest/v1/sync_meta?select=id&limit=1'),
        headers: {
          'apikey': SupabaseConfig.anonKey,
          'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
        },
      ).timeout(const Duration(seconds: 3));
      return res.statusCode >= 200 && res.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  Future<void> syncAll({bool forcePush = false}) async {
    if (_isSyncing) return;

    final isOnline = await checkInternetConnection();
    if (!isOnline) {
      _updateState(_currentState.copyWith(
        status: SyncStatus.offline,
        message: 'No Internet Connection! Local data is safely preserved.',
        isOnline: false,
      ));
      return;
    }

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
          toJson: (a) => a.toJson(),
          fromJson: (m) {
            m['balance'] = (m['balance'] as num?)?.toDouble() ?? 0.0;
            m['openingBalance'] = (m['openingBalance'] as num?)?.toDouble() ?? 0.0;
            m['openingBalanceDate'] = m['openingBalanceDate']?.toString() ?? '';
            m['accountScope'] = m['accountScope']?.toString() ?? 'Company';
            m['ownerName'] = m['ownerName']?.toString() ?? '';
            return BankAccountsTableData.fromJson(m);
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

        // 21. Audit Logs
        () => _syncAuditLogs(forcePush: forcePush),

        // 22. Recycle Bin
        () => _syncTable<RecycleBinTableData>(
          collection: 'recycle_bin',
          table: db.recycleBinTable,
          getAllLocal: () => db.select(db.recycleBinTable).get(),
          getId: (r) => r.id,
          toJson: (r) {
            final json = r.toJson();
            if (json['jsonData'] is String) {
              try {
                json['jsonData'] = jsonDecode(json['jsonData'] as String);
              } catch (_) {}
            }
            return json;
          },
          fromJson: (m) {
            if (m['jsonData'] is Map) {
              m['jsonData'] = m['jsonData'] as Map<String, dynamic>;
            } else if (m['jsonData'] is String) {
              m['jsonData'] = jsonDecode(m['jsonData'] as String) as Map<String, dynamic>;
            } else {
              m['jsonData'] = <String, dynamic>{};
            }
            return RecycleBinTableData.fromJson(m);
          },
          forcePush: forcePush,
        ),
      ];

      const batchSize = 5;
      for (var i = 0; i < syncTasks.length; i += batchSize) {
        if (!_isSyncing) break;
        final end = (i + batchSize < syncTasks.length) ? i + batchSize : syncTasks.length;
        final currentBatch = syncTasks.sublist(i, end);

        final results = await Future.wait(currentBatch.map((task) async {
          try {
            return await task();
          } catch (e) {
            debugPrint('CloudSync table task error: $e');
            return 0;
          }
        }));

        totalSynced += results.fold(0, (sum, count) => sum + count);
      }

      await _reconcileAccountBalances();
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
        final now = DateTime.now();
        SharedPreferences.getInstance().then((prefs) {
          prefs.setInt('cloud_sync_last_timestamp', now.millisecondsSinceEpoch);
        });
        _updateState(_currentState.copyWith(
          status: SyncStatus.success,
          lastSyncedAt: now,
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
      // 1. Pull remote users from Supabase if online (skipped on force push)
      if (!forcePush) {
        try {
          final getUrl = Uri.parse('${SupabaseConfig.url}/rest/v1/app_users?select=*');
          final res = await _httpClient.get(getUrl, headers: headers).timeout(const Duration(seconds: 8));
          if (res.statusCode == 200) {
            final remoteList = jsonDecode(res.body) as List<dynamic>;
            final remoteUserIds = <String>{};
            for (final item in remoteList) {
              final map = item as Map<String, dynamic>;
              final id = map['id']?.toString() ?? '';
              if (id.isEmpty) continue;
              remoteUserIds.add(id);
              final remoteRecord = AdminUserRecord.fromMap(map);

              // Remove any stale local duplicate user with same username under a different ID
              if (remoteRecord.username.isNotEmpty) {
                await db.customStatement(
                  'DELETE FROM app_users WHERE LOWER(username) = ? AND id != ?',
                  [remoteRecord.username.trim().toLowerCase(), remoteRecord.id],
                );
              }

              // Update/replace local SQLite record with latest remote credentials
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

            // Propagate deletions: if a non-superadmin user was removed from Supabase, remove locally
            if (remoteUserIds.isNotEmpty) {
              final localUsers = await authRepo.getAllUsers();
              for (final u in localUsers) {
                if (!remoteUserIds.contains(u.id) && !u.isSuperAdmin && u.username.toLowerCase() != 'admin') {
                  await db.customStatement('DELETE FROM app_users WHERE id = ?', [u.id]);
                }
              }
            }
          }
        } catch (_) {}
      }

      // 2. Push local users to Supabase
      final updatedLocal = await authRepo.getAllUsers();
      if (updatedLocal.isNotEmpty) {
        final pushUrl = Uri.parse('${SupabaseConfig.url}/rest/v1/app_users?on_conflict=id');
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
        } else {
          debugPrint('CloudSync: app_users push warning: ${pushRes.statusCode} - ${pushRes.body}');
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
      // 1. Pull remote roles from Supabase and save/update locally
      if (!forcePush) {
        try {
          final getUrl = Uri.parse('${SupabaseConfig.url}/rest/v1/app_roles?select=*');
          final res = await _httpClient.get(getUrl, headers: headers).timeout(const Duration(seconds: 8));
          if (res.statusCode == 200) {
            final remoteList = jsonDecode(res.body) as List<dynamic>;
            final remoteRoleIds = <String>{};
            for (final item in remoteList) {
              final map = item as Map<String, dynamic>;
              final id = map['id']?.toString() ?? '';
              if (id.isEmpty) continue;
              remoteRoleIds.add(id);
              final remoteRole = UserRole.fromMap(map);
              await authRepo.saveCustomRole(remoteRole);
              count++;
            }

            // Propagate deletions: if a custom role was removed from Supabase, remove locally
            if (remoteRoleIds.isNotEmpty) {
              final localRoles = await authRepo.getAllRoles();
              for (final r in localRoles) {
                if (!remoteRoleIds.contains(r.id) && !r.isSystemRole && r.roleName.toLowerCase() != 'super admin') {
                  await authRepo.deleteRole(r.roleName);
                }
              }
            }
          }
        } catch (_) {}
      }

      // 2. Push local roles to Supabase
      final updatedRoles = await authRepo.getAllRoles();
      if (updatedRoles.isNotEmpty) {
        final pushUrl = Uri.parse('${SupabaseConfig.url}/rest/v1/app_roles?on_conflict=id');
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
        } else {
          debugPrint('CloudSync: app_roles push warning: ${pushRes.statusCode} - ${pushRes.body}');
        }
      }
    } catch (e) {
      debugPrint('CloudSync: app_roles sync notice: $e');
    }
    return count;
  }

  Future<int> _syncAuditLogs({bool forcePush = false}) async {
    final authRepo = AuthLocalRepository(db);
    final headers = {
      'apikey': SupabaseConfig.anonKey,
      'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
      'Content-Type': 'application/json',
    };
    int count = 0;
    try {
      // 1. Pull remote audit_logs from Supabase if online (skipped on forcePush)
      if (!forcePush) {
        try {
          final getUrl = Uri.parse('${SupabaseConfig.url}/rest/v1/audit_logs?select=*&order=created_at.desc&limit=500');
          final res = await _httpClient.get(getUrl, headers: headers).timeout(const Duration(seconds: 8));
          if (res.statusCode == 200) {
            final remoteList = jsonDecode(res.body) as List<dynamic>;
            for (final item in remoteList) {
              final map = item as Map<String, dynamic>;
              final id = map['id']?.toString() ?? '';
              if (id.isEmpty) continue;
              
              await db.customStatement('''
                INSERT OR IGNORE INTO audit_logs (id, timestamp, user, action, module, ip_address, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?)
              ''', [
                id,
                map['timestamp']?.toString() ?? '',
                map['user']?.toString() ?? '',
                map['action']?.toString() ?? '',
                map['module']?.toString() ?? '',
                map['ip_address']?.toString() ?? '192.168.1.1',
                map['created_at']?.toString() ?? DateTime.now().toIso8601String(),
              ]);
              count++;
            }
          }
        } catch (_) {}
      }

      // 2. Push local audit_logs to Supabase
      final localLogs = await authRepo.getAllAuditLogs();
      if (localLogs.isNotEmpty) {
        final pushUrl = Uri.parse('${SupabaseConfig.url}/rest/v1/audit_logs?on_conflict=id');
        final rowsToPush = localLogs.map((log) => {
          'id': log['id']?.toString() ?? '',
          'timestamp': log['timestamp']?.toString() ?? '',
          'user': log['user']?.toString() ?? '',
          'action': log['action']?.toString() ?? '',
          'module': log['module']?.toString() ?? '',
          'ip_address': log['ip_address']?.toString() ?? '192.168.1.1',
          'created_at': log['created_at']?.toString() ?? DateTime.now().toIso8601String(),
        }).where((m) => (m['id'] as String).isNotEmpty).toList();

        if (rowsToPush.isNotEmpty) {
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
          } else {
            debugPrint('CloudSync: audit_logs push warning: ${pushRes.statusCode} - ${pushRes.body}');
          }
        }
      }
    } catch (e) {
      debugPrint('CloudSync: audit_logs sync notice: $e');
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

        if (tableName == 'expense_records') {
          rawMap.remove('isPersonalExpense');
        }

        for (final key in ['phones', 'teamMembers', 'items', 'repayments']) {
          if (rawMap[key] is String && (rawMap[key] as String).startsWith('[')) {
            try {
              rawMap[key] = jsonDecode(rawMap[key] as String);
            } catch (_) {}
          }
        }

        // Decode jsonData (Map) for recycle_bin JSONB column
        if (rawMap['jsonData'] is String && (rawMap['jsonData'] as String).startsWith('{')) {
          try {
            rawMap['jsonData'] = jsonDecode(rawMap['jsonData'] as String);
          } catch (_) {}
        }

        // Sanitize top-level null values for optional string fields to empty string "" to prevent PostgREST NOT NULL rejection
        rawMap.forEach((k, v) {
          if (v == null) {
            rawMap[k] = '';
          }
        });

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

        if (tableName == 'expense_records') {
          rawMap.remove('isPersonalExpense');
        }

        // Ensure lists aren't string-encoded for JSONB columns
        for (final key in ['phones', 'teamMembers', 'items', 'repayments']) {
          if (rawMap[key] is String && (rawMap[key] as String).startsWith('[')) {
            try {
              rawMap[key] = jsonDecode(rawMap[key] as String);
            } catch (_) {}
          }
        }

        // Ensure map/object JSON fields aren't string-encoded for JSONB columns
        if (rawMap['jsonData'] is String && (rawMap['jsonData'] as String).startsWith('{')) {
          try {
            rawMap['jsonData'] = jsonDecode(rawMap['jsonData'] as String);
          } catch (_) {}
        }

        // Sanitize top-level null values for optional string fields to empty string "" to prevent PostgREST NOT NULL rejection
        rawMap.forEach((k, v) {
          if (v == null) {
            rawMap[k] = '';
          }
        });

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
          } else if (pushRes.body.contains('PGRST204') && pushRes.body.contains('Could not find the')) {
            final match = RegExp(r"Could not find the '([^']+)' column").firstMatch(pushRes.body);
            final missingCol = match?.group(1);
            if (missingCol != null && missingCol.isNotEmpty) {
              final retryChunk = chunk.map((m) {
                final copy = Map<String, dynamic>.from(m);
                copy.remove(missingCol);
                return copy;
              }).toList();
              try {
                final retryRes = await _httpClient.post(
                  pushUrl,
                  headers: {
                    ...headers,
                    'Prefer': 'resolution=merge-duplicates',
                  },
                  body: jsonEncode(retryChunk),
                ).timeout(const Duration(seconds: 8));
                if (retryRes.statusCode == 200 || retryRes.statusCode == 201) {
                  syncedCount += retryChunk.length;
                  _lastSyncedHashes.addAll(newHashes);
                  continue;
                }
              } catch (_) {}
            }
            debugPrint('Supabase push notice on $tableName: ${pushRes.statusCode} - ${pushRes.body}');
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
          final itemsToUpsert = <dynamic>[];
          final newHashesToSave = <String, int>{};
          final itemPulledCallbacks = <Map<String, dynamic>>[];
          final existingLocalIds = localRows.map((e) => getId(e)).toSet();

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
            final existsLocally = existingLocalIds.contains(id);

            if (!existsLocally || lastHash == null || lastHash != remoteHash) {
              try {
                final entity = fromJson(map);
                itemsToUpsert.add(entity);
                newHashesToSave['$tableName:$id'] = remoteHash;
                if (onItemPulled != null) {
                  itemPulledCallbacks.add(map);
                }
              } catch (e) {
                debugPrint('Supabase parse error on $tableName: $e');
              }
            }
          }

          if (itemsToUpsert.isNotEmpty) {
            await db.transaction(() async {
              for (final entity in itemsToUpsert) {
                await db.upsert(table, entity as dynamic);
              }
            });
            _lastSyncedHashes.addAll(newHashesToSave);
            syncedCount += itemsToUpsert.length;

            if (onItemPulled != null) {
              for (final map in itemPulledCallbacks) {
                await onItemPulled(map);
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

  Future<void> _reconcileAccountBalances() async {
    try {
      final accounts = await db.getAll(db.bankAccountsTable);
      if (accounts.isEmpty) return;

      final allIncomes = await db.getAll(db.incomeRecordsTable);
      final allExpenses = await db.getAll(db.expenseRecordsTable);
      final allLoans = await db.getAll(db.loanRecordsTable);
      final allLedgers = await db.getAll(db.ledgerEntriesTable);

      final domainIncomes = allIncomes.map((i) => IncomeRecord(
        id: i.id,
        date: i.date,
        clientId: i.clientId ?? '',
        clientName: i.clientName ?? '',
        amount: i.amount,
        accountId: i.accountId,
        invoiceNumber: i.invoiceNumber ?? '',
        description: i.description ?? '',
        status: i.status ?? 'Received',
      )).toList();

      final domainExpenses = allExpenses.map((e) => ExpenseRecord(
        id: e.id,
        date: e.date,
        amount: e.amount,
        accountId: e.accountId,
        category: e.category,
        vendorName: e.vendorName ?? '',
        description: e.description ?? '',
      )).toList();

      final domainLoans = allLoans.map((l) => LoanRecord(
        id: l.id,
        borrowerName: l.borrowerName,
        type: l.type,
        amount: l.amount,
        remainingBalance: l.remainingBalance,
        startDate: l.startDate,
        endDate: l.endDate,
        status: l.status,
        description: l.description,
        repayments: l.repayments.map((m) => LoanRepayment(
          id: m['id']?.toString() ?? '',
          date: m['date']?.toString() ?? '',
          amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
          accountId: m['accountId']?.toString() ?? '',
          accountName: m['accountName']?.toString() ?? '',
        )).toList(),
      )).toList();

      final domainLedgers = allLedgers.map((l) => LedgerEntry(
        id: l.id,
        date: l.date,
        accountId: l.accountId,
        accountName: l.accountName,
        type: l.type,
        category: l.category,
        amount: l.amount,
        reference: l.reference,
        description: l.description,
      )).toList();

      final openingLedgerMap = <String, LedgerEntriesTableData>{};
      for (final l in allLedgers) {
        if (l.category == 'Opening Balance' || l.id.startsWith('led_opening_')) {
          openingLedgerMap[l.accountId] = l;
        }
      }

      for (final a in accounts) {
        final isPersonal = (a.accountScope.toLowerCase() == 'personal') ||
            a.id.toLowerCase().contains('personal') ||
            a.name.toLowerCase().contains('personal');
        final ledgerOpening = openingLedgerMap[a.id];
        final rawOpening = a.openingBalance > 0 ? a.openingBalance : (ledgerOpening?.amount ?? 0.0);
        final openingBal = rawOpening > 0 ? rawOpening : (ledgerOpening?.amount ?? 0.0);

        final bankAcc = BankAccount(
          id: a.id,
          name: a.name,
          type: a.type,
          accountNumber: a.accountNumber,
          bankName: a.bankName,
          balance: a.balance,
          status: a.status,
          openingBalance: openingBal,
          accountScope: isPersonal ? 'Personal' : 'Company',
        );

        final realBal = calculateAuthoritativeAccountBalance(
          account: bankAcc,
          incomes: domainIncomes,
          expenses: domainExpenses,
          loans: domainLoans,
          ledgerEntries: domainLedgers,
        );

        if ((a.balance - realBal).abs() > 0.001) {
          await db.upsert(
            db.bankAccountsTable,
            BankAccountsTableCompanion.insert(
              id: a.id,
              name: a.name,
              type: a.type,
              accountNumber: a.accountNumber,
              bankName: a.bankName,
              balance: realBal,
              status: a.status,
              openingBalance: Value(a.openingBalance),
              openingBalanceDate: Value(a.openingBalanceDate),
              accountScope: Value(a.accountScope),
              ownerName: Value(a.ownerName),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('CloudSync: reconcile balances error: $e');
    }
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
    ref.invalidate(recoveryProvider);
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
