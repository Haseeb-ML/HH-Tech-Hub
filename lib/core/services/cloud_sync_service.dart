import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'database_service.dart';

enum SyncStatus { idle, syncing, success, offline, error }

class SyncState {
  final SyncStatus status;
  final DateTime? lastSyncedAt;
  final String? message;
  final int syncedCount;
  final bool isOnline;

  const SyncState({
    this.status = SyncStatus.idle,
    this.lastSyncedAt,
    this.message,
    this.syncedCount = 0,
    this.isOnline = true,
  });

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncedAt,
    String? message,
    int? syncedCount,
    bool? isOnline,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      message: message ?? this.message,
      syncedCount: syncedCount ?? this.syncedCount,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

class CloudSyncService {
  static const String projectId = 'hh-tech-hub-3e615';
  static const String baseUrl =
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';
  static const String commitUrl = '$baseUrl:commit';

  final AppDatabase db;
  Timer? _timer;
  bool _isSyncing = false;
  void Function(SyncState)? onStatusChanged;
  SyncState _currentState = const SyncState();

  CloudSyncService(this.db);

  SyncState get currentState => _currentState;

  void _updateState(SyncState newState) {
    _currentState = newState;
    onStatusChanged?.call(newState);
  }

  void startAutoSync({Duration interval = const Duration(seconds: 40)}) {
    _timer?.cancel();
    Future.delayed(const Duration(seconds: 2), () => syncAll());
    _timer = Timer.periodic(interval, (_) => syncAll());
  }

  void stopAutoSync() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> deleteRemote(String collection, String id) async {
    try {
      final uri = Uri.parse('$baseUrl/$collection/$id');
      await http.delete(uri).timeout(const Duration(seconds: 6));
    } catch (e) {
      debugPrint('CloudSync: Delete remote error: $e');
    }
  }

