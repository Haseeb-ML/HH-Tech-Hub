class ProjectTask {
  final String id;
  final String projectId;
  final String projectName;
  final String title;
  final String description;
  final String assigneeId;
  final String assigneeName;
  final String dueDate;
  final String priority; // 'Low', 'Medium', 'High'
  final String status; // 'To Do', 'In Progress', 'In Review', 'Done'

  const ProjectTask({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.title,
    required this.description,
    required this.assigneeId,
    required this.assigneeName,
    required this.dueDate,
    required this.priority,
    required this.status,
  });

  ProjectTask copyWith({
    String? id,
    String? projectId,
    String? projectName,
    String? title,
    String? description,
    String? assigneeId,
    String? assigneeName,
    String? dueDate,
    String? priority,
    String? status,
  }) {
    return ProjectTask(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      title: title ?? this.title,
      description: description ?? this.description,
      assigneeId: assigneeId ?? this.assigneeId,
      assigneeName: assigneeName ?? this.assigneeName,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
    );
  }
}
