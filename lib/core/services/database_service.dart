import 'dart:io';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'database_service.g.dart';

// --- TYPE CONVERTERS ---
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();
  @override
  List<String> fromSql(String fromDb) => List<String>.from(jsonDecode(fromDb));
  @override
  String toSql(List<String> value) => jsonEncode(value);
}

class InvoiceItemListConverter extends TypeConverter<List<Map<String, dynamic>>, String> {
  const InvoiceItemListConverter();
  @override
  List<Map<String, dynamic>> fromSql(String fromDb) => List<Map<String, dynamic>>.from(jsonDecode(fromDb));
  @override
  String toSql(List<Map<String, dynamic>> value) => jsonEncode(value);
}

class PurchaseItemListConverter extends TypeConverter<List<Map<String, dynamic>>, String> {
  const PurchaseItemListConverter();
  @override
  List<Map<String, dynamic>> fromSql(String fromDb) => List<Map<String, dynamic>>.from(jsonDecode(fromDb));
  @override
  String toSql(List<Map<String, dynamic>> value) => jsonEncode(value);
}

class LoanRepaymentListConverter extends TypeConverter<List<Map<String, dynamic>>, String> {
  const LoanRepaymentListConverter();
  @override
  List<Map<String, dynamic>> fromSql(String fromDb) => List<Map<String, dynamic>>.from(jsonDecode(fromDb));
  @override
  String toSql(List<Map<String, dynamic>> value) => jsonEncode(value);
}

// --- OLD TABLES (For Dashboard etc.) ---
class TransactionsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get details => text()();
  TextColumn get type => text()();
  RealColumn get amount => real()();
  TextColumn get date => text()();
  BoolColumn get isIncome => boolean()();
}

class ActivitiesTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get content => text()();
  TextColumn get timestamp => text()();
  TextColumn get iconName => text()();
  TextColumn get colorHex => text()();
}

class TasksTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get dueDate => text()();
  TextColumn get assignee => text()();
  BoolColumn get isCompleted => boolean()();
}

class StockAlertsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get assetName => text()();
  TextColumn get currentStatus => text()();
  TextColumn get recommendation => text()();
  TextColumn get colorHex => text()();
  TextColumn get bgHex => text()();
}

// --- NEW TABLES ---
class ClientsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get contactPerson => text()();
  TextColumn get email => text()();
  TextColumn get phone => text()();
  TextColumn get status => text()();
  TextColumn get industry => text()();
  IntColumn get totalProjects => integer()();
  RealColumn get advancedPayment => real()();
  RealColumn get fullPayment => real()();
  @override Set<Column> get primaryKey => {id};
}

class BankAccountsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get accountNumber => text()();
  TextColumn get bankName => text()();
  RealColumn get balance => real()();
  TextColumn get status => text()();
  @override Set<Column> get primaryKey => {id};
}

class ExpenseRecordsTable extends Table {
  TextColumn get id => text()();
  TextColumn get date => text()();
  RealColumn get amount => real()();
  TextColumn get accountId => text()();
  TextColumn get category => text()();
  TextColumn get vendorName => text()();
  TextColumn get description => text()();
  @override Set<Column> get primaryKey => {id};
}

class IncomeRecordsTable extends Table {
  TextColumn get id => text()();
  TextColumn get date => text()();
  TextColumn get clientId => text()();
  TextColumn get clientName => text()();
  RealColumn get amount => real()();
  TextColumn get accountId => text()();
  TextColumn get invoiceNumber => text()();
  TextColumn get description => text()();
  TextColumn get status => text()();
  TextColumn get projectId => text().nullable()();
  TextColumn get projectName => text().nullable()();
  TextColumn get projectPaymentType => text().nullable()();
  @override Set<Column> get primaryKey => {id};
}

class LedgerEntriesTable extends Table {
  TextColumn get id => text()();
  TextColumn get date => text()();
  TextColumn get accountId => text()();
  TextColumn get accountName => text()();
  TextColumn get type => text()();
  TextColumn get category => text()();
  RealColumn get amount => real()();
  TextColumn get reference => text()();
  TextColumn get description => text()();
  @override Set<Column> get primaryKey => {id};
}

