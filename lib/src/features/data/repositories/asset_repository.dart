import '../models/volunteer_asset.dart';
import '../services/asset_service.dart';

class AssetRepository {
  final AssetService service;

  AssetRepository(this.service);

  Future<List<VolunteerAsset>> fetchMyAssets() {
    return service.fetchMyAssets();
  }
}
