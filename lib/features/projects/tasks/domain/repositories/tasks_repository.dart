import '../entities/project_task.dart';

abstract class TasksRepository {
  Future<List<ProjectTask>> getTasks();
  Future<void> addTask(ProjectTask task);
  Future<void> updateTask(ProjectTask task);
  Future<void> deleteTask(String id);
}
