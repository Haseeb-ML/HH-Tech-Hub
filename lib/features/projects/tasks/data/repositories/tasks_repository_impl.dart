import 'package:software_house_erp/core/services/database_service.dart';
import '../../domain/entities/project_task.dart';
import '../../domain/repositories/tasks_repository.dart';

class TasksRepositoryImpl implements TasksRepository {
  final DriftDatabaseService _dbService;

  TasksRepositoryImpl(this._dbService);

  @override
  Future<List<ProjectTask>> getTasks() async {
    final list = await _dbService.db.getAll(_dbService.db.projectTasksTable);
    return list.map((t) => ProjectTask(
      id: t.id,
      projectId: t.projectId,
      projectName: t.projectName,
      title: t.title,
      description: t.description,
      assigneeId: t.assigneeId,
      assigneeName: t.assigneeName,
      dueDate: t.dueDate,
      priority: t.priority,
      status: t.status,
    )).toList();
  }

  @override
  Future<void> addTask(ProjectTask task) async {
    await _dbService.db.upsert(
      _dbService.db.projectTasksTable,
      ProjectTasksTableCompanion.insert(
        id: task.id,
        projectId: task.projectId,
        projectName: task.projectName,
        title: task.title,
        description: task.description,
        assigneeId: task.assigneeId,
        assigneeName: task.assigneeName,
        dueDate: task.dueDate,
        priority: task.priority,
        status: task.status,
      ),
    );
  }

  @override
  Future<void> updateTask(ProjectTask task) async {
    await addTask(task);
  }

  @override
  Future<void> deleteTask(String id) async {
    await _dbService.db.deleteById(_dbService.db.projectTasksTable, id);
  }
}
