import '../entities/asset.dart';

abstract class AssetsRepository {
  Future<List<Asset>> getAssets();
  Future<void> addAsset(Asset asset);
  Future<void> updateAsset(Asset asset);
  Future<void> deleteAsset(String id);
}
