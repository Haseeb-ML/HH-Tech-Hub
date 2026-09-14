import 'package:software_house_erp/core/services/database_service.dart';
import '../../domain/entities/asset.dart';
import '../../domain/repositories/assets_repository.dart';
import 'package:drift/drift.dart';

class AssetsRepositoryImpl implements AssetsRepository {
  final DriftDatabaseService _dbService;

  AssetsRepositoryImpl(this._dbService);

  @override
  Future<List<Asset>> getAssets() async {
    final list = await _dbService.db.getAll(_dbService.db.assetsTable);
    return list.map((a) => Asset(
      id: a.id,
      name: a.name,
      type: a.type,
      serialNumber: a.serialNumber,
      purchaseDate: a.purchaseDate,
      cost: a.cost,
      status: a.status,
      condition: a.condition,
      assignedToId: a.assignedToId,
      assignedToName: a.assignedToName,
    )).toList();
  }

  @override
  Future<void> addAsset(Asset asset) async {
    await _dbService.db.upsert(
      _dbService.db.assetsTable,
      AssetsTableCompanion.insert(
        id: asset.id,
        name: asset.name,
        type: asset.type,
        serialNumber: asset.serialNumber,
        purchaseDate: asset.purchaseDate,
        cost: asset.cost,
        status: asset.status,
        condition: asset.condition,
        assignedToId: Value(asset.assignedToId),
        assignedToName: Value(asset.assignedToName),
      ),
    );
  }

  @override
  Future<void> updateAsset(Asset asset) async {
    await addAsset(asset);
  }

  @override
  Future<void> deleteAsset(String id) async {
    await (_dbService.db.delete(_dbService.db.assetsTable)..where((t) => t.id.equals(id))).go();
  }
}
