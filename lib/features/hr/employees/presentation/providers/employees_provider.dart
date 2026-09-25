import 'package:software_house_erp/core/services/database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/employee.dart';
import '../../domain/repositories/employees_repository.dart';
import '../../data/repositories/employees_repository_impl.dart';
import 'package:software_house_erp/core/auth/models/app_permissions.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';


class EmployeesState {
  final List<Employee> employees;
  final bool isLoading;
  final String searchQuery;
  final String departmentFilter;
  final String statusFilter;

  const EmployeesState({
    required this.employees,
    required this.isLoading,
    required this.searchQuery,
    required this.departmentFilter,
    required this.statusFilter,
  });

  EmployeesState copyWith({
    List<Employee>? employees,
    bool? isLoading,
    String? searchQuery,
    String? departmentFilter,
    String? statusFilter,
  }) {
    return EmployeesState(
      employees: employees ?? this.employees,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      departmentFilter: departmentFilter ?? this.departmentFilter,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }

  List<Employee> get filteredEmployees {
    return employees.where((emp) {
      final matchesSearch = emp.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          emp.designation.toLowerCase().contains(searchQuery.toLowerCase()) ||
          emp.email.toLowerCase().contains(searchQuery.toLowerCase()) ||
          emp.department.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesDept = departmentFilter == 'All' || emp.department == departmentFilter;
      final matchesStatus = statusFilter == 'All' || emp.status == statusFilter;

      return matchesSearch && matchesDept && matchesStatus;
    }).toList();
  }
}

final employeesRepositoryProvider = Provider<EmployeesRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return EmployeesRepositoryImpl(dbService);
});

class EmployeesNotifier extends Notifier<EmployeesState> {
  EmployeesRepository get _repository => ref.read(employeesRepositoryProvider);

  @override
  EmployeesState build() {
    _loadEmployees();
    return const EmployeesState(
      employees: [],
      isLoading: true,
      searchQuery: '',
      departmentFilter: 'All',
      statusFilter: 'All',
    );
  }

  Future<void> _loadEmployees() async {
    try {
      final list = await _repository.getEmployees();
      state = state.copyWith(employees: list, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setDepartmentFilter(String dept) {
    state = state.copyWith(departmentFilter: dept);
  }

  void setStatusFilter(String status) {
    state = state.copyWith(statusFilter: status);
  }

  Future<void> addEmployee(Employee employee) async {
    final adminState = ref.read(adminProvider);
    if (!adminState.hasPermission(AppModule.employees, PermissionAction.create)) {
      throw Exception('Access Denied: You do not have permission to add employees.');
    }

    state = state.copyWith(isLoading: true);
    await _repository.addEmployee(employee);
    ref.read(adminProvider.notifier).logAction(
      action: 'Added new employee: ${employee.name} (${employee.designation})',
      module: 'HR',
    );
    final updated = await _repository.getEmployees();
    state = state.copyWith(employees: updated, isLoading: false);
  }

  Future<void> updateEmployee(Employee employee) async {
    final adminState = ref.read(adminProvider);
    if (!adminState.hasPermission(AppModule.employees, PermissionAction.edit)) {
      throw Exception('Access Denied: You do not have permission to edit employees.');
    }

    state = state.copyWith(isLoading: true);
    await _repository.updateEmployee(employee);
    ref.read(adminProvider.notifier).logAction(
      action: 'Updated employee: ${employee.name}',
      module: 'HR',
    );
    final updated = await _repository.getEmployees();
    state = state.copyWith(employees: updated, isLoading: false);
  }

  Future<void> deleteEmployee(String id) async {
    final adminState = ref.read(adminProvider);
    if (!adminState.hasPermission(AppModule.employees, PermissionAction.delete)) {
      throw Exception('Access Denied: You do not have permission to delete employees.');
    }

    final found = state.employees.where((e) => e.id == id).firstOrNull;
    final empName = found != null ? found.name : 'ID $id';

    state = state.copyWith(isLoading: true);
    await _repository.deleteEmployee(id);
    ref.read(adminProvider.notifier).logAction(
      action: 'Deleted employee: $empName',
      module: 'HR',
    );
    final updated = await _repository.getEmployees();
    state = state.copyWith(employees: updated, isLoading: false);
  }
}

final employeesProvider = NotifierProvider<EmployeesNotifier, EmployeesState>(() {
  return EmployeesNotifier();
});
