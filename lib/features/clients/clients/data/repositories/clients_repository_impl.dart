import 'package:software_house_erp/core/services/database_service.dart';
import '../../domain/entities/client.dart';
import '../../domain/repositories/clients_repository.dart';

class ClientsRepositoryImpl implements ClientsRepository {
  final DriftDatabaseService _dbService;

  ClientsRepositoryImpl(this._dbService);

  @override
  Future<List<Client>> getClients() async {
    final list = await _dbService.db.getAll(_dbService.db.clientsTable);
    return list.map((c) => Client(
      id: c.id,
      name: c.name,
      contactPerson: c.contactPerson,
      email: c.email,
      phone: c.phone,
      status: c.status,
      industry: c.industry,
      totalProjects: c.totalProjects,
      advancedPayment: c.advancedPayment,
      fullPayment: c.fullPayment,
    )).toList();
  }

  @override
  Future<void> addClient(Client client) async {
    await _dbService.db.upsert(
      _dbService.db.clientsTable,
      ClientsTableCompanion.insert(
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
      ),
    );
  }

  @override
  Future<void> updateClient(Client client) async {
    await addClient(client);
  }

  @override
  Future<void> deleteClient(String id) async {
    await _dbService.db.deleteById(_dbService.db.clientsTable, id);
  }
}
