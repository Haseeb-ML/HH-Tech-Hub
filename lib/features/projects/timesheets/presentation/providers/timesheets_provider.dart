import 'package:software_house_erp/core/services/database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/timesheet_entry.dart';
import '../../domain/repositories/timesheets_repository.dart';
import '../../data/repositories/timesheets_repository_impl.dart';
import 'package:software_house_erp/core/auth/models/app_permissions.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';


class TimesheetsState {
  final List<TimesheetEntry> entries;
  final bool isLoading;
  final String searchQuery;
  final String projectIdFilter;
  final String employeeIdFilter;
  final String statusFilter;

  const TimesheetsState({
    required this.entries,
    required this.isLoading,
    required this.searchQuery,
    required this.projectIdFilter,
    required this.employeeIdFilter,
    required this.statusFilter,
  });

  TimesheetsState copyWith({
    List<TimesheetEntry>? entries,
    bool? isLoading,
    String? searchQuery,
    String? projectIdFilter,
    String? employeeIdFilter,
    String? statusFilter,
  }) {
    return TimesheetsState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      projectIdFilter: projectIdFilter ?? this.projectIdFilter,
      employeeIdFilter: employeeIdFilter ?? this.employeeIdFilter,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }

  List<TimesheetEntry> get filteredEntries {
    return entries.where((entry) {
      final matchesSearch = entry.taskTitle.toLowerCase().contains(searchQuery.toLowerCase()) ||
          entry.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
          entry.employeeName.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesProject = projectIdFilter == 'All' || entry.projectId == projectIdFilter;
      final matchesEmployee = employeeIdFilter == 'All' || entry.employeeId == employeeIdFilter;
      final matchesStatus = statusFilter == 'All' || entry.status == statusFilter;

      return matchesSearch && matchesProject && matchesEmployee && matchesStatus;
    }).toList();
  }
}

final timesheetsRepositoryProvider = Provider<TimesheetsRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return TimesheetsRepositoryImpl(dbService);
});

class TimesheetsNotifier extends Notifier<TimesheetsState> {
  TimesheetsRepository get _repository => ref.read(timesheetsRepositoryProvider);

  @override
  TimesheetsState build() {
    _loadTimesheets();
    return const TimesheetsState(
      entries: [],
      isLoading: true,
      searchQuery: '',
      projectIdFilter: 'All',
      employeeIdFilter: 'All',
      statusFilter: 'All',
    );
  }

  Future<void> _loadTimesheets() async {
    try {
      final list = await _repository.getTimesheets();
      state = state.copyWith(entries: list, isLoading: false);
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

  void setEmployeeIdFilter(String filter) {
    state = state.copyWith(employeeIdFilter: filter);
  }

  void setStatusFilter(String filter) {
    state = state.copyWith(statusFilter: filter);
  }

  Future<void> addTimesheet(TimesheetEntry entry) async {
    final adminState = ref.read(adminProvider);
    if (!adminState.hasPermission(AppModule.timesheets, PermissionAction.create)) {
      return;
    }
    state = state.copyWith(isLoading: true);
    await _repository.addTimesheet(entry);
    ref.read(adminProvider.notifier).logAction(
      action: 'Added timesheet: ${entry.taskTitle} by ${entry.employeeName} (${entry.hours}h)',
      module: 'Projects',
    );
    final updated = await _repository.getTimesheets();
    state = state.copyWith(entries: updated, isLoading: false);
  }

  Future<void> updateTimesheet(TimesheetEntry entry) async {
    final adminState = ref.read(adminProvider);
    if (!adminState.hasPermission(AppModule.timesheets, PermissionAction.edit)) {
      return;
    }
    state = state.copyWith(isLoading: true);
    await _repository.updateTimesheet(entry);
    ref.read(adminProvider.notifier).logAction(
      action: 'Updated timesheet: ${entry.taskTitle} by ${entry.employeeName} (${entry.hours}h, Status: ${entry.status})',
      module: 'Projects',
    );
    final updated = await _repository.getTimesheets();
    state = state.copyWith(entries: updated, isLoading: false);
  }

  Future<void> deleteTimesheet(String id) async {
    final adminState = ref.read(adminProvider);
    if (!adminState.hasPermission(AppModule.timesheets, PermissionAction.delete)) {
      return;
    }
    state = state.copyWith(isLoading: true);
    await _repository.deleteTimesheet(id);
    ref.read(adminProvider.notifier).logAction(
      action: 'Deleted timesheet: $id',
      module: 'Projects',
    );
    final updated = await _repository.getTimesheets();
    state = state.copyWith(entries: updated, isLoading: false);
  }
}

final timesheetsProvider = NotifierProvider<TimesheetsNotifier, TimesheetsState>(() {
  return TimesheetsNotifier();
});
