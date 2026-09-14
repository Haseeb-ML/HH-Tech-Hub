import '../entities/client.dart';

abstract class ClientsRepository {
  Future<List<Client>> getClients();
  Future<void> addClient(Client client);
  Future<void> updateClient(Client client);
  Future<void> deleteClient(String id);
}
