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
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title + Add Button Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
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
                            ),
                            Row(
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
                                const SizedBox(width: 12),
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
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Search and Filters Bar
                        GlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Search
                                Expanded(
                                  flex: 2,
                                  child: Container(
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
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Project Filter
                                Expanded(
                                  child: Container(
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
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Assignee Filter
                                Expanded(
                                  child: Container(
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
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Priority Filter
                                Container(
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
                                ),
                              ],
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
                                  : ListView(
                                      children: columns.map((colStatus) {
                                        final colTasks = state.filteredTasks.where((t) => t.status == colStatus).toList();
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                                          child: ExpansionTile(
                                            title: Text('${tr(colStatus)} (${colTasks.length})', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                            backgroundColor: context.cardBg,
                                            collapsedBackgroundColor: context.cardBg,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              side: BorderSide(color: context.border),
                                            ),
                                            initiallyExpanded: colStatus == 'To Do',
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.all(12),
                                                child: Column(
                                                  children: colTasks.map((t) => Padding(
                                                    padding: const EdgeInsets.only(bottom: 8.0),
                                                    child: _TaskCard(task: t),
                                                  )).toList(),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
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

class _KanbanColumn extends ConsumerWidget {
  final String status;
  final List<ProjectTask> tasks;

  const _KanbanColumn({required this.status, required this.tasks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);
    
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
              onWillAcceptWithDetails: (details) => details.data.status != status,
              onAcceptWithDetails: (details) {
                ref.read(tasksProvider.notifier).updateTask(
                  details.data.copyWith(status: status),
                );
              },
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
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 16, color: context.textSecondary),
                color: context.cardBg,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 100),
                onSelected: (val) async {
                  if (val == 'delete') {
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
                  } else if (val == 'edit') {
                    final result = await showDialog<ProjectTask>(
                      context: context,
                      builder: (context) => _AddEditTaskDialog(task: task),
                    );
                    if (result != null) {
                      ref.read(tasksProvider.notifier).updateTask(result);
                    }
                  } else if (val.startsWith('move_')) {
                    final targetStatus = val.substring(5);
                    ref.read(tasksProvider.notifier).updateTask(task.copyWith(status: targetStatus));
                  }
                },
                itemBuilder: (context) {
                  final otherStatuses = ['To Do', 'In Progress', 'In Review', 'Done']
                      .where((s) => s != task.status)
                      .toList();
                  return [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit Task', style: TextStyle(color: context.textPrimary, fontSize: 12)),
                    ),
                    ...otherStatuses.map((s) => PopupMenuItem(
                      value: 'move_$s',
                      child: Text('Move to "$s"', style: TextStyle(color: context.textSecondary, fontSize: 12)),
                    )),
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

    return Dialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Consumer(
          builder: (context, ref, child) {
            final projects = ref.watch(projectsProvider).projects;
            final employees = ref.watch(employeesProvider).employees.where((e) => e.status == 'Active').toList();

            return Form(
              key: _formKey,
              child: SingleChildScrollView(
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
                      value: _selectedProjectId,
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

                    // Removed manual Assignee Dropdown, derived from Project automatically.
                    const SizedBox(height: 16),

                    // Priority & Status Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel(tr('Priority')),
                              DropdownButtonFormField<String>(
                                value: _priority,
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
                                value: _status,
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
            );
          },
        ),
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
