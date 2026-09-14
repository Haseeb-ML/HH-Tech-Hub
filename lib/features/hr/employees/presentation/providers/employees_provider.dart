import 'package:software_house_erp/core/services/database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/employee.dart';
import '../../domain/repositories/employees_repository.dart';
import '../../data/repositories/employees_repository_impl.dart';


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
    state = state.copyWith(isLoading: true);
    await _repository.addEmployee(employee);
    final updated = await _repository.getEmployees();
    state = state.copyWith(employees: updated, isLoading: false);
  }

  Future<void> updateEmployee(Employee employee) async {
    state = state.copyWith(isLoading: true);
    await _repository.updateEmployee(employee);
    final updated = await _repository.getEmployees();
    state = state.copyWith(employees: updated, isLoading: false);
  }

  Future<void> deleteEmployee(String id) async {
    state = state.copyWith(isLoading: true);
    await _repository.deleteEmployee(id);
    final updated = await _repository.getEmployees();
    state = state.copyWith(employees: updated, isLoading: false);
  }
}

final employeesProvider = NotifierProvider<EmployeesNotifier, EmployeesState>(() {
  return EmployeesNotifier();
});
