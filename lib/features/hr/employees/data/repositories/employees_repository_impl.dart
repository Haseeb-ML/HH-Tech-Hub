import 'package:software_house_erp/core/services/database_service.dart';
import '../../domain/entities/employee.dart';
import '../../domain/repositories/employees_repository.dart';
import 'package:drift/drift.dart';

class EmployeesRepositoryImpl implements EmployeesRepository {
  final DriftDatabaseService _dbService;

  EmployeesRepositoryImpl(this._dbService);

  @override
  Future<List<Employee>> getEmployees() async {
    final list = await _dbService.db.getAll(_dbService.db.employeesTable);
    return list.map((e) => Employee(
      id: e.id,
      name: e.name,
      email: e.email,
      phones: e.phones,
      cnic: e.cnic,
      designation: e.designation,
      department: e.department,
      joiningDate: e.joiningDate,
      leavingDate: e.leavingDate,
      status: e.status,
      salaryType: e.salaryType,
      baseSalary: e.baseSalary,
      paymentMethod: e.paymentMethod,
    )).toList();
  }

  @override
  Future<void> addEmployee(Employee employee) async {
    await _dbService.db.upsert(
      _dbService.db.employeesTable,
      EmployeesTableCompanion.insert(
        id: employee.id,
        name: employee.name,
        email: employee.email,
        phones: employee.phones,
        cnic: Value(employee.cnic),
        designation: employee.designation,
        department: employee.department,
        joiningDate: employee.joiningDate,
        leavingDate: Value(employee.leavingDate),
        status: employee.status,
        salaryType: employee.salaryType,
        baseSalary: employee.baseSalary,
        paymentMethod: employee.paymentMethod,
      ),
    );
  }

  @override
  Future<void> updateEmployee(Employee employee) async {
    await addEmployee(employee);
  }

  @override
  Future<void> deleteEmployee(String id) async {
    await _dbService.db.deleteById(_dbService.db.employeesTable, id);
  }
}
