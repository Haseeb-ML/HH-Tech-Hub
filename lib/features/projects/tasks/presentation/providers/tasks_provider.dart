import 'package:software_house_erp/core/services/database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/project_task.dart';
import '../../domain/repositories/tasks_repository.dart';
import '../../data/repositories/tasks_repository_impl.dart';



class TasksState {
  final List<ProjectTask> tasks;
  final bool isLoading;
  final String searchQuery;
  final String projectIdFilter;
  final String priorityFilter;
  final String assigneeFilter;

  const TasksState({
    required this.tasks,
    required this.isLoading,
    required this.searchQuery,
    required this.projectIdFilter,
    required this.priorityFilter,
    required this.assigneeFilter,
  });

  TasksState copyWith({
    List<ProjectTask>? tasks,
    bool? isLoading,
    String? searchQuery,
    String? projectIdFilter,
    String? priorityFilter,
    String? assigneeFilter,
  }) {
    return TasksState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      projectIdFilter: projectIdFilter ?? this.projectIdFilter,
      priorityFilter: priorityFilter ?? this.priorityFilter,
      assigneeFilter: assigneeFilter ?? this.assigneeFilter,
    );
  }

  List<ProjectTask> get filteredTasks {
    return tasks.where((task) {
      final matchesSearch = task.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          task.description.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesProject = projectIdFilter == 'All' || task.projectId == projectIdFilter;
      final matchesPriority = priorityFilter == 'All' || task.priority == priorityFilter;
      final matchesAssignee = assigneeFilter == 'All' || task.assigneeId == assigneeFilter;

      return matchesSearch && matchesProject && matchesPriority && matchesAssignee;
    }).toList();
  }
}

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return TasksRepositoryImpl(dbService);
});

class TasksNotifier extends Notifier<TasksState> {
  TasksRepository get _repository => ref.read(tasksRepositoryProvider);

  @override
  TasksState build() {
    _loadTasks();
    return const TasksState(
      tasks: [],
      isLoading: true,
      searchQuery: '',
      projectIdFilter: 'All',
      priorityFilter: 'All',
      assigneeFilter: 'All',
    );
  }

  Future<void> _loadTasks() async {
    try {
      final list = await _repository.getTasks();
      state = state.copyWith(tasks: list, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setProjectIdFilter(String filter) {
    state = state.copyWith(projectIdFilter: filter);
  }

  void setPriorityFilter(String filter) {
    state = state.copyWith(priorityFilter: filter);
  }

  void setAssigneeFilter(String filter) {
    state = state.copyWith(assigneeFilter: filter);
  }

  Future<void> addTask(ProjectTask task) async {
    state = state.copyWith(isLoading: true);
    await _repository.addTask(task);
    final updated = await _repository.getTasks();
    state = state.copyWith(tasks: updated, isLoading: false);
  }

  Future<void> updateTask(ProjectTask task) async {
    state = state.copyWith(isLoading: true);
    await _repository.updateTask(task);
    final updated = await _repository.getTasks();
    state = state.copyWith(tasks: updated, isLoading: false);
  }

  Future<void> deleteTask(String id) async {
    state = state.copyWith(isLoading: true);
    await _repository.deleteTask(id);
    final updated = await _repository.getTasks();
    state = state.copyWith(tasks: updated, isLoading: false);
  }
}

final tasksProvider = NotifierProvider<TasksNotifier, TasksState>(() {
  return TasksNotifier();
});
