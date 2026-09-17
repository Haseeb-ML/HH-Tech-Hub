import 'package:software_house_erp/core/services/database_service.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/projects_repository.dart';

class ProjectsRepositoryImpl implements ProjectsRepository {
  final DriftDatabaseService _dbService;

  ProjectsRepositoryImpl(this._dbService);

  @override
  Future<List<Project>> getProjects() async {
    final list = await _dbService.db.getAll(_dbService.db.projectsTable);
    return list.map((p) => Project(
      id: p.id,
      name: p.name,
      description: p.description,
      clientId: p.clientId,
      clientName: p.clientName,
      startDate: p.startDate,
      endDate: p.endDate,
      status: p.status,
      budget: p.budget,
      advancedPayment: p.advancedPayment,
      partialPayments: p.partialPayments,
      finalPayment: p.finalPayment,
      paymentStatus: p.paymentStatus,
      bankAccountId: p.bankAccountId,
      bankAccountName: p.bankAccountName,
      accountHolder: p.accountHolder,
      teamMembers: p.teamMembers,
      clientPaymentSource: p.clientPaymentSource,
    )).toList();
  }

  @override
  Future<void> addProject(Project project) async {
    await _dbService.db.upsert(
      _dbService.db.projectsTable,
      ProjectsTableCompanion.insert(
        id: project.id,
        name: project.name,
        description: project.description,
        clientId: project.clientId,
        clientName: project.clientName,
        startDate: project.startDate,
        endDate: project.endDate,
        status: project.status,
        budget: project.budget,
        advancedPayment: project.advancedPayment,
        partialPayments: project.partialPayments,
        finalPayment: project.finalPayment,
        paymentStatus: project.paymentStatus,
        bankAccountId: project.bankAccountId,
        bankAccountName: project.bankAccountName,
        accountHolder: project.accountHolder,
        teamMembers: project.teamMembers,
        clientPaymentSource: project.clientPaymentSource,
      ),
    );
  }

  @override
  Future<void> updateProject(Project project) async {
    await addProject(project);
  }

  @override
  Future<void> deleteProject(String id) async {
    await _dbService.db.deleteById(_dbService.db.projectsTable, id);
  }
}
