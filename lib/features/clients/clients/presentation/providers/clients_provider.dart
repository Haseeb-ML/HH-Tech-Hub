import 'package:software_house_erp/core/services/database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/client.dart';
import '../../domain/repositories/clients_repository.dart';
import '../../data/repositories/clients_repository_impl.dart';
import 'package:software_house_erp/core/auth/models/app_permissions.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';
import 'package:software_house_erp/features/administration/recovery/presentation/providers/recovery_provider.dart';


class ClientsState {
  final List<Client> clients;
  final bool isLoading;
  final String searchQuery;
  final String statusFilter;

  const ClientsState({
    required this.clients,
    required this.isLoading,
    required this.searchQuery,
    required this.statusFilter,
  });

  ClientsState copyWith({
    List<Client>? clients,
    bool? isLoading,
    String? searchQuery,
    String? statusFilter,
  }) {
    return ClientsState(
      clients: clients ?? this.clients,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }

  List<Client> get filteredClients {
    return clients.where((client) {
      final matchesSearch = client.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          client.contactPerson.toLowerCase().contains(searchQuery.toLowerCase()) ||
          client.email.toLowerCase().contains(searchQuery.toLowerCase()) ||
          client.industry.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesStatus = statusFilter == 'All' || client.status == statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();
  }
}

final clientsRepositoryProvider = Provider<ClientsRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return ClientsRepositoryImpl(dbService);
});

class ClientsNotifier extends Notifier<ClientsState> {
  ClientsRepository get _repository => ref.read(clientsRepositoryProvider);

  @override
  ClientsState build() {
    _loadClients();
    return const ClientsState(
      clients: [],
      isLoading: true,
      searchQuery: '',
      statusFilter: 'All',
    );
  }

  Future<void> _loadClients() async {
    try {
      final clients = await _repository.getClients();
      state = state.copyWith(clients: clients, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setStatusFilter(String filter) {
    state = state.copyWith(statusFilter: filter);
  }

  Future<void> addClient(Client client) async {
    final adminState = ref.read(adminProvider);
    if (!adminState.hasPermission(AppModule.clients, PermissionAction.create)) {
      throw Exception('Access Denied: You do not have permission to add clients.');
    }
    await _repository.addClient(client);
    ref.read(adminProvider.notifier).logAction(
      action: 'Added client: ${client.name} (Industry: ${client.industry})',
      module: 'Clients',
    );
    final updatedClients = await _repository.getClients();
    state = state.copyWith(clients: updatedClients, isLoading: false);
  }

  Future<void> updateClient(Client client) async {
    final adminState = ref.read(adminProvider);
    if (!adminState.hasPermission(AppModule.clients, PermissionAction.edit)) {
      throw Exception('Access Denied: You do not have permission to edit clients.');
    }
    state = state.copyWith(isLoading: true);
    await _repository.updateClient(client);
    ref.read(adminProvider.notifier).logAction(
      action: 'Updated client: ${client.name} (Status: ${client.status})',
      module: 'Clients',
    );
    final updatedClients = await _repository.getClients();
    state = state.copyWith(clients: updatedClients, isLoading: false);
  }

  Future<void> deleteClient(String id) async {
    final adminState = ref.read(adminProvider);
    if (!adminState.hasPermission(AppModule.clients, PermissionAction.delete)) {
      throw Exception('Access Denied: You do not have permission to delete clients.');
    }
    final client = state.clients.where((c) => c.id == id).firstOrNull;
    if (client != null) {
      await ref.read(recoveryProvider.notifier).addDeletedItem(
        id: client.id,
        itemType: 'Client',
        title: client.name,
        subtitle: '${client.contactPerson} • ${client.email}',
        jsonData: client.toMap(),
        deletedBy: adminState.currentUser?.name ?? 'Admin',
      );
    }
    state = state.copyWith(isLoading: true);
    await _repository.deleteClient(id);
    ref.read(adminProvider.notifier).logAction(
      action: 'Deleted client: $id',
      module: 'Clients',
    );
    final updatedClients = await _repository.getClients();
    state = state.copyWith(clients: updatedClients, isLoading: false);
  }
}

final clientsProvider = NotifierProvider<ClientsNotifier, ClientsState>(() {
  return ClientsNotifier();
});
