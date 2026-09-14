const _attendanceUnset = Object();

class AttendanceRecord {
  final String id;
  final String employeeId;
  final String employeeName;
  final String date; // 'YYYY-MM-DD'
  final String status; // 'Not Marked', 'Present', 'Absent', 'Leave', 'Off'
  final String? checkIn; // '09:00 AM'
  final String? checkOut; // '06:00 PM'
  final String? notes;

  const AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.date,
    required this.status,
    this.checkIn,
    this.checkOut,
    this.notes,
  });

  AttendanceRecord copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? date,
    String? status,
    Object? checkIn = _attendanceUnset,
    Object? checkOut = _attendanceUnset,
    Object? notes = _attendanceUnset,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      date: date ?? this.date,
      status: status ?? this.status,
      checkIn: identical(checkIn, _attendanceUnset) ? this.checkIn : checkIn as String?,
      checkOut: identical(checkOut, _attendanceUnset) ? this.checkOut : checkOut as String?,
      notes: identical(notes, _attendanceUnset) ? this.notes : notes as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'date': date,
      'status': status,
      'checkIn': checkIn,
      'checkOut': checkOut,
      'notes': notes,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] ?? '',
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      date: map['date'] ?? '',
      status: map['status'] ?? 'Not Marked',
      checkIn: map['checkIn'],
      checkOut: map['checkOut'],
      notes: map['notes'],
    );
  }
}