  Future<void> syncAll() async {
    if (_isSyncing) return;
    _isSyncing = true;

    _updateState(_currentState.copyWith(
      status: SyncStatus.syncing,
      message: 'Syncing with Firebase Cloud...',
    ));

    try {
      int totalSynced = 0;

      // 1. Clients
      totalSynced += await _syncTable<ClientsTableData>(
        collection: 'clients',
        table: db.clientsTable,
        getAllLocal: () => db.select(db.clientsTable).get(),
        getId: (c) => c.id,
        toJson: (c) => c.toJson(),
        fromJson: (m) => ClientsTableData.fromJson(m),
      );

      // 2. Bank Accounts
      totalSynced += await _syncTable<BankAccountsTableData>(
        collection: 'bank_accounts',
        table: db.bankAccountsTable,
        getAllLocal: () => db.select(db.bankAccountsTable).get(),
        getId: (a) => a.id,
        toJson: (a) => a.toJson(),
        fromJson: (m) => BankAccountsTableData.fromJson(m),
      );

      // 3. Expense Records
      totalSynced += await _syncTable<ExpenseRecordsTableData>(
        collection: 'expense_records',
        table: db.expenseRecordsTable,
        getAllLocal: () => db.select(db.expenseRecordsTable).get(),
        getId: (e) => e.id,
        toJson: (e) => e.toJson(),
        fromJson: (m) => ExpenseRecordsTableData.fromJson(m),
      );

      // 4. Income Records
      totalSynced += await _syncTable<IncomeRecordsTableData>(
        collection: 'income_records',
        table: db.incomeRecordsTable,
        getAllLocal: () => db.select(db.incomeRecordsTable).get(),
        getId: (i) => i.id,
        toJson: (i) => i.toJson(),
        fromJson: (m) => IncomeRecordsTableData.fromJson(m),
      );

      // 5. Ledger Entries
      totalSynced += await _syncTable<LedgerEntriesTableData>(
        collection: 'ledger_entries',
        table: db.ledgerEntriesTable,
        getAllLocal: () => db.select(db.ledgerEntriesTable).get(),
        getId: (l) => l.id,
        toJson: (l) => l.toJson(),
        fromJson: (m) => LedgerEntriesTableData.fromJson(m),
      );

      // 6. Loan Records
      totalSynced += await _syncTable<LoanRecordsTableData>(
        collection: 'loan_records',
        table: db.loanRecordsTable,
        getAllLocal: () => db.select(db.loanRecordsTable).get(),
        getId: (l) => l.id,
        toJson: (l) => l.toJson(),
        fromJson: (m) => LoanRecordsTableData.fromJson(m),
      );

      // 7. Advance Records
      totalSynced += await _syncTable<AdvanceRecordsTableData>(
        collection: 'advance_records',
        table: db.advanceRecordsTable,
        getAllLocal: () => db.select(db.advanceRecordsTable).get(),
        getId: (a) => a.id,
        toJson: (a) => a.toJson(),
        fromJson: (m) => AdvanceRecordsTableData.fromJson(m),
      );

      // 8. Attendance Records
      totalSynced += await _syncTable<AttendanceRecordsTableData>(
        collection: 'attendance_records',
        table: db.attendanceRecordsTable,
        getAllLocal: () => db.select(db.attendanceRecordsTable).get(),
        getId: (a) => a.id,
        toJson: (a) => a.toJson(),
        fromJson: (m) => AttendanceRecordsTableData.fromJson(m),
      );

      // 9. Employees
      totalSynced += await _syncTable<EmployeesTableData>(
        collection: 'employees',
        table: db.employeesTable,
        getAllLocal: () => db.select(db.employeesTable).get(),
        getId: (e) => e.id,
        toJson: (e) => e.toJson(),
        fromJson: (m) => EmployeesTableData.fromJson(m),
      );

      // 10. Salary Records
      totalSynced += await _syncTable<SalaryRecordsTableData>(
        collection: 'salary_records',
        table: db.salaryRecordsTable,
        getAllLocal: () => db.select(db.salaryRecordsTable).get(),
        getId: (s) => s.id,
        toJson: (s) => s.toJson(),
        fromJson: (m) => SalaryRecordsTableData.fromJson(m),
      );

      // 11. Assets
      totalSynced += await _syncTable<AssetsTableData>(
        collection: 'assets',
        table: db.assetsTable,
        getAllLocal: () => db.select(db.assetsTable).get(),
        getId: (a) => a.id,
        toJson: (a) => a.toJson(),
        fromJson: (m) => AssetsTableData.fromJson(m),
      );

      // 12. Inventory Items
      totalSynced += await _syncTable<InventoryItemsTableData>(
        collection: 'inventory_items',
        table: db.inventoryItemsTable,
        getAllLocal: () => db.select(db.inventoryItemsTable).get(),
        getId: (i) => i.id,
        toJson: (i) => i.toJson(),
        fromJson: (m) => InventoryItemsTableData.fromJson(m),
      );

      // 13. Projects
      totalSynced += await _syncTable<ProjectsTableData>(
        collection: 'projects',
        table: db.projectsTable,
        getAllLocal: () => db.select(db.projectsTable).get(),
        getId: (p) => p.id,
        toJson: (p) => p.toJson(),
        fromJson: (m) => ProjectsTableData.fromJson(m),
      );

      // 14. Project Tasks
      totalSynced += await _syncTable<ProjectTasksTableData>(
        collection: 'project_tasks',
        table: db.projectTasksTable,
        getAllLocal: () => db.select(db.projectTasksTable).get(),
        getId: (t) => t.id,
        toJson: (t) => t.toJson(),
        fromJson: (m) => ProjectTasksTableData.fromJson(m),
      );

      // 15. Timesheet Entries
      totalSynced += await _syncTable<TimesheetEntriesTableData>(
        collection: 'timesheet_entries',
        table: db.timesheetEntriesTable,
        getAllLocal: () => db.select(db.timesheetEntriesTable).get(),
        getId: (t) => t.id,
        toJson: (t) => t.toJson(),
        fromJson: (m) => TimesheetEntriesTableData.fromJson(m),
      );

      // 16. Purchase Orders
      totalSynced += await _syncTable<PurchaseOrdersTableData>(
        collection: 'purchase_orders',
        table: db.purchaseOrdersTable,
        getAllLocal: () => db.select(db.purchaseOrdersTable).get(),
        getId: (p) => p.id,
        toJson: (p) => p.toJson(),
        fromJson: (m) => PurchaseOrdersTableData.fromJson(m),
      );

      // 17. Products
      totalSynced += await _syncTable<ProductsTableData>(
        collection: 'products',
        table: db.productsTable,
        getAllLocal: () => db.select(db.productsTable).get(),
        getId: (p) => p.id,
        toJson: (p) => p.toJson(),
        fromJson: (m) => ProductsTableData.fromJson(m),
      );

      // 18. Sales Invoices
      totalSynced += await _syncTable<SalesInvoicesTableData>(
        collection: 'sales_invoices',
        table: db.salesInvoicesTable,
        getAllLocal: () => db.select(db.salesInvoicesTable).get(),
        getId: (s) => s.id,
        toJson: (s) => s.toJson(),
        fromJson: (m) => SalesInvoicesTableData.fromJson(m),
      );

      _updateState(_currentState.copyWith(
        status: SyncStatus.success,
        lastSyncedAt: DateTime.now(),
        message: 'Synchronized with Firebase Cloud',
        syncedCount: totalSynced,
        isOnline: true,
      ));
    } catch (e) {
      debugPrint('CloudSync Error: $e');
      _updateState(_currentState.copyWith(
        status: SyncStatus.offline,
        message: 'Cloud Sync paused (Offline mode active)',
        isOnline: false,
      ));
    } finally {
      _isSyncing = false;
    }
  }

