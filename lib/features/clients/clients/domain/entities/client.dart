class Client {
  final String id;
  final String name;
  final String contactPerson;
  final String email;
  final String phone;
  final String status; // 'Active', 'Inactive', 'Lead'
  final String industry;
  final int totalProjects;
  final double advancedPayment;
  final double fullPayment;

  const Client({
    required this.id,
    required this.name,
    required this.contactPerson,
    required this.email,
    required this.phone,
    required this.status,
    required this.industry,
    required this.totalProjects,
    required this.advancedPayment,
    required this.fullPayment,
  });

  Client copyWith({
    String? id,
    String? name,
    String? contactPerson,
    String? email,
    String? phone,
    String? status,
    String? industry,
    int? totalProjects,
    double? advancedPayment,
    double? fullPayment,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      industry: industry ?? this.industry,
      totalProjects: totalProjects ?? this.totalProjects,
      advancedPayment: advancedPayment ?? this.advancedPayment,
      fullPayment: fullPayment ?? this.fullPayment,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contactPerson': contactPerson,
      'email': email,
      'phone': phone,
      'status': status,
      'industry': industry,
      'totalProjects': totalProjects,
      'advancedPayment': advancedPayment,
      'fullPayment': fullPayment,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      contactPerson: map['contactPerson'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      status: map['status'] ?? 'Active',
      industry: map['industry'] ?? '',
      totalProjects: map['totalProjects'] ?? 0,
      advancedPayment: (map['advancedPayment'] as num?)?.toDouble() ?? 0.0,
      fullPayment: (map['fullPayment'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
