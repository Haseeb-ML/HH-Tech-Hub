import 'package:flutter/foundation.dart';
import 'package:software_house_erp/core/services/database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/auth/models/app_permissions.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/projects_repository.dart';
import '../../data/repositories/projects_repository_impl.dart';


class ProjectsState {
  final List<Project> projects;
  final bool isLoading;
  final String searchQuery;
  final String statusFilter;

  const ProjectsState({
    required this.projects,
    required this.isLoading,
    required this.searchQuery,
    required this.statusFilter,
  });

  ProjectsState copyWith({
    List<Project>? projects,
    bool? isLoading,
    String? searchQuery,
    String? statusFilter,
  }) {
    return ProjectsState(
      projects: projects ?? this.projects,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }

  List<Project> get filteredProjects {
    return projects.where((project) {
      final matchesSearch = project.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          project.clientName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          project.description.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesStatus = statusFilter == 'All' || project.status == statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();
  }
}

final projectsRepositoryProvider = Provider<ProjectsRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return ProjectsRepositoryImpl(dbService);
});

class ProjectsNotifier extends Notifier<ProjectsState> {
  ProjectsRepository get _repository => ref.read(projectsRepositoryProvider);

  @override
  ProjectsState build() {
    _loadProjects();
    return const ProjectsState(
      projects: [],
      isLoading: true,
      searchQuery: '',
      statusFilter: 'All',
    );
  }

  Future<void> _loadProjects() async {
    try {
      final list = await _repository.getProjects();
      state = state.copyWith(projects: list, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setStatusFilter(String filter) {
    state = state.copyWith(statusFilter: filter);
  }

  Future<void> addProject(Project project) async {
    final adminState = ref.read(adminProvider);
    if (!adminState.hasPermission(AppModule.projectsList, PermissionAction.create)) {
      debugPrint('Unauthorized: Missing create permission for projects');
      return;
    }
    state = state.copyWith(isLoading: true);
    await _repository.addProject(project);
    ref.read(adminProvider.notifier).logAction(
      action: 'Created project "${project.name}" (Client: ${project.clientName})',
      module: 'Projects',
    );
    final updated = await _repository.getProjects();
    state = state.copyWith(projects: updated, isLoading: false);
  }

  Future<void> updateProject(Project project) async {
    final adminState = ref.read(adminProvider);
    if (!adminState.hasPermission(AppModule.projectsList, PermissionAction.edit)) {
      debugPrint('Unauthorized: Missing edit permission for projects');
      return;
    }
    state = state.copyWith(isLoading: true);
    await _repository.updateProject(project);
    ref.read(adminProvider.notifier).logAction(
      action: 'Updated project "${project.name}" (Status: ${project.status})',
      module: 'Projects',
    );
    final updated = await _repository.getProjects();
    state = state.copyWith(projects: updated, isLoading: false);
  }

  Future<void> deleteProject(String id) async {
    final adminState = ref.read(adminProvider);
    if (!adminState.hasPermission(AppModule.projectsList, PermissionAction.delete)) {
      debugPrint('Unauthorized: Missing delete permission for projects');
      return;
    }
    final found = state.projects.where((p) => p.id == id).firstOrNull;
    final projName = found != null ? found.name : 'ID $id';

    state = state.copyWith(isLoading: true);
    await _repository.deleteProject(id);
    ref.read(adminProvider.notifier).logAction(
      action: 'Deleted project "$projName"',
      module: 'Projects',
    );
    final updated = await _repository.getProjects();
    state = state.copyWith(projects: updated, isLoading: false);
  }
}

final projectsProvider = NotifierProvider<ProjectsNotifier, ProjectsState>(() {
  return ProjectsNotifier();
});
