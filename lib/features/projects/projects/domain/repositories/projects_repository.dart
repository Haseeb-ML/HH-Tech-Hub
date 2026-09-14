import '../entities/project.dart';

abstract class ProjectsRepository {
  Future<List<Project>> getProjects();
  Future<void> addProject(Project project);
  Future<void> updateProject(Project project);
  Future<void> deleteProject(String id);
}