class LoanRecordsTable extends Table {
  TextColumn get id => text()();
  TextColumn get borrowerName => text()();
  TextColumn get type => text()();
  RealColumn get amount => real()();
  RealColumn get remainingBalance => real()();
  TextColumn get startDate => text()();
  TextColumn get endDate => text()();
  TextColumn get status => text()();
  TextColumn get description => text()();
  TextColumn get repayments => text().map(const LoanRepaymentListConverter())();
  @override Set<Column> get primaryKey => {id};
}

class AdvanceRecordsTable extends Table {
  TextColumn get id => text()();
  TextColumn get employeeId => text()();
  TextColumn get employeeName => text()();
  RealColumn get amount => real()();
  TextColumn get requestDate => text()();
  TextColumn get reason => text()();
  IntColumn get repaymentMonths => integer()();
  RealColumn get amountRepaid => real()();
  TextColumn get status => text()();
  @override Set<Column> get primaryKey => {id};
}

class AttendanceRecordsTable extends Table {
  TextColumn get id => text()();
  TextColumn get employeeId => text()();
  TextColumn get employeeName => text()();
  TextColumn get date => text()();
  TextColumn get status => text()();
  TextColumn get checkIn => text().nullable()();
  TextColumn get checkOut => text().nullable()();
  TextColumn get notes => text().nullable()();
  @override Set<Column> get primaryKey => {id};
}

class EmployeesTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get email => text()();
  TextColumn get phones => text().map(const StringListConverter())();
  TextColumn get designation => text()();
  TextColumn get department => text()();
  TextColumn get joiningDate => text()();
  TextColumn get leavingDate => text().nullable()();
  TextColumn get status => text()();
  TextColumn get salaryType => text()();
  RealColumn get baseSalary => real()();
  TextColumn get paymentMethod => text()();
  @override Set<Column> get primaryKey => {id};
}

class SalaryRecordsTable extends Table {
  TextColumn get id => text()();
  TextColumn get employeeId => text()();
  TextColumn get employeeName => text()();
  TextColumn get payPeriod => text()();
  RealColumn get baseSalary => real()();
  RealColumn get allowances => real()();
  RealColumn get deductions => real()();
  RealColumn get netPaid => real()();
  TextColumn get paymentDate => text()();
  TextColumn get status => text()();
  TextColumn get paymentMethod => text()();
  @override Set<Column> get primaryKey => {id};
}

class AssetsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get serialNumber => text()();
  TextColumn get purchaseDate => text()();
  RealColumn get cost => real()();
  TextColumn get status => text()();
  TextColumn get condition => text()();
  TextColumn get assignedToId => text().nullable()();
  TextColumn get assignedToName => text().nullable()();
  @override Set<Column> get primaryKey => {id};
}

class InventoryItemsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  IntColumn get quantity => integer()();
  IntColumn get minQuantity => integer()();
  TextColumn get unit => text()();
  RealColumn get pricePerUnit => real()();
  TextColumn get lastRestockedDate => text()();
  @override Set<Column> get primaryKey => {id};
}

class ProjectsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  TextColumn get clientId => text()();
  TextColumn get clientName => text()();
  TextColumn get startDate => text()();
  TextColumn get endDate => text()();
  TextColumn get status => text()();
  RealColumn get budget => real()();
  RealColumn get advancedPayment => real()();
  RealColumn get partialPayments => real()();
  RealColumn get finalPayment => real()();
  TextColumn get paymentStatus => text()();
  TextColumn get bankAccountId => text()();
  TextColumn get bankAccountName => text()();
  TextColumn get accountHolder => text()();
  TextColumn get teamMembers => text().map(const StringListConverter())();
  TextColumn get clientPaymentSource => text()();
  @override Set<Column> get primaryKey => {id};
}

