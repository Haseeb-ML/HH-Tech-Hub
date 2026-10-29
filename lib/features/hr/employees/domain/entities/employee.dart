class Employee {
  final String id;
  final String name;
  final String email;
  final List<String> phones;
  final String cnic;
  final String designation;
  final String department;
  final String joiningDate;
  final String? leavingDate;
  final String status; // 'Active', 'On Leave', 'Terminated'
  final String salaryType; // 'Monthly', 'Hourly'
  final double baseSalary;
  final String paymentMethod; // 'Bank Transfer', 'Cash', 'Cheque'

  const Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.phones,
    this.cnic = '',
    required this.designation,
    required this.department,
    required this.joiningDate,
    this.leavingDate,
    required this.status,
    required this.salaryType,
    required this.baseSalary,
    required this.paymentMethod,
  });

  Employee copyWith({
    String? id,
    String? name,
    String? email,
    List<String>? phones,
    String? cnic,
    String? designation,
    String? department,
    String? joiningDate,
    String? leavingDate,
    String? status,
    String? salaryType,
    double? baseSalary,
    String? paymentMethod,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phones: phones ?? this.phones,
      cnic: cnic ?? this.cnic,
      designation: designation ?? this.designation,
      department: department ?? this.department,
      joiningDate: joiningDate ?? this.joiningDate,
      leavingDate: leavingDate ?? this.leavingDate,
      status: status ?? this.status,
      salaryType: salaryType ?? this.salaryType,
      baseSalary: baseSalary ?? this.baseSalary,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phones': phones,
      'cnic': cnic,
      'designation': designation,
      'department': department,
      'joiningDate': joiningDate,
      'leavingDate': leavingDate,
      'status': status,
      'salaryType': salaryType,
      'baseSalary': baseSalary,
      'paymentMethod': paymentMethod,
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phones: List<String>.from(map['phones'] ?? (map['phone'] != null ? [map['phone']] : [])),
      cnic: map['cnic'] ?? '',
      designation: map['designation'] ?? '',
      department: map['department'] ?? '',
      joiningDate: map['joiningDate'] ?? '',
      leavingDate: map['leavingDate'],
      status: map['status'] ?? 'Active',
      salaryType: map['salaryType'] ?? 'Monthly',
      baseSalary: (map['baseSalary'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] ?? 'Bank Transfer',
    );
  }
}
