import '../../domain/entities/client.dart';

class ClientModel extends Client {
  const ClientModel({
    required super.id,
    required super.name,
    required super.contactPerson,
    required super.email,
    required super.phone,
    required super.status,
    required super.industry,
    required super.totalProjects,
    required super.advancedPayment,
    required super.fullPayment,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'] as String,
      name: json['name'] as String,
      contactPerson: json['contactPerson'] as String,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String,
      status: json['status'] as String,
      industry: json['industry'] as String,
      totalProjects: json['totalProjects'] as int,
      advancedPayment: (json['totalBilled'] as num?)?.toDouble() ?? 0.0,
      fullPayment: (json['fullPayment'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contactPerson': contactPerson,
      'email': email,
      'phone': phone,
      'status': status,
      'industry': industry,
      'totalProjects': totalProjects,
      'totalBilled': advancedPayment,
      'fullPayment': fullPayment,
    };
  }

  factory ClientModel.fromEntity(Client client) {
    return ClientModel(
      id: client.id,
      name: client.name,
      contactPerson: client.contactPerson,
      email: client.email,
      phone: client.phone,
      status: client.status,
      industry: client.industry,
      totalProjects: client.totalProjects,
      advancedPayment: client.advancedPayment,
      fullPayment: client.fullPayment,
    );
  }
}
