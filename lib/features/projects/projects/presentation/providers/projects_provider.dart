import 'package:software_house_erp/core/services/database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    state = state.copyWith(isLoading: true);
    await _repository.addProject(project);
    final updated = await _repository.getProjects();
    state = state.copyWith(projects: updated, isLoading: false);
  }

  Future<void> updateProject(Project project) async {
    state = state.copyWith(isLoading: true);
    await _repository.updateProject(project);
    final updated = await _repository.getProjects();
    state = state.copyWith(projects: updated, isLoading: false);
  }

  Future<void> deleteProject(String id) async {
    state = state.copyWith(isLoading: true);
    await _repository.deleteProject(id);
    final updated = await _repository.getProjects();
    state = state.copyWith(projects: updated, isLoading: false);
  }
}

final projectsProvider = NotifierProvider<ProjectsNotifier, ProjectsState>(() {
  return ProjectsNotifier();
});