class ProjectTasksTable extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get projectName => text()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get assigneeId => text()();
  TextColumn get assigneeName => text()();
  TextColumn get dueDate => text()();
  TextColumn get priority => text()();
  TextColumn get status => text()();
  @override Set<Column> get primaryKey => {id};
}

class TimesheetEntriesTable extends Table {
  TextColumn get id => text()();
  TextColumn get employeeId => text()();
  TextColumn get employeeName => text()();
  TextColumn get projectId => text()();
  TextColumn get projectName => text()();
  TextColumn get taskTitle => text()();
  TextColumn get date => text()();
  RealColumn get hours => real()();
  TextColumn get description => text()();
  TextColumn get status => text()();
  @override Set<Column> get primaryKey => {id};
}

class PurchaseOrdersTable extends Table {
  TextColumn get id => text()();
  TextColumn get vendorId => text()();
  TextColumn get vendorName => text()();
  TextColumn get date => text()();
  TextColumn get deliveryDate => text()();
  TextColumn get items => text().map(const PurchaseItemListConverter())();
  RealColumn get subtotal => real()();
  RealColumn get tax => real()();
  RealColumn get total => real()();
  TextColumn get status => text()();
  @override Set<Column> get primaryKey => {id};
}

class ProductsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  TextColumn get category => text()();
  RealColumn get price => real()();
  TextColumn get status => text()();
  @override Set<Column> get primaryKey => {id};
}

class SalesInvoicesTable extends Table {
  TextColumn get id => text()();
  TextColumn get clientId => text()();
  TextColumn get clientName => text()();
  TextColumn get date => text()();
  TextColumn get dueDate => text()();
  TextColumn get items => text().map(const InvoiceItemListConverter())();
  RealColumn get subtotal => real()();
  RealColumn get tax => real()();
  RealColumn get total => real()();
  TextColumn get status => text()();
  @override Set<Column> get primaryKey => {id};
}

abstract class DatabaseService {
  Future<void> initialize();
  // Transactions
  Future<List<Map<String, dynamic>>> getTransactions();
  Future<int> insertTransaction(Map<String, dynamic> data);
  // Activities
  Future<List<Map<String, dynamic>>> getActivities();
  Future<int> insertActivity(Map<String, dynamic> data);
  // Tasks
  Future<List<Map<String, dynamic>>> getTasks();
  Future<void> toggleTask(int id, bool isCompleted);
  // Alerts
  Future<List<Map<String, dynamic>>> getStockAlerts();
}

@DriftDatabase(tables: [
  TransactionsTable, ActivitiesTable, TasksTable, StockAlertsTable,
  ClientsTable, BankAccountsTable, ExpenseRecordsTable, IncomeRecordsTable, LedgerEntriesTable,
  LoanRecordsTable, AdvanceRecordsTable, AttendanceRecordsTable, EmployeesTable, SalaryRecordsTable,
  AssetsTable, InventoryItemsTable, ProjectsTable, ProjectTasksTable, TimesheetEntriesTable,
  PurchaseOrdersTable, ProductsTable, SalesInvoicesTable
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  @override int get schemaVersion => 2; // Bump version!
  
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) => m.createAll(),
        onUpgrade: (Migrator m, int from, int to) async {
          for (final table in allTables) {
            try {
              await m.createTable(table);
            } catch (e) {
              // Ignore if already exists
            }
          }
        },
      );
  
  // Generic CRUD for new tables
  Future<List<T>> getAll<TableDsl extends Table, T extends DataClass>(TableInfo<TableDsl, T> table) => select(table).get();
  Future<void> upsert<TableDsl extends Table, T extends DataClass>(TableInfo<TableDsl, T> table, Insertable<T> entity) => into(table).insertOnConflictUpdate(entity);
  Future<void> deleteById<TableDsl extends Table, T extends DataClass>(TableInfo<TableDsl, T> table, String id) => (delete(table)..where((tbl) => (tbl as dynamic).id.equals(id))).go();
  
  // Old specific ones for Transactions/Activities/Tasks
  Future<List<TransactionsTableData>> getAllTransactions() => select(transactionsTable).get();
  Future<int> addTransaction(TransactionsTableCompanion entry) => into(transactionsTable).insert(entry);
  Future<List<ActivitiesTableData>> getAllActivities() => select(activitiesTable).get();
  Future<int> addActivity(ActivitiesTableCompanion entry) => into(activitiesTable).insert(entry);
  Future<List<TasksTableData>> getAllTasks() => select(tasksTable).get();
  Future<int> addTask(TasksTableCompanion entry) => into(tasksTable).insert(entry);
  Future<void> updateTaskCompletion(int taskId, bool completed) {
    return (update(tasksTable)..where((t) => t.id.equals(taskId)))
        .write(TasksTableCompanion(isCompleted: Value(completed)));
  }
  Future<List<StockAlertsTableData>> getAllStockAlerts() => select(stockAlertsTable).get();
  Future<int> addStockAlert(StockAlertsTableCompanion entry) => into(stockAlertsTable).insert(entry);
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'erp_local.db'));
    return NativeDatabase(file);
  });
}

