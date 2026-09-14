class TimesheetEntry {
  final String id;
  final String employeeId;
  final String employeeName;
  final String projectId;
  final String projectName;
  final String taskTitle;
  final String date;
  final double hours;
  final String description;
  final String status; // 'Pending', 'Approved', 'Rejected'

  const TimesheetEntry({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.projectId,
    required this.projectName,
    required this.taskTitle,
    required this.date,
    required this.hours,
    required this.description,
    required this.status,
  });

  TimesheetEntry copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? projectId,
    String? projectName,
    String? taskTitle,
    String? date,
    double? hours,
    String? description,
    String? status,
  }) {
    return TimesheetEntry(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      taskTitle: taskTitle ?? this.taskTitle,
      date: date ?? this.date,
      hours: hours ?? this.hours,
      description: description ?? this.description,
      status: status ?? this.status,
    );
  }
}
