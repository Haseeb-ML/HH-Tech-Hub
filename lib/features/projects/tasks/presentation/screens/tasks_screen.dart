import 'package:flutter/material.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/features/projects/shared/widgets/projects_sub_nav.dart';
import '../providers/tasks_provider.dart';
import '../../domain/entities/project_task.dart';
import 'package:software_house_erp/core/widgets/export_button.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import '../../../../hr/employees/presentation/providers/employees_provider.dart';
import 'package:software_house_erp/core/widgets/explain_tooltip.dart';
import 'package:software_house_erp/core/auth/models/app_permissions.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    debugPrint('TasksScreen: build method called');
    final state = ref.watch(tasksProvider);
    final projects = ref.watch(projectsProvider).projects;
    final employees = ref.watch(employeesProvider).employees;
    final theme = Theme.of(context);
    final adminState = ref.watch(adminProvider);
    final canCreate = adminState.hasPermission(AppModule.tasks, PermissionAction.create);

    // Kanban columns
    final columns = ['To Do', 'In Progress', 'In Review', 'Done'];

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: state.isLoading && state.tasks.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const ProjectsSubNav(activeRoute: '/projects/tasks'),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 12.0 : 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title + Add Button Row
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isMobile = constraints.maxWidth < 650;
                            final titleWidget = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Task Board',
                                  style: theme.textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: context.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Manage project operations and tasks workflow using an agile Kanban Board.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            );

                            final actions = Wrap(
                              spacing: 12,
                              runSpacing: 10,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                ExportButton(
                                  title: 'Project Tasks Board',
                                  fileName: 'project_tasks_export',
                                  headers: ['Task ID', 'Project ID', 'Project Name', 'Title', tr('Description'), 'Assignee Name', tr('Due Date'), tr('Priority'), tr('Status')],
                                  rows: state.filteredTasks.map((t) => [
                                    t.id,
                                    t.projectId,
                                    t.projectName,
                                    t.title,
                                    t.description,
                                    t.assigneeName,
                                    t.dueDate,
                                    t.priority,
                                    t.status,
                                  ]).toList(),
                                ),
                                if (canCreate)
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final result = await showDialog<ProjectTask>(
                                        context: context,
                                        builder: (context) => const _AddEditTaskDialog(),
                                      );
                                      if (result != null) {
                                        ref.read(tasksProvider.notifier).addTask(result);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('${tr("Task")} "${result.title}" ${tr("added successfully.")}'),
                                            behavior: SnackBarBehavior.floating,
                                            backgroundColor: context.success,
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Add Task'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: context.primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                  ),
                              ],
                            );

                            if (isMobile) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  titleWidget,
                                  const SizedBox(height: 14),
                                  actions,
                                ],
                              );
                            }

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(child: titleWidget),
                                const SizedBox(width: 16),
                                actions,
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Search and Filters Bar
                        GlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final isNarrow = constraints.maxWidth < 750;

                                final searchWidget = Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: context.border, width: 1),
                                  ),
                                  child: TextField(
                                    onChanged: (val) => ref.read(tasksProvider.notifier).setSearchQuery(val),
                                    style: TextStyle(color: context.textPrimary),
                                    decoration: InputDecoration(
                                      hintText: tr('Search tasks by title or details...'),
                                      hintStyle: TextStyle(
                                        fontSize: 13,
                                        color: context.textMuted,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search,
                                        size: 18,
                                        color: context.textMuted,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                  ),
                                );

                                final projectFilter = Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: context.border, width: 1),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: state.projectIdFilter,
                                      dropdownColor: context.cardBg,
                                      style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                      items: [
                                        const DropdownMenuItem(value: 'All', child: Text('All Projects')),
                                        ...projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          ref.read(tasksProvider.notifier).setProjectIdFilter(val);
                                        }
                                      },
                                    ),
                                  ),
                                );

                                final assigneeFilter = Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: context.border, width: 1),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: state.assigneeFilter,
                                      dropdownColor: context.cardBg,
                                      style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                      items: [
                                        const DropdownMenuItem(value: 'All', child: Text('All Assignees')),
                                        ...employees.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          ref.read(tasksProvider.notifier).setAssigneeFilter(val);
                                        }
                                      },
                                    ),
                                  ),
                                );

                                final priorityFilter = Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: context.border, width: 1),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: state.priorityFilter,
                                      dropdownColor: context.cardBg,
                                      style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                      items: ['All', 'Low', 'Medium', 'High'].map((p) {
                                        return DropdownMenuItem<String>(
                                          value: p,
                                          child: Text('${tr('Priority')}: ${p == 'All' ? tr('All') : tr(p)}'),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          ref.read(tasksProvider.notifier).setPriorityFilter(val);
                                        }
                                      },
                                    ),
                                  ),
                                );

                                if (isNarrow) {
                                  return Column(
                                    children: [
                                      searchWidget,
                                      const SizedBox(height: 12),
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: [
                                            SizedBox(width: 150, child: projectFilter),
                                            const SizedBox(width: 10),
                                            SizedBox(width: 150, child: assigneeFilter),
                                            const SizedBox(width: 10),
                                            priorityFilter,
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(flex: 2, child: searchWidget),
                                    const SizedBox(width: 12),
                                    Expanded(child: projectFilter),
                                    const SizedBox(width: 12),
                                    Expanded(child: assigneeFilter),
                                    const SizedBox(width: 12),
                                    priorityFilter,
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Kanban Columns Layout
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 900;
                              return isWide
                                  ? Row(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: columns.map((colStatus) {
                                        final colTasks = state.filteredTasks.where((t) => t.status == colStatus).toList();
                                        return Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                            child: _KanbanColumn(
                                              status: colStatus,
                                              tasks: colTasks,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    )
                                  : _MobileKanbanView(
                                      columns: columns,
                                      tasks: state.filteredTasks,
                                    );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _MobileKanbanView extends ConsumerStatefulWidget {
  final List<String> columns;
  final List<ProjectTask> tasks;

  const _MobileKanbanView({
    required this.columns,
    required this.tasks,
  });

  @override
  ConsumerState<_MobileKanbanView> createState() => _MobileKanbanViewState();
}

class _MobileKanbanViewState extends ConsumerState<_MobileKanbanView> {
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.columns.isNotEmpty ? widget.columns.first : 'To Do';
  }

  Color _getStatusColor(BuildContext context, String status) {
    if (status == 'In Progress') {
      return context.warning;
    } else if (status == 'In Review') {
      return Colors.purple;
    } else if (status == 'Done') {
      return context.success;
    }
    return context.primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final statusTasks = widget.tasks.where((t) => t.status == _selectedStatus).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Responsive Status Tab Bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: widget.columns.map((status) {
              final isSelected = status == _selectedStatus;
              final count = widget.tasks.where((t) => t.status == status).length;
              final statusColor = _getStatusColor(context, status);

              return Padding(
                padding: const EdgeInsets.only(right: 8.0, bottom: 4.0),
                child: InkWell(
                  onTap: () => setState(() => _selectedStatus = status),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? statusColor.withOpacity(0.12) : context.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? statusColor : context.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          tr(status),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? statusColor : context.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? statusColor
                                : (context.isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : context.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // Task Cards List
        Expanded(
          child: statusTasks.isEmpty
              ? Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_turned_in_outlined,
                        size: 44,
                        color: context.textSecondary.withOpacity(0.4),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No tasks in ${tr(_selectedStatus)}',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: statusTasks.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: _TaskCard(task: statusTasks[index]),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _KanbanColumn extends ConsumerWidget {
  final String status;
  final List<ProjectTask> tasks;

  const _KanbanColumn({required this.status, required this.tasks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);
    final adminState = ref.watch(adminProvider);
    final canEdit = adminState.hasPermission(AppModule.tasks, PermissionAction.edit);
    
    // Status border color mapping
    Color headerBorderColor = context.primaryColor;
    if (status == 'In Progress') {
      headerBorderColor = context.warning;
    } else if (status == 'In Review') {
      headerBorderColor = Colors.purple;
    } else if (status == 'Done') {
      headerBorderColor = context.success;
    }

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Column Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: context.border, width: 1),
                top: BorderSide(color: headerBorderColor, width: 3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr(status),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.isDarkMode ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: context.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Cards list
          Expanded(
            child: DragTarget<ProjectTask>(
              onWillAcceptWithDetails: canEdit ? (details) => details.data.status != status : (_) => false,
              onAcceptWithDetails: canEdit
                  ? (details) {
                      ref.read(tasksProvider.notifier).updateTask(
                        details.data.copyWith(status: status),
                      );
                    }
                  : null,
              builder: (context, candidateData, rejectedData) {
                return Container(
                  decoration: BoxDecoration(
                    color: candidateData.isNotEmpty
                        ? context.primaryColor.withOpacity(0.05)
                        : Colors.transparent,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: LongPressDraggable<ProjectTask>(
                          maxSimultaneousDrags: canEdit ? 1 : 0,
                          data: task,
                          delay: const Duration(milliseconds: 150),
                          feedback: Material(
                            elevation: 8,
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 300,
                              child: Opacity(
                                opacity: 0.95,
                                child: _TaskCard(task: task),
                              ),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: _TaskCard(task: task),
                          ),
                          child: ExplainTooltip(
                            message: '• Task: ${task.title}\n• Project: ${task.projectName}\n• Assigned to: ${task.assigneeName}\n• Priority: ${task.priority} | Status: ${task.status}\n• Due: ${task.dueDate}\n• Drag card to move between columns\n• Click ⋮ menu to edit or delete',
                            child: _TaskCard(task: task),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends ConsumerWidget {
  final ProjectTask task;

  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);
    final initials = task.assigneeName.split(' ').map((e) => e[0]).take(2).join().toUpperCase();

    // Priority color mapping
    Color priorityColor = context.success;
    Color priorityBg = context.successLight;
    if (task.priority == 'High') {
      priorityColor = context.error;
      priorityBg = context.errorLight;
    } else if (task.priority == 'Medium') {
      priorityColor = context.warning;
      priorityBg = context.warningLight;
    }

    final isAutoExplain = ref.watch(autoExplainProvider);
    final adminState = ref.watch(adminProvider);
    final canEdit = adminState.hasPermission(AppModule.tasks, PermissionAction.edit);
    final canDelete = adminState.hasPermission(AppModule.tasks, PermissionAction.delete);

    return Container(
        decoration: BoxDecoration(
        color: context.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isAutoExplain ? context.primaryColor : context.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Project name badge & Actions popup
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  task.projectName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: context.primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (canEdit || canDelete)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 16, color: context.textSecondary),
                  color: context.cardBg,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 100),
                  onSelected: (val) async {
                    if (val == 'delete' && canDelete) {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Task'),
                          content: Text('${tr("Are you sure you want to delete task")} "${task.title}"? ${tr("This action cannot be undone.")}'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(tr('Cancel'), style: TextStyle(color: context.textSecondary)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(tr('Delete'), style: TextStyle(color: context.error)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        ref.read(tasksProvider.notifier).deleteTask(task.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${tr("Task")} "${task.title}" ${tr("deleted.")}'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: context.error,
                          ),
                        );
                      }
                    } else if (val == 'edit' && canEdit) {
                      final result = await showDialog<ProjectTask>(
                        context: context,
                        builder: (context) => _AddEditTaskDialog(task: task),
                      );
                      if (result != null) {
                        ref.read(tasksProvider.notifier).updateTask(result);
                      }
                    } else if (val.startsWith('move_') && canEdit) {
                      final targetStatus = val.substring(5);
                      ref.read(tasksProvider.notifier).updateTask(task.copyWith(status: targetStatus));
                    }
                  },
                  itemBuilder: (context) {
                    final otherStatuses = ['To Do', 'In Progress', 'In Review', 'Done']
                        .where((s) => s != task.status)
                        .toList();
                    return [
                      if (canEdit)
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit Task', style: TextStyle(color: context.textPrimary, fontSize: 12)),
                        ),
                      if (canEdit)
                        ...otherStatuses.map((s) => PopupMenuItem(
                          value: 'move_$s',
                          child: Text('Move to "$s"', style: TextStyle(color: context.textSecondary, fontSize: 12)),
                        )),
                      if (canDelete)
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete Task', style: TextStyle(color: context.error, fontSize: 12)),
                        ),
                    ];
                  },
                ),
            ],
          ),
          const SizedBox(height: 6),

          // Title
          Text(
            task.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
              fontSize: 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // Description
          Text(
            task.description,
            style: TextStyle(color: context.textSecondary, fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Row 3: Priority badge & Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  task.priority,
                  style: TextStyle(
                    color: priorityColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 10, color: context.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    task.dueDate,
                    style: TextStyle(color: context.textSecondary, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Assignee details row
          Row(
            children: [
              CircleAvatar(
                radius: 10,
                backgroundColor: context.primaryColor.withOpacity(0.15),
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: context.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.assigneeName,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddEditTaskDialog extends ConsumerStatefulWidget {
  final ProjectTask? task;

  const _AddEditTaskDialog({this.task});

  @override
  ConsumerState<_AddEditTaskDialog> createState() => _AddEditTaskDialogState();
}

class _AddEditTaskDialogState extends ConsumerState<_AddEditTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  
  String? _selectedProjectId;
  String? _selectedProjectName;
  String? _selectedAssigneeId;
  String? _selectedAssigneeName;
  
  String _priority = 'Medium';
  String _status = 'To Do';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descController = TextEditingController(text: widget.task?.description ?? '');
    
    if (widget.task != null) {
      _selectedProjectId = widget.task!.projectId;
      _selectedProjectName = widget.task!.projectName;
      _selectedAssigneeId = widget.task!.assigneeId;
      _selectedAssigneeName = widget.task!.assigneeName;
      _priority = widget.task!.priority;
      _status = widget.task!.status;
      _dueDate = DateTime.tryParse(widget.task!.dueDate) ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      backgroundColor: context.cardBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Consumer(
        builder: (context, ref, child) {
          final projects = ref.watch(projectsProvider).projects;

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Center(
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.task == null ? 'Create New Task' : 'Edit Task Details',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          color: context.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Project Select
                    _buildLabel(tr('Project')),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedProjectId,
                      dropdownColor: context.cardBg,
                      style: TextStyle(color: context.textPrimary, fontSize: 13),
                      decoration: _buildInputDecoration('Choose associated project'),
                      validator: (val) => val == null ? 'Please select project' : null,
                      items: projects.map((p) {
                        return DropdownMenuItem(value: p.id, child: Text(p.name));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final project = projects.firstWhere((p) => p.id == val);
                          final allEmployees = ref.read(employeesProvider).employees;
                          final teamNames = project.teamMembers.isEmpty 
                              ? ['Unassigned'] 
                              : project.teamMembers.map((id) {
                                  try {
                                    return allEmployees.firstWhere((e) => e.id == id).name;
                                  } catch (_) {
                                    return 'Unknown';
                                  }
                                }).toList();

                          setState(() {
                            _selectedProjectId = val;
                            _selectedProjectName = project.name;
                            _selectedAssigneeId = project.teamMembers.isEmpty ? 'unassigned' : project.teamMembers.join(', ');
                            _selectedAssigneeName = teamNames.join(', ');
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Task Title
                    _buildLabel('Task Title'),
                    TextFormField(
                      controller: _titleController,
                      style: TextStyle(color: context.textPrimary),
                      decoration: _buildInputDecoration('e.g. Develop login page'),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter task title' : null,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    _buildLabel('Description / Specifications'),
                    TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      style: TextStyle(color: context.textPrimary),
                      decoration: _buildInputDecoration('Task description...'),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter task details' : null,
                    ),
                    const SizedBox(height: 16),

                    // Priority & Status Row
                    if (isMobile) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(tr('Priority')),
                          DropdownButtonFormField<String>(
                            initialValue: _priority,
                            dropdownColor: context.cardBg,
                            style: TextStyle(color: context.textPrimary, fontSize: 13),
                            decoration: _buildInputDecoration(''),
                            items: [
                              DropdownMenuItem(value: 'Low', child: Text(tr('Low'))),
                              DropdownMenuItem(value: 'Medium', child: Text(tr('Medium'))),
                              DropdownMenuItem(value: 'High', child: Text(tr('High'))),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _priority = val);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(tr('Status')),
                          DropdownButtonFormField<String>(
                            initialValue: _status,
                            dropdownColor: context.cardBg,
                            style: TextStyle(color: context.textPrimary, fontSize: 13),
                            decoration: _buildInputDecoration(''),
                            items: [
                              DropdownMenuItem(value: 'To Do', child: Text(tr('To Do'))),
                              DropdownMenuItem(value: 'In Progress', child: Text(tr('In Progress'))),
                              DropdownMenuItem(value: 'In Review', child: Text(tr('In Review'))),
                              DropdownMenuItem(value: 'Done', child: Text(tr('Done'))),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _status = val);
                            },
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel(tr('Priority')),
                                DropdownButtonFormField<String>(
                                  initialValue: _priority,
                                  dropdownColor: context.cardBg,
                                  style: TextStyle(color: context.textPrimary, fontSize: 13),
                                  decoration: _buildInputDecoration(''),
                                  items: [
                                    DropdownMenuItem(value: 'Low', child: Text(tr('Low'))),
                                    DropdownMenuItem(value: 'Medium', child: Text(tr('Medium'))),
                                    DropdownMenuItem(value: 'High', child: Text(tr('High'))),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _priority = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel(tr('Status')),
                                DropdownButtonFormField<String>(
                                  initialValue: _status,
                                  dropdownColor: context.cardBg,
                                  style: TextStyle(color: context.textPrimary, fontSize: 13),
                                  decoration: _buildInputDecoration(''),
                                  items: [
                                    DropdownMenuItem(value: 'To Do', child: Text(tr('To Do'))),
                                    DropdownMenuItem(value: 'In Progress', child: Text(tr('In Progress'))),
                                    DropdownMenuItem(value: 'In Review', child: Text(tr('In Review'))),
                                    DropdownMenuItem(value: 'Done', child: Text(tr('Done'))),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _status = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Due Date
                    _buildLabel(tr('Due Date')),
                    OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dueDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => _dueDate = picked);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: context.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _dueDate.toIso8601String().substring(0, 10),
                            style: TextStyle(color: context.textPrimary),
                          ),
                          Icon(Icons.calendar_today, size: 16, color: context.primaryColor),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(tr('Cancel'), style: TextStyle(color: context.textSecondary)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            final adminState = ref.read(adminProvider);
                            if (widget.task == null && !adminState.hasPermission(AppModule.tasks, PermissionAction.create)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Access Denied: You do not have permission to create tasks.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            if (widget.task != null && !adminState.hasPermission(AppModule.tasks, PermissionAction.edit)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Access Denied: You do not have permission to edit tasks.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            if (_formKey.currentState!.validate() &&
                                _selectedProjectId != null &&
                                _selectedAssigneeId != null) {
                              final task = ProjectTask(
                                id: widget.task?.id ?? 'task_${DateTime.now().millisecondsSinceEpoch}',
                                projectId: _selectedProjectId!,
                                projectName: _selectedProjectName!,
                                title: _titleController.text.trim(),
                                description: _descController.text.trim(),
                                assigneeId: _selectedAssigneeId!,
                                assigneeName: _selectedAssigneeName!,
                                dueDate: _dueDate.toIso8601String().substring(0, 10),
                                priority: _priority,
                                status: _status,
                              );
                              Navigator.of(context).pop(task);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: Text(widget.task == null ? 'Create Task' : tr('Save Changes')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
             ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: context.textSecondary,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: context.isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.primaryColor, width: 1.5),
      ),
    );
  }
}
