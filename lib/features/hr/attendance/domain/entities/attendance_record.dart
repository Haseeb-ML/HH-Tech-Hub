const _attendanceUnset = Object();

class AttendanceStatus {
  static const notMarked = 'Not Marked';
  static const present = 'Present';
  static const absent = 'Absent';
  static const halfDay = 'Half Day';
  static const leave = 'Leave';
  static const workFromHome = 'Work From Home';
  static const officialVisit = 'Official Visit';
  static const off = 'Off';
  static const holiday = 'Holiday';

  static const List<String> all = [
    notMarked,
    present,
    absent,
    halfDay,
    leave,
    workFromHome,
    officialVisit,
    off,
    holiday,
  ];

  static const List<String> values = all;

  static bool isValid(String status) => all.contains(status);

  /// Normalizes legacy statuses (e.g. 'Late' -> 'Present')
  static String normalize(String? status) {
    if (status == null || status.trim().isEmpty) return notMarked;
    final trimmed = status.trim();
    if (trimmed.toLowerCase() == 'late') return present;
    for (final s in all) {
      if (s.toLowerCase() == trimmed.toLowerCase()) return s;
    }
    return notMarked;
  }
}

int? parseTimeToMinutes(String? timeStr) {
  if (timeStr == null || timeStr.trim().isEmpty) return null;
  final trimmed = timeStr.trim().toUpperCase();

  final reg12 = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$', caseSensitive: false);
  final match = reg12.firstMatch(trimmed);
  if (match != null) {
    int h = int.tryParse(match.group(1)!) ?? 0;
    final int m = int.tryParse(match.group(2)!) ?? 0;
    final ampm = match.group(3)?.toUpperCase();
    if (ampm != null) {
      if (ampm == 'PM' && h < 12) h += 12;
      if (ampm == 'AM' && h == 12) h = 0;
    }
    return h * 60 + m;
  }
  return null;
}

class AttendanceRecord {
  final String id;
  final String employeeId;
  final String employeeName;
  final String date; // 'YYYY-MM-DD'
  final String status; // One of AttendanceStatus.all
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

  bool isLate({int workStartMinutes = 9 * 60, int graceMinutes = 15}) {
    if (status != AttendanceStatus.present &&
        status != AttendanceStatus.halfDay &&
        status != AttendanceStatus.workFromHome &&
        status != AttendanceStatus.officialVisit) {
      return false;
    }
    final inMinutes = parseTimeToMinutes(checkIn);
    if (inMinutes == null) return false;
    final cutoff = workStartMinutes + graceMinutes;
    return inMinutes > cutoff;
  }

  int lateMinutes({int workStartMinutes = 9 * 60, int graceMinutes = 15}) {
    if (status != AttendanceStatus.present &&
        status != AttendanceStatus.halfDay &&
        status != AttendanceStatus.workFromHome &&
        status != AttendanceStatus.officialVisit) {
      return 0;
    }
    final inMinutes = parseTimeToMinutes(checkIn);
    if (inMinutes == null) return 0;
    final cutoff = workStartMinutes + graceMinutes;
    return inMinutes > cutoff ? inMinutes - workStartMinutes : 0;
  }

  double? get workingHours {
    if (checkIn == null || checkOut == null) return null;
    final inM = parseTimeToMinutes(checkIn);
    final outM = parseTimeToMinutes(checkOut);
    if (inM == null || outM == null) return null;
    if (outM <= inM) return null;
    return (outM - inM) / 60.0;
  }

  String get workingHoursDisplay {
    final hours = workingHours;
    if (hours == null) {
      if (checkIn != null &&
          checkIn!.trim().isNotEmpty &&
          (checkOut == null || checkOut!.trim().isEmpty)) {
        if (status == AttendanceStatus.present ||
            status == AttendanceStatus.halfDay ||
            status == AttendanceStatus.workFromHome ||
            status == AttendanceStatus.officialVisit) {
          return 'Incomplete';
        }
      }
      return '--';
    }
    final wholeH = hours.toInt();
    final mins = ((hours - wholeH) * 60).round();
    return '${wholeH}h ${mins.toString().padLeft(2, '0')}m';
  }

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
    final rawStatus = (map['status'] ?? AttendanceStatus.notMarked).toString();
    return AttendanceRecord(
      id: map['id'] ?? '',
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      date: map['date'] ?? '',
      status: AttendanceStatus.normalize(rawStatus),
      checkIn: map['checkIn'],
      checkOut: map['checkOut'],
      notes: map['notes'],
    );
  }
}