  Future<int> _syncTable<T>({
    required String collection,
    required dynamic table,
    required Future<List<T>> Function() getAllLocal,
    required String Function(T) getId,
    required Map<String, dynamic> Function(T) toJson,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    int pulledCount = 0;

    // 1. Pull from Firestore
    try {
      final pullUri = Uri.parse('$baseUrl/$collection?pageSize=500');
      final res = await http.get(pullUri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final documents = data['documents'] as List<dynamic>? ?? [];
        for (final doc in documents) {
          final fields = doc['fields'] as Map<String, dynamic>?;
          if (fields != null && fields['payload'] != null) {
            final payloadStr = fields['payload']['stringValue'] as String?;
            if (payloadStr != null && payloadStr.isNotEmpty) {
              try {
                final itemMap = jsonDecode(payloadStr) as Map<String, dynamic>;
                final entity = fromJson(itemMap);
                await db.upsert(table, entity as dynamic);
                pulledCount++;
              } catch (err) {
                // skip corrupted item
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('CloudSync: Pull error for $collection: $e');
    }

    // 2. Push local records to Firestore
    try {
      final localItems = await getAllLocal();
      if (localItems.isNotEmpty) {
        final writes = <Map<String, dynamic>>[];
        for (final item in localItems) {
          final id = getId(item);
          if (id.isEmpty) continue;
          final jsonMap = toJson(item);
          writes.add({
            'update': {
              'name': 'projects/$projectId/databases/(default)/documents/$collection/$id',
              'fields': {
                'payload': {'stringValue': jsonEncode(jsonMap)},
                'updatedAt': {'stringValue': DateTime.now().toIso8601String()},
              }
            }
          });
        }

        // Commit in chunks of 200
        for (var i = 0; i < writes.length; i += 200) {
          final chunk = writes.sublist(i, (i + 200 > writes.length) ? writes.length : i + 200);
          final commitBody = jsonEncode({'writes': chunk});
          await http.post(
            Uri.parse(commitUrl),
            headers: {'Content-Type': 'application/json'},
            body: commitBody,
          ).timeout(const Duration(seconds: 10));
        }
      }
    } catch (e) {
      debugPrint('CloudSync: Push error for $collection: $e');
    }

    return pulledCount;
  }
}

class CloudSyncNotifier extends Notifier<SyncState> {
  @override
  SyncState build() {
    final service = ref.watch(cloudSyncServiceProvider);
    service.onStatusChanged = (newState) {
      state = newState;
    };
    return service.currentState;
  }

  Future<void> syncNow() async {
    final service = ref.read(cloudSyncServiceProvider);
    await service.syncAll();
  }
}

final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  final service = CloudSyncService(dbService.db);
  service.startAutoSync();
  return service;
});

final cloudSyncStateProvider =
    NotifierProvider<CloudSyncNotifier, SyncState>(CloudSyncNotifier.new);
