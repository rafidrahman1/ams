import '../models/asset_checklist_item.dart';
import '../models/volunteer_asset.dart';
import '../services/asset_service.dart';

class AssetRepository {
  final AssetService service;

  AssetRepository(this.service);

  Future<List<VolunteerAsset>> fetchMyAssets() {
    return service.fetchMyAssets();
  }

  Future<List<AssetChecklistItem>> fetchChecklistByAssetId(String astId) {
    return service.fetchChecklistByAssetId(astId);
  }
}