Future<File> getDatabaseFile() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  return File(p.join(dbFolder.path, 'erp_local.db'));
}

Future<Directory> getBackupsDirectory() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final backupDir = Directory(p.join(dbFolder.path, 'erp_backups'));
  if (!await backupDir.exists()) {
    await backupDir.create(recursive: true);
  }
  return backupDir;
}

class DriftDatabaseService implements DatabaseService {
  final AppDatabase db; // Made public to access AppDatabase directly from repositories
  DriftDatabaseService(this.db);
  @override Future<void> initialize() async {}
  
  // Transactions
  @override
  Future<List<Map<String, dynamic>>> getTransactions() async {
    final list = await db.getAllTransactions();
    return list.map((tx) => {'id': tx.id, 'details': tx.details, 'type': tx.type, 'amount': tx.amount, 'date': tx.date, 'isIncome': tx.isIncome}).toList();
  }
  @override
  Future<int> insertTransaction(Map<String, dynamic> data) async {
    return await db.addTransaction(TransactionsTableCompanion(
      details: Value(data['details'] as String), type: Value(data['type'] as String),
      amount: Value(data['amount'] as double), date: Value(data['date'] as String),
      isIncome: Value(data['isIncome'] as bool),
    ));
  }
  // Activities
  @override
  Future<List<Map<String, dynamic>>> getActivities() async {
    final list = await db.getAllActivities();
    return list.map((act) => {'id': act.id, 'content': act.content, 'timestamp': act.timestamp, 'iconName': act.iconName, 'colorHex': act.colorHex}).toList();
  }
  @override
  Future<int> insertActivity(Map<String, dynamic> data) async {
    return await db.addActivity(ActivitiesTableCompanion(
      content: Value(data['content'] as String), timestamp: Value(data['timestamp'] as String),
      iconName: Value(data['iconName'] as String), colorHex: Value(data['colorHex'] as String),
    ));
  }
  // Tasks (original tasks, not ProjectTasks)
  @override
  Future<List<Map<String, dynamic>>> getTasks() async {
    final list = await db.getAllTasks();
    return list.map((t) => {'id': t.id, 'name': t.name, 'dueDate': t.dueDate, 'assignee': t.assignee, 'isCompleted': t.isCompleted}).toList();
  }
  @override
  Future<void> toggleTask(int id, bool isCompleted) async {
    await db.updateTaskCompletion(id, isCompleted);
  }
  // Alerts
  @override
  Future<List<Map<String, dynamic>>> getStockAlerts() async {
    final list = await db.getAllStockAlerts();
    return list.map((a) => {'id': a.id, 'assetName': a.assetName, 'currentStatus': a.currentStatus, 'recommendation': a.recommendation, 'colorHex': a.colorHex, 'bgHex': a.bgHex}).toList();
  }
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final databaseServiceProvider = Provider<DriftDatabaseService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftDatabaseService(db);
});
